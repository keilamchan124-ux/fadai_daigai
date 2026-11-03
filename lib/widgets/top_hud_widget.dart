import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../utils/formatters.dart';

class TopHudWidget extends StatelessWidget {
  final GameEngine engine;
  final VoidCallback onOpenRetireModal;
  final VoidCallback onOpenMetaHub;
  final VoidCallback onOpenVipStore;

  const TopHudWidget({
    super.key,
    required this.engine,
    required this.onOpenRetireModal,
    required this.onOpenMetaHub,
    required this.onOpenVipStore,
  });

  @override
  Widget build(BuildContext context) {
    final boss = engine.currentBoss;
    final phase = engine.marketPhase;
    final isPlanning = engine.quarterPhase == QuarterPhase.planning;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: engine.isTycoonVip
              ? [const Color(0xFF4A2500), const Color(0xFF241200)]
              : [const Color(0xFF2B1B17), const Color(0xFF1A110E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: engine.isTycoonVip ? const Color(0xFFFFD700) : const Color(0xFFD4AF37),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 第一行：季度狀態、大市週期、層級身份、頂部功能小掣
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isPlanning ? const Color(0xFF1565C0) : const Color(0xFFC62828),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPlanning
                      ? '🗓️ 第${engine.currentQuarter}/${GameEngine.maxQuarters}季・⏸️佈局中'
                      : '🗓️ 第${engine.currentQuarter}/${GameEngine.maxQuarters}季・⏱️${engine.quarterSecondsLeft}s',
                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Color(phase.colorHex),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  phase.title,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '第${engine.generation}代・${engine.currentTier.name}',
                  style: const TextStyle(color: Color(0xFFFFE082), fontSize: 11.5, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _miniTopIconButton(
                icon: '🌳',
                label: '傳承',
                onTap: onOpenRetireModal,
              ),
              const SizedBox(width: 4),
              _miniTopIconButton(
                icon: '🏆',
                label: '圖鑑',
                onTap: onOpenMetaHub,
              ),
              const SizedBox(width: 4),
              _miniTopIconButton(
                icon: '👑',
                label: engine.isTycoonVip ? 'VIP' : '會員',
                highlight: true,
                onTap: onOpenVipStore,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 第二行：現金與身家數字（真實 TweenAnimationBuilder 滾動效果）+ 死對頭頭像
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: engine.cash),
                      duration: const Duration(milliseconds: 380),
                      builder: (context, val, _) => Text(
                        '💰 現金 ${HkFormatters.money(val)}',
                        style: TextStyle(
                          color: engine.cash >= engine.quarterRentQuota
                              ? const Color(0xFF69F0AE)
                              : const Color(0xFFFFD54F),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: engine.netWorth),
                      duration: const Duration(milliseconds: 450),
                      builder: (context, val, _) => Text(
                        '總資產 ${HkFormatters.money(val)} ｜ 本季租金 ${HkFormatters.money(engine.quarterRentQuota)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: engine.bossInDistress
                        ? const Color(0xFFB71C1C).withValues(alpha: 0.85)
                        : Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: engine.bossInDistress ? Colors.redAccent : Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          boss.assetPath,
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Text(boss.emoji, style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${boss.title}・${boss.name}',
                              style: const TextStyle(
                                color: Color(0xFFFFCA28),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              engine.bossBubbleQuote,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // 第三行：「差少少」目標進度條 + 大市風聲跑馬燈
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: engine.almostThereProgress,
              minHeight: 7,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                engine.bossInDistress ? Colors.redAccent : const Color(0xFFFFB300),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  engine.almostThereGoalText,
                  style: const TextStyle(color: Color(0xFFFFF59D), fontSize: 10.5, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          // 第四行：已裝備奇物欄 (Relic Bar) + 連環閃電儲氣進度 (滿即送免費3選1)
          Row(
            children: [
              Image.asset('assets/images/relic_joker.png', width: 18, height: 18),
              const SizedBox(width: 4),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: engine.equippedRelics.isEmpty
                        ? [
                            const Text(
                              '奇物欄：尚未裝備（可於下方「招租/奇物」選取）',
                              style: TextStyle(color: Colors.white60, fontSize: 10),
                            ),
                          ]
                        : engine.equippedRelics
                            .map(
                              (r) => Tooltip(
                                message: '${r.name}：${r.description}',
                                child: Container(
                                  margin: const EdgeInsets.only(right: 5),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Color(r.rarity.colorHex).withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Color(r.rarity.colorHex), width: 1),
                                  ),
                                  child: Text(
                                    '${r.emoji}${r.name}',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF004D40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00E676), width: 1),
                ),
                child: Text(
                  '⚡連擊 ${engine.chainComboCharge}/${engine.chainComboTarget} (免費:${engine.pendingFreeDrafts})',
                  style: const TextStyle(color: Color(0xFF69F0AE), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniTopIconButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFFF8F00) : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 2),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
