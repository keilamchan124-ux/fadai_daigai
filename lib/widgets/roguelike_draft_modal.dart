import 'package:flutter/material.dart';

import '../data/game_catalog.dart';
import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../services/game_services.dart';
import '../utils/formatters.dart';
import 'engine_builder.dart';

class RoguelikeDraftModal {
  static bool _isShowing = false;

  static Future<void> show(
    BuildContext context,
    GameEngine engine, {
    int? targetSlot,
  }) async {
    if (_isShowing) return;
    _isShowing = true;
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        backgroundColor: const Color(0xFF1A110D),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) => EngineBuilder(
          engine: engine,
          builder: (context, _) {
            final draft = engine.activeDraft;
            if (draft == null) {
              return const SizedBox.shrink();
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 頂部 3選1 標題與 Codex MCP 圖示
                    Row(
                      children: [
                        Image.asset(
                          draft.kind == DraftKind.shopDraft
                              ? 'assets/images/draft_banner.png'
                              : 'assets/images/relic_joker.png',
                          width: 42,
                          height: 42,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                draft.kind.title,
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                draft.headerPrompt,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (draft.canSkip)
                          IconButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // 三張候選卡（嚴格 3 選 1）
                    ...List.generate(draft.choices.length, (idx) {
                      final item = draft.choices[idx];
                      return _buildChoiceCard(
                        ctx,
                        engine,
                        item,
                        idx,
                        targetSlot: targetSlot,
                      );
                    }),
                    const SizedBox(height: 8),
                    // 底部：跳過領津貼掣 + 洗牌刷新掣 + 免費洗牌掣
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '💰 現金：${HkFormatters.money(engine.cash)}',
                          style: const TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (draft.canSkip && draft.skipBonusCash > 0)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF69F0AE),
                              side: const BorderSide(color: Color(0xFF69F0AE)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            onPressed: () {
                              HapticSoundService.dealClosedStamp();
                              engine.skipCurrentDraftForBonus();
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.savings_outlined, size: 15),
                            label: Text(
                              '跳過並領取 +${HkFormatters.money(draft.skipBonusCash)}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (draft.canReroll)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  MonetizationService.showRewardedOrDirect(
                                    engine: engine,
                                    rewardName: '免費刷新候選清單',
                                    onRewardEarned: () {
                                      engine.freeRerolls++;
                                      engine.rerollCurrentDraft(
                                        freeFromAd: true,
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.auto_awesome, size: 14),
                                label: const Text(
                                  '免費刷新',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                              const SizedBox(width: 6),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1565C0),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                                onPressed: engine.cash >= engine.draftRerollCost
                                    ? () {
                                        HapticSoundService.lightTap();
                                        engine.rerollCurrentDraft();
                                      }
                                    : null,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 15,
                                ),
                                label: Text(
                                  '刷新 (${HkFormatters.money(engine.draftRerollCost)})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      _isShowing = false;
    }
  }

  static Widget _buildChoiceCard(
    BuildContext ctx,
    GameEngine engine,
    DraftCardItem item,
    int index, {
    int? targetSlot,
  }) {
    final canAfford = engine.cash >= item.cost;
    final borderColor = item.willTriggerThreeMerge
        ? const Color(0xFF00E676)
        : Color(item.rarity.colorHex);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(item.rarity.colorHex).withValues(alpha: 0.30),
            const Color(0xFF261A15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width:
              item.willTriggerThreeMerge || item.rarity == RarityTier.legendary
              ? 2.4
              : 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: canAfford
            ? () async {
                HapticSoundService.dealClosedStamp();
                var target = targetSlot;
                if (engine.eventNeedsTarget(item.id)) {
                  target = await showDialog<int>(
                    context: ctx,
                    builder: (dialog) => SimpleDialog(
                      title: const Text('選擇商舖'),
                      children: engine.slots
                          .asMap()
                          .entries
                          .where((e) => e.value != null)
                          .map(
                            (e) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(dialog, e.key),
                              child: Text(
                                '${e.key + 1}：${GameCatalog.shopById(e.value!.definitionId).name}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                  if (target == null) return;
                }
                if (!ctx.mounted) return;
                String? replace;
                if (engine.activeDraft?.kind != DraftKind.shopDraft &&
                    engine.activeDraft?.kind != DraftKind.tacticalEvent &&
                    engine.equippedRelicIds.length >=
                        GameEngine.maxEquippedRelics) {
                  replace = await showDialog<String>(
                    context: ctx,
                    builder: (dialog) => SimpleDialog(
                      title: const Text('替換哪件奇物？'),
                      children: engine.equippedRelics
                          .map(
                            (r) => SimpleDialogOption(
                              onPressed: () => Navigator.pop(dialog, r.id),
                              child: Text(r.name),
                            ),
                          )
                          .toList(),
                    ),
                  );
                  if (replace == null) return;
                }
                if (!ctx.mounted) return;
                if (engine.selectDraftChoice(
                  index,
                  targetSlot: target,
                  replaceRelicId: replace,
                )) {
                  if (engine.activeDraft == null) Navigator.pop(ctx);
                }
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              // 左側圖示：街舖用 Codex MCP 行業 Sprite，奇物用 Emoji / 金章
              if (item.primaryTag != null)
                Image.asset(
                  shopTagAssetPath(item.primaryTag!),
                  width: 44,
                  height: 44,
                  errorBuilder: (_, _, _) =>
                      Text(item.emoji, style: const TextStyle(fontSize: 30)),
                )
              else
                Text(item.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              // 中間標題、稀有度標籤、三合一提示與規則說明
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Color(item.rarity.colorHex),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.rarity.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: Color(0xFFFFE082),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.ruleDetail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                    if (item.mergeProgressText.isNotEmpty ||
                        item.synergyPreviewText.isNotEmpty ||
                        item.relicSynergyText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (item.mergeProgressText.isNotEmpty)
                              _buildBadgeChip(
                                item.mergeProgressText,
                                item.willTriggerThreeMerge
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFFFFD54F),
                              ),
                            if (item.synergyPreviewText.isNotEmpty)
                              _buildBadgeChip(
                                item.synergyPreviewText,
                                const Color(0xFF40C4FF),
                              ),
                            if (item.relicSynergyText.isNotEmpty)
                              _buildBadgeChip(
                                item.relicSynergyText,
                                const Color(0xFFFFAB40),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 右側選擇掣 + 鎖卡掣
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAfford
                          ? const Color(0xFFFFB300)
                          : Colors.white24,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    onPressed: canAfford
                        ? () {
                            HapticSoundService.dealClosedStamp();
                            if (engine.selectDraftChoice(
                              index,
                              targetSlot: targetSlot,
                            )) {
                              Navigator.pop(ctx);
                            }
                          }
                        : null,
                    child: Text(
                      item.cost <= 0 ? '免費選取' : HkFormatters.money(item.cost),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (engine.activeDraft?.kind == DraftKind.shopDraft)
                    InkWell(
                      onTap: () {
                        HapticSoundService.lightTap();
                        engine.toggleLockDraftChoice(index);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.isLocked ? '🔒 已鎖定' : '🔓 鎖定保留',
                          style: TextStyle(
                            color: item.isLocked
                                ? const Color(0xFFFFD54F)
                                : Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildBadgeChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
