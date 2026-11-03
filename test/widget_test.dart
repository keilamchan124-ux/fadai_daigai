import 'package:fadai_daigai/data/game_catalog.dart';
import 'package:fadai_daigai/engine/game_engine.dart';
import 'package:fadai_daigai/main.dart';
import 'package:fadai_daigai/models/game_models.dart';
import 'package:fadai_daigai/services/game_services.dart';
import 'package:fadai_daigai/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Catalog & Roguelike completeness: 40 shops, 16 synergies, 24 relics, 18 tactical 3-choice events', () {
    expect(kAllShops.length, 40);
    expect(kAllSynergies.length, 16);
    expect(kAllBosses.length, 5);
    expect(kAllRelics.length, 24);
    expect(kAllTacticalEvents.length, 18);
    expect(kAllTalents.length, 24);
    expect(kAllLuxuries.length, 24);
    expect(kAllAchievements.length, 100);
  });

  test('Quarter-based Roguelike loop, 3-in-1 Merge into newest slot, Draft Cache/Lock/Skip & Save', () {
    final engine = GameEngine(seed: 42);

    // 1. 開局即有傳家寶 3 選 1 Draft，且排陣階段時間完全暫停
    expect(engine.activeDraft, isNotNull);
    expect(engine.activeDraft!.kind, DraftKind.starterRelic);
    expect(engine.selectDraftChoice(0), isTrue);
    expect(engine.equippedRelicIds.length, 1);
    expect(engine.quarterPhase, QuarterPhase.planning);
    final secBefore = engine.quarterSecondsLeft;
    engine.tickOneSecond();
    expect(engine.quarterSecondsLeft, secBefore); // 排陣階段唔會偷跑秒數

    // 2. 測試三合一自動升星（保留最新擺入嗰格）
    engine.cash = 50000;
    expect(engine.buyShopIntoSlot('t1_fishball', targetSlot: 1), isTrue);
    expect(engine.willShopTriggerThreeMerge('t1_fishball'), isTrue);
    expect(engine.buyShopIntoSlot('t1_fishball', targetSlot: 3), isTrue);
    expect(engine.slots[3]!.level, 2);
    expect(engine.slots[3]!.starBadge, '⭐⭐');
    expect(engine.slots[0], isNull);
    expect(engine.slots[1], isNull);

    // 3. 測試街舖招租 3 選 1 緩存防刷、鎖卡與洗牌
    engine.openShopDraft3Choice();
    final firstSetIds = engine.activeDraft!.choices.map((c) => c.id).toList();
    engine.activeDraft = null;
    engine.openShopDraft3Choice(); // 重開唔會免費刷新
    expect(engine.activeDraft!.choices.map((c) => c.id).toList(), firstSetIds);
    engine.toggleLockDraftChoice(0);
    final lockedId = engine.activeDraft!.choices[0].id;
    expect(engine.rerollCurrentDraft(), isTrue);
    expect(engine.activeDraft!.choices.first.id, lockedId);
    expect(engine.selectDraftChoice(0), isTrue);

    // 4. 測試開市 18 秒跑完自動交租進入第 2 季
    engine.startQuarterMarketRun();
    expect(engine.quarterPhase, QuarterPhase.running);
    for (int i = 0; i < 18; i++) {
      engine.tickOneSecond();
    }
    expect(engine.currentQuarter, 2);
    expect(engine.quarterPhase, QuarterPhase.planning);
    expect(engine.activeDraft, isNotNull); // 自動彈出季度免費 3 選 1
    engine.skipCurrentDraftForBonus();
    expect(engine.activeDraft, isNull);

    // 5. 測試引繼碼匯出與匯入（包含奇物與季度進度）
    final code = PersistenceService.exportSaveCode(engine);
    final engine2 = GameEngine(seed: 99);
    expect(PersistenceService.importSaveCode(engine2, code), isTrue);
    expect(engine2.equippedRelicIds, engine.equippedRelicIds);
    expect(engine2.currentQuarter, 2);
    expect(HkFormatters.money(12500), '\$1.3萬');
    expect(HkFormatters.money(2e16), '\$2京');
  });

  testWidgets('FadaiDaigaiApp renders Quarter HUD and Market Start button', (WidgetTester tester) async {
    final testEngine = GameEngine(seed: 7);
    await tester.pumpWidget(
      FadaiDaigaiApp(
        customEngine: testEngine,
        enablePeriodicTimer: false,
      ),
    );
    await tester.pump();

    expect(find.textContaining('總資產'), findsOneWidget);
    expect(find.textContaining('開始營業'), findsOneWidget);
    expect(find.textContaining('招租 (免×1)'), findsOneWidget);
    expect(find.textContaining('決策 ('), findsOneWidget);
  });
}
