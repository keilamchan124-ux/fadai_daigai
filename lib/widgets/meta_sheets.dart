import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/game_catalog.dart';
import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../services/game_services.dart';
import '../utils/formatters.dart';
import 'engine_builder.dart';

class MetaSheets {
  // 1. 搞事事件卡彈窗
  static Future<void> showOpportunityDialog(
    BuildContext context,
    GameEngine engine,
    OpportunityCard card,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF281A14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFFFB300), width: 2),
        ),
        title: Row(
          children: [
            Text(card.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                card.title,
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                card.isPonziScheme
                    ? '⚠️ 高風險投資項目：參與後回報倍數將每秒上升，請於崩盤前在主畫面點擊「即時撤資」。'
                    : '📊 預估成功率：${((card.successChance + engine.currentTrait.luckBonus) * 100).clamp(15, 95).toInt()}% ｜ 成功回報 ×${card.rewardMultiplier}',
                style: const TextStyle(color: Color(0xFF80DEEA), fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              engine.resolveOpportunityCard(card, accepted: false);
              Navigator.pop(ctx);
            },
            child: Text(
              card.rejectLabel,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB300),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              HapticSoundService.dealClosedStamp();
              engine.resolveOpportunityCard(card, accepted: true);
              Navigator.pop(ctx);
            },
            child: Text(
              card.acceptLabel,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  // 2. 熊市銀主盤限時拍賣彈窗（配 Codex MCP 生成嘅 stamp_deal.png 金章）
  static Future<void> showAuctionDialog(
    BuildContext context,
    GameEngine engine,
  ) {
    return showDialog(
      context: context,
      builder: (ctx) => EngineBuilder(
        engine: engine,
        builder: (context, _) {
          final auc = engine.activeAuction;
          if (auc == null) {
            return AlertDialog(
              backgroundColor: const Color(0xFF241612),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/stamp_deal.png',
                    width: 88,
                    height: 88,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    engine.lastToastMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('返回街區'),
                ),
              ],
            );
          }

          final bidderLabel = auc.highestBidder == 'player'
              ? '🙋‍♂️ 你正領先'
              : (auc.highestBidder == 'rival'
                    ? '👹 競爭對手${engine.currentBoss.name}'
                    : '👜 其他買家');

          return AlertDialog(
            backgroundColor: const Color(0xFF281815),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            title: Row(
              children: [
                Image.asset(
                  'assets/images/stamp_deal.png',
                  width: 38,
                  height: 38,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🔨 備戰資產競投',
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${auc.emoji} ${auc.title}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  auc.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  '當前叫價：${HkFormatters.money(auc.currentBid)}',
                  style: const TextStyle(
                    color: Color(0xFF69F0AE),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '最高出價者：$bidderLabel',
                  style: const TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  engine.finishAuctionNow();
                },
                child: const Text(
                  '立即結算',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  HapticSoundService.lightTap();
                  engine.playerBidInAuction();
                },
                icon: const Icon(Icons.gavel_rounded),
                label: Text('出價擊敗對手'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 3. 傳承退休與三系家訓天賦樹 + 家族挑戰
  static void showRetireAndTalentSheet(
    BuildContext context,
    GameEngine engine,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1410),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: EngineBuilder(
            engine: engine,
            builder: (context, _) {
              final retirePrestige = engine.calculateRetirementPrestige();
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFF2D1E18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🌳 家族第 ${engine.generation} 代 ｜ 現有家族聲望：${engine.familyPrestige} 點',
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '家族信託基金：${HkFormatters.money(engine.familyFund)}（退休可領取 +$retirePrestige 聲望）',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB300),
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () {
                            HapticSoundService.dealClosedStamp();
                            engine.retireAndInherit();
                            MonetizationService.maybeShowGentleInterstitial(
                              engine,
                            );
                          },
                          icon: const Icon(Icons.stars_rounded),
                          label: Text('退休傳承 (+$retirePrestige)'),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [ TextButton(onPressed:()=>engine.resetTalents(),child:const Text('重配天賦（全額退聲望）')),

                      for (final plan in const {
                        'food': '飲食起手',
                        'logistics': '物流起手',
                        'capital': '資金起手',
                      }.entries)
                        TextButton(
                          onPressed: () {
                            if (!engine.isStartingPlanUnlocked(plan.key)) { engine.lastToastMessage='累計完成 3 季解鎖物流、6 季解鎖資金起手。'; engine.notifyListeners(); return; }
                            engine.startingPlan = plan.key;
                            engine.lastToastMessage = '下局起手：${plan.value}';
                            engine.notifyListeners();
                          },
                          child: Text(plan.value),
                        ),
                      TextButton(
                        onPressed: () {
                          engine.startDailyChallenge(DateTime.now().toUtc());
                          Navigator.pop(context);
                        },
                        child: const Text('每日同種子挑戰（開新局）'),
                      ),
                    ],
                  ),
                  const TabBar(
                    indicatorColor: Color(0xFFFFB300),
                    labelColor: Color(0xFFFFD54F),
                    unselectedLabelColor: Colors.white60,
                    tabs: [
                      Tab(text: '📜 家訓天賦樹 (24節點)'),
                      Tab(text: '⚔️ 王朝家族挑戰 (8試煉)'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: kAllTalents.length,
                          itemBuilder: (_, idx) {
                            final t = kAllTalents[idx];
                            final lvl = engine.talentLevels[t.id] ?? 0;
                            final cost = t.basePrestigeCost * (lvl + 1);
                            final canUp =
                                lvl < t.maxLevel &&
                                engine.familyPrestige >= cost;
                            return Card(
                              color: const Color(0xFF291D18),
                              child: ListTile(
                                leading: Text(
                                  t.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                title: Text(
                                  '${t.branch.emoji}【${t.branch.name}】${t.name} (Lv.$lvl/${t.maxLevel})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  t.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: canUp
                                      ? () => engine.upgradeTalent(t.id)
                                      : null,
                                  child: Text(
                                    lvl >= t.maxLevel ? '已滿級' : '$cost 聲望',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: kAllChallenges.length,
                          itemBuilder: (_, idx) {
                            final ch = kAllChallenges[idx];
                            final done = engine.completedChallenges.contains(
                              ch.id,
                            );
                            final isCurrent = engine.activeChallengeId == ch.id;
                            return Card(
                              color: const Color(0xFF291D18),
                              child: ListTile(
                                leading: Text(
                                  ch.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                title: Text(
                                  '${ch.name} ${done ? "✅已完成" : ""}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD54F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  ch.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: ElevatedButton(
                                  onPressed: isCurrent
                                      ? null
                                      : () {
                                          engine.retireAndInherit(
                                            nextChallengeId: ch.id,
                                          );
                                          Navigator.pop(ctx);
                                        },
                                  child: Text(isCurrent ? '挑戰中' : '開啟挑戰'),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // 4. 圖鑑中心：24件奢侈品收藏、100個成就與稱號、16流派圖鑑、每日任務
  static void showMetaHubSheet(BuildContext context, GameEngine engine) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1410),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DefaultTabController(
        length: 4,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          child: EngineBuilder(
            engine: engine,
            builder: (context, _) => Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  indicatorColor: Color(0xFFFFB300),
                  labelColor: Color(0xFFFFD54F),
                  unselectedLabelColor: Colors.white60,
                  tabs: [
                    Tab(text: '🛥️ 奢侈品收藏 (24)'),
                    Tab(text: '🏆 成就與稱號 (100)'),
                    Tab(text: '🧩 流派羈絆圖鑑 (16)'),
                    Tab(text: '📅 每日任務'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // 奢侈品
                      ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: kAllLuxuries.length,
                        itemBuilder: (_, idx) {
                          final lux = kAllLuxuries[idx];
                          final owned = engine.ownedLuxuries.contains(lux.id);
                          final canBuy = !owned && engine.cash >= lux.cost;
                          return Card(
                            color: owned
                                ? const Color(0xFF1B3B2B)
                                : const Color(0xFF281D18),
                            child: ListTile(
                              leading: Text(
                                lux.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                              title: Text(
                                '【${lux.category}】${lux.name}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                lux.buffDescription,
                                style: const TextStyle(
                                  color: Color(0xFF69F0AE),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: canBuy
                                    ? () => engine.buyLuxury(lux.id)
                                    : null,
                                child: Text(
                                  owned ? '已收藏' : HkFormatters.money(lux.cost),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // 100 成就
                      ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: kAllAchievements.length,
                        itemBuilder: (_, idx) {
                          final ach = kAllAchievements[idx];
                          final unlocked = engine.unlockedAchievements.contains(
                            ach.id,
                          );
                          return Card(
                            color: unlocked
                                ? const Color(0xFF2E2614)
                                : const Color(0xFF221A16),
                            child: ListTile(
                              leading: Text(
                                unlocked ? ach.emoji : '🔒',
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(
                                '${ach.title}（稱號：${ach.honorTitle}）',
                                style: TextStyle(
                                  color: unlocked
                                      ? const Color(0xFFFFD54F)
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                ach.isSecret && !unlocked
                                    ? '【隱藏成就】在香江商界持續探索即可解鎖。'
                                    : ach.description,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11.5,
                                ),
                              ),
                              trailing: Text(
                                '+${ach.prestigeReward} 聲望',
                                style: const TextStyle(
                                  color: Color(0xFF80DEEA),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // 16 流派圖鑑
                      ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: kAllSynergies.length,
                        itemBuilder: (_, idx) {
                          final syn = kAllSynergies[idx];
                          final found = engine.discoveredSynergies.contains(
                            syn.id,
                          );
                          return Card(
                            color: found
                                ? const Color(0xFF2E1E14)
                                : const Color(0xFF221916),
                            child: ListTile(
                              leading: Text(
                                syn.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                              title: Text(
                                '${syn.name} — ${syn.styleName} ${found ? "✅已解鎖" : ""}',
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                syn.description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // 每日任務
                      ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: engine.dailyQuests.length,
                        itemBuilder: (_, idx) {
                          final q = engine.dailyQuests[idx];
                          return Card(
                            color: const Color(0xFF281D18),
                            child: ListTile(
                              leading: Text(
                                q.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(
                                '${q.title} (${q.progress}/${q.target})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '獎勵：+${q.prestigeReward} 家族聲望',
                                style: const TextStyle(
                                  color: Color(0xFF80DEEA),
                                  fontSize: 12,
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: q.isCompleted && !q.claimed
                                    ? () => engine.claimDailyQuest(q.id)
                                    : null,
                                child: Text(q.claimed ? '已領取' : '領取'),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 5. HK$68「大亨會員」商店與雲端存檔設定
  static void showVipAndSaveSheet(BuildContext context, GameEngine engine) {
    final codeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F1510),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => EngineBuilder(
        engine: engine,
        builder: (context, _) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 48,
                      height: 48,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '👑 《發達大計》大亨會員 (HK\$68 永久買斷)\n免除所有插頁廣告・直接領取獎勵福利・永久收入+10%・專屬金框招牌',
                      style: TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: engine.isTycoonVip
                        ? null
                        : () => MonetizationService.purchaseTycoonVip(engine),
                    icon: const Icon(Icons.workspace_premium),
                    label: Text(
                      engine.isTycoonVip ? '已開通大亨會員' : 'HK\$68 買斷大亨會員',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        MonetizationService.restorePurchases(engine),
                    child: const Text('恢復購買'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      MonetizationService.showRewardedOrDirect(
                        engine: engine,
                        rewardName: '補滿 5 點行動力',
                        onRewardEarned: () =>
                            engine.actionPoints = GameEngine.maxActionPoints,
                      );
                    },
                    icon: const Icon(Icons.bolt),
                    label: const Text('免費補滿行動力'),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 22),
              const Text(
                '☁️ 雲端存檔與跨裝置引繼碼',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final msg = await PersistenceService.syncCloudSave(
                        engine,
                      );
                      engine.lastToastMessage = msg;
                    },
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('同步雲端備份'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final code = PersistenceService.exportSaveCode(engine);
                      Clipboard.setData(ClipboardData(text: code));
                      engine.lastToastMessage = '📋 存檔引繼碼已複製至剪貼簿。';
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('複製存檔碼'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: '貼上 FD88-... 存檔碼以匯入進度',
                        hintStyle: TextStyle(color: Colors.white38),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final ok = PersistenceService.importSaveCode(
                        engine,
                        codeCtrl.text,
                      );
                      engine.lastToastMessage = ok
                          ? '✅ 存檔匯入成功。'
                          : '❌ 存檔碼格式或簽名無效。';
                      if (ok) Navigator.pop(ctx);
                    },
                    child: const Text('匯入'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
