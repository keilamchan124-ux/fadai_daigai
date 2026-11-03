import 'dart:math';

enum TierType {
  street(1, '街頭層', '街頭商戶', '🍢', 6, 2, 3, 2, 25000),
  community(2, '社區層', '社區業主', '🏢', 6, 2, 3, 1, 180000),
  city(3, '城市層', '企業莊家', '🏙️', 8, 2, 4, 2, 1500000),
  multinational(4, '跨國層', '金融集團', '🌐', 8, 2, 4, 3, 15000000),
  tycoon(5, '首富層', '商業巨擘', '👑', 8, 2, 4, 3, 180000000);

  final int level;
  final String name;
  final String identity;
  final String emoji;
  final int slotCount;
  final int rows;
  final int cols;
  final int goldenSlotIndex;
  final double targetNetWorth;

  const TierType(
    this.level,
    this.name,
    this.identity,
    this.emoji,
    this.slotCount,
    this.rows,
    this.cols,
    this.goldenSlotIndex,
    this.targetNetWorth,
  );

  static TierType fromLevel(int lvl) {
    return TierType.values.firstWhere(
      (e) => e.level == lvl,
      orElse: () => TierType.street,
    );
  }
}

enum ShopTag {
  food('飲食', '🍢', 0xFFE65100),
  property('地產', '🏠', 0xFF1565C0),
  finance('金融', '💰', 0xFFF9A825),
  logistics('物流', '🚚', 0xFF2E7D32),
  entertainment('娛樂', '🀄', 0xFF8E24AA),
  shadow('逆市', '💀', 0xFF37474F);

  final String label;
  final String emoji;
  final int colorHex;
  const ShopTag(this.label, this.emoji, this.colorHex);
}

enum TriggerType {
  timer('定時運作'),
  onReceivePulse('接力聯動'),
  charge3('蓄力三次觸發'),
  onMarketSwing('轉市觸發');

  final String label;
  const TriggerType(this.label);
}

enum PassDirection {
  right('向右傳遞 ➡️'),
  left('向左傳遞 ⬅️'),
  bothHorizontal('左右傳遞 ↔️'),
  skipOneRight('跳格向右 ⏭️'),
  across('對面傳遞 ↕️'),
  allNeighbors('四周擴散 ❇️'),
  terminal('終點結算 🎯');

  final String label;
  const PassDirection(this.label);
}

enum MarketPhase {
  bull('☀️ 景氣暢旺', '金融與地產收益提升，股市表現向好', 0xFFD32F2F),
  inflation('🔥 通脹升溫', '飲食與物流收益上升，物業升值但借貸利率提高', 0xFFF57C00),
  bubble('🫧 市場過熱', '各項收益大幅增加，但隨後容易轉入衰退週期', 0xFF7B1FA2),
  bear('⛈️ 經濟調整', '整體消費放緩，但競爭對手容易出現資金周轉問題', 0xFF1976D2);

  final String title;
  final String subtitle;
  final int colorHex;
  const MarketPhase(this.title, this.subtitle, this.colorHex);
}

class ShopDefinition {
  final String id;
  final String name;
  final String emoji;
  final int tier;
  final List<ShopTag> tags;
  final double baseCost;
  final double basePayout;
  final TriggerType triggerType;
  final int triggerIntervalSeconds;
  final double chainMultiplier;
  final PassDirection passDirection;
  final double antiRivalPower;
  final double bullMod;
  final double bearMod;
  final String flavorText;
  final String chainRuleText;

  const ShopDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tier,
    required this.tags,
    required this.baseCost,
    required this.basePayout,
    required this.triggerType,
    this.triggerIntervalSeconds = 4,
    required this.chainMultiplier,
    required this.passDirection,
    this.antiRivalPower = 10,
    this.bullMod = 1.0,
    this.bearMod = 1.0,
    required this.flavorText,
    required this.chainRuleText,
  });
}

class PlacedShop {
  final String definitionId;
  int level; // 1=⭐, 2=⭐⭐, 3=⭐⭐⭐ (三合一升星或強化)
  int chargeCount;
  double secondsAccumulator;
  bool isRenovated;
  double permanentBonusPayout; // 成長流永久疊加產出
  double neighborPermBonusMult; // 拆遷/風水永久倍率加成
  double lastPulseAmount;
  DateTime? lastTriggeredAt;

  PlacedShop({
    required this.definitionId,
    this.level = 1,
    this.chargeCount = 0,
    this.secondsAccumulator = 0,
    this.isRenovated = false,
    this.permanentBonusPayout = 0,
    this.neighborPermBonusMult = 0,
    this.lastPulseAmount = 0,
    this.lastTriggeredAt,
  });

  String get starBadge => '⭐' * level.clamp(1, 3) + (level > 3 ? '+${level - 3}' : '');

  double get levelMultiplier =>
      pow(2.15, level - 1).toDouble() *
      (isRenovated ? 2.0 : 1.0) *
      (1.0 + neighborPermBonusMult);

  Map<String, dynamic> toJson() => {
        'definitionId': definitionId,
        'level': level,
        'chargeCount': chargeCount,
        'isRenovated': isRenovated,
        'permanentBonusPayout': permanentBonusPayout,
        'neighborPermBonusMult': neighborPermBonusMult,
      };

  factory PlacedShop.fromJson(Map<String, dynamic> json) => PlacedShop(
        definitionId: json['definitionId'] as String,
        level: (json['level'] as num?)?.toInt() ?? 1,
        chargeCount: (json['chargeCount'] as num?)?.toInt() ?? 0,
        isRenovated: json['isRenovated'] as bool? ?? false,
        permanentBonusPayout: (json['permanentBonusPayout'] as num?)?.toDouble() ?? 0,
        neighborPermBonusMult: (json['neighborPermBonusMult'] as num?)?.toDouble() ?? 0,
      );
}

class SynergyDefinition {
  final String id;
  final String name;
  final String styleName;
  final String emoji;
  final String description;
  final Map<ShopTag, int> requiredTags;
  final List<String> requiredShopIds;
  final int extraChainSteps;
  final double chainMultiplierBonus;
  final double insiderAccuracyBonus;
  final bool bearMarketImmunity;
  final double bearIncomeMultiplier;
  final double bargainDiscount;
  final double propertyDownPaymentDiscount;
  final double rivalDamageMultiplier;

  const SynergyDefinition({
    required this.id,
    required this.name,
    required this.styleName,
    required this.emoji,
    required this.description,
    this.requiredTags = const {},
    this.requiredShopIds = const [],
    this.extraChainSteps = 0,
    this.chainMultiplierBonus = 1.0,
    this.insiderAccuracyBonus = 0.0,
    this.bearMarketImmunity = false,
    this.bearIncomeMultiplier = 1.0,
    this.bargainDiscount = 0.0,
    this.propertyDownPaymentDiscount = 0.0,
    this.rivalDamageMultiplier = 1.0,
  });
}

class RivalBossDefinition {
  final String id;
  final int tier;
  final String name;
  final String title;
  final String emoji;
  final String assetPath;
  final double maxHp;
  final double stealRate;
  final double takeoverBaseCost;
  final List<String> tauntQuotes;
  final List<String> panicQuotes;
  final String defeatedQuote;

  const RivalBossDefinition({
    required this.id,
    required this.tier,
    required this.name,
    required this.title,
    required this.emoji,
    required this.assetPath,
    required this.maxHp,
    required this.stealRate,
    required this.takeoverBaseCost,
    required this.tauntQuotes,
    required this.panicQuotes,
    required this.defeatedQuote,
  });
}

class StockState {
  final String id;
  final String code;
  final String name;
  final String emoji;
  final ShopTag sector;
  final double basePrice;
  final double volatility;
  double currentPrice;
  double previousPrice;
  List<double> history;
  bool? insiderBullishTip; // true = 莊家拉升, false = 莊家派貨/停牌危機
  double ownedShares;
  double averageEntryPrice;
  double marginDebt; // 3x 孖展借入金額
  double shortShares; // 沽空股數
  double shortEntryPrice;

  StockState({
    required this.id,
    required this.code,
    required this.name,
    required this.emoji,
    required this.sector,
    required this.basePrice,
    required this.volatility,
    double? currentPrice,
    double? previousPrice,
    List<double>? history,
    this.insiderBullishTip,
    this.ownedShares = 0,
    this.averageEntryPrice = 0,
    this.marginDebt = 0,
    this.shortShares = 0,
    this.shortEntryPrice = 0,
  })  : currentPrice = currentPrice ?? basePrice,
        previousPrice = previousPrice ?? basePrice,
        history = history ?? List<double>.filled(10, basePrice, growable: true);

  double get changePercent =>
      previousPrice <= 0 ? 0 : ((currentPrice - previousPrice) / previousPrice) * 100;

  double get positionValue => ownedShares * currentPrice;

  double get shortPositionNetValue {
    if (shortShares <= 0) return 0;
    final profitPerShare = shortEntryPrice - currentPrice;
    return (shortShares * shortEntryPrice) + (shortShares * profitPerShare);
  }

  double get netEquity => (positionValue - marginDebt) + shortPositionNetValue;

  Map<String, dynamic> toJson() => {
        'id': id,
        'currentPrice': currentPrice,
        'previousPrice': previousPrice,
        'history': history,
        'insiderBullishTip': insiderBullishTip,
        'ownedShares': ownedShares,
        'averageEntryPrice': averageEntryPrice,
        'marginDebt': marginDebt,
        'shortShares': shortShares,
        'shortEntryPrice': shortEntryPrice,
      };
}

class PropertyState {
  final String id;
  final String name;
  final String emoji;
  final int minTier;
  final double basePrice;
  final double baseRentPerSec;
  double currentPrice;
  int ownedCount;
  int renovatedCount;
  int mortgagedCount;

  PropertyState({
    required this.id,
    required this.name,
    required this.emoji,
    required this.minTier,
    required this.basePrice,
    required this.baseRentPerSec,
    double? currentPrice,
    this.ownedCount = 0,
    this.renovatedCount = 0,
    this.mortgagedCount = 0,
  }) : currentPrice = currentPrice ?? basePrice;

  double get totalRentPerSec =>
      (ownedCount * baseRentPerSec) + (renovatedCount * baseRentPerSec * 1.2);

  double get totalEquityValue =>
      (ownedCount * currentPrice) - (mortgagedCount * currentPrice * 0.7);

  Map<String, dynamic> toJson() => {
        'id': id,
        'currentPrice': currentPrice,
        'ownedCount': ownedCount,
        'renovatedCount': renovatedCount,
        'mortgagedCount': mortgagedCount,
      };
}

class OpportunityCard {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final int minTier;
  final String acceptLabel;
  final String rejectLabel;
  final bool isPonziScheme;
  final double costFactor; // 相對當前現金或基礎規模
  final double successChance;
  final double rewardMultiplier;
  final double failPenaltyFactor;
  final String successMessage;
  final String failMessage;

  const OpportunityCard({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    this.minTier = 1,
    required this.acceptLabel,
    required this.rejectLabel,
    this.isPonziScheme = false,
    this.costFactor = 0.25,
    this.successChance = 0.68,
    this.rewardMultiplier = 2.6,
    this.failPenaltyFactor = 0.35,
    required this.successMessage,
    required this.failMessage,
  });
}

class ActivePonziState {
  final String title;
  final double principal;
  double currentMultiplier;
  int secondsElapsed;
  final int bustAtSecond;

  ActivePonziState({
    required this.title,
    required this.principal,
    this.currentMultiplier = 1.2,
    this.secondsElapsed = 0,
    required this.bustAtSecond,
  });

  double get cashOutValue => principal * currentMultiplier;
}

class ActiveAuctionState {
  final String title;
  final String emoji;
  final String description;
  final String rewardShopId;
  final double marketValue;
  double currentBid;
  final double minIncrement;
  String highestBidder; // 'player', 'rival', 'passerby'
  int secondsLeft;
  final double rivalMaxBid;
  final double passerbyMaxBid;

  ActiveAuctionState({
    required this.title,
    required this.emoji,
    required this.description,
    required this.rewardShopId,
    required this.marketValue,
    required this.currentBid,
    required this.minIncrement,
    this.highestBidder = 'passerby',
    this.secondsLeft = 18,
    required this.rivalMaxBid,
    required this.passerbyMaxBid,
  });
}

enum TalentBranch {
  industrial('穩健實業', '🏭', '提升商舖基礎收入、連鎖傳遞與抗跌能力'),
  shark('金融投資', '🦈', '提升股市融資、內幕準確度、市場操作與收購折扣'),
  fengshui('風水運勢', '☯️', '提升暴擊倍率、商業機遇收益與家族信託基金');

  final String name;
  final String emoji;
  final String description;
  const TalentBranch(this.name, this.emoji, this.description);
}

class FamilyTalentNode {
  final String id;
  final TalentBranch branch;
  final String name;
  final String emoji;
  final String description;
  final int maxLevel;
  final int basePrestigeCost;
  final double effectPerLevel;

  const FamilyTalentNode({
    required this.id,
    required this.branch,
    required this.name,
    required this.emoji,
    required this.description,
    this.maxLevel = 5,
    required this.basePrestigeCost,
    required this.effectPerLevel,
  });
}

class HeirTrait {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final double shopIncomeMod;
  final double stockProfitMod;
  final double rivalDamageMod;
  final double startingCashMod;
  final double luckBonus;

  const HeirTrait({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.shopIncomeMod = 1.0,
    this.stockProfitMod = 1.0,
    this.rivalDamageMod = 1.0,
    this.startingCashMod = 1.0,
    this.luckBonus = 0.0,
  });
}

class LuxuryItem {
  final String id;
  final String name;
  final String category;
  final String emoji;
  final double cost;
  final String buffDescription;
  final double globalIncomeBonus;
  final double prestigeGainBonus;
  final double startingCashBonus;

  const LuxuryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.emoji,
    required this.cost,
    required this.buffDescription,
    this.globalIncomeBonus = 0.05,
    this.prestigeGainBonus = 0.0,
    this.startingCashBonus = 0.0,
  });
}

class AchievementDefinition {
  final String id;
  final String title;
  final String honorTitle; // 稱號
  final String emoji;
  final String description;
  final String metricKey;
  final double targetValue;
  final int prestigeReward;
  final bool isSecret;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.honorTitle,
    required this.emoji,
    required this.description,
    required this.metricKey,
    required this.targetValue,
    this.prestigeReward = 5,
    this.isSecret = false,
  });
}

class DynastyChallenge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String rewardLuxuryId;
  final bool noLoansAllowed;
  final bool permanentBearMarket;
  final ShopTag? restrictedTagOnly;
  final int? timeLimitMinutes;
  final double rivalHpMultiplier;

  const DynastyChallenge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.rewardLuxuryId,
    this.noLoansAllowed = false,
    this.permanentBearMarket = false,
    this.restrictedTagOnly,
    this.timeLimitMinutes,
    this.rivalHpMultiplier = 1.0,
  });
}

class DailyQuestState {
  final String id;
  final String title;
  final String emoji;
  final String metricKey;
  final int target;
  int progress;
  final int prestigeReward;
  bool claimed;

  DailyQuestState({
    required this.id,
    required this.title,
    required this.emoji,
    required this.metricKey,
    required this.target,
    this.progress = 0,
    this.prestigeReward = 10,
    this.claimed = false,
  });

  bool get isCompleted => progress >= target;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'emoji': emoji,
        'metricKey': metricKey,
        'target': target,
        'progress': progress,
        'prestigeReward': prestigeReward,
        'claimed': claimed,
      };

  factory DailyQuestState.fromJson(Map<String, dynamic> json) => DailyQuestState(
        id: json['id'] as String,
        title: json['title'] as String,
        emoji: json['emoji'] as String,
        metricKey: json['metricKey'] as String,
        target: (json['target'] as num).toInt(),
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        prestigeReward: (json['prestigeReward'] as num?)?.toInt() ?? 10,
        claimed: json['claimed'] as bool? ?? false,
      );
}

class ChainStepEvent {
  final int fromSlot;
  final int toSlot;
  final String shopName;
  final String emoji;
  final double payout;
  final int stepDepth;
  final bool isSuperBurst;

  const ChainStepEvent({
    required this.fromSlot,
    required this.toSlot,
    required this.shopName,
    required this.emoji,
    required this.payout,
    required this.stepDepth,
    this.isSuperBurst = false,
  });
}

enum RarityTier {
  common('普通', 0xFF78909C),
  rare('罕有', 0xFF1E88E5),
  epic('史詩', 0xFF8E24AA),
  legendary('傳奇', 0xFFFFB300);

  final String label;
  final int colorHex;
  const RarityTier(this.label, this.colorHex);
}

class RoguelikeRelic {
  final String id;
  final String name;
  final String emoji;
  final RarityTier rarity;
  final String description;
  final String buildHint;

  const RoguelikeRelic({
    required this.id,
    required this.name,
    required this.emoji,
    required this.rarity,
    required this.description,
    required this.buildHint,
  });
}

class TacticalOption {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final RarityTier rarity;

  const TacticalOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    this.rarity = RarityTier.rare,
  });
}

class TacticalThreeChoiceEvent {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final List<TacticalOption> options; // 嚴格 3 選 1

  const TacticalThreeChoiceEvent({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.options,
  });
}

enum QuarterPhase {
  planning('⏸️ 規劃排陣（時間暫停）'),
  running('🔥 營業運作中'),
  gameOver('💀 未能繳租・結業清盤'),
  victory('👑 完成十二季目標');

  final String label;
  const QuarterPhase(this.label);
}

enum DraftKind {
  starterRelic('開局傳家寶三選一'),
  shopDraft('季度商舖招租三選一'),
  relicDraft('商業奇物三選一'),
  tacticalEvent('商業決策三選一');

  final String title;
  const DraftKind(this.title);
}

class DraftCardItem {
  final String id;
  final String title;
  final String subtitle;
  final String ruleDetail;
  final String emoji;
  final RarityTier rarity;
  double cost;
  bool willTriggerThreeMerge;
  final String mergeProgressText; // 例如 "⭐ 已有 2/3（揀即升⭐⭐！）"
  final String synergyPreviewText; // 例如 "🧩 掃街不夜城 2/3 → 3/3 激活！"
  final String relicSynergyText; // 例如 "🔗 聯動：食神百年黑鐵鑊"
  final ShopTag? primaryTag;
  bool isLocked;

  DraftCardItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.ruleDetail,
    required this.emoji,
    required this.rarity,
    this.cost = 0,
    this.willTriggerThreeMerge = false,
    this.mergeProgressText = '',
    this.synergyPreviewText = '',
    this.relicSynergyText = '',
    this.primaryTag,
    this.isLocked = false,
  });
}

class ActiveDraftState {
  final DraftKind kind;
  final String headerPrompt;
  final List<DraftCardItem> choices; // 嚴格 3 張卡
  final bool canSkip;
  final bool canReroll;
  final double skipBonusCash;

  const ActiveDraftState({
    required this.kind,
    required this.headerPrompt,
    required this.choices,
    this.canSkip = true,
    this.canReroll = true,
    this.skipBonusCash = 0,
  });
}
