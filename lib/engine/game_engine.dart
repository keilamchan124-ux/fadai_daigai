import 'dart:convert';
import 'dart:math';

import '../data/game_catalog.dart';
import '../models/game_models.dart';
import '../utils/formatters.dart';

class GameEngine {
  final Random _rng;
  final List<void Function()> _listeners = [];

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);
  void notifyListeners() {
    for (final l in List<void Function()>.from(_listeners)) {
      l();
    }
  }

  // 當前代數與局內核心資產
  int generation = 1;
  HeirTrait currentTrait = kAllHeirTraits.first;
  TierType currentTier = TierType.street;
  double cash = 1500;
  double bankLoan = 0;
  double peakNetWorthThisRun = 1500;
  double peakNetWorthAllTime = 1500;

  // 街區網格與死對頭狀態
  List<PlacedShop?> slots = List<PlacedShop?>.filled(6, null, growable: true);
  bool bossDefeatedInCurrentTier = false;
  double bossCurrentHp = 350;
  String bossBubbleQuote = '「年輕人，這條街的商舖向來由我主導。」';
  bool bossInDistress = false; // 熊市斷供閃紅燈
  int bossDistressSecondsLeft = 0;

  // 大市經濟週期與預兆
  MarketPhase marketPhase = MarketPhase.bull;
  MarketPhase nextMarketPhase = MarketPhase.inflation;
  int phaseSecondsRemaining = 75;
  String marketForecastHeadline = '☀️ 市道暢旺：市民消費意欲高漲。';
  bool forecastRevealed = false;
  double bubbleRisk = 0.10; // 玩家槓桿與造市推高泡沫風險

  // 行動力與冷卻
  int actionPoints = 3;
  static const int maxActionPoints = 5;
  int actionPointRegenTimer = 20;
  int timeSkipCooldown = 0;
  int tierSkillCooldown = 0;
  bool emergencyFundUsedThisRun = false;

  // 股市、物業、進行中事件與 Roguelike 3選1 狀態
  late List<StockState> stocks;
  late List<PropertyState> properties;
  List<SynergyDefinition> activeSynergies = [];
  List<String> equippedRelicIds = [];
  static const int maxEquippedRelics = 6;
  ActiveDraftState? activeDraft;
  ActiveDraftState? _cachedShopDraft;
  DraftCardItem? lockedShopCard;
  int pendingFreeDrafts = 1; // 免費 3選1 抽卡次數
  int pendingRelicDrafts = 0; // 風水奇物 3選1 令牌
  int chainComboCharge = 0; // 連環閃電儲氣進度
  int chainComboTarget = 12; // 儲滿即送一次免費 3選1
  int draftRerollCount = 0;

  // 回合制季度交租與開市節奏狀態（Quarter-Based Roguelike）
  int currentQuarter = 1;
  static const int maxQuarters = 12;
  QuarterPhase quarterPhase = QuarterPhase.planning;
  int quarterSecondsLeft = 18;
  bool isSpeed2x = false;
  double rentDiscountMod = 1.0;

  int stageSecondsLeft = 180; // 相容舊版指標
  bool isRunFailed = false;
  ActivePonziState? activePonzi;
  ActiveAuctionState? activeAuction;
  OpportunityCard? pendingOpportunity;

  bool hasRelic(String relicId) => equippedRelicIds.contains(relicId);

  List<RoguelikeRelic> get equippedRelics => equippedRelicIds
      .map((id) => kAllRelics.where((r) => r.id == id).firstOrNull)
      .whereType<RoguelikeRelic>()
      .toList();

  // 最近一次連鎖動畫事件與浮動訊息
  List<ChainStepEvent> recentChainEvents = [];
  String lastToastMessage = '家族留下一筆啟動資金與魚蛋檔，可嘗試將商舖拖曳至相鄰格位組成連鎖。';
  int tutorialStep = 0; // 0=拖舖教學, 1=買舖教學, 2=搞事/股票教學, 3=完成

  // 跨代傳承、家族基金、收藏與統計
  int familyPrestige = 0;
  double familyFund = 0;
  Map<String, int> talentLevels = {};
  Set<String> ownedLuxuries = {};
  Set<String> unlockedAchievements = {};
  Set<String> discoveredShops = {'t1_fishball', 't1_sweet_soup'};
  Set<String> discoveredSynergies = {};
  Set<String> completedChallenges = {};
  String? activeChallengeId;
  bool isTycoonVip = false;

  // 統計指標與每日任務
  Map<String, double> metrics = {};
  List<DailyQuestState> dailyQuests = [];
  int loginStreakDays = 1;
  bool loginRewardClaimedToday = false;
  int runElapsedSeconds = 0;
  int bestVictorySeconds = 0;
  DateTime lastSavedTimestamp = DateTime.now();

  GameEngine({int? seed}) : _rng = Random(seed) {
    stocks = createInitialStocks();
    properties = createInitialProperties();
    _initDailyQuests();
    startNewGeneration(isFirstBoot: true);
  }
  RivalBossDefinition get currentBoss => GameCatalog.bossForTier(currentTier.level);

  DynastyChallenge? get activeChallenge => activeChallengeId == null
      ? null
      : kAllChallenges.firstWhere((c) => c.id == activeChallengeId, orElse: () => kAllChallenges.first);

  double talentEffect(String talentId) {
    final lvl = talentLevels[talentId] ?? 0;
    if (lvl <= 0) return 0.0;
    final node = GameCatalog.talentById(talentId);
    return lvl * node.effectPerLevel;
  }

  double get globalIncomeMultiplier {
    double mult = currentTrait.shopIncomeMod;
    mult *= (1.0 + talentEffect('tal_ind_1')) * (1.0 + talentEffect('tal_ind_8'));
    mult *= (1.0 + talentEffect('tal_fs_8'));
    for (final luxId in ownedLuxuries) {
      final lux = kAllLuxuries.where((l) => l.id == luxId).firstOrNull;
      if (lux != null) mult += lux.globalIncomeBonus;
    }
    if (isTycoonVip) mult *= 1.10;
    return mult;
  }

  double get shopsAssetValue {
    double total = 0;
    for (final s in slots) {
      if (s == null) continue;
      final def = GameCatalog.shopById(s.definitionId);
      total += def.baseCost * s.levelMultiplier * 0.8;
    }
    return total;
  }

  double get stocksNetEquity => stocks.fold(0.0, (sum, s) => sum + s.netEquity);

  double get propertiesNetEquity => properties.fold(0.0, (sum, p) => sum + p.totalEquityValue);

  double get netWorth => cash + shopsAssetValue + stocksNetEquity + propertiesNetEquity - bankLoan;

  List<StockState> get visibleStocks {
    if (currentTier == TierType.street) return stocks.take(3).toList();
    if (currentTier == TierType.community) return stocks.take(5).toList();
    return stocks;
  }

  String get currentHonorTitle {
    if (unlockedAchievements.isEmpty) return '廟街創業者';
    final lastId = unlockedAchievements.last;
    final ach = kAllAchievements.where((a) => a.id == lastId).firstOrNull;
    return ach?.honorTitle ?? '香江創業者';
  }

  double get quarterRentQuota {
    const baseQuotas = <double>[
      850,    // Q1
      1800,   // Q2
      3600,   // Q3 (Boss 1 死線)
      7500,   // Q4
      15000,  // Q5
      32000,  // Q6 (Boss 2 死線)
      68000,  // Q7
      145000, // Q8
      310000, // Q9 (Boss 3 死線)
      680000, // Q10
      1500000,// Q11
      3300000,// Q12 (終局大考)
    ];
    final idx = (currentQuarter - 1).clamp(0, baseQuotas.length - 1);
    return (baseQuotas[idx] * rentDiscountMod).roundToDouble();
  }

  String get almostThereGoalText {
    if (quarterPhase == QuarterPhase.gameOver) {
      return '💀 第 $currentQuarter 季未能繳付 ${HkFormatters.money(quarterRentQuota)} 租金，商舖已被收回。';
    }
    if (quarterPhase == QuarterPhase.victory) {
      return '👑 已通過全部 12 季商業考核，可隨時安排退休傳承或繼續挑戰。';
    }
    final quota = quarterRentQuota;
    if (cash < quota) {
      final diff = (quota - cash).clamp(0.0, double.infinity);
      return '🚨 第 $currentQuarter/$maxQuarters 季應繳租金 ${HkFormatters.money(quota)}（尚欠現金 ${HkFormatters.money(diff)}）';
    }
    if (bossInDistress && !bossDefeatedInCurrentTier) {
      return '🔥 ${currentBoss.name}陷入資金困難，可斥資 ${HkFormatters.money(takeoverCost)} 收購黃金舖位。';
    }
    return '✅ 已備妥本季租金 ${HkFormatters.money(quota)}，多餘資金可用於收購${currentBoss.name}或升級商舖。';
  }

  double get almostThereProgress {
    return (cash / quarterRentQuota).clamp(0.05, 1.0);
  }

  double get currentBossMaxHp {
    final mult = activeChallenge?.rivalHpMultiplier ?? 1.0;
    return currentBoss.maxHp * mult;
  }

  double get takeoverCost {
    double discount = talentEffect('tal_shk_4');
    for (final syn in activeSynergies) {
      discount += syn.bargainDiscount;
    }
    discount = discount.clamp(0.0, 0.65);
    final hpRatio = (bossCurrentHp / currentBossMaxHp).clamp(0.15, 1.0);
    return currentBoss.takeoverBaseCost * (1.0 - discount) * (bossInDistress ? 0.45 : hpRatio);
  }
  void _initDailyQuests() {
    dailyQuests = [
      DailyQuestState(id: 'dq_chain', title: '觸發 25 次商舖連鎖效應', emoji: '⚡', metricKey: 'chains_triggered', target: 25, prestigeReward: 15),
      DailyQuestState(id: 'dq_opp', title: '完成 5 次商業機遇決策', emoji: '🎲', metricKey: 'opportunities_taken', target: 5, prestigeReward: 15),
      DailyQuestState(id: 'dq_stock', title: '進行 5 次股票或物業投資', emoji: '📈', metricKey: 'stock_trades', target: 5, prestigeReward: 20),
    ];
  }

  void startNewGeneration({
    bool isFirstBoot = false,
    bool comebackBonus = false,
    String? challengeId,
  }) {
    if (!isFirstBoot) {
      generation += 1;
      _addMetric('generation', 1, setMax: true, absoluteVal: generation.toDouble());
    }
    activeChallengeId = challengeId;
    currentTrait = kAllHeirTraits[_rng.nextInt(kAllHeirTraits.length)];
    currentTier = TierType.street;

    double startCash = 1800 * currentTrait.startingCashMod * (1.0 + talentEffect('tal_fs_1'));
    for (final luxId in ownedLuxuries) {
      final lux = kAllLuxuries.where((l) => l.id == luxId).firstOrNull;
      if (lux != null) startCash *= (1.0 + lux.startingCashBonus);
    }
    if (comebackBonus) startCash *= 1.5; // 破產東山再起加成
    if (familyFund > 0) {
      final injected = familyFund * 0.5;
      startCash += injected;
      familyFund -= injected;
    }

    cash = startCash;
    bankLoan = 0;
    peakNetWorthThisRun = cash;
    runElapsedSeconds = 0;
    emergencyFundUsedThisRun = false;
    actionPoints = 3;
    timeSkipCooldown = 0;
    tierSkillCooldown = 0;
    equippedRelicIds = [];
    activeDraft = null;
    _cachedShopDraft = null;
    lockedShopCard = null;
    pendingFreeDrafts = 1;
    pendingRelicDrafts = 0;
    chainComboCharge = 0;
    chainComboTarget = 12;
    draftRerollCount = 0;
    currentQuarter = 1;
    quarterPhase = QuarterPhase.planning;
    quarterSecondsLeft = 18;
    rentDiscountMod = 1.0;
    stageSecondsLeft = 180;
    isRunFailed = false;
    activePonzi = null;
    activeAuction = null;
    pendingOpportunity = null;

    // 初始化 2x3 街頭網格：第 0 格魚蛋檔、第 4 格糖水舖（引導玩家拖去隔離），第 2 格黃金位俾蘭姐霸住
    slots = List<PlacedShop?>.filled(currentTier.slotCount, null, growable: true);
    slots[0] = PlacedShop(definitionId: 't1_fishball', level: 1);
    slots[4] = PlacedShop(definitionId: 't1_sweet_soup', level: 1);

    bossDefeatedInCurrentTier = false;
    bossCurrentHp = currentBossMaxHp;
    bossInDistress = false;
    bossDistressSecondsLeft = 0;
    bossBubbleQuote = currentBoss.tauntQuotes.first;

    marketPhase = (activeChallenge?.permanentBearMarket ?? false) ? MarketPhase.bear : MarketPhase.bull;
    nextMarketPhase = MarketPhase.inflation;
    phaseSecondsRemaining = 65;
    forecastRevealed = false;
    bubbleRisk = 0.10;
    marketForecastHeadline = marketPhase.subtitle;

    stocks = createInitialStocks();
    properties = createInitialProperties();
    recalculateSynergies();
    // 開局即彈出「傳家寶奇物 3 選 1」決定今局核心流派！
    openRelicDraft3Choice(isStarter: true);
    notifyListeners();
  }

  void recalculateSynergies() {
    final tagCounts = <ShopTag, int>{};
    final placedIds = <String>{};
    for (final s in slots) {
      if (s == null) continue;
      placedIds.add(s.definitionId);
      final def = GameCatalog.shopById(s.definitionId);
      for (final t in def.tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }

    final reqReduction = hasRelic('rel_tycoon_seal') ? 1 : 0;
    final newlyActive = <SynergyDefinition>[];
    for (final syn in kAllSynergies) {
      bool ok = true;
      for (final entry in syn.requiredTags.entries) {
        final needed = max(1, entry.value - reqReduction);
        if ((tagCounts[entry.key] ?? 0) < needed) {
          ok = false;
          break;
        }
      }
      for (final reqId in syn.requiredShopIds) {
        if (!placedIds.contains(reqId)) {
          ok = false;
          break;
        }
      }
      if (ok) {
        newlyActive.add(syn);
        discoveredSynergies.add(syn.id);
      }
    }
    activeSynergies = newlyActive;
    _addMetric('max_active_synergies', newlyActive.length.toDouble(), setMax: true, absoluteVal: newlyActive.length.toDouble());
  }

  void toggleSpeed2x() {
    isSpeed2x = !isSpeed2x;
    notifyListeners();
  }

  void startQuarterMarketRun() {
    if (quarterPhase == QuarterPhase.gameOver || quarterPhase == QuarterPhase.victory) return;
    activeDraft = null;
    quarterPhase = QuarterPhase.running;
    if (quarterSecondsLeft <= 0) quarterSecondsLeft = 18;
    lastToastMessage = '🔔 第 $currentQuarter 季開始營業，請於 18 秒內籌集 ${HkFormatters.money(quarterRentQuota)} 租金。';
    notifyListeners();
  }

  void _settleQuarterEnd() {
    final quota = quarterRentQuota;
    if (cash < quota) {
      quarterPhase = QuarterPhase.gameOver;
      isRunFailed = true;
      lastToastMessage = '💀 第 $currentQuarter 季未能繳付租金 ${HkFormatters.money(quota)}（手頭現金僅 ${HkFormatters.money(cash)}），宣告結業。';
      notifyListeners();
      return;
    }

    cash -= quota;
    if (currentQuarter >= maxQuarters) {
      quarterPhase = QuarterPhase.victory;
      if (bestVictorySeconds == 0 || runElapsedSeconds < bestVictorySeconds) {
        bestVictorySeconds = runElapsedSeconds;
      }
      lastToastMessage = '👑 已繳清第 $maxQuarters 季最終租金 ${HkFormatters.money(quota)}，順利通過全數考核。';
      notifyListeners();
      return;
    }

    final finishedQ = currentQuarter;
    currentQuarter += 1;
    quarterPhase = QuarterPhase.planning;
    quarterSecondsLeft = 18;
    draftRerollCount = 0;
    _cachedShopDraft = null;
    pendingFreeDrafts += 1;
    actionPoints = min(maxActionPoints, actionPoints + 2);

    if (finishedQ % 3 == 0) {
      pendingRelicDrafts += 1;
      advanceToNextTier(forceQuarterPromotion: true);
    }
    lastToastMessage = '✅ 已繳付第 $finishedQ 季租金 ${HkFormatters.money(quota)}，可進行第 $currentQuarter 季免費商舖選取。';
    openShopDraft3Choice(isFree: true);
  }
  void tickOneSecond() {
    // 當處於排陣備戰階段、或者彈出緊 3選1 / 拍賣視窗時，時間完全暫停！
    if (activeDraft != null) return;
    if (quarterPhase != QuarterPhase.running) return;

    runElapsedSeconds += 1;
    if (timeSkipCooldown > 0) timeSkipCooldown -= 1;
    if (tierSkillCooldown > 0) tierSkillCooldown -= 1;

    // 行動力回復
    if (actionPoints < maxActionPoints) {
      actionPointRegenTimer -= 1;
      if (actionPointRegenTimer <= 0) {
        actionPoints += 1;
        actionPointRegenTimer = 20;
      }
    }

    // 物業收租與銀行貸款利息
    final rentGain = properties.fold(0.0, (sum, p) => sum + p.totalRentPerSec) *
        (1.0 + talentEffect('tal_ind_4')) *
        globalIncomeMultiplier;
    if (rentGain > 0) cash += rentGain;

    if (bankLoan > 0) {
      double rateMod = (marketPhase == MarketPhase.inflation ? 1.4 : 1.0) *
          (1.0 - talentEffect('tal_shk_2')).clamp(0.3, 1.5);
      if (hasRelic('rel_blackcard')) rateMod *= 0.5;
      final interest = bankLoan * 0.0025 * rateMod;
      cash -= interest;
    }

    // 街舖計時與連環閃電觸發
    recentChainEvents = [];
    for (int i = 0; i < slots.length; i++) {
      // 如果黃金轉角位仲俾死對頭霸住，該格唔會觸發玩家舖頭
      if (!bossDefeatedInCurrentTier && i == currentTier.goldenSlotIndex) continue;
      final shop = slots[i];
      if (shop == null) continue;
      final def = GameCatalog.shopById(shop.definitionId);
      if (def.triggerType == TriggerType.timer) {
        shop.secondsAccumulator += 1;
        final interval = max(2, def.triggerIntervalSeconds - (hasRelic('rel_red_taxi') ? 1 : 0));
        if (shop.secondsAccumulator >= interval) {
          shop.secondsAccumulator = 0;
          final effBase = (def.basePayout + shop.permanentBonusPayout) * shop.levelMultiplier;
          _triggerSlotChain(i, effBase, 1, <int>{});
        }
      }
    }

    // 死對頭每 10 秒干擾與削血
    _tickBossInteraction();

    // 大市週期與股票跳動
    _tickMarketAndStocks();

    // 進行中老千層壓局與銀主盤拍賣
    _tickPonziAndAuction();

    // 更新最高身家與成就檢查
    final nw = netWorth;
    if (nw > peakNetWorthThisRun) peakNetWorthThisRun = nw;
    if (nw > peakNetWorthAllTime) {
      peakNetWorthAllTime = nw;
      _addMetric('peak_net_worth', nw, setMax: true, absoluteVal: nw);
    }

    // 本季開市倒數與季度交租結算
    quarterSecondsLeft -= 1;
    if (quarterSecondsLeft <= 0) {
      _settleQuarterEnd();
    }

    _checkAchievements();
    notifyListeners();
  }
  void _triggerSlotChain(int slotIdx, double incomingPayout, int depth, Set<int> visitedInBranch) {
    if (slotIdx < 0 || slotIdx >= slots.length) return;
    if (!bossDefeatedInCurrentTier && slotIdx == currentTier.goldenSlotIndex) return;
    final shop = slots[slotIdx];
    if (shop == null) return;

    final def = GameCatalog.shopById(shop.definitionId);
    int maxSteps = 5 + activeSynergies.fold<int>(0, (s, e) => s + e.extraChainSteps) + (hasRelic('rel_bagua_mirror') ? 3 : 0);
    if (depth > maxSteps) return;

    // 蓄力三連爆判定（《灌鉛老千骰盅》改為 2 次即爆）
    bool isBurst = false;
    final neededCharge = hasRelic('rel_dice') ? 2 : 3;
    if (def.triggerType == TriggerType.charge3 && depth > 1) {
      shop.chargeCount += 1;
      if (shop.chargeCount < neededCharge) {
        shop.lastPulseAmount = incomingPayout * 0.25;
        cash += shop.lastPulseAmount;
        return;
      }
      shop.chargeCount = 0;
      isBurst = true;
    }

    // 《食神百年黑鐵鑊》：飲食舖每次觸發永久成長基礎產出
    if (hasRelic('rel_wok') && def.tags.contains(ShopTag.food)) {
      shop.permanentBonusPayout += def.basePayout * 0.06;
    }

    // 採用 Balatro 式「加算區 + 獨立乘區」雙桶公式，防止指數無限失控膨脹
    double additiveBonus = depth == 1 ? 0.0 : (def.chainMultiplier - 1.0) * 0.75;
    if (isBurst && hasRelic('rel_dice')) additiveBonus += 0.45;
    if (shop.level >= 2 && hasRelic('rel_merge_crown')) additiveBonus += 0.55;
    if (hasRelic('rel_blackcard') && (bankLoan > 0 || stocks.any((s) => s.marginDebt > 0))) {
      additiveBonus += 0.40;
    }
    if (hasRelic('rel_combo_battery') && depth > 1) {
      additiveBonus += (depth - 1) * 0.25;
    }
    if (hasRelic('rel_empty_slot_aura')) {
      final emptyCnt = slots.where((s) => s == null).length;
      additiveBonus += emptyCnt * 0.35;
    }
    if (hasRelic('rel_neon_sign')) {
      final uniqueTags = <ShopTag>{};
      for (final s in slots) {
        if (s != null) uniqueTags.addAll(GameCatalog.shopById(s.definitionId).tags);
      }
      additiveBonus += uniqueTags.length * 0.16;
    }
    if (hasRelic('rel_land_deed') && (def.tags.contains(ShopTag.property) || def.tags.contains(ShopTag.finance))) {
      final totalProps = properties.fold(0, (s, p) => s + p.ownedCount);
      additiveBonus += totalProps * 0.18;
    }
    additiveBonus += talentEffect('tal_ind_2');
    for (final syn in activeSynergies) {
      additiveBonus += (syn.chainMultiplierBonus - 1.0) * 0.85;
    }

    // 獨立乘區（大市週期、黃金轉角位、死對頭抽水、賭神籌碼暴擊）
    double indepMult = globalIncomeMultiplier;
    if (hasRelic('rel_vip_chip')) {
      final hasEnt = slots.any((s) => s != null && GameCatalog.shopById(s.definitionId).tags.contains(ShopTag.entertainment));
      if (_rng.nextDouble() < (hasEnt ? 0.55 : 0.30)) indepMult *= 1.75;
    }

    final bearImmune = activeSynergies.any((s) => s.bearMarketImmunity) || hasRelic('rel_vulture_badge');
    if (marketPhase == MarketPhase.bull) {
      indepMult *= def.bullMod;
    } else if (marketPhase == MarketPhase.bubble) {
      indepMult *= def.bullMod * 1.25;
    } else if (marketPhase == MarketPhase.bear) {
      final bearMod = bearImmune ? max(1.0, def.bearMod) : def.bearMod + talentEffect('tal_ind_6');
      indepMult *= bearMod * (hasRelic('rel_vulture_badge') ? 1.65 : 1.0);
    }

    if (bossDefeatedInCurrentTier && slotIdx == currentTier.goldenSlotIndex) {
      indepMult *= ((hasRelic('rel_corner_throne') ? 2.6 : 1.65) + talentEffect('tal_fs_4'));
    }

    if (!bossDefeatedInCurrentTier && _isNeighborOf(slotIdx, currentTier.goldenSlotIndex)) {
      final steal = (currentBoss.stealRate - talentEffect('tal_fs_5')).clamp(0.05, 0.40);
      indepMult *= (1.0 - steal);
    }

    final effBasePayout = (def.basePayout + shop.permanentBonusPayout) * shop.levelMultiplier;
    final baseForStep = effBasePayout + (depth > 1 ? incomingPayout * 0.18 : 0.0);
    double stepPayout = baseForStep * (1.0 + additiveBonus) * indepMult;
    if (depth > 1 && hasRelic('rel_tea_thermos')) {
      stepPayout += min(quarterRentQuota * 0.04, cash * 0.02);
    }
    cash += stepPayout;
    shop.lastPulseAmount = stepPayout;
    shop.lastTriggeredAt = DateTime.now();

    if (depth > 1) {
      _addMetric('chains_triggered', 1);
      _addMetric('max_chain_depth', depth.toDouble(), setMax: true, absoluteVal: depth.toDouble());
      if (tutorialStep == 0) tutorialStep = 1;
      chainComboCharge += 1;
      if (chainComboCharge >= chainComboTarget) {
        chainComboCharge = 0;
        chainComboTarget = min(30, chainComboTarget + 3);
        pendingFreeDrafts += 1;
        lastToastMessage = '⚡ 連鎖累積已滿，獲得 1 次免費商舖選取機會。';
      }
    }

    // ⭐⭐⭐ 三星傳奇進化額外獎勵全鄰格傳遞；《開光關帝金身》令終結收割舖反彈！
    PassDirection effectiveDir = (shop.level >= 3 && def.passDirection != PassDirection.terminal)
        ? PassDirection.allNeighbors
        : def.passDirection;
    if (effectiveDir == PassDirection.terminal) {
      if (hasRelic('rel_guandi')) {
        effectiveDir = PassDirection.bothHorizontal;
      } else {
        return;
      }
    }

    visitedInBranch.add(slotIdx);
    final nextSlots = _targetSlotsForPass(slotIdx, effectiveDir);
    if (hasRelic('rel_containers') && def.tags.contains(ShopTag.logistics)) {
      final skipMore = _targetSlotsForPass(slotIdx, PassDirection.skipOneRight);
      for (final sIdx in skipMore) {
        if (!nextSlots.contains(sIdx)) nextSlots.add(sIdx);
      }
    }

    for (final nextIdx in nextSlots) {
      if (visitedInBranch.contains(nextIdx)) continue;
      if (!bossDefeatedInCurrentTier && nextIdx == currentTier.goldenSlotIndex) continue;
      if (slots[nextIdx] != null) {
        recentChainEvents.add(ChainStepEvent(
          fromSlot: slotIdx,
          toSlot: nextIdx,
          shopName: def.name,
          emoji: def.emoji,
          payout: stepPayout,
          stepDepth: depth + 1,
          isSuperBurst: isBurst || depth >= 3,
        ));
        _triggerSlotChain(nextIdx, stepPayout, depth + 1, visitedInBranch);
      }
    }
  }
  List<int> _targetSlotsForPass(int slotIdx, PassDirection dir) {
    final rows = currentTier.rows;
    final cols = currentTier.cols;
    final r = slotIdx ~/ cols;
    final c = slotIdx % cols;
    final targets = <int>[];

    void addIfValid(int nr, int nc) {
      if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
        targets.add(nr * cols + nc);
      } else if (hasRelic('rel_bagua_mirror') && nr >= 0 && nr < rows) {
        final wrappedCol = (nc + cols) % cols;
        targets.add(nr * cols + wrappedCol);
      }
    }

    switch (dir) {
      case PassDirection.right:
        addIfValid(r, c + 1);
        break;
      case PassDirection.left:
        addIfValid(r, c - 1);
        break;
      case PassDirection.bothHorizontal:
        addIfValid(r, c - 1);
        addIfValid(r, c + 1);
        break;
      case PassDirection.skipOneRight:
        if (c + 2 < cols) {
          addIfValid(r, c + 2);
        } else {
          addIfValid(r, c + 1);
        }
        break;
      case PassDirection.across:
        if (rows > 1) {
          addIfValid(r == 0 ? 1 : 0, c);
        } else {
          addIfValid(r, c + 1);
        }
        break;
      case PassDirection.allNeighbors:
        addIfValid(r, c - 1);
        addIfValid(r, c + 1);
        if (rows > 1) addIfValid(r == 0 ? 1 : 0, c);
        break;
      case PassDirection.terminal:
        break;
    }
    return targets;
  }

  bool _isNeighborOf(int slotA, int slotB) {
    final cols = currentTier.cols;
    final rA = slotA ~/ cols, cA = slotA % cols;
    final rB = slotB ~/ cols, cB = slotB % cols;
    return (rA == rB && (cA - cB).abs() == 1) || (cA == cB && (rA - rB).abs() == 1);
  }

  void _tickBossInteraction() {
    if (bossDefeatedInCurrentTier) return;

    // 玩家隔離舖每秒自動打價格戰削死對頭血條
    final goldenIdx = currentTier.goldenSlotIndex;
    double dps = 0;
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] == null) continue;
      if (_isNeighborOf(i, goldenIdx)) {
        final def = GameCatalog.shopById(slots[i]!.definitionId);
        dps += def.antiRivalPower * slots[i]!.levelMultiplier;
      }
    }
    if (hasRelic('rel_corner_throne')) {
      dps += currentBossMaxHp * 0.04;
    }
    if (dps > 0) {
      double dmgMult = currentTrait.rivalDamageMod *
          (1.0 + talentEffect('tal_ind_5')) *
          (hasRelic('rel_brass_knuckle') ? 2.0 : 1.0);
      for (final syn in activeSynergies) {
        dmgMult *= syn.rivalDamageMultiplier;
      }
      final totalDmg = dps * dmgMult;
      bossCurrentHp = (bossCurrentHp - totalDmg).clamp(0.0, currentBossMaxHp);
      if (hasRelic('rel_brass_knuckle')) {
        cash += totalDmg * 12.0;
      }
    }

    if (bossInDistress) {
      bossDistressSecondsLeft -= 1;
      if (bossDistressSecondsLeft <= 0) {
        bossInDistress = false;
        bossBubbleQuote = currentBoss.tauntQuotes[_rng.nextInt(currentBoss.tauntQuotes.length)];
      }
    } else if (marketPhase == MarketPhase.bear && _rng.nextDouble() < 0.14) {
      bossInDistress = true;
      bossDistressSecondsLeft = 30;
      bossBubbleQuote = currentBoss.panicQuotes.first;
      lastToastMessage = '🔥 ${currentBoss.name}於熊市中資金周轉不靈，30 秒內可按半價收購。';
    } else if (runElapsedSeconds % 10 == 0) {
      bossBubbleQuote = currentBoss.tauntQuotes[_rng.nextInt(currentBoss.tauntQuotes.length)];
    }
  }

  bool takeoverRivalBoss() {
    if (bossDefeatedInCurrentTier) return false;
    final cost = takeoverCost;
    if (cash < cost) return false;

    cash -= cost;
    bossDefeatedInCurrentTier = true;
    bossCurrentHp = 0;
    bossInDistress = false;
    bossBubbleQuote = currentBoss.defeatedQuote;

    // 搶埋黃金轉角位並送一間當前層級代表舖
    final goldenIdx = currentTier.goldenSlotIndex;
    final tierShops = kAllShops.where((s) => s.tier == currentTier.level).toList();
    final giftShop = tierShops[_rng.nextInt(tierShops.length)];
    slots[goldenIdx] = PlacedShop(definitionId: giftShop.id, level: 2);
    discoveredShops.add(giftShop.id);
    recalculateSynergies();

    _addMetric('bosses_defeated', 1);
    pendingFreeDrafts += 1;
    pendingRelicDrafts += 1;
    lastToastMessage = '🎉 已成功收購${currentBoss.name}的業務，取得黃金轉角舖位並獲贈 1 次商業奇物選取機會。';

    // 街頭與社區層吞併Boss後直接晉升；城市層以上需身家達標方可晉升跨國/首富層
    if (currentTier.level < 3 || (currentTier.level < 5 && netWorth >= currentTier.targetNetWorth)) {
      advanceToNextTier(forceQuarterPromotion: true);
    }
    openRelicDraft3Choice();
    notifyListeners();
    return true;
  }
  int get maxTierForCurrentGeneration {
    if (generation <= 1) return 4; // 第1代可一路去到跨國層
    return 5; // 第2代起全面開放首富層
  }

  bool advanceToNextTier({bool forceQuarterPromotion = false}) {
    if (currentTier.level >= maxTierForCurrentGeneration) return false;
    if (!forceQuarterPromotion && currentTier.level >= 3 && netWorth < currentTier.targetNetWorth) return false;
    final nextTier = TierType.fromLevel(currentTier.level + 1);
    currentTier = nextTier;

    // 擴充街區片位（例如 6 格 -> 8 格）
    while (slots.length < nextTier.slotCount) {
      slots.add(null);
    }

    // 新一層死對頭登場霸住黃金轉角位（如該位有舊舖，自動搬去空位）
    bossDefeatedInCurrentTier = false;
    bossCurrentHp = currentBossMaxHp;
    bossInDistress = false;
    bossBubbleQuote = currentBoss.tauntQuotes.first;

    final goldenIdx = currentTier.goldenSlotIndex;
    if (slots[goldenIdx] != null) {
      final emptyIdx = slots.indexWhere((s) => s == null);
      if (emptyIdx != -1 && emptyIdx != goldenIdx) {
        slots[emptyIdx] = slots[goldenIdx];
        slots[goldenIdx] = null;
      }
    }

    recalculateSynergies();
    lastToastMessage = '🏙️ 業務晉升至【${currentTier.name}・${currentTier.identity}】，競爭對手${currentBoss.name}登場。';
    notifyListeners();
    return true;
  }

  void _tickMarketAndStocks() {
    phaseSecondsRemaining -= 1;

    // 提早 45 秒預兆下一個大市週期
    if (phaseSecondsRemaining == 45 && !forecastRevealed) {
      forecastRevealed = true;
      double acc = 0.70 + talentEffect('tal_shk_1');
      for (final syn in activeSynergies) {
        acc += syn.insiderAccuracyBonus;
      }
      acc = acc.clamp(0.70, 0.96);
      final isAccurate = _rng.nextDouble() <= acc;
      final shownPhase = isAccurate ? nextMarketPhase : MarketPhase.values[_rng.nextInt(MarketPhase.values.length)];
      marketForecastHeadline = '📡 市場預測（準確度 ${(acc * 100).toInt()}%）：45 秒後大市可能轉入【${shownPhase.title}】。';

      // 同時隨機放出一隻莊家內幕股貼士
      for (final s in stocks) {
        s.insiderBullishTip = null;
      }
      final tipStock = visibleStocks[_rng.nextInt(visibleStocks.length)];
      tipStock.insiderBullishTip = shownPhase != MarketPhase.bear;
    }

    if (phaseSecondsRemaining <= 0) {
      if (activeChallenge?.permanentBearMarket ?? false) {
        marketPhase = MarketPhase.bear;
      } else {
        marketPhase = nextMarketPhase;
      }
      // 決定再下一階段：泡沫過後必爆股災熊市
      if (marketPhase == MarketPhase.bubble || _rng.nextDouble() < bubbleRisk) {
        nextMarketPhase = MarketPhase.bear;
        bubbleRisk = 0.10;
      } else {
        final candidates = MarketPhase.values.where((p) => p != marketPhase).toList();
        nextMarketPhase = candidates[_rng.nextInt(candidates.length)];
      }
      phaseSecondsRemaining = 65 + _rng.nextInt(25);
      forecastRevealed = false;
      marketForecastHeadline = '${marketPhase.title}：${marketPhase.subtitle}';

      // 轉市暴擊舖觸發
      for (int i = 0; i < slots.length; i++) {
        if (!bossDefeatedInCurrentTier && i == currentTier.goldenSlotIndex) continue;
        final s = slots[i];
        if (s == null) continue;
        final def = GameCatalog.shopById(s.definitionId);
        if (def.triggerType == TriggerType.onMarketSwing) {
          _triggerSlotChain(i, def.basePayout * s.levelMultiplier * 1.8, 1, <int>{});
        }
      }

      // 進入熊市時自動觸發一次銀主盤拍賣或蘭姐斷供
      if (marketPhase == MarketPhase.bear) {
        if (!bossDefeatedInCurrentTier && !bossInDistress) {
          bossInDistress = true;
          bossDistressSecondsLeft = 30;
          bossBubbleQuote = currentBoss.panicQuotes.first;
        }
        if (activeAuction == null) {
          startBearMarketAuction();
        }
      }
    }

    // 每 2 秒更新一次股價與物業價格
    if (runElapsedSeconds % 2 == 0) {
      double drift = 0.0;
      if (marketPhase == MarketPhase.bull) drift = 0.025;
      if (marketPhase == MarketPhase.inflation) drift = 0.015;
      if (marketPhase == MarketPhase.bubble) drift = 0.055;
      if (marketPhase == MarketPhase.bear) drift = -0.048;

      for (final stk in stocks) {
        stk.previousPrice = stk.currentPrice;
        double tipBoost = 0.0;
        if (stk.insiderBullishTip == true) tipBoost = 0.035;
        if (stk.insiderBullishTip == false) tipBoost = -0.035;
        final noise = (_rng.nextDouble() * 2 - 1) * stk.volatility * 0.45;
        final pctChange = (drift + tipBoost + noise).clamp(-0.22, 0.28);
        stk.currentPrice = max(0.5, stk.currentPrice * (1.0 + pctChange));
        stk.history.add(stk.currentPrice);
        if (stk.history.length > 16) stk.history.removeAt(0);

        // 檢查 3x 孖展斬倉線
        if (stk.marginDebt > 0 && stk.positionValue < stk.marginDebt * 1.05) {
          stk.ownedShares = 0;
          stk.marginDebt = 0;
          stk.averageEntryPrice = 0;
          lastToastMessage = '⚠️ ${stk.name}股價急跌觸發強制平倉，請留意市場走勢及時止蝕。';
        }
      }

      for (final prop in properties) {
        final propDrift = marketPhase == MarketPhase.bear ? -0.015 : 0.012;
        prop.currentPrice = max(prop.basePrice * 0.5, prop.currentPrice * (1.0 + propDrift));
      }
    }
  }
  void swapOrMoveShops(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    if (fromIndex < 0 || fromIndex >= slots.length || toIndex < 0 || toIndex >= slots.length) return;
    if (!bossDefeatedInCurrentTier &&
        (fromIndex == currentTier.goldenSlotIndex || toIndex == currentTier.goldenSlotIndex)) {
      lastToastMessage = '⚠️ 黃金轉角舖位仍由${currentBoss.name}佔據，需完成收購後方可使用。';
      notifyListeners();
      return;
    }

    final temp = slots[fromIndex];
    slots[fromIndex] = slots[toIndex];
    slots[toIndex] = temp;
    recalculateSynergies();

    // 拖位後即刻免費試爆一次全街定時起點連鎖，俾玩家即時感受爽感
    recentChainEvents = [];
    for (int i = 0; i < slots.length; i++) {
      if (!bossDefeatedInCurrentTier && i == currentTier.goldenSlotIndex) continue;
      final s = slots[i];
      if (s == null) continue;
      final def = GameCatalog.shopById(s.definitionId);
      if (def.triggerType == TriggerType.timer) {
        _triggerSlotChain(i, def.basePayout * s.levelMultiplier, 1, <int>{});
      }
    }
    notifyListeners();
  }

  double shopPurchaseCost(ShopDefinition def) {
    final discount = (talentEffect('tal_ind_3') + (hasRelic('rel_abacus_gold') ? 0.25 : 0.0)).clamp(0.0, 0.65);
    return def.baseCost * (1.0 - discount);
  }

  List<int> targetSlotsForShopAt(int slotIdx) {
    if (slotIdx < 0 || slotIdx >= slots.length) return const [];
    final s = slots[slotIdx];
    if (s == null) return const [];
    final def = GameCatalog.shopById(s.definitionId);
    PassDirection dir = (s.level >= 3 && def.passDirection != PassDirection.terminal)
        ? PassDirection.allNeighbors
        : def.passDirection;
    if (dir == PassDirection.terminal && hasRelic('rel_guandi')) {
      dir = PassDirection.bothHorizontal;
    }
    return _targetSlotsForPass(slotIdx, dir);
  }

  bool willShopTriggerThreeMerge(String shopId) {
    final matchingLvl1 = slots.where((s) => s != null && s.definitionId == shopId && s.level == 1).length;
    return matchingLvl1 >= 2;
  }

  void _applyBulldozerNeighborBuff(int centerIdx) {
    if (!hasRelic('rel_bulldozer')) return;
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] != null && _isNeighborOf(i, centerIdx)) {
        slots[i]!.neighborPermBonusMult += 0.35;
      }
    }
  }

  bool _tryThreeInOneMerge() {
    bool anyMerged = false;
    for (int targetLvl = 1; targetLvl <= 2; targetLvl++) {
      final byId = <String, List<int>>{};
      for (int i = 0; i < slots.length; i++) {
        if (!bossDefeatedInCurrentTier && i == currentTier.goldenSlotIndex) continue;
        final s = slots[i];
        if (s != null && s.level == targetLvl) {
          byId.putIfAbsent(s.definitionId, () => []).add(i);
        }
      }
      for (final entry in byId.entries) {
        if (entry.value.length >= 3) {
          // 保留最新擺入嗰格（entry.value.last），避免破壞玩家精心排好嘅位置
          final keepIdx = entry.value.last;
          final removeA = entry.value[0];
          final removeB = entry.value[1];
          slots[keepIdx]!.level = targetLvl + 1;
          slots[keepIdx]!.permanentBonusPayout +=
              slots[removeA]!.permanentBonusPayout + slots[removeB]!.permanentBonusPayout;
          slots[removeA] = null;
          slots[removeB] = null;
          _applyBulldozerNeighborBuff(keepIdx);
          final def = GameCatalog.shopById(entry.key);
          final extraHint = slots[keepIdx]!.level >= 3 ? '（已解鎖全鄰格擴散）' : '';
          lastToastMessage = '🌟 三合一升星完成：【${def.name}】合成為 ${slots[keepIdx]!.starBadge}$extraHint，騰出 2 個舖位。';
          anyMerged = true;
        }
      }
    }
    return anyMerged;
  }

  bool buyShopIntoSlot(String shopId, {int? targetSlot, bool isFreeFromDraft = false}) {
    final def = GameCatalog.shopById(shopId);
    if (activeChallenge?.restrictedTagOnly != null &&
        !def.tags.contains(activeChallenge!.restrictedTagOnly)) {
      lastToastMessage = '⚠️ 當前家族挑戰只准經營【${activeChallenge!.restrictedTagOnly!.label}】類別業務。';
      notifyListeners();
      return false;
    }

    final cost = isFreeFromDraft ? 0.0 : shopPurchaseCost(def);
    if (cash < cost) return false;

    // 如果街位已滿，但場上已有 2 間同款 Lv.1 舖，可直接原位三合一升星！
    final lvl1Indices = <int>[];
    for (int i = 0; i < slots.length; i++) {
      if (!bossDefeatedInCurrentTier && i == currentTier.goldenSlotIndex) continue;
      if (slots[i] != null && slots[i]!.definitionId == shopId && slots[i]!.level == 1) {
        lvl1Indices.add(i);
      }
    }

    int slotIdx = targetSlot ?? -1;
    if (slotIdx < 0 || slotIdx >= slots.length || slots[slotIdx] != null ||
        (!bossDefeatedInCurrentTier && slotIdx == currentTier.goldenSlotIndex)) {
      slotIdx = -1;
      for (int i = 0; i < slots.length; i++) {
        if (!bossDefeatedInCurrentTier && i == currentTier.goldenSlotIndex) continue;
        if (slots[i] == null) {
          slotIdx = i;
          break;
        }
      }
    }

    if (slotIdx == -1 && lvl1Indices.length >= 2) {
      cash -= cost;
      final keepIdx = lvl1Indices[0];
      final removeIdx = lvl1Indices[1];
      slots[keepIdx]!.level = 2;
      slots[removeIdx] = null;
      _applyBulldozerNeighborBuff(keepIdx);
      _tryThreeInOneMerge();
      recalculateSynergies();
      lastToastMessage = '🌟 三合一升星完成：【${def.name}】直接升至 ⭐⭐ 二星。';
      notifyListeners();
      return true;
    }

    if (slotIdx == -1) {
      lastToastMessage = '⚠️ 商舖格位已滿，可選擇同款商舖作三合一升星，或點擊現有商舖轉讓騰出格位。';
      notifyListeners();
      return false;
    }

    cash -= cost;
    slots[slotIdx] = PlacedShop(definitionId: def.id, level: 1);
    discoveredShops.add(def.id);
    if (tutorialStep == 1) tutorialStep = 2;
    _tryThreeInOneMerge();
    recalculateSynergies();
    _triggerSlotChain(slotIdx, def.basePayout, 1, <int>{});
    notifyListeners();
    return true;
  }

  double shopUpgradeCost(int slotIdx) {
    final shop = slots[slotIdx];
    if (shop == null) return 0;
    final def = GameCatalog.shopById(shop.definitionId);
    final discount = talentEffect('tal_ind_3').clamp(0.0, 0.45);
    return def.baseCost * pow(1.55, shop.level) * (1.0 - discount);
  }

  bool upgradeShopAtSlot(int slotIdx) {
    final shop = slots[slotIdx];
    if (shop == null || shop.level >= 8) return false;
    final cost = shopUpgradeCost(slotIdx);
    if (cash < cost) return false;

    cash -= cost;
    shop.level += 1;
    lastToastMessage = '⬆️ 商舖升級成功，Lv.${shop.level} 收入與連鎖收益提升。';
    notifyListeners();
    return true;
  }

  void sellShopAtSlot(int slotIdx) {
    final shop = slots[slotIdx];
    if (shop == null) return;
    final def = GameCatalog.shopById(shop.definitionId);
    final refundRate = hasRelic('rel_abacus_gold') ? 1.0 : 0.70;
    final refund = def.baseCost * shop.levelMultiplier * refundRate;
    cash += refund;
    slots[slotIdx] = null;
    _applyBulldozerNeighborBuff(slotIdx);
    recalculateSynergies();
    lastToastMessage = '💰 已轉讓商舖並套現 ${HkFormatters.money(refund)}。';
    notifyListeners();
  }
  bool buyStock(String stockId, {double cashFraction = 0.25, bool useMargin3x = false}) {
    if (activeChallenge?.id == 'ch_property_tycoon') {
      lastToastMessage = '⚠️ 「地產鉅子」挑戰期間不可買賣股票。';
      notifyListeners();
      return false;
    }
    if (useMargin3x && (activeChallenge?.noLoansAllowed ?? false)) {
      lastToastMessage = '⚠️ 「零負債經營」挑戰期間不可使用融資借貸。';
      notifyListeners();
      return false;
    }
    final stk = stocks.firstWhere((s) => s.id == stockId);
    final investCash = (cash * cashFraction).clamp(0.0, cash);
    if (investCash < 50) return false;

    cash -= investCash;
    final buyingPower = useMargin3x ? investCash * 3.0 : investCash;
    if (useMargin3x) {
      stk.marginDebt += investCash * 2.0;
      bubbleRisk = (bubbleRisk + 0.04).clamp(0.05, 0.75);
    }
    final newShares = buyingPower / stk.currentPrice;
    final totalCost = (stk.ownedShares * stk.averageEntryPrice) + buyingPower;
    stk.ownedShares += newShares;
    stk.averageEntryPrice = totalCost / stk.ownedShares;

    if (tutorialStep == 2) tutorialStep = 3;
    _addMetric('stock_trades', 1);
    notifyListeners();
    return true;
  }

  bool sellStock(String stockId) {
    final stk = stocks.firstWhere((s) => s.id == stockId);
    if (stk.ownedShares <= 0) return false;

    final grossValue = stk.positionValue;
    final netProceeds = grossValue - stk.marginDebt;
    final costBasis = (stk.ownedShares * stk.averageEntryPrice) - stk.marginDebt;
    final profit = netProceeds - costBasis;

    double finalPayout = netProceeds;
    if (profit > 0) {
      final bonusMult = currentTrait.stockProfitMod * (1.0 + talentEffect('tal_shk_8')) - 1.0;
      if (bonusMult > 0) finalPayout += profit * bonusMult;
    }
    cash = max(0.0, cash + finalPayout);
    stk.ownedShares = 0;
    stk.marginDebt = 0;
    stk.averageEntryPrice = 0;
    _addMetric('stock_trades', 1);
    notifyListeners();
    return true;
  }

  bool shortStock(String stockId, {double cashFraction = 0.25}) {
    final stk = stocks.firstWhere((s) => s.id == stockId);
    final collateral = (cash * cashFraction).clamp(0.0, cash);
    if (collateral < 50) return false;

    cash -= collateral;
    final shares = collateral / stk.currentPrice;
    final prevCollateral = stk.shortShares * stk.shortEntryPrice;
    stk.shortShares += shares;
    stk.shortEntryPrice = (prevCollateral + collateral) / stk.shortShares;
    _addMetric('stock_trades', 1);
    notifyListeners();
    return true;
  }

  bool coverShortStock(String stockId) {
    final stk = stocks.firstWhere((s) => s.id == stockId);
    if (stk.shortShares <= 0) return false;

    final collateral = stk.shortShares * stk.shortEntryPrice;
    final rawProfit = (stk.shortEntryPrice - stk.currentPrice) * stk.shortShares;
    double finalProfit = rawProfit;
    if (rawProfit > 0) {
      finalProfit *= currentTrait.stockProfitMod * (1.0 + talentEffect('tal_shk_5'));
      _addMetric('short_wins', 1);
    }
    cash = max(0.0, cash + collateral + finalProfit);
    stk.shortShares = 0;
    stk.shortEntryPrice = 0;
    notifyListeners();
    return true;
  }

  double propertyDownPaymentCost(PropertyState prop) {
    double discount = 0.0;
    for (final syn in activeSynergies) {
      discount += syn.propertyDownPaymentDiscount;
    }
    discount = discount.clamp(0.0, 0.55);
    return prop.currentPrice * (1.0 - discount);
  }

  bool buyProperty(String propId) {
    final prop = properties.firstWhere((p) => p.id == propId);
    final cost = propertyDownPaymentCost(prop);
    if (cash < cost) return false;

    cash -= cost;
    prop.ownedCount += 1;
    _addMetric('properties_bought', 1);
    notifyListeners();
    return true;
  }

  bool renovateProperty(String propId) {
    final prop = properties.firstWhere((p) => p.id == propId);
    if (prop.renovatedCount >= prop.ownedCount) return false;
    final cost = prop.currentPrice * 0.45 * (1.0 - talentEffect('tal_ind_7')).clamp(0.4, 1.0);
    if (cash < cost) return false;

    cash -= cost;
    prop.renovatedCount += 1;
    bubbleRisk = (bubbleRisk + 0.03).clamp(0.05, 0.75);
    _addMetric('properties_bought', 1);
    notifyListeners();
    return true;
  }

  bool mortgageProperty(String propId) {
    if (activeChallenge?.noLoansAllowed ?? false) return false;
    final prop = properties.firstWhere((p) => p.id == propId);
    if (prop.mortgagedCount >= prop.ownedCount) return false;

    final cashOut = prop.currentPrice * 0.70;
    prop.mortgagedCount += 1;
    cash += cashOut;
    bankLoan += cashOut;
    bubbleRisk = (bubbleRisk + 0.04).clamp(0.05, 0.75);
    notifyListeners();
    return true;
  }
  double get maxLoanCapacity => max(5000.0, netWorth * 1.2);

  bool borrowLoan(double amount) {
    if (activeChallenge?.noLoansAllowed ?? false) {
      lastToastMessage = '⚠️ 「零負債經營」挑戰期間不可申請借貸。';
      notifyListeners();
      return false;
    }
    if (bankLoan + amount > maxLoanCapacity) return false;
    bankLoan += amount;
    cash += amount;
    bubbleRisk = (bubbleRisk + 0.03).clamp(0.05, 0.75);
    notifyListeners();
    return true;
  }

  bool repayLoan(double amount) {
    final pay = min(cash, min(bankLoan, amount));
    if (pay <= 0) return false;
    cash -= pay;
    bankLoan -= pay;
    notifyListeners();
    return true;
  }

  bool triggerTimeSkip({bool fromRewardAd = false}) {
    if (!fromRewardAd && timeSkipCooldown > 0) return false;
    for (int i = 0; i < 15; i++) {
      tickOneSecond();
    }
    final bonus = max(300.0, shopsAssetValue * 0.08) * (1.0 + talentEffect('tal_fs_6'));
    cash += bonus;
    if (!fromRewardAd) timeSkipCooldown = 35;
    lastToastMessage = '⚡ 已快速推進 15 秒，並額外獲得 ${HkFormatters.money(bonus)} 營業收益。';
    notifyListeners();
    return true;
  }

  bool useTierSpecialSkill() {
    if (tierSkillCooldown > 0) return false;
    final cdMult = (1.0 - talentEffect('tal_shk_6')).clamp(0.5, 1.0);
    tierSkillCooldown = (45 * cdMult).round();
    _addMetric('tier_skills_used', 1);

    switch (currentTier) {
      case TierType.street:
        startBearMarketAuction();
        lastToastMessage = '🔨 已發動【街頭特技：特價商舖拍賣】，拍賣會隨即開始。';
        break;
      case TierType.community:
        final rentBurst = max(8000.0, propertiesNetEquity * 0.12 + shopsAssetValue * 0.15);
        cash += rentBurst;
        lastToastMessage = '🏢 已發動【商場特技：全區租金結算】，獲得 ${HkFormatters.money(rentBurst)}。';
        break;
      case TierType.city:
        for (final s in visibleStocks) {
          s.currentPrice *= 1.32;
        }
        bubbleRisk = (bubbleRisk + 0.08).clamp(0.05, 0.85);
        lastToastMessage = '📣 已發動【金融特技：發佈利好消息】，全線股票上升 +32%。';
        break;
      case TierType.multinational:
        marketPhase = MarketPhase.bear;
        phaseSecondsRemaining = 45;
        bossInDistress = true;
        bossDistressSecondsLeft = 30;
        lastToastMessage = '🦈 已發動【資本特技：引發市場調整】，競爭對手陷入資金壓力。';
        break;
      case TierType.tycoon:
        final reclamationGain = max(5e9, netWorth * 0.22);
        cash += reclamationGain;
        bossCurrentHp = (bossCurrentHp * 0.4);
        lastToastMessage = '👑 已發動【集團特技：大型發展計劃】，資產增加 ${HkFormatters.money(reclamationGain)}。';
        break;
    }
    notifyListeners();
    return true;
  }

  OpportunityCard? drawOpportunityCard() {
    if (actionPoints <= 0) return null;
    actionPoints -= 1;
    final eligible = kAllOpportunityCards.where((c) => c.minTier <= currentTier.level).toList();
    final card = eligible[_rng.nextInt(eligible.length)];
    pendingOpportunity = card;
    notifyListeners();
    return card;
  }

  String resolveOpportunityCard(OpportunityCard card, {required bool accepted}) {
    pendingOpportunity = null;
    _addMetric('opportunities_taken', 1);
    if (!accepted) {
      lastToastMessage = '為求穩健，你已婉拒「${card.title}」。';
      notifyListeners();
      return lastToastMessage;
    }

    final tierCap = currentTier.targetNetWorth * 0.12;
    final baseStake = min(tierCap, max(300.0, cash * card.costFactor));
    if (card.isPonziScheme) {
      final stake = min(cash, baseStake);
      cash -= stake;
      final bustSec = 6 + _rng.nextInt(8) + (talentEffect('tal_shk_7') * 10).round();
      activePonzi = ActivePonziState(
        title: card.title,
        principal: max(300.0, stake),
        bustAtSecond: bustSec,
      );
      lastToastMessage = '🚨 已參與【${card.title}】，回報倍數正持續上升，請於崩盤前及時撤資。';
      notifyListeners();
      return lastToastMessage;
    }

    final chance = (card.successChance + currentTrait.luckBonus + talentEffect('tal_fs_3')).clamp(0.15, 0.96);
    if (_rng.nextDouble() <= chance) {
      final gain = baseStake * card.rewardMultiplier * globalIncomeMultiplier;
      cash += gain;
      lastToastMessage = '🎉 ${card.successMessage}（淨利潤 ${HkFormatters.money(gain)}）';
    } else {
      final loss = min(cash * 0.6, baseStake * card.failPenaltyFactor);
      cash -= loss;
      lastToastMessage = '💥 ${card.failMessage}（損失 ${HkFormatters.money(loss)}）';
    }
    notifyListeners();
    return lastToastMessage;
  }
  void _tickPonziAndAuction() {
    if (activePonzi != null) {
      activePonzi!.secondsElapsed += 1;
      activePonzi!.currentMultiplier *= (1.16 + talentEffect('tal_shk_7') * 0.15);
      if (activePonzi!.secondsElapsed >= activePonzi!.bustAtSecond) {
        final title = activePonzi!.title;
        activePonzi = null;
        _addMetric('ponzi_busted', 1);
        lastToastMessage = '💥 【$title】資金鏈斷裂，主辦方潛逃，投入本金全數損失。';
      }
    }

    if (activeAuction != null) {
      activeAuction!.secondsLeft -= 1;
      if (activeAuction!.secondsLeft > 0) {
        final nextPrice = activeAuction!.currentBid + activeAuction!.minIncrement;
        if (activeAuction!.highestBidder != 'rival' &&
            nextPrice <= activeAuction!.rivalMaxBid &&
            _rng.nextDouble() < 0.45) {
          activeAuction!.currentBid = nextPrice;
          activeAuction!.highestBidder = 'rival';
        } else if (activeAuction!.highestBidder != 'passerby' &&
            nextPrice <= activeAuction!.passerbyMaxBid &&
            _rng.nextDouble() < 0.35) {
          activeAuction!.currentBid = nextPrice;
          activeAuction!.highestBidder = 'passerby';
        }
      } else {
        finishAuctionNow();
      }
    }
  }

  double cashOutPonzi() {
    if (activePonzi == null) return 0;
    final payout = activePonzi!.cashOutValue;
    cash += payout;
    activePonzi = null;
    _addMetric('ponzi_escaped', 1);
    lastToastMessage = '🏃‍♂️ 已及時撤資，成功從高風險項目提取 ${HkFormatters.money(payout)}。';
    notifyListeners();
    return payout;
  }

  void startBearMarketAuction() {
    final tierShops = kAllShops.where((s) => s.tier == currentTier.level).toList();
    final targetShop = tierShops[_rng.nextInt(tierShops.length)];
    final mktVal = targetShop.baseCost * 1.4;
    final startBid = mktVal * 0.35;
    final inc = max(100.0, mktVal * 0.08);
    // 第一代新手局首次拍賣劇本保證玩家容易贏
    final isEasyScript = generation == 1 && (metrics['auctions_won'] ?? 0) == 0;
    activeAuction = ActiveAuctionState(
      title: '銀主盤拍賣：${targetShop.name}（Lv.2）',
      emoji: targetShop.emoji,
      description: '原價 ${HkFormatters.money(mktVal)}，底價三五折起標，投得即可進駐空位或折算差價。',
      rewardShopId: targetShop.id,
      marketValue: mktVal,
      currentBid: startBid,
      minIncrement: inc,
      highestBidder: 'passerby',
      secondsLeft: 16,
      rivalMaxBid: isEasyScript ? startBid + inc : mktVal * 0.82,
      passerbyMaxBid: isEasyScript ? startBid : mktVal * 0.68,
    );
    notifyListeners();
  }

  bool playerBidInAuction() {
    final auc = activeAuction;
    if (auc == null) return false;
    final nextBid = auc.highestBidder == 'player' ? auc.currentBid : auc.currentBid + auc.minIncrement;
    if (cash < nextBid) return false;
    auc.currentBid = nextBid;
    auc.highestBidder = 'player';
    notifyListeners();
    return true;
  }

  void finishAuctionNow() {
    final auc = activeAuction;
    if (auc == null) return;
    activeAuction = null;

    if (auc.highestBidder == 'player' && cash >= auc.currentBid) {
      double rebate = talentEffect('tal_shk_3');
      for (final syn in activeSynergies) {
        rebate += syn.bargainDiscount;
      }
      final finalPrice = auc.currentBid * (1.0 - rebate.clamp(0.0, 0.50));
      cash -= finalPrice;
      // 嘗試放入空位，如無空位直接折算 1.5 倍市價利潤
      int emptySlot = -1;
      for (int i = 0; i < slots.length; i++) {
        if (!bossDefeatedInCurrentTier && i == currentTier.goldenSlotIndex) continue;
        if (slots[i] == null) {
          emptySlot = i;
          break;
        }
      }
      if (emptySlot != -1) {
        slots[emptySlot] = PlacedShop(definitionId: auc.rewardShopId, level: 2);
        discoveredShops.add(auc.rewardShopId);
        recalculateSynergies();
      } else {
        cash += auc.marketValue * 1.35;
      }
      _addMetric('auctions_won', 1);
      lastToastMessage = '🔨 拍賣成交：已以 ${HkFormatters.money(finalPrice)} 投得【${auc.title}】。';
    } else {
      _addMetric('auctions_lost', 1);
      lastToastMessage = '😤 銀主盤已被${auc.highestBidder == 'rival' ? currentBoss.name : '其他買家'}投得。';
    }
    notifyListeners();
  }
  int calculateRetirementPrestige({bool isBankrupt = false}) {
    final base = max(1.0, log(max(1000.0, peakNetWorthThisRun)) / ln10 - 2.5);
    double pts = pow(base, 2.35) * 6.0 + (currentTier.level - 1) * 18;
    pts *= (1.0 + talentEffect('tal_fs_7'));
    for (final luxId in ownedLuxuries) {
      final lux = kAllLuxuries.where((l) => l.id == luxId).firstOrNull;
      if (lux != null) pts *= (1.0 + lux.prestigeGainBonus);
    }
    if (isBankrupt) pts *= 0.45;
    return max(5, pts.round());
  }

  int retireAndInherit({bool isBankrupt = false, String? nextChallengeId}) {
    final gained = calculateRetirementPrestige(isBankrupt: isBankrupt);
    familyPrestige += gained;
    familyFund += max(500.0, peakNetWorthThisRun * 0.04);

    if (isBankrupt) {
      _addMetric('bankruptcies', 1);
    } else if (activeChallenge != null) {
      if (currentTier.level >= 3) {
        completedChallenges.add(activeChallenge!.id);
        ownedLuxuries.add(activeChallenge!.rewardLuxuryId);
      }
    }

    startNewGeneration(comebackBonus: isBankrupt, challengeId: nextChallengeId);
    lastToastMessage = isBankrupt
        ? '💪 已完成世代交接，獲得 $gained 點家族聲望及「東山再起」1.5 倍啟動資金加成。'
        : '🎉 已完成退休傳承，第 $generation 代繼承人正式接手，獲得 $gained 點家族聲望。';
    notifyListeners();
    return gained;
  }

  double calculateAndApplyOfflineFund(DateTime now, {bool doubleWithAd = false}) {
    // 專注單局 Roguelike 策略體驗，移除離線掛機結算
    lastSavedTimestamp = now;
    return 0;
  }

  double get draftRerollCost {
    final base = max(120.0, quarterRentQuota * 0.08);
    final mult = pow(1.45, draftRerollCount).toDouble() * (hasRelic('rel_merge_crown') ? 0.5 : 1.0);
    return (base * mult).roundToDouble();
  }

  String _buildSynergyPreviewForShop(ShopDefinition s) {
    final tagCounts = <ShopTag, int>{};
    for (final sl in slots) {
      if (sl == null) continue;
      for (final t in GameCatalog.shopById(sl.definitionId).tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }
    final reqRed = hasRelic('rel_tycoon_seal') ? 1 : 0;
    for (final syn in kAllSynergies) {
      if (activeSynergies.any((a) => a.id == syn.id)) continue;
      for (final entry in syn.requiredTags.entries) {
        if (s.tags.contains(entry.key)) {
          final need = max(1, entry.value - reqRed);
          final cur = tagCounts[entry.key] ?? 0;
          if (cur + 1 >= need) return '🧩 選擇即可激活【${syn.name}】';
          return '🧩 ${syn.name} $cur/$need ➡️ ${cur + 1}/$need';
        }
      }
    }
    return '';
  }

  String _buildRelicPreviewForShop(ShopDefinition s) {
    if (hasRelic('rel_wok') && s.tags.contains(ShopTag.food)) return '🏺 配合【百年黑鐵鑊】提升產出';
    if (hasRelic('rel_containers') && s.tags.contains(ShopTag.logistics)) return '🏺 配合【葵涌貨櫃模型】隔格傳遞';
    if (hasRelic('rel_vip_chip') && s.tags.contains(ShopTag.entertainment)) return '🏺 配合【貴賓廳水晶籌碼】提升暴擊';
    if (hasRelic('rel_land_deed') && (s.tags.contains(ShopTag.property) || s.tags.contains(ShopTag.finance))) {
      return '🏺 配合【淺水灣地契】收租加成';
    }
    if (hasRelic('rel_dice') && s.triggerType == TriggerType.charge3) return '🏺 配合【精製水晶骰盅】2 次蓄力觸發';
    if (hasRelic('rel_guandi') && s.passDirection == PassDirection.terminal) return '🏺 配合【關帝銅像】終結反彈';
    return '';
  }

  void openShopDraft3Choice({bool isFree = false, bool forceNewRoll = false}) {
    final useFreeToken = isFree || pendingFreeDrafts > 0;
    final skipCash = (quarterRentQuota * 0.16).roundToDouble();
    if (!forceNewRoll && _cachedShopDraft != null) {
      for (final c in _cachedShopDraft!.choices) {
        final def = GameCatalog.shopById(c.id);
        c.cost = useFreeToken ? 0.0 : shopPurchaseCost(def);
        c.willTriggerThreeMerge = willShopTriggerThreeMerge(c.id);
      }
      activeDraft = _cachedShopDraft;
      notifyListeners();
      return;
    }

    final pool = List<ShopDefinition>.from(GameCatalog.shopsForTier(currentTier.level));
    if (activeChallenge?.restrictedTagOnly != null) {
      pool.retainWhere((s) => s.tags.contains(activeChallenge!.restrictedTagOnly));
    }
    pool.shuffle(_rng);
    final selected = <ShopDefinition>[];
    if (lockedShopCard != null) {
      selected.add(GameCatalog.shopById(lockedShopCard!.id));
    }
    for (final s in pool) {
      if (selected.length >= 3) break;
      if (selected.every((e) => e.id != s.id)) selected.add(s);
    }
    while (selected.length < 3 && pool.isNotEmpty) {
      selected.add(pool.first);
    }

    final cards = selected.map((s) {
      final cnt1 = slots.where((sl) => sl != null && sl.definitionId == s.id && sl.level == 1).length;
      final cnt2 = slots.where((sl) => sl != null && sl.definitionId == s.id && sl.level == 2).length;
      final canMerge = cnt1 >= 2;
      final mergeTxt = canMerge
          ? (cnt2 >= 2 ? '🌟 已有 2/3 ➡️ 選擇即連升 ⭐⭐⭐' : '🌟 已有 2/3 ➡️ 選擇即合成 ⭐⭐')
          : '📦 場上同款 $cnt1/3 間';
      final rarity = s.tier >= currentTier.level
          ? (s.chainMultiplier >= 2.3 ? RarityTier.legendary : RarityTier.epic)
          : (canMerge ? RarityTier.rare : RarityTier.common);
      final price = useFreeToken ? 0.0 : shopPurchaseCost(s);
      return DraftCardItem(
        id: s.id,
        title: s.name,
        subtitle: '${s.tags.map((t) => t.label).join("・")} ｜ 基礎 ${HkFormatters.money(s.basePayout)}',
        ruleDetail: '${s.chainRuleText}\n${s.flavorText}',
        emoji: s.emoji,
        rarity: rarity,
        cost: price,
        willTriggerThreeMerge: canMerge,
        primaryTag: s.tags.first,
        mergeProgressText: mergeTxt,
        synergyPreviewText: _buildSynergyPreviewForShop(s),
        relicSynergyText: _buildRelicPreviewForShop(s),
        isLocked: lockedShopCard?.id == s.id,
      );
    }).toList();

    _cachedShopDraft = ActiveDraftState(
      kind: DraftKind.shopDraft,
      headerPrompt: useFreeToken
          ? '🎁 免費商舖招租（3 選 1）：集齊 3 間同款商舖即可自動三合一升星。'
          : '🏪 商舖招租（3 選 1）：集齊 3 間同款商舖可自動合成 ⭐⭐ 二星。',
      choices: cards,
      canSkip: true,
      canReroll: true,
      skipBonusCash: skipCash,
    );
    activeDraft = _cachedShopDraft;
    notifyListeners();
  }

  void openRelicDraft3Choice({bool isStarter = false, bool forceReroll = false}) {
    if (!isStarter && !forceReroll && pendingRelicDrafts <= 0) {
      lastToastMessage = '⚠️ 需收購競爭對手或每滿 3 季方可獲得商業奇物選取機會。';
      notifyListeners();
      return;
    }
    final unowned = kAllRelics.where((r) => !equippedRelicIds.contains(r.id)).toList();
    final pool = unowned.isNotEmpty ? unowned : List<RoguelikeRelic>.from(kAllRelics);
    pool.shuffle(_rng);
    final picks = pool.take(3).toList();

    final cards = picks.map((r) {
      return DraftCardItem(
        id: r.id,
        title: r.name,
        subtitle: '${r.rarity.label}奇物 ｜ ${r.buildHint}',
        ruleDetail: r.description,
        emoji: r.emoji,
        rarity: r.rarity,
        cost: 0,
      );
    }).toList();

    activeDraft = ActiveDraftState(
      kind: isStarter ? DraftKind.starterRelic : DraftKind.relicDraft,
      headerPrompt: isStarter
          ? '🏺 開局傳家寶（3 選 1）：請選擇一件核心商業奇物以奠定本局經營策略。'
          : '📜 商業奇物（3 選 1）（已裝備 ${equippedRelicIds.length}/$maxEquippedRelics）',
      choices: cards,
      canSkip: !isStarter,
      canReroll: true,
      skipBonusCash: isStarter ? 0 : (quarterRentQuota * 0.22).roundToDouble(),
    );
    notifyListeners();
  }

  bool openTacticalEvent3Choice() {
    if (actionPoints <= 0) return false;
    actionPoints -= 1;
    final ev = kAllTacticalEvents[_rng.nextInt(kAllTacticalEvents.length)];
    final cards = ev.options.map((opt) {
      return DraftCardItem(
        id: opt.id,
        title: opt.title,
        subtitle: '策略路線抉擇',
        ruleDetail: opt.subtitle,
        emoji: opt.emoji,
        rarity: opt.rarity,
        cost: 0,
      );
    }).toList();

    activeDraft = ActiveDraftState(
      kind: DraftKind.tacticalEvent,
      headerPrompt: '${ev.emoji}【${ev.title}】${ev.description}',
      choices: cards,
      canSkip: false,
      canReroll: false,
    );
    notifyListeners();
    return true;
  }

  void toggleLockDraftChoice(int choiceIndex) {
    final draft = activeDraft;
    if (draft == null || draft.kind != DraftKind.shopDraft) return;
    if (choiceIndex < 0 || choiceIndex >= draft.choices.length) return;
    final target = draft.choices[choiceIndex];
    if (target.isLocked) {
      target.isLocked = false;
      lockedShopCard = null;
      lastToastMessage = '🔓 已取消鎖定【${target.title}】。';
    } else {
      for (final c in draft.choices) {
        c.isLocked = false;
      }
      target.isLocked = true;
      lockedShopCard = target;
      lastToastMessage = '🔒 已鎖定【${target.title}】，刷新或進入下一季時將會保留此選項。';
    }
    notifyListeners();
  }

  void skipCurrentDraftForBonus() {
    final draft = activeDraft;
    if (draft == null || !draft.canSkip) return;
    final bonus = draft.skipBonusCash;
    if (draft.kind == DraftKind.shopDraft && pendingFreeDrafts > 0) {
      pendingFreeDrafts -= 1;
      _cachedShopDraft = null;
    } else if (draft.kind == DraftKind.relicDraft && pendingRelicDrafts > 0) {
      pendingRelicDrafts -= 1;
    }
    if (bonus > 0) {
      cash += bonus;
      lastToastMessage = '💰 已跳過本輪選取，並領取招商津貼 +${HkFormatters.money(bonus)}。';
    }
    activeDraft = null;
    notifyListeners();
  }

  bool rerollCurrentDraft({bool freeFromAd = false}) {
    final draft = activeDraft;
    if (draft == null || !draft.canReroll) return false;
    final cost = freeFromAd ? 0.0 : draftRerollCost;
    if (cash < cost) return false;
    cash -= cost;
    draftRerollCount += 1;
    if (draft.kind == DraftKind.shopDraft) {
      openShopDraft3Choice(isFree: draft.choices.first.cost == 0, forceNewRoll: true);
    } else if (draft.kind == DraftKind.relicDraft || draft.kind == DraftKind.starterRelic) {
      openRelicDraft3Choice(isStarter: draft.kind == DraftKind.starterRelic, forceReroll: true);
    }
    return true;
  }

  bool selectDraftChoice(int choiceIndex, {int? targetSlot}) {
    final draft = activeDraft;
    if (draft == null || choiceIndex < 0 || choiceIndex >= draft.choices.length) return false;
    final item = draft.choices[choiceIndex];

    if (draft.kind == DraftKind.shopDraft) {
      final isFree = item.cost <= 0;
      final ok = buyShopIntoSlot(item.id, targetSlot: targetSlot, isFreeFromDraft: isFree);
      if (!ok) return false;
      if (isFree && pendingFreeDrafts > 0) pendingFreeDrafts -= 1;
      if (lockedShopCard?.id == item.id) lockedShopCard = null;
      _cachedShopDraft = null;
      activeDraft = null;
      notifyListeners();
      return true;
    }

    if (draft.kind == DraftKind.starterRelic || draft.kind == DraftKind.relicDraft) {
      if (draft.kind == DraftKind.relicDraft && pendingRelicDrafts > 0) {
        pendingRelicDrafts -= 1;
      }
      if (!equippedRelicIds.contains(item.id)) {
        if (equippedRelicIds.length >= maxEquippedRelics) {
          final removedId = equippedRelicIds.removeAt(0);
          final removedName = kAllRelics.where((r) => r.id == removedId).firstOrNull?.name ?? '舊奇物';
          equippedRelicIds.add(item.id);
          lastToastMessage = '🏺 奇物欄位已滿，已卸下【$removedName】並裝備【${item.title}】。';
        } else {
          equippedRelicIds.add(item.id);
          lastToastMessage = '🏺 已裝備奇物【${item.title}】，商舖連鎖效果即時提升。';
        }
      }
      recalculateSynergies();
      activeDraft = null;
      notifyListeners();
      return true;
    }

    if (draft.kind == DraftKind.tacticalEvent) {
      _executeTacticalOption(item.id);
      _addMetric('opportunities_taken', 1);
      activeDraft = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  void _executeTacticalOption(String optId) {
    final mult = hasRelic('rel_ponzi_whistle') ? 1.4 : 1.0;
    switch (optId) {
      case 'tac_urban_1':
        final occupied = <int>[];
        for (int i = 0; i < slots.length; i++) {
          if (!bossDefeatedInCurrentTier && i == currentTier.goldenSlotIndex) continue;
          if (slots[i] != null) occupied.add(i);
        }
        if (occupied.isNotEmpty) {
          slots[occupied.first] = null;
        }
        for (final s in slots) {
          if (s != null) s.neighborPermBonusMult += 0.35 * mult;
        }
        recalculateSynergies();
        lastToastMessage = '💥 已配合重建方案，全街現存商舖永久獲得 +${(35 * mult).toInt()}% 產出倍率。';
        break;
      case 'tac_urban_2':
        cash *= 0.75;
        for (final s in slots) {
          if (s != null) {
            s.level += 1;
            lastToastMessage = '⭐⭐ 已完成商舖翻新，商舖升至 ${s.starBadge}。';
            break;
          }
        }
        break;
      case 'tac_urban_3':
        final gain = currentTier.targetNetWorth * 0.18 * mult;
        cash += gain;
        lastToastMessage = '💰 已領取市建局安置補償金 +${HkFormatters.money(gain)}。';
        break;
      case 'tac_fs_1':
        cash *= 0.55;
        final unowned = kAllRelics.where((r) => !equippedRelicIds.contains(r.id)).toList();
        if (unowned.isNotEmpty) {
          final pick = unowned[_rng.nextInt(unowned.length)];
          if (equippedRelicIds.length >= maxEquippedRelics) equippedRelicIds.removeAt(0);
          equippedRelicIds.add(pick.id);
          recalculateSynergies();
          lastToastMessage = '🏺 已獲得商業奇物【${pick.name}】。';
        }
        break;
      case 'tac_fs_2':
        for (int k = 0; k < 5; k++) {
          for (int i = 0; i < slots.length; i++) {
            if (!bossDefeatedInCurrentTier && i == currentTier.goldenSlotIndex) continue;
            if (slots[i] != null) {
              final def = GameCatalog.shopById(slots[i]!.definitionId);
              _triggerSlotChain(i, def.basePayout * slots[i]!.levelMultiplier, 1, <int>{});
            }
          }
        }
        bossCurrentHp = (bossCurrentHp + currentBossMaxHp * 0.15).clamp(0, currentBossMaxHp);
        lastToastMessage = '⚡ 催財佈局生效，全街商舖連續觸發 5 輪連鎖收益。';
        break;
      case 'tac_fs_3':
        bossCurrentHp *= 0.55;
        lastToastMessage = '⚔️ 化解格局生效，競爭對手實力大幅削弱。';
        break;
      case 'tac_shk_1':
        marketPhase = MarketPhase.bull;
        for (final s in stocks) {
          s.currentPrice *= 1.55;
        }
        lastToastMessage = '📈 基金聯手入市，全線股票上升 +55%。';
        break;
      case 'tac_shk_2':
        marketPhase = MarketPhase.bear;
        bossInDistress = true;
        bossDistressSecondsLeft = 30;
        lastToastMessage = '⛈️ 市場出現拋售潮，競爭對手陷入資金困難，可把握半價收購良機。';
        break;
      case 'tac_shk_3':
        pendingFreeDrafts += 2;
        lastToastMessage = '🎁 已獲得 2 次免費商舖選取機會。';
        break;
      case 'tac_chef_1':
        for (final s in slots) {
          if (s == null) continue;
          final def = GameCatalog.shopById(s.definitionId);
          if (def.tags.contains(ShopTag.food) || def.tags.contains(ShopTag.entertainment)) {
            s.neighborPermBonusMult += 0.45 * mult;
          }
        }
        lastToastMessage = '🔥 秘方授權生效，飲食及娛樂商舖永久產出 +45%。';
        break;
      case 'tac_chef_2':
        PlacedShop? best;
        for (final s in slots) {
          if (s != null && (best == null || s.level > best.level)) best = s;
        }
        if (best != null) {
          buyShopIntoSlot(best.definitionId, isFreeFromDraft: true);
        }
        break;
      case 'tac_chef_3':
        final stake = cash * 0.30;
        cash -= stake;
        activePonzi = ActivePonziState(
          title: '貴賓私募投資會',
          principal: max(500.0, stake),
          bustAtSecond: hasRelic('rel_ponzi_whistle') ? 12 : 8,
        );
        lastToastMessage = '🍷 貴賓投資會已啟動，請於主畫面適時點擊「即時撤資」。';
        break;
      case 'tac_trd_1':
      case 'tac_auc_1':
        startBearMarketAuction();
        lastToastMessage = '🔨 已啟動三折銀主盤拍賣會。';
        break;
      case 'tac_trd_2':
        final add = min(quarterRentQuota * 1.2, max(1500.0, cash * 0.55));
        cash += add;
        bankLoan += add;
        lastToastMessage = '💳 已批出緊急過橋貸款，現金與負債同步增加 +${HkFormatters.money(add)}。';
        break;
      case 'tac_cus_1':
      case 'tac_hor_1':
      case 'tac_crt_1':
        if (_rng.nextDouble() < (0.62 * mult).clamp(0.25, 0.90)) {
          final prize = quarterRentQuota * 0.75 * mult;
          cash += prize;
          lastToastMessage = '🎰 投資博弈成功，獲得額外收益 +${HkFormatters.money(prize)}。';
        } else {
          final fine = cash * 0.28;
          cash -= fine;
          lastToastMessage = '🚨 行動受阻，損失 -${HkFormatters.money(fine)}。';
        }
        break;
      case 'tac_Sub_1':
      case 'tac_sub_1':
      case 'tac_ban_1':
        rentDiscountMod = (rentDiscountMod * 0.80).clamp(0.45, 1.5);
        lastToastMessage = '🏛️ 租金減免協議生效，往後每季應繳租金永久減免 20%。';
        break;
      case 'tac_icac_1':
      case 'tac_rek_2':
        bankLoan = 0;
        pendingRelicDrafts += 1;
        lastToastMessage = '☕ 已完成債務重組協議，銀行債務全數豁免並獲得 1 次商業奇物選取機會。';
        openRelicDraft3Choice();
        break;
      case 'tac_kol_1':
      case 'tac_fil_1':
      case 'tac_tun_1':
        cash *= 0.80;
        for (final s in slots) {
          if (s != null) s.neighborPermBonusMult += 0.28 * mult;
        }
        lastToastMessage = '📣 宣傳推廣奏效，全街商舖永久獲得 +${(28 * mult).toInt()}% 產出加成。';
        break;
      case 'tac_typh_1':
      case 'tac_mah_1':
        final gain = quarterRentQuota * 0.42 * mult;
        cash += gain;
        lastToastMessage = '🌪️ 應變策略奏效，即時進帳 +${HkFormatters.money(gain)}。';
        break;
      default:
        if (optId.endsWith('_2')) {
          pendingFreeDrafts += 1;
          for (final s in slots) {
            if (s != null) {
              s.level = min(3, s.level + 1);
              break;
            }
          }
          lastToastMessage = '⭐⭐ 策略升級完成，隨機商舖升星並獲得 1 次免費商舖選取機會。';
        } else {
          final subsidy = quarterRentQuota * 0.25 * mult;
          cash += subsidy;
          actionPoints = maxActionPoints;
          lastToastMessage = '🛡️ 已領取穩健營運津貼 +${HkFormatters.money(subsidy)} 並回復全部行動力。';
        }
        break;
    }
  }

  bool injectEmergencyFamilyFund() {
    if (emergencyFundUsedThisRun || familyFund <= 0) return false;
    emergencyFundUsedThisRun = true;
    final amount = familyFund;
    familyFund = 0;
    cash += amount;
    lastToastMessage = '🏺 家族信託已緊急注資 ${HkFormatters.money(amount)} 支援營運。';
    notifyListeners();
    return true;
  }

  bool upgradeTalent(String talentId) {
    final node = GameCatalog.talentById(talentId);
    final curLvl = talentLevels[talentId] ?? 0;
    if (curLvl >= node.maxLevel) return false;
    final cost = node.basePrestigeCost * (curLvl + 1);
    if (familyPrestige < cost) return false;

    familyPrestige -= cost;
    talentLevels[talentId] = curLvl + 1;
    notifyListeners();
    return true;
  }

  bool buyLuxury(String luxuryId) {
    if (ownedLuxuries.contains(luxuryId)) return false;
    final lux = GameCatalog.luxuryById(luxuryId);
    if (cash < lux.cost) return false;

    cash -= lux.cost;
    ownedLuxuries.add(luxuryId);
    _addMetric('luxuries_owned', ownedLuxuries.length.toDouble(), setMax: true, absoluteVal: ownedLuxuries.length.toDouble());
    lastToastMessage = '🛥️ 已購入名流珍藏【${lux.name}】，跨代加成永久生效。';
    notifyListeners();
    return true;
  }

  bool claimDailyQuest(String questId) {
    final q = dailyQuests.where((d) => d.id == questId).firstOrNull;
    if (q == null || !q.isCompleted || q.claimed) return false;
    q.claimed = true;
    familyPrestige += q.prestigeReward;
    notifyListeners();
    return true;
  }

  void _addMetric(String key, double delta, {bool setMax = false, double? absoluteVal}) {
    if (setMax && absoluteVal != null) {
      metrics[key] = max(metrics[key] ?? 0.0, absoluteVal);
    } else {
      metrics[key] = (metrics[key] ?? 0.0) + delta;
    }
    for (final q in dailyQuests) {
      if (q.metricKey == key && !q.claimed) {
        q.progress = min(q.target, q.progress + delta.round());
      }
    }
  }

  void _checkAchievements() {
    for (final ach in kAllAchievements) {
      if (unlockedAchievements.contains(ach.id)) continue;
      final val = metrics[ach.metricKey] ?? 0.0;
      if (val >= ach.targetValue) {
        unlockedAchievements.add(ach.id);
        familyPrestige += ach.prestigeReward;
      }
    }
  }
  String toJsonString() {
    lastSavedTimestamp = DateTime.now();
    return jsonEncode({
      'generation': generation,
      'traitId': currentTrait.id,
      'tierLevel': currentTier.level,
      'cash': cash,
      'bankLoan': bankLoan,
      'peakNetWorthThisRun': peakNetWorthThisRun,
      'peakNetWorthAllTime': peakNetWorthAllTime,
      'slots': slots.map((s) => s?.toJson()).toList(),
      'equippedRelicIds': equippedRelicIds,
      'currentQuarter': currentQuarter,
      'quarterPhase': quarterPhase.index,
      'quarterSecondsLeft': quarterSecondsLeft,
      'pendingFreeDrafts': pendingFreeDrafts,
      'pendingRelicDrafts': pendingRelicDrafts,
      'rentDiscountMod': rentDiscountMod,
      'bossDefeated': bossDefeatedInCurrentTier,
      'bossHp': bossCurrentHp,
      'familyPrestige': familyPrestige,
      'familyFund': familyFund,
      'talentLevels': talentLevels,
      'ownedLuxuries': ownedLuxuries.toList(),
      'unlockedAchievements': unlockedAchievements.toList(),
      'discoveredShops': discoveredShops.toList(),
      'discoveredSynergies': discoveredSynergies.toList(),
      'completedChallenges': completedChallenges.toList(),
      'activeChallengeId': activeChallengeId,
      'isTycoonVip': isTycoonVip,
      'metrics': metrics,
      'tutorialStep': tutorialStep,
      'lastSavedMs': lastSavedTimestamp.millisecondsSinceEpoch,
    });
  }

  void loadFromJsonString(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    generation = (map['generation'] as num?)?.toInt() ?? 1;
    final traitId = map['traitId'] as String?;
    currentTrait = kAllHeirTraits.firstWhere((t) => t.id == traitId, orElse: () => kAllHeirTraits.first);
    currentTier = TierType.fromLevel((map['tierLevel'] as num?)?.toInt() ?? 1);
    cash = (map['cash'] as num?)?.toDouble() ?? 1500;
    bankLoan = (map['bankLoan'] as num?)?.toDouble() ?? 0;
    peakNetWorthThisRun = (map['peakNetWorthThisRun'] as num?)?.toDouble() ?? cash;
    peakNetWorthAllTime = (map['peakNetWorthAllTime'] as num?)?.toDouble() ?? cash;

    final rawSlots = map['slots'] as List<dynamic>? ?? [];
    slots = List<PlacedShop?>.generate(currentTier.slotCount, (i) {
      if (i >= rawSlots.length || rawSlots[i] == null) return null;
      return PlacedShop.fromJson(Map<String, dynamic>.from(rawSlots[i] as Map));
    });

    equippedRelicIds = List<String>.from(map['equippedRelicIds'] as List? ?? []);
    currentQuarter = (map['currentQuarter'] as num?)?.toInt() ?? 1;
    final qpIdx = (map['quarterPhase'] as num?)?.toInt() ?? 0;
    quarterPhase = QuarterPhase.values[qpIdx.clamp(0, QuarterPhase.values.length - 1)];
    quarterSecondsLeft = (map['quarterSecondsLeft'] as num?)?.toInt() ?? 18;
    pendingFreeDrafts = (map['pendingFreeDrafts'] as num?)?.toInt() ?? 1;
    pendingRelicDrafts = (map['pendingRelicDrafts'] as num?)?.toInt() ?? 0;
    rentDiscountMod = (map['rentDiscountMod'] as num?)?.toDouble() ?? 1.0;
    if (equippedRelicIds.isNotEmpty) {
      activeDraft = null;
    }

    bossDefeatedInCurrentTier = map['bossDefeated'] as bool? ?? false;
    bossCurrentHp = (map['bossHp'] as num?)?.toDouble() ?? currentBossMaxHp;
    familyPrestige = (map['familyPrestige'] as num?)?.toInt() ?? 0;
    familyFund = (map['familyFund'] as num?)?.toDouble() ?? 0;
    talentLevels = (map['talentLevels'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    ownedLuxuries = Set<String>.from(map['ownedLuxuries'] as List? ?? []);
    unlockedAchievements = Set<String>.from(map['unlockedAchievements'] as List? ?? []);
    discoveredShops = Set<String>.from(map['discoveredShops'] as List? ?? []);
    discoveredSynergies = Set<String>.from(map['discoveredSynergies'] as List? ?? []);
    completedChallenges = Set<String>.from(map['completedChallenges'] as List? ?? []);
    activeChallengeId = map['activeChallengeId'] as String?;
    isTycoonVip = map['isTycoonVip'] as bool? ?? false;
    metrics = (map['metrics'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toDouble()));
    tutorialStep = (map['tutorialStep'] as num?)?.toInt() ?? 0;
    final savedMs = (map['lastSavedMs'] as num?)?.toInt();
    if (savedMs != null) {
      lastSavedTimestamp = DateTime.fromMillisecondsSinceEpoch(savedMs);
    }
    recalculateSynergies();
    notifyListeners();
  }
}
