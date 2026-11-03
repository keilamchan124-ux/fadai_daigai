import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../services/game_services.dart';
import '../utils/formatters.dart';

class MiniStockAndBottomBarWidget extends StatelessWidget {
  final GameEngine engine;
  final void Function(StockState stock) onTapStock;
  final VoidCallback onTapBuyShopSheet;
  final VoidCallback onTapOpportunityButton;
  final VoidCallback onTapFinanceSheet;

  const MiniStockAndBottomBarWidget({
    super.key,
    required this.engine,
    required this.onTapStock,
    required this.onTapBuyShopSheet,
    required this.onTapOpportunityButton,
    required this.onTapFinanceSheet,
  });

  @override
  Widget build(BuildContext context) {
    final stocks = engine.visibleStocks;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1A120F),
        border: Border(top: BorderSide(color: Color(0xFFD4AF37), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 如果有進行中嘅老千層壓局，顯示緊急「割禾青走人」紅燈掣！
          if (engine.activePonzi != null)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amberAccent, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '🚨 項目【${engine.activePonzi!.title}】回報 ×${engine.activePonzi!.currentMultiplier.toStringAsFixed(2)}（可提取 ${HkFormatters.money(engine.activePonzi!.cashOutValue)}）',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD600),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    onPressed: () {
                      HapticSoundService.dealClosedStamp();
                      engine.cashOutPonzi();
                    },
                    child: const Text('即時撤資', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
          // 迷你股市吧（橫排即時跳動股票卡，1秒篤入落注）
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stocks.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final stk = stocks[idx];
                final chg = stk.changePercent;
                final isUp = chg >= 0;
                final hasPosition = stk.ownedShares > 0 || stk.shortShares > 0;
                return InkWell(
                  onTap: () {
                    HapticSoundService.lightTap();
                    onTapStock(stk);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 138,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: hasPosition ? const Color(0xFF263238) : const Color(0xFF281E1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: stk.insiderBullishTip != null
                            ? const Color(0xFFFFD700)
                            : (isUp ? const Color(0xFFEF5350) : const Color(0xFF26A69A)),
                        width: stk.insiderBullishTip != null ? 1.8 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(stk.emoji, style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${stk.code} ${stk.name}',
                                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (stk.insiderBullishTip != null)
                              const Text('🕵️', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${stk.currentPrice.toStringAsFixed(1)}',
                              style: const TextStyle(color: Color(0xFFFFE082), fontSize: 12, fontWeight: FontWeight.w900),
                            ),
                            Text(
                              HkFormatters.percent(chg),
                              style: TextStyle(
                                color: isUp ? const Color(0xFFFF5252) : const Color(0xFF69F0AE),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // 底部四大 Roguelike 核心行動掣（新增【開市收錢 / 2x快進】主控掣）
          Row(
            children: [
              Expanded(
                flex: 11,
                child: _bigActionButton(
                  emoji: engine.quarterPhase == QuarterPhase.planning ? '🔥' : (engine.isSpeed2x ? '⚡' : '⏩'),
                  title: engine.quarterPhase == QuarterPhase.planning
                      ? '開始營業'
                      : (engine.isSpeed2x ? '2x 快進中' : '1x 營業中'),
                  subtitle: engine.quarterPhase == QuarterPhase.planning
                      ? '目標 ${HkFormatters.money(engine.quarterRentQuota)}'
                      : '剩餘 ${engine.quarterSecondsLeft}s (點擊切換速度)',
                  colors: engine.quarterPhase == QuarterPhase.planning
                      ? const [Color(0xFF00C853), Color(0xFF1B5E20)]
                      : const [Color(0xFFD50000), Color(0xFF7F0000)],
                  onTap: () {
                    HapticSoundService.dealClosedStamp();
                    if (engine.quarterPhase == QuarterPhase.planning) {
                      engine.startQuarterMarketRun();
                    } else {
                      engine.toggleSpeed2x();
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 10,
                child: _bigActionButton(
                  emoji: '🃏',
                  title: engine.pendingFreeDrafts > 0
                      ? '招租 (免×${engine.pendingFreeDrafts})'
                      : '招租 3選1',
                  subtitle: '集齊3間升⭐⭐',
                  colors: const [Color(0xFFE65100), Color(0xFFBF360C)],
                  onTap: () {
                    HapticSoundService.lightTap();
                    onTapBuyShopSheet();
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 10,
                child: _bigActionButton(
                  emoji: '🎲',
                  title: '決策 (${engine.actionPoints}/${GameEngine.maxActionPoints})',
                  subtitle: engine.actionPoints > 0 ? '18組商業決策' : '補充行動力',
                  colors: const [Color(0xFF8E24AA), Color(0xFF4A148C)],
                  onTap: () {
                    HapticSoundService.lightTap();
                    onTapOpportunityButton();
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 9,
                child: _bigActionButton(
                  emoji: '🏺',
                  title: engine.pendingRelicDrafts > 0
                      ? '奇物 (×${engine.pendingRelicDrafts})'
                      : '奇物/金融',
                  subtitle: '奇物・物業・借貸',
                  colors: const [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  onTap: () {
                    HapticSoundService.lightTap();
                    onTapFinanceSheet();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // 即時街頭戰報列
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              engine.lastToastMessage,
              style: const TextStyle(color: Color(0xFFFFF59D), fontSize: 10.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigActionButton({
    required String emoji,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 9.5),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
