// ignore_for_file: avoid_print
import 'package:fadai_daigai/engine/game_engine.dart';
import 'package:fadai_daigai/models/game_models.dart';
import 'package:fadai_daigai/utils/formatters.dart';

void _playNaiveBotRun(GameEngine engine) {
  if (engine.activeDraft != null) engine.selectDraftChoice(0);
  // 笨 Bot：唔識排陣拖位，唔留錢交租，見到乜亂買乜
  for (int q = 1; q <= GameEngine.maxQuarters; q++) {
    if (engine.quarterPhase == QuarterPhase.gameOver || engine.quarterPhase == QuarterPhase.victory) break;
    if (engine.activeDraft != null) {
      if (!engine.selectDraftChoice(q % 3)) {
        engine.skipCurrentDraftForBonus();
      }
    }
    engine.openShopDraft3Choice();
    if (engine.activeDraft != null) {
      if (!engine.selectDraftChoice(0)) engine.activeDraft = null;
    }
    engine.startQuarterMarketRun();
    for (int s = 0; s < 18; s++) {
      engine.tickOneSecond();
    }
  }
}

void _playStrategicBotRun(GameEngine engine) {
  if (engine.activeDraft != null) engine.selectDraftChoice(0);
  // 策略 Bot：開局即拖動糖水舖去魚蛋檔右邊 (#2) 砌連環閃電
  engine.swapOrMoveShops(4, 1);

  for (int q = 1; q <= GameEngine.maxQuarters; q++) {
    if (engine.quarterPhase == QuarterPhase.gameOver || engine.quarterPhase == QuarterPhase.victory) break;

    // 處理季度免費 3 選 1 或奇物 3 選 1
    while (engine.activeDraft != null || engine.pendingRelicDrafts > 0 || engine.pendingFreeDrafts > 0) {
      if (engine.activeDraft == null && engine.pendingRelicDrafts > 0) {
        engine.openRelicDraft3Choice();
      } else if (engine.activeDraft == null && engine.pendingFreeDrafts > 0) {
        engine.openShopDraft3Choice(isFree: true);
      }
      final draft = engine.activeDraft;
      if (draft == null) break;
      int bestIdx = 0;
      for (int i = 0; i < draft.choices.length; i++) {
        final c = draft.choices[i];
        if (c.willTriggerThreeMerge || c.synergyPreviewText.contains('激活') || c.relicSynergyText.isNotEmpty) {
          bestIdx = i;
          break;
        }
      }
      if (!engine.selectDraftChoice(bestIdx)) {
        engine.skipCurrentDraftForBonus();
      }
    }

    // 留夠本季交租安全線後，多餘資金用嚟吞併死對頭或觸發命運 3 選 1
    final reserve = engine.quarterRentQuota * 0.85;
    if (!engine.bossDefeatedInCurrentTier && engine.cash - engine.takeoverCost >= reserve * 0.5) {
      engine.takeoverRivalBoss();
      if (engine.activeDraft != null) engine.selectDraftChoice(0);
    }
    if (engine.actionPoints >= 1) {
      if (engine.openTacticalEvent3Choice()) {
        // 揀穩健或減租/升星路線
        engine.selectDraftChoice(1);
      }
    }

    engine.startQuarterMarketRun();
    for (int s = 0; s < 18; s++) {
      engine.tickOneSecond();
    }
  }
}

void main() {
  const int runsPerBot = 500;
  int naiveWins = 0;
  int strategicWins = 0;
  double naiveTotalQuarters = 0;
  double strategicTotalQuarters = 0;
  double strategicTotalPeakNW = 0;
  int strategicMergedShops = 0;

  final sw = Stopwatch()..start();

  for (int r = 0; r < runsPerBot; r++) {
    final naiveEngine = GameEngine(seed: 10000 + r);
    _playNaiveBotRun(naiveEngine);
    if (naiveEngine.quarterPhase == QuarterPhase.victory) naiveWins++;
    naiveTotalQuarters += naiveEngine.currentQuarter;

    final stratEngine = GameEngine(seed: 50000 + r);
    _playStrategicBotRun(stratEngine);
    if (stratEngine.quarterPhase == QuarterPhase.victory) strategicWins++;
    strategicTotalQuarters += stratEngine.currentQuarter;
    strategicTotalPeakNW += stratEngine.peakNetWorthThisRun;
    strategicMergedShops += stratEngine.slots.where((s) => s != null && s.level >= 2).length;
  }

  sw.stop();
  print('=== 《發達大計》Quarter-Based Roguelike 1,000 局對比模擬報告 ===');
  print('1,000 局模擬總耗時: ${sw.elapsedMilliseconds} ms');
  print('【笨 Bot (亂買唔排陣)】12 季通關勝率: ${(naiveWins / runsPerBot * 100).toStringAsFixed(1)}% (平均死於第 ${(naiveTotalQuarters / runsPerBot).toStringAsFixed(1)} 季)');
  print('【策略 Bot (排連鎖+湊三合一+控租)】12 季通關勝率: ${(strategicWins / runsPerBot * 100).toStringAsFixed(1)}% (平均到達第 ${(strategicTotalQuarters / runsPerBot).toStringAsFixed(1)} 季)');
  print('策略 Bot 平均每局合成 ⭐⭐/⭐⭐⭐ 街舖數: ${(strategicMergedShops / runsPerBot).toStringAsFixed(2)} 間');
  print('策略 Bot 平均最高身家: ${HkFormatters.money(strategicTotalPeakNW / runsPerBot)}');
}
