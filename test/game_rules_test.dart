import 'package:fadai_daigai/engine/game_engine.dart';
import 'package:fadai_daigai/models/game_models.dart';
import 'package:flutter_test/flutter_test.dart';

GameEngine ready() {
  final e = GameEngine(seed: 42);
  e.selectDraftChoice(0);
  return e;
}

void main() {
  test('moving and buying in planning cannot mint income', () {
    final e = ready();
    final cash = e.cash;
    final tokens = e.pendingFreeDrafts;
    for (var i = 0; i < 100; i++) {
      e.swapOrMoveShops(4, 1);
      e.swapOrMoveShops(1, 4);
    }
    expect(e.cash, cash);
    expect(e.pendingFreeDrafts, tokens);
    expect(e.buyShopIntoSlot('t1_newsstand', isFreeFromDraft: true), isTrue);
    expect(e.cash, cash);
  });
  test('planning cannot generate time or cash; fast forward matches ticks', () {
    final a = ready();
    final b = ready();
    final cash = a.cash;
    expect(a.triggerTimeSkip(), isFalse);
    a.tickOneSecond(allowInPlanning: true);
    expect(a.cash, cash);
    expect(a.runElapsedSeconds, 0);
    a.startQuarterMarketRun();
    b.startQuarterMarketRun();
    expect(a.triggerTimeSkip(), isTrue);
    for (var i = 0; i < 18; i++) {
      b.tickOneSecond();
    }
    expect(a.cash, b.cash);
    expect(a.currentQuarter, b.currentQuarter);
    expect(a.pendingFreeDrafts, b.pendingFreeDrafts);
  });
  test('paid draft skips do not award money or create free shops', () {
    final e = ready();
    e.pendingFreeDrafts = 0;
    final cash = e.cash;
    for (var i = 0; i < 10; i++) {
      e.openShopDraft3Choice(isFree: true);
      expect(e.activeDraft!.choices.every((c) => c.cost > 0), isTrue);
      e.skipCurrentDraftForBonus();
    }
    expect(e.cash, cash);
  });
  test(
    'selling refunds actual paid investment, free shops cannot mint cash',
    () {
      final e = ready();
      e.cash = 10000;
      e.equippedRelicIds = ['rel_abacus_gold'];
      final before = e.cash;
      e.buyShopIntoSlot('t1_newsstand', targetSlot: 1);
      e.sellShopAtSlot(1);
      expect(e.cash, before);
      e.sellShopAtSlot(0);
      expect(e.cash, before);
      expect(e.borrowLoan(-100), isFalse);
      expect(e.borrowLoan(double.nan), isFalse);
    },
  );
  test('quarter caps and shop investment survive save load', () {
    final e = ready();
    e.quarterRebatePaid = 42;
    e.quarterChainDrafts = 1;
    e.slots[0]!.investedCash = 300;
    e.slots[0]!.secondsAccumulator = 2;
    final restored = GameEngine(seed: 8)..loadFromJsonString(e.toJsonString());
    expect(restored.quarterRebatePaid, 42);
    expect(restored.quarterChainDrafts, 1);
    expect(restored.slots[0]!.investedCash, 300);
    expect(restored.slots[0]!.secondsAccumulator, 2);
    expect(restored.quarterPhase, QuarterPhase.planning);
  });
}
