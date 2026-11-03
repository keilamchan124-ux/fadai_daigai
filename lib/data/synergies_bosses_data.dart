import '../models/game_models.dart';

const List<SynergyDefinition> kAllSynergies = [
  SynergyDefinition(
    id: 'syn_street_intel', name: '商業資訊網絡', styleName: '市場資訊流', emoji: '🕵️',
    description: '2間娛樂 + 1間飲食商舖：市場預測準確度提升至 95%，連鎖加成 +15%',
    requiredTags: {ShopTag.entertainment: 2, ShopTag.food: 1},
    chainMultiplierBonus: 1.15, insiderAccuracyBonus: 0.25,
  ),
  SynergyDefinition(
    id: 'syn_subdivided_king', name: '物業活化配套', styleName: '地產營運流', emoji: '🏠',
    description: '地產 + 金融 + 物流各1間：置業首期減半，連鎖加成 +20%',
    requiredTags: {ShopTag.property: 1, ShopTag.finance: 1, ShopTag.logistics: 1},
    chainMultiplierBonus: 1.20, propertyDownPaymentDiscount: 0.5,
  ),
  SynergyDefinition(
    id: 'syn_crisis_profiteer', name: '逆市資產管理', styleName: '逆市對沖流', emoji: '💀',
    description: '集齊 3 間逆市商舖：經濟調整期收益提升，拍賣與收購費用獲得 75 折優惠',
    requiredTags: {ShopTag.shadow: 3},
    bearIncomeMultiplier: 2.6, bargainDiscount: 0.25, rivalDamageMultiplier: 1.35,
  ),
  SynergyDefinition(
    id: 'syn_night_market', name: '特色美食街區', styleName: '穩健實業流', emoji: '🍢',
    description: '集齊 3 間飲食商舖：不受經濟調整期減產影響，連鎖傳遞上限 +1 步',
    requiredTags: {ShopTag.food: 3},
    extraChainSteps: 1, bearMarketImmunity: true, chainMultiplierBonus: 1.15,
  ),
  SynergyDefinition(
    id: 'syn_landlord_hegemony', name: '核心地產聯盟', styleName: '商業收租流', emoji: '🏢',
    description: '集齊 3 間地產商舖：全街連鎖加成 +28%，對競爭對手壓制力 +30%',
    requiredTags: {ShopTag.property: 3},
    chainMultiplierBonus: 1.28, rivalDamageMultiplier: 1.30,
  ),
  SynergyDefinition(
    id: 'syn_wallstreet_wolf', name: '中環金融商會', styleName: '資本運作流', emoji: '🦈',
    description: '集齊 3 間金融商舖：連鎖加成 +32%，市場預測準確度 +15%',
    requiredTags: {ShopTag.finance: 3},
    chainMultiplierBonus: 1.32, insiderAccuracyBonus: 0.15,
  ),
  SynergyDefinition(
    id: 'syn_speed_logistics', name: '高效物流網絡', styleName: '跨格傳遞流', emoji: '🚚',
    description: '集齊 3 間物流商舖：連鎖傳遞上限 +2 步，連鎖加成 +18%',
    requiredTags: {ShopTag.logistics: 3},
    extraChainSteps: 2, chainMultiplierBonus: 1.18,
  ),
  SynergyDefinition(
    id: 'syn_sleepless_entertainment', name: '不夜城娛樂區', styleName: '蓄力收益流', emoji: '🎰',
    description: '集齊 3 間娛樂商舖：連鎖加成 +30%，削減競爭對手實力 +25%',
    requiredTags: {ShopTag.entertainment: 3},
    chainMultiplierBonus: 1.30, rivalDamageMultiplier: 1.25,
  ),
  SynergyDefinition(
    id: 'syn_food_delivery', name: '餐飲速遞聯盟', styleName: '快速周轉流', emoji: '🛵',
    description: '飲食×2 + 物流×2：連鎖傳遞 +1 步，全街連鎖加成 +22%',
    requiredTags: {ShopTag.food: 2, ShopTag.logistics: 2},
    extraChainSteps: 1, chainMultiplierBonus: 1.22,
  ),
  SynergyDefinition(
    id: 'syn_gray_syndicate', name: '特種商業聯盟', styleName: '強勢收購流', emoji: '🕶️',
    description: '逆市×2 + 娛樂×2：對競爭對手壓制力 +50%，收購成本減免 20%',
    requiredTags: {ShopTag.shadow: 2, ShopTag.entertainment: 2},
    rivalDamageMultiplier: 1.50, bargainDiscount: 0.20,
  ),
  SynergyDefinition(
    id: 'syn_reit_empire', name: '綜合商場網絡', styleName: '資產增值流', emoji: '🏬',
    description: '地產×2 + 娛樂×2：連鎖加成 +26%，置業首期減免 30%',
    requiredTags: {ShopTag.property: 2, ShopTag.entertainment: 2},
    chainMultiplierBonus: 1.26, propertyDownPaymentDiscount: 0.30,
  ),
  SynergyDefinition(
    id: 'syn_loan_shark_chain', name: '信貸融資網絡', styleName: '高息利差流', emoji: '💸',
    description: '金融×2 + 逆市×2：經濟調整期收益提升，全街連鎖加成 +24%',
    requiredTags: {ShopTag.finance: 2, ShopTag.shadow: 2},
    bearIncomeMultiplier: 1.8, chainMultiplierBonus: 1.24,
  ),
  SynergyDefinition(
    id: 'syn_port_trade', name: '自由港貿易樞紐', styleName: '國際航運流', emoji: '⚓',
    description: '物流×2 + 金融×2：連鎖傳遞 +1 步，全街連鎖加成 +28%',
    requiredTags: {ShopTag.logistics: 2, ShopTag.finance: 2},
    extraChainSteps: 1, chainMultiplierBonus: 1.28,
  ),
  SynergyDefinition(
    id: 'syn_grassroots_king', name: '民生商業網絡', styleName: '抗跌長青流', emoji: '🛒',
    description: '飲食×2 + 地產×2：不受經濟調整期減產影響，對競爭對手壓制力 +35%',
    requiredTags: {ShopTag.food: 2, ShopTag.property: 2},
    bearMarketImmunity: true, rivalDamageMultiplier: 1.35,
  ),
  SynergyDefinition(
    id: 'syn_capital_tycoon', name: '地產金融集團', styleName: '資本整合流', emoji: '🏦',
    description: '地產×2 + 金融×2：全街連鎖加成 +38%，市場預測準確度 +10%',
    requiredTags: {ShopTag.property: 2, ShopTag.finance: 2},
    chainMultiplierBonus: 1.38, insiderAccuracyBonus: 0.10,
  ),
  SynergyDefinition(
    id: 'syn_all_industry_king', name: '多元綜合企業', styleName: '全行業協同流', emoji: '👑',
    description: '同時擁有飲食、地產、金融、物流、娛樂、逆市各 1 間：連鎖 +2 步，加成 +65%',
    requiredTags: {
      ShopTag.food: 1, ShopTag.property: 1, ShopTag.finance: 1,
      ShopTag.logistics: 1, ShopTag.entertainment: 1, ShopTag.shadow: 1,
    },
    extraChainSteps: 2, chainMultiplierBonus: 1.65, bearMarketImmunity: true,
  ),
];
const List<RivalBossDefinition> kAllBosses = [
  RivalBossDefinition(
    id: 'boss_lan', tier: 1, name: '蘭姐', title: '資深業主代表', emoji: '👩🏻‍🦱',
    assetPath: 'assets/images/boss_lan.png',
    maxHp: 350, stealRate: 0.28, takeoverBaseCost: 35000,
    tauntQuotes: [
      '「年輕人，這條街的商舖大多由我管理，下季將會調整租金。」',
      '「經營小食店想擴充規模？先累積足夠資金吧。」',
      '「鄰近商舖的熟客，不少已經轉來光顧我的店舖了。」',
    ],
    panicQuotes: ['「糟了，今期按揭周轉出現問題，資金一時難以調配！」'],
    defeatedQuote: '「佩服！黃金轉角位交由你經營，我轉往其他區發展。」',
  ),
  RivalBossDefinition(
    id: 'boss_ray', tier: 2, name: 'Ray 少', title: '家族集團少東', emoji: '🕶️',
    assetPath: 'assets/images/boss_ray.png',
    maxHp: 1800, stealRate: 0.30, takeoverBaseCost: 650000,
    tauntQuotes: [
      '「我們家族資金充裕，物業競投隨時可以奉陪到底。」',
      '「單靠傳統小店很難與大型連鎖品牌競爭。」',
      '「今晚本區舉行大型推廣活動，將會吸引大量人流。」',
    ],
    panicQuotes: ['「為甚麼家族信託暫停了我的授信額度？銀行正在催繳保證金！」'],
    defeatedQuote: '「這個地段暫時讓給你經營，我們日後在更高層次再較量。」',
  ),
  RivalBossDefinition(
    id: 'boss_chan', tier: 3, name: '陳主席', title: '證券財團主理人', emoji: '🦈',
    assetPath: 'assets/images/boss_chan.png',
    maxHp: 12000, stealRate: 0.32, takeoverBaseCost: 28000000,
    tauntQuotes: [
      '「市場波動瞬息萬變，缺乏耐性的投資者很難全身而退。」',
      '「配股與資產重組是資本市場常見的運作方式。」',
      '「你的實業現金流，能否應付大市的劇烈波動？」',
    ],
    panicQuotes: ['「市場走勢完全超出預期，我們的持倉正面臨重大壓力！」'],
    defeatedQuote: '「你的資金調配確實高明，這個核心席位就由你接手吧。」',
  ),
  RivalBossDefinition(
    id: 'boss_sniper', tier: 4, name: 'Victor', title: '外資量化基金代表', emoji: '🎯',
    assetPath: 'assets/images/boss_sniper.png',
    maxHp: 220000, stealRate: 0.34, takeoverBaseCost: 3500000000,
    tauntQuotes: [
      '「我們的量化交易模型已全面分析你的資金結構。」',
      '「跨市場套利與匯率對沖，考驗的是整體的抗風險能力。」',
      '「我們已準備好提出全面收購方案。」',
    ],
    panicQuotes: ['「市場流動性突然收緊，我們的槓桿部位需要緊急平倉！」'],
    defeatedQuote: '「你的實力令人欽佩，亞洲區的業務就交由你主導了。」',
  ),
  RivalBossDefinition(
    id: 'boss_syndicate', tier: 5, name: '龍先生', title: '跨國財團掌舵人', emoji: '🐉',
    assetPath: 'assets/images/boss_syndicate.png',
    maxHp: 6000000, stealRate: 0.35, takeoverBaseCost: 220000000000,
    tauntQuotes: [
      '「這座城市的商業版圖，是由無數企業家世代累積而成。」',
      '「大型基建與長遠發展項目，需要極為龐大的資本支持。」',
      '「唯有經歷多次經濟週期考驗的企業，才能屹立不倒。」',
    ],
    panicQuotes: ['「想不到你的產業鏈如此穩健，連集團基金也難以抗衡！」'],
    defeatedQuote: '「後生可畏，這座城市的商界領袖之位實至名歸。」',
  ),
];

List<StockState> createInitialStocks() => [
  StockState(id: 'stk_fish', code: '0088', name: '香江餐飲控股', emoji: '🍢', sector: ShopTag.food, basePrice: 12.0, volatility: 0.14),
  StockState(id: 'stk_prop', code: '0016', name: '都會地產發展', emoji: '🏢', sector: ShopTag.property, basePrice: 45.0, volatility: 0.18),
  StockState(id: 'stk_shark', code: '0888', name: '環球金融科技', emoji: '💸', sector: ShopTag.finance, basePrice: 8.5, volatility: 0.28),
  StockState(id: 'stk_port', code: '0293', name: '維港航運物流', emoji: '⚓', sector: ShopTag.logistics, basePrice: 22.0, volatility: 0.16),
  StockState(id: 'stk_macau', code: '1928', name: '星光綜合娛樂', emoji: '🎰', sector: ShopTag.entertainment, basePrice: 32.0, volatility: 0.22),
  StockState(id: 'stk_pawn', code: '0666', name: '逆市資產管理', emoji: '🦇', sector: ShopTag.shadow, basePrice: 15.0, volatility: 0.24),
  StockState(id: 'stk_reit', code: '0823', name: '領匯商業房託', emoji: '🛒', sector: ShopTag.property, basePrice: 60.0, volatility: 0.11),
  StockState(id: 'stk_island', code: '9999', name: '長遠基建發展', emoji: '🏝️', sector: ShopTag.finance, basePrice: 120.0, volatility: 0.25),
];

List<PropertyState> createInitialProperties() => [
  PropertyState(id: 'prop_stall', name: '廟街商業攤位', emoji: '⛺', minTier: 1, basePrice: 12000, baseRentPerSec: 180),
  PropertyState(id: 'prop_tonglau', name: '深水埗商住唐樓', emoji: '🏚️', minTier: 2, basePrice: 180000, baseRentPerSec: 2600),
  PropertyState(id: 'prop_street_shop', name: '旺角核心區地舖', emoji: '🏪', minTier: 2, basePrice: 950000, baseRentPerSec: 13500),
  PropertyState(id: 'prop_office', name: '中環甲級寫字樓全層', emoji: '🏢', minTier: 3, basePrice: 22000000, baseRentPerSec: 290000),
  PropertyState(id: 'prop_mall', name: '銅鑼灣大型購物商場', emoji: '🏬', minTier: 4, basePrice: 680000000, baseRentPerSec: 8500000),
  PropertyState(id: 'prop_island', name: '海濱商業綜合發展區', emoji: '🏝️', minTier: 5, basePrice: 45000000000, baseRentPerSec: 580000000),
];
