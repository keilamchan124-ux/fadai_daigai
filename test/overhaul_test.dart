import 'package:fadai_daigai/engine/game_engine.dart';
import 'package:fadai_daigai/data/game_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fadai_daigai/models/game_models.dart';

GameEngine ready() => GameEngine(seed: 42)..selectDraftChoice(0);
void main() {
  test('cash upgrades preserve star identity and directional rules', () {
    final e = ready()..cash = 100000;
    final direction = e.targetSlotsForShopAt(0);
    for (var i = 0; i < 3; i++) {
      expect(e.upgradeShopAtSlot(0), isTrue);
    }
    expect(e.slots[0]!.level, 1);
    expect(e.slots[0]!.upgradeLevel, 3);
    expect(e.upgradeShopAtSlot(0), isFalse);
    expect(e.targetSlotsForShopAt(0), direction);
  });
  test('save preserves exact next reroll and running continuation', () {
    final a = ready()..cash = 100000;
    a.openShopDraft3Choice();
    a.toggleLockDraftChoice(0);
    final b = GameEngine(seed: 99)..loadFromJsonString(a.toJsonString());
    expect(
      b.activeDraft!.choices.map((c) => c.id),
      a.activeDraft!.choices.map((c) => c.id),
    );
    a.rerollCurrentDraft();
    b.rerollCurrentDraft();
    expect(
      b.activeDraft!.choices.map((c) => c.id),
      a.activeDraft!.choices.map((c) => c.id),
    );
    a.skipCurrentDraftForBonus();
    b.skipCurrentDraftForBonus();
    a.startQuarterMarketRun();
    b.startQuarterMarketRun();
    for (var i = 0; i < 18; i++) {
      a.tickOneSecond();
      b.tickOneSecond();
    }
    expect(b.cash, a.cash);
    expect(
      b.stocks.map((s) => s.currentPrice),
      a.stocks.map((s) => s.currentPrice),
    );
  });
  test('quarter market remains stable and phase guards reject trading', () {
    final e = ready()..cash = 100000;
    final phase = e.marketPhase;
    e.startQuarterMarketRun();
    expect(e.buyProperty(e.properties.first.id), isFalse);
    expect(e.borrowLoan(100), isFalse);
    expect(e.upgradeShopAtSlot(0), isFalse);
    for (var i = 0; i < 18; i++) {
      e.tickOneSecond();
    }
    expect(e.quarterLedger.single['market'], phase.name);
    expect(e.completedQuarters, 1);
  });
  test('retiring without play earns no prestige or trust fund', () {
    final e = ready();
    expect(e.calculateRetirementPrestige(), 0);
    e.retireAndInherit();
    expect(e.familyFund, 0);
    expect(e.familyPrestige, 0);
  });
  test('relic slots require explicit replacement', () {
    final e = ready();
    e.equippedRelicIds = kAllRelics.take(6).map((r) => r.id).toList();
    e.pendingRelicDrafts = 1;
    e.openRelicDraft3Choice();
    final old = List.of(e.equippedRelicIds);
    final chosen = e.activeDraft!.choices.first.id;
    expect(e.selectDraftChoice(0), isFalse);
    expect(e.equippedRelicIds, old);
    expect(e.selectDraftChoice(0, replaceRelicId: old[2]), isTrue);
    expect(e.equippedRelicIds, contains(chosen));
    expect(e.equippedRelicIds, isNot(contains(old[2])));
  });
  test('quarterly event is once per quarter and recent events persist', () {
    final e = ready()..cash = 100000;
    expect(e.openTacticalEvent3Choice(), isTrue);
    final options = e.activeDraft!.choices.map((c) => c.id).toList();
    final b = GameEngine(seed: 8)..loadFromJsonString(e.toJsonString());
    expect(b.activeDraft!.choices.map((c) => c.id), options);
    expect(e.selectDraftChoice(2, targetSlot: 0), isTrue);
    expect(e.openTacticalEvent3Choice(), isFalse);
  });
  test('merge preserves investment and newest selected position', () {
    final e = ready()..cash = 100000;
    e.buyShopIntoSlot('t1_fishball', targetSlot: 3);
    e.buyShopIntoSlot('t1_fishball', targetSlot: 1);
    expect(e.slots[1]!.level, 2);
    expect(e.slots[1]!.investedCash, 1200);
    expect(e.slots[0], isNull);
    expect(e.slots[3], isNull);
  });
  test('goal text and preview do not mutate live cash or rewards', () {
    final e = ready()..cash = 100000;
    final before = e.toJsonString();
    for (var i = 0; i < 10; i++) {
      e.almostThereGoalText;
      e.previewQuarterCash();
    }
    expect(
      e.toJsonString().replaceAll(
        RegExp(r'"lastSavedMs":\d+'),
        '"lastSavedMs":0',
      ),
      before.replaceAll(RegExp(r'"lastSavedMs":\d+'), '"lastSavedMs":0'),
    );
  });
  test('resume cannot repeat opening pulse or reconfigure business', () {
    final e = ready()..cash = 100000;
    e.startQuarterMarketRun();
    for (var i = 0; i < 5; i++) {
      e.tickOneSecond();
    }
    final b = GameEngine(seed: 99)..loadFromJsonString(e.toJsonString());
    expect(b.resumingQuarter, isTrue);
    expect(b.borrowLoan(100), isFalse);
    b.startQuarterMarketRun();
    for (var i = 0; i < 13; i++) {
      e.tickOneSecond();
      b.tickOneSecond();
    }
    expect(b.cash, e.cash);
    expect(b.currentQuarter, e.currentQuarter);
  });
  test('daily challenge ignores permanent income and wealth advantages', () {
    final a = ready();
    final b = ready();
    b.familyFund = 1000000;
    b.isTycoonVip = true;
    b.talentLevels['tal_fs_1'] = 5;
    a.startDailyChallenge(DateTime.utc(2026, 11, 3));
    b.startDailyChallenge(DateTime.utc(2026, 11, 3));
    expect(a.cash, b.cash);
    expect(a.globalIncomeMultiplier, b.globalIncomeMultiplier);
    expect(
      a.activeDraft!.choices.map((c) => c.id),
      b.activeDraft!.choices.map((c) => c.id),
    );
  });
  test('rescue is a saved choice and charges next quarter exactly once', () {
    final e = ready();
    e.slots = List.filled(e.slots.length, null, growable: true);
    e.cash = e.quarterRentQuota * 0.8;
    e.startQuarterMarketRun();
    e.triggerTimeSkip();
    expect(e.quarterPhase.name, 'rescue');
    final b = GameEngine(seed: 7)..loadFromJsonString(e.toJsonString());
    expect(b.resolveRescue(true), isTrue);
    expect(b.deferredPayment, closeTo(225, 0.001));
    expect(b.completedQuarters, 1);
    expect(b.resolveRescue(true), isFalse);
  });
  test('auction refuses full board without charging or minting money', () {
    final e = ready()..cash = 100000;
    e.startBearMarketAuction();
    e.playerBidInAuction();
    for (var i = 0; i < e.slots.length; i++) {
      if (i != e.currentTier.goldenSlotIndex) {
        e.buyShopIntoSlot('t1_newsstand', targetSlot: i, isFreeFromDraft: true);
      }
    }
    // Fill without auto-merging to exercise settlement guard.
    for (var i = 0; i < e.slots.length; i++) {
      if (i != e.currentTier.goldenSlotIndex) {
        e.slots[i] = e.slots.whereType<PlacedShop>().first;
      }
    }
    final before = e.cash;
    e.finishAuctionNow();
    expect(e.cash, before);
    expect(e.activeAuction, isNotNull);
  });
  test('invalid import rolls back the entire engine state', () {
    final e = ready()..cash = 3210;
    final ids = e.equippedRelicIds.toList();
    expect(
      () => e.loadFromJsonString('{"cash":42,"bankLoan":0,"saveVersion":999}'),
      throwsFormatException,
    );
    expect(e.cash, 3210);
    expect(e.equippedRelicIds, ids);
  });
  test(
    'starting plans unlock through completed quarters and preserve asset budget',
    () {
      final e = ready();
      expect(e.isStartingPlanUnlocked('logistics'), isFalse);
      e.metrics['quarters_completed'] = 6;
      e.startNewGeneration(plan: 'logistics');
      expect(e.startingPlan, 'logistics');
      expect(e.slots[0]!.definitionId, 't1_newsstand');
      expect(e.slots[4]!.definitionId, 't1_van_delivery');
    },
  );
  test('endless mode is opt in and starts the fifth chapter', () {
    final e = ready();
    expect(e.continueEndless(), isFalse);
    e.activeDraft = null;
    e.currentTier = TierType.multinational;
    e.currentQuarter = 12;
    e.quarterPhase = QuarterPhase.victory;
    expect(e.continueEndless(), isTrue);
    expect(e.currentQuarter, 13);
    expect(e.currentTier, TierType.tycoon);
    expect(e.quarterRentQuota, greaterThan(44000));
  });
}
