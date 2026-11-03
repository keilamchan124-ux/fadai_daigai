import 'dart:async';

import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../services/game_services.dart';
import '../utils/formatters.dart';
import '../widgets/action_sheets.dart';
import '../widgets/engine_builder.dart';
import '../widgets/meta_sheets.dart';
import '../widgets/mini_stock_bar_widget.dart';
import '../widgets/roguelike_draft_modal.dart';
import '../widgets/street_grid_widget.dart';
import '../widgets/top_hud_widget.dart';

class MainGameScreen extends StatefulWidget {
  final GameEngine engine;
  final bool enablePeriodicTimer;

  const MainGameScreen({
    super.key,
    required this.engine,
    this.enablePeriodicTimer = true,
  });

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> with WidgetsBindingObserver {
  Timer? _tickTimer;
  int _autoSaveCounter = 0;
  bool _shownAuctionDialogForCurrent = false;

  GameEngine get engine => widget.engine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootAndLoad();
    if (widget.enablePeriodicTimer) {
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        final prevQ = engine.currentQuarter;
        engine.tickOneSecond();
        if (engine.isSpeed2x && engine.quarterPhase == QuarterPhase.running) {
          engine.tickOneSecond();
        }
        if (engine.currentQuarter != prevQ) {
          MonetizationService.resetQuarterAdFallback();
          if (engine.activeDraft != null) {
            RoguelikeDraftModal.show(context, engine);
          }
        }
        _autoSaveCounter += 1;
        if (_autoSaveCounter >= 10) {
          _autoSaveCounter = 0;
          PersistenceService.saveGame(engine);
        }
        if (engine.activeAuction == null) {
          _shownAuctionDialogForCurrent = false;
        }
      });
    }
  }

  Future<void> _bootAndLoad() async {
    await MonetizationService.initialize(engine);
    await PersistenceService.loadGameAndSettleOffline(engine);
    if (!mounted) return;
    if (widget.enablePeriodicTimer && engine.generation == 1 && engine.runElapsedSeconds < 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await ActionSheets.showOpeningComicDialog(context, engine);
        if (!mounted) return;
        if (engine.activeDraft != null) {
          RoguelikeDraftModal.show(context, engine);
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      PersistenceService.saveGame(engine);
    } else if (state == AppLifecycleState.resumed) {
      engine.calculateAndApplyOfflineFund(DateTime.now());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickTimer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return EngineBuilder(
      engine: engine,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF140E0B),
          body: SafeArea(
            child: Column(
              children: [
                // 1. 頂部狀態欄 (約 15% 高度)
                TopHudWidget(
                  engine: engine,
                  onOpenRetireModal: () => MetaSheets.showRetireAndTalentSheet(context, engine),
                  onOpenMetaHub: () => MetaSheets.showMetaHubSheet(context, engine),
                  onOpenVipStore: () => MetaSheets.showVipAndSaveSheet(context, engine),
                ),
                // 如果有進行中銀主盤拍賣，顯示頂部搶拍橫幅
                if (engine.activeAuction != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    color: const Color(0xFFD84315),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '🔨 ${engine.activeAuction!.title} 搶拍中 (${engine.activeAuction!.secondsLeft}s)：現價 ${HkFormatters.money(engine.activeAuction!.currentBid)}',
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD600),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          ),
                          onPressed: () {
                            _shownAuctionDialogForCurrent = true;
                            MetaSheets.showAuctionDialog(context, engine);
                          },
                          child: Text(
                            _shownAuctionDialogForCurrent ? '進入競投' : '參與競投',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                // 2. 中間你條街 (約 55% 高度)
                Expanded(
                  child: StreetGridWidget(
                    engine: engine,
                    onTapEmptySlot: (slotIdx) {
                      engine.openShopDraft3Choice();
                      RoguelikeDraftModal.show(context, engine, targetSlot: slotIdx);
                    },
                    onTapOccupiedSlot: (slotIdx) =>
                        ActionSheets.showOccupiedSlotSheet(context, engine, slotIdx),
                    onTakeoverSuccess: () {
                      if (engine.activeDraft != null) {
                        RoguelikeDraftModal.show(context, engine);
                      }
                    },
                  ),
                ),
                // 3. 中下迷你股市吧 + 底部三大 Roguelike 行動掣 (約 30% 高度)
                MiniStockAndBottomBarWidget(
                  engine: engine,
                  onTapStock: (stk) => ActionSheets.showStockQuickSheet(context, engine, stk),
                  onTapBuyShopSheet: () {
                    engine.openShopDraft3Choice();
                    RoguelikeDraftModal.show(context, engine);
                  },
                  onTapOpportunityButton: () {
                    if (engine.actionPoints <= 0) {
                      MonetizationService.showRewardedOrDirect(
                        engine: engine,
                        rewardName: '補滿 5 點行動力',
                        onRewardEarned: () => engine.actionPoints = GameEngine.maxActionPoints,
                      );
                      return;
                    }
                    if (engine.openTacticalEvent3Choice()) {
                      RoguelikeDraftModal.show(context, engine);
                    }
                  },
                  onTapFinanceSheet: () => ActionSheets.showFinanceAndSkillSheet(context, engine),
                ),
                if (engine.quarterPhase == QuarterPhase.gameOver ||
                    engine.quarterPhase == QuarterPhase.victory)
                  _buildRunEndBanner(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRunEndBanner(BuildContext context) {
    final isWin = engine.quarterPhase == QuarterPhase.victory;
    final prestige = engine.calculateRetirementPrestige(isBankrupt: !isWin);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWin
              ? [const Color(0xFF1B5E20), const Color(0xFF004D40)]
              : [const Color(0xFFB71C1C), const Color(0xFF4A0000)],
        ),
        border: const Border(top: BorderSide(color: Color(0xFFFFD700), width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWin
                      ? '👑 恭喜通過全部 12 季租金考核。'
                      : '💀 第 ${engine.currentQuarter} 季未能繳清 ${HkFormatters.money(engine.quarterRentQuota)} 租金。',
                  style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 13, fontWeight: FontWeight.w900),
                ),
                Text(
                  '最高總資產 ${HkFormatters.money(engine.peakNetWorthThisRun)} ｜ 結算可獲 +$prestige 家族聲望${!isWin ? " + 下代1.5倍啟動資金" : ""}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              HapticSoundService.dealClosedStamp();
              engine.retireAndInherit(isBankrupt: !isWin);
              if (engine.activeDraft != null) {
                RoguelikeDraftModal.show(context, engine);
              }
            },
            child: Text(
              isWin ? '退休傳承下一代' : '東山再起開新局',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
