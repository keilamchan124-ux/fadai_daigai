import 'package:flutter/material.dart';

import '../data/game_catalog.dart';
import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../services/game_services.dart';
import '../utils/formatters.dart';

class StreetGridWidget extends StatelessWidget {
  final GameEngine engine;
  final void Function(int slotIndex) onTapEmptySlot;
  final void Function(int slotIndex) onTapOccupiedSlot;
  final VoidCallback onTakeoverSuccess;

  const StreetGridWidget({
    super.key,
    required this.engine,
    required this.onTapEmptySlot,
    required this.onTapOccupiedSlot,
    required this.onTakeoverSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final tier = engine.currentTier;
    final cols = tier.cols;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/street_bg.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.52),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        children: [
          // 頂部流派羈絆橫條與連鎖提示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: Colors.black.withValues(alpha: 0.55),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    '${tier.emoji} ${tier.name}（長按拖曳商舖調換位置以組成連鎖）',
                    style: const TextStyle(color: Color(0xFFFFE082), fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  if (engine.activeSynergies.isEmpty)
                    const Text(
                      '💡 集齊 3 間同類別或指定組合即可觸發【商業羈絆】',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    )
                  else
                    ...engine.activeSynergies.map(
                      (syn) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFD84315), Color(0xFFF57F17)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${syn.emoji} ${syn.name}（${syn.styleName}）',
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 教學手指提示橫幅（第一代新手引導）
          if (engine.generation == 1 && engine.tutorialStep == 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: const Color(0xFFE65100).withValues(alpha: 0.9),
              child: const Text(
                '👆 新手引導：長按「街頭魚蛋檔」拖曳至「發記糖水舖」左側格位，即可觸發首次連鎖效應。',
                style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ),
          // 最近一次連環閃電戰報跑馬燈
          if (engine.recentChainEvents.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              color: const Color(0xFF1B5E20).withValues(alpha: 0.85),
              child: Text(
                '⚡ 連鎖收益觸發：${engine.recentChainEvents.map((e) => "${e.emoji}${e.shopName}(+${HkFormatters.money(e.payout)})").join(" ➡️ ")}',
                style: const TextStyle(color: Color(0xFFB9F6CA), fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // 街區網格 + 連環閃電光束動畫疊層
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: engine.slots.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.92,
                        ),
                        itemBuilder: (context, index) => _buildSlotTile(context, index),
                      ),
                      if (engine.recentChainEvents.isNotEmpty)
                        IgnorePointer(
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: _ChainLightningPainter(
                              events: engine.recentChainEvents,
                              cols: cols,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSlotTile(BuildContext context, int index) {
    final isGolden = index == engine.currentTier.goldenSlotIndex;
    final bossOccupying = isGolden && !engine.bossDefeatedInCurrentTier;

    if (bossOccupying) {
      return _buildBossOccupiedCard(context);
    }

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) {
        HapticSoundService.chainPulse(3);
        engine.swapOrMoveShops(details.data, index);
      },
      builder: (context, candidateData, _) {
        final isHovering = candidateData.isNotEmpty;
        final placed = engine.slots[index];

        if (placed == null) {
          return InkWell(
            onTap: () {
              HapticSoundService.lightTap();
              onTapEmptySlot(index);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: isHovering
                    ? Colors.amber.withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isGolden
                      ? const Color(0xFFFFD700)
                      : (isHovering ? Colors.amberAccent : Colors.white24),
                  width: isGolden || isHovering ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isGolden)
                    const Text('🌟 2x 黃金轉角位', style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
                  const Icon(Icons.add_business_rounded, color: Colors.white70, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    '空置舖位 #${index + 1}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    '點擊招租進駐',
                    style: TextStyle(color: Colors.white54, fontSize: 9.5),
                  ),
                ],
              ),
            ),
          );
        }

        final cardWidget = _buildOccupiedShopCard(index, placed, isGolden, isHovering);
        return Draggable<int>(
          data: index,
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(width: 115, height: 120, child: cardWidget),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: cardWidget),
          child: InkWell(
            onTap: () {
              HapticSoundService.lightTap();
              onTapOccupiedSlot(index);
            },
            borderRadius: BorderRadius.circular(14),
            child: cardWidget,
          ),
        );
      },
    );
  }

  Widget _buildBossOccupiedCard(BuildContext context) {
    final boss = engine.currentBoss;
    final hpRatio = (engine.bossCurrentHp / engine.currentBossMaxHp).clamp(0.0, 1.0);
    final cost = engine.takeoverCost;
    final canAfford = engine.cash >= cost;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: engine.bossInDistress
              ? [const Color(0xFFB71C1C), const Color(0xFF4A0000)]
              : [const Color(0xFF4A148C), const Color(0xFF1A0933)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: engine.bossInDistress ? Colors.redAccent : const Color(0xFFFFD700),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  boss.assetPath,
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Text(boss.emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '🌟黃金位：${boss.name}',
                  style: const TextStyle(color: Color(0xFFFFD700), fontSize: 10.5, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: hpRatio,
              minHeight: 6,
              backgroundColor: Colors.black45,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
            ),
          ),
          Text(
            engine.bossInDistress ? '🔥 資金困難，可半價收購' : '分薄鄰格收入 ${(boss.stealRate * 100).toInt()}%',
            style: const TextStyle(color: Colors.white, fontSize: 9.5),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(
            width: double.infinity,
            height: 26,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? const Color(0xFFFFB300) : Colors.white24,
                foregroundColor: Colors.black,
                padding: EdgeInsets.zero,
              ),
              onPressed: canAfford
                  ? () {
                      if (engine.takeoverRivalBoss()) {
                        HapticSoundService.dealClosedStamp();
                        onTakeoverSuccess();
                      }
                    }
                  : null,
              child: Text(
                '收購 ${HkFormatters.money(cost)}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildOccupiedShopCard(
    int index,
    PlacedShop placed,
    bool isGolden,
    bool isHovering,
  ) {
    final def = GameCatalog.shopById(placed.definitionId);
    final primaryTag = def.tags.first;
    final recentlyTriggered = placed.lastTriggeredAt != null &&
        DateTime.now().difference(placed.lastTriggeredAt!).inMilliseconds < 1400;
    final targetSlots = engine.targetSlotsForShopAt(index);
    final targetText = targetSlots.isEmpty
        ? '🛑 終結結算'
        : '➡️ 傳至 ${targetSlots.map((i) => "#${i + 1}").join("、")}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(primaryTag.colorHex).withValues(alpha: 0.90),
            const Color(0xFF1A1412).withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: recentlyTriggered
              ? const Color(0xFF00E676)
              : (isGolden ? const Color(0xFFFFD700) : (isHovering ? Colors.white : Colors.white38)),
          width: recentlyTriggered || isGolden ? 2.2 : 1.2,
        ),
        boxShadow: recentlyTriggered
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.65),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '#${index + 1}',
                  style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 3),
              Image.asset(
                shopTagAssetPath(primaryTag),
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Text(def.emoji, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  def.name,
                  style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  placed.starBadge,
                  style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.45), width: 0.8),
            ),
            child: Text(
              '${def.triggerType.label} ｜ $targetText',
              style: const TextStyle(color: Color(0xFFFFF59D), fontSize: 9.5, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '×${def.chainMultiplier.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              ),
              if (placed.lastPulseAmount > 0)
                Text(
                  '+${HkFormatters.money(placed.lastPulseAmount)}',
                  style: const TextStyle(
                    color: Color(0xFF69F0AE),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChainLightningPainter extends CustomPainter {
  final List<ChainStepEvent> events;
  final int cols;

  _ChainLightningPainter({required this.events, required this.cols});

  Offset _centerForSlot(int slotIdx, double width) {
    final spacing = 8.0;
    final tileW = (width - spacing * (cols - 1)) / cols;
    final tileH = tileW / 0.92;
    final r = slotIdx ~/ cols;
    final c = slotIdx % cols;
    return Offset(
      c * (tileW + spacing) + tileW * 0.5,
      r * (tileH + spacing) + tileH * 0.5,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.48)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final corePaint = Paint()
      ..color = const Color(0xFF69F0AE)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final ev in events) {
      final p1 = _centerForSlot(ev.fromSlot, size.width);
      final p2 = _centerForSlot(ev.toSlot, size.width);
      final mid = Offset((p1.dx + p2.dx) * 0.5, (p1.dy + p2.dy) * 0.5 - 10);
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, corePaint);
      canvas.drawCircle(p2, 5.0, Paint()..color = const Color(0xFFFFD700));
    }
  }

  @override
  bool shouldRepaint(covariant _ChainLightningPainter oldDelegate) =>
      oldDelegate.events != events || oldDelegate.cols != cols;
}
