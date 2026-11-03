import 'package:flutter/material.dart';

import '../data/game_catalog.dart';
import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../services/game_services.dart';
import '../utils/formatters.dart';
import 'engine_builder.dart';
import 'roguelike_draft_modal.dart';

class ActionSheets {
  // 1. 3秒漫畫風開場卡 (使用 Codex MCP 生成嘅 grandpa_will.png)
  static Future<void> showOpeningComicDialog(
    BuildContext context,
    GameEngine engine,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF261812),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFFFD700), width: 2.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/grandpa_will.png',
                  height: 175,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '📜 祖傳商舖地契',
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '「家族留下 ${HkFormatters.money(engine.cash)} 啟動資金與一間街頭魚蛋檔，旁邊的黃金轉角舖位則由競爭對手蘭姐佔據——請善用資金重振家業。」',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '🧬 本代繼承人特質：${engine.currentTrait.emoji} ${engine.currentTrait.name}\n（${engine.currentTrait.description}）',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF80DEEA),
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.flash_on_rounded),
                  label: const Text(
                    '開始經營',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. 點擊已放置街舖：升格 / 睇連鎖詳情 / 頂讓套現
  static void showOccupiedSlotSheet(
    BuildContext context,
    GameEngine engine,
    int slotIndex,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF211612),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => EngineBuilder(
        engine: engine,
        builder: (context, _) {
          final placed = engine.slots[slotIndex];
          if (placed == null) return const SizedBox.shrink();
          final def = GameCatalog.shopById(placed.definitionId);
          final upCost = engine.shopUpgradeCost(slotIndex);
          final canUpgrade = engine.cash >= upCost;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      shopTagAssetPath(def.tags.first),
                      width: 44,
                      height: 44,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${def.name}（${placed.starBadge}・強化 ${placed.upgradeLevel}/3）',
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            def.flavorText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '⚡ 連鎖規則：${def.chainRuleText}',
                  style: const TextStyle(
                    color: Color(0xFF80DEEA),
                    fontSize: 13,
                  ),
                ),
                Text(
                  '💰 當前基礎產出：${HkFormatters.money(def.basePayout * placed.levelMultiplier)} ｜ 對手壓制力：${(def.antiRivalPower * placed.levelMultiplier).toStringAsFixed(0)}/秒',
                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canUpgrade
                              ? const Color(0xFFFFB300)
                              : Colors.white24,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: canUpgrade
                            ? () {
                                HapticSoundService.dealClosedStamp();
                                engine.upgradeShopAtSlot(slotIndex);
                              }
                            : null,
                        icon: const Icon(Icons.upgrade_rounded),
                        label: Text(
                          '強化 ${placed.upgradeLevel}/3 (${HkFormatters.money(upCost)})',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                        ),
                        onPressed: () {
                          engine.sellShopAtSlot(slotIndex);
                          Navigator.pop(ctx);
                        },
                        child: const Text('轉讓套現'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 3. 買舖與物業收租抽屜
  static void showBuyShopAndPropertySheet(
    BuildContext context,
    GameEngine engine, {
    int? targetSlot,
  }) {
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
          height: MediaQuery.of(context).size.height * 0.72,
          child: EngineBuilder(
            engine: engine,
            builder: (context, _) {
              final shops = GameCatalog.shopsForTier(engine.currentTier.level);
              final props = engine.properties
                  .where((p) => p.minTier <= engine.currentTier.level)
                  .toList();

              return Column(
                children: [
                  const TabBar(
                    indicatorColor: Color(0xFFFFB300),
                    labelColor: Color(0xFFFFD54F),
                    unselectedLabelColor: Colors.white60,
                    tabs: [
                      Tab(text: '🏪 開設商舖（組成連鎖）'),
                      Tab(text: '🏢 置業收租（翻新/按揭）'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: shops.length,
                          itemBuilder: (_, idx) {
                            final s = shops[idx];
                            final cost = engine.shopPurchaseCost(s);
                            final canBuy = engine.cash >= cost;
                            return Card(
                              color: const Color(0xFF2D201A),
                              child: ListTile(
                                leading: Image.asset(
                                  shopTagAssetPath(s.tags.first),
                                  width: 38,
                                  height: 38,
                                ),
                                title: Text(
                                  '${s.name}（${s.tags.map((t) => t.label).join("/")}）',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                subtitle: Text(
                                  '${s.chainRuleText}\n基礎產出 ${HkFormatters.money(s.basePayout)} ｜ 對手壓制 ${s.antiRivalPower.toInt()}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                isThreeLine: true,
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canBuy
                                        ? const Color(0xFFFFB300)
                                        : Colors.white24,
                                    foregroundColor: Colors.black,
                                  ),
                                  onPressed: canBuy
                                      ? () {
                                          if (engine.buyShopIntoSlot(
                                            s.id,
                                            targetSlot: targetSlot,
                                          )) {
                                            HapticSoundService.dealClosedStamp();
                                            if (targetSlot != null) {
                                              Navigator.pop(ctx);
                                            }
                                          }
                                        }
                                      : null,
                                  child: Text(HkFormatters.money(cost)),
                                ),
                              ),
                            );
                          },
                        ),
                        ListView.builder(
                          padding: const EdgeInsets.all(10),
                          itemCount: props.length,
                          itemBuilder: (_, idx) {
                            final p = props[idx];
                            final cost = engine.propertyDownPaymentCost(p);
                            return Card(
                              color: const Color(0xFF26201B),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${p.emoji} ${p.name}（持有 ${p.ownedCount} 項）',
                                          style: const TextStyle(
                                            color: Color(0xFFFFD54F),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '收租 +${HkFormatters.money(p.totalRentPerSec)}/秒',
                                          style: const TextStyle(
                                            color: Color(0xFF69F0AE),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        ElevatedButton(
                                          onPressed: engine.cash >= cost
                                              ? () => engine.buyProperty(p.id)
                                              : null,
                                          child: Text(
                                            '購入 ${HkFormatters.money(cost)}',
                                          ),
                                        ),
                                        OutlinedButton(
                                          onPressed:
                                              p.renovatedCount < p.ownedCount
                                              ? () => engine.renovateProperty(
                                                  p.id,
                                                )
                                              : null,
                                          child: Text(
                                            '翻新升租 (${p.renovatedCount}/${p.ownedCount})',
                                          ),
                                        ),
                                        OutlinedButton(
                                          onPressed:
                                              p.mortgagedCount < p.ownedCount
                                              ? () => engine.mortgageProperty(
                                                  p.id,
                                                )
                                              : null,
                                          child: Text(
                                            '按揭套現 (${p.mortgagedCount}/${p.ownedCount})',
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

  // 4. 1秒極速股票落注彈窗（買升 / 孖展3x / 做淡沽空 / 平倉）
  static void showStockQuickSheet(
    BuildContext context,
    GameEngine engine,
    StockState stock,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1614),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => EngineBuilder(
        engine: engine,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stock.emoji} ${stock.code} ${stock.name}',
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${stock.currentPrice.toStringAsFixed(2)} (${HkFormatters.percent(stock.changePercent)})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (stock.insiderBullishTip != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    stock.insiderBullishTip!
                        ? '🕵️ 市場消息：有大型機構正吸納此股份，後市看俏。'
                        : '🕵️ 市場消息：有大型股東正準備減持，請留意下跌風險。',
                    style: const TextStyle(
                      color: Color(0xFF80DEEA),
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                '持倉淨值：${HkFormatters.money(stock.netEquity)}（正股 ${stock.ownedShares.toStringAsFixed(0)} 股 ｜ 融資債務 ${HkFormatters.money(stock.marginDebt)} ｜ 沽空 ${stock.shortShares.toStringAsFixed(0)} 股）',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                    onPressed: () => engine.buyStock(
                      stock.id,
                      cashFraction: 0.5,
                      useMargin3x: false,
                    ),
                    child: const Text('買入正股 (50%現金)'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD84315),
                    ),
                    onPressed: () => engine.buyStock(
                      stock.id,
                      cashFraction: 0.5,
                      useMargin3x: true,
                    ),
                    child: const Text('🔥 3倍融資買入'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                    ),
                    onPressed: () =>
                        engine.shortStock(stock.id, cashFraction: 0.4),
                    child: const Text('📉 建立淡倉'),
                  ),
                  if (stock.ownedShares > 0)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => engine.sellStock(stock.id),
                      child: const Text('💰 沽出正股平倉'),
                    ),
                  if (stock.shortShares > 0)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => engine.coverShortStock(stock.id),
                      child: const Text('💰 平淡倉結算'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 5. 借錢 / 催谷跳月 / 層級造市特技 / 銀主盤拍賣抽屜
  static void showFinanceAndSkillSheet(
    BuildContext context,
    GameEngine engine,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1D1512),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => EngineBuilder(
        engine: engine,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🏦 銀行融資・快速推進・專屬技能',
                style: TextStyle(
                  color: Color(0xFFFFD54F),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '當前欠債：${HkFormatters.money(engine.bankLoan)} ／ 授信上限：${HkFormatters.money(engine.maxLoanCapacity)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if(engine.relocationShops.isNotEmpty)
                    TextButton(onPressed:()=>engine.placeRelocatedShop(),child:Text('安置搬遷商舖（${engine.relocationShops.length}）')),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: engine.pendingRelicDrafts > 0
                          ? const Color(0xFFFFB300)
                          : Colors.white24,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: engine.pendingRelicDrafts > 0
                        ? () {
                            Navigator.pop(ctx);
                            engine.openRelicDraft3Choice();
                            if (engine.activeDraft != null) {
                              RoguelikeDraftModal.show(context, engine);
                            }
                          }
                        : null,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      '🏺 商業奇物 3 選 1 (令牌×${engine.pendingRelicDrafts})',
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      showBuyShopAndPropertySheet(context, engine);
                    },
                    icon: const Icon(Icons.apartment_rounded),
                    label: const Text('🏢 置業收租 / 圖鑑直購'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        engine.borrowLoan(engine.maxLoanCapacity * 0.35),
                    icon: const Icon(Icons.account_balance_wallet),
                    label: Text(
                      '借入 ${HkFormatters.money(engine.maxLoanCapacity * 0.35)}',
                    ),
                  ),
                  if (engine.bankLoan > 0)
                    OutlinedButton(
                      onPressed: () => engine.repayLoan(engine.bankLoan),
                      child: const Text('清還貸款'),
                    ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8F00),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      engine.triggerTimeSkip();
                    },
                    icon: const Icon(Icons.fast_forward_rounded),
                    label: const Text('⚡ 完成本季營業（免費）'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2),
                    ),
                    onPressed: engine.tierSkillCooldown <= 0
                        ? () => engine.useTierSpecialSkill()
                        : null,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      engine.tierSkillCooldown <= 0
                          ? '🔥 發動${engine.currentTier.identity}專屬技能'
                          : '技能冷卻 (${engine.tierSkillCooldown}s)',
                    ),
                  ),
                  if (!engine.emergencyFundUsedThisRun && engine.familyFund > 0)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                      ),
                      onPressed: () => engine.injectEmergencyFamilyFund(),
                      icon: const Icon(Icons.savings),
                      label: Text(
                        '家族信託注資 (${HkFormatters.money(engine.familyFund)})',
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
}
