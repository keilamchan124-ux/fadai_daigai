import '../models/game_models.dart';

const List<LuxuryItem> kAllLuxuries = [
  // 名錶與古董 (6)
  LuxuryItem(id: 'lux_watch_rolex', name: '金勞滿天星腕錶', category: '名錶珠寶', emoji: '⌚', cost: 85000, buffDescription: '全遊戲永久收入 +4%', globalIncomeBonus: 0.04),
  LuxuryItem(id: 'lux_watch_jade', name: '帝王綠翡翠玉扳指', category: '名錶珠寶', emoji: '💍', cost: 350000, buffDescription: '傳承家族聲望 +5%', prestigeGainBonus: 0.05),
  LuxuryItem(id: 'lux_watch_gold', name: '百達翡麗陀飛輪', category: '名錶珠寶', emoji: '🕰️', cost: 1800000, buffDescription: '全遊戲永久收入 +6%', globalIncomeBonus: 0.06),
  LuxuryItem(id: 'lux_art_vase', name: '乾隆御製琺瑯彩瓶', category: '名錶珠寶', emoji: '🏺', cost: 8500000, buffDescription: '開局起步本金 +15%', startingCashBonus: 0.15),
  LuxuryItem(id: 'lux_art_diamond', name: '維港之星粉紅巨鑽', category: '名錶珠寶', emoji: '💎', cost: 42000000, buffDescription: '全遊戲永久收入 +8%', globalIncomeBonus: 0.08),
  LuxuryItem(id: 'lux_art_dragon', name: '純金九龍鎮宅寶印', category: '名錶珠寶', emoji: '🐉', cost: 180000000, buffDescription: '傳承家族聲望 +10%', prestigeGainBonus: 0.10),
  // 超跑與座駕 (6)
  LuxuryItem(id: 'lux_car_alphard', name: '中港兩地牌保母車', category: '名車座駕', emoji: '🚐', cost: 950000, buffDescription: '開局起步本金 +10%', startingCashBonus: 0.10),
  LuxuryItem(id: 'lux_car_ferrari', name: '烈馬赤紅超跑 F8', category: '名車座駕', emoji: '🏎️', cost: 4800000, buffDescription: '全遊戲永久收入 +6%', globalIncomeBonus: 0.06),
  LuxuryItem(id: 'lux_car_phantom', name: '勞斯萊斯幻影加長版', category: '名車座駕', emoji: '🚘', cost: 15000000, buffDescription: '傳承家族聲望 +8%', prestigeGainBonus: 0.08),
  LuxuryItem(id: 'lux_car_plate1', name: '「1號」無字頭天價車牌', category: '名車座駕', emoji: '🪪', cost: 65000000, buffDescription: '全遊戲永久收入 +9%', globalIncomeBonus: 0.09),
  LuxuryItem(id: 'lux_car_bugatti', name: '限量黑金超跑王', category: '名車座駕', emoji: '⚡', cost: 220000000, buffDescription: '開局起步本金 +25%', startingCashBonus: 0.25),
  LuxuryItem(id: 'lux_car_fleet', name: '半島酒店勞斯萊斯車隊', category: '名車座駕', emoji: '🎩', cost: 950000000, buffDescription: '全遊戲永久收入 +12%', globalIncomeBonus: 0.12),
  // 豪宅與遊艇 (6)
  LuxuryItem(id: 'lux_mansion_repulse', name: '淺水灣海景複式豪宅', category: '豪宅遊艇', emoji: '🏖️', cost: 85000000, buffDescription: '全遊戲永久收入 +8%', globalIncomeBonus: 0.08),
  LuxuryItem(id: 'lux_yacht_victoria', name: '維港88呎超級遊艇', category: '豪宅遊艇', emoji: '🛥️', cost: 260000000, buffDescription: '傳承家族聲望 +10%', prestigeGainBonus: 0.10),
  LuxuryItem(id: 'lux_mansion_peak', name: '太平山頂白加道大宅', category: '豪宅遊艇', emoji: '🏰', cost: 1200000000, buffDescription: '全遊戲永久收入 +12%', globalIncomeBonus: 0.12),
  LuxuryItem(id: 'lux_jet_gulf', name: '灣流 G800 環球私人飛機', category: '豪宅遊艇', emoji: '🛩️', cost: 3800000000, buffDescription: '開局起步本金 +35%', startingCashBonus: 0.35),
  LuxuryItem(id: 'lux_horse_champion', name: '沙田馬王「發達精英」', category: '豪宅遊艇', emoji: '🐎', cost: 12000000000, buffDescription: '全遊戲永久收入 +15%', globalIncomeBonus: 0.15),
  LuxuryItem(id: 'lux_club_golf', name: '深水灣私人高爾夫球會', category: '豪宅遊艇', emoji: '⛳', cost: 45000000000, buffDescription: '傳承家族聲望 +15%', prestigeGainBonus: 0.15),
  // 傳奇地標與私人島 (6)
  LuxuryItem(id: 'lux_vineyard_fr', name: '波爾多百年列級酒莊', category: '傳奇霸業', emoji: '🍷', cost: 110000000000, buffDescription: '全遊戲永久收入 +15%', globalIncomeBonus: 0.15),
  LuxuryItem(id: 'lux_football_uk', name: '英超豪門冠軍球會', category: '傳奇霸業', emoji: '⚽', cost: 260000000000, buffDescription: '傳承家族聲望 +20%', prestigeGainBonus: 0.20),
  LuxuryItem(id: 'lux_cruise_fleet', name: '環球皇家郵輪艦隊', category: '傳奇霸業', emoji: '🚢', cost: 480000000000, buffDescription: '全遊戲永久收入 +18%', globalIncomeBonus: 0.18),
  LuxuryItem(id: 'lux_tower_landmark', name: '維港第一高摩天冠名權', category: '傳奇霸業', emoji: '🏙️', cost: 720000000000, buffDescription: '開局起步本金 +50%', startingCashBonus: 0.50),
  LuxuryItem(id: 'lux_island_paradise', name: '南太平洋免稅私人王國島', category: '傳奇霸業', emoji: '🏝️', cost: 900000000000, buffDescription: '全遊戲永久收入 +25%', globalIncomeBonus: 0.25),
  LuxuryItem(id: 'lux_crown_tycoon', name: '香江萬億造王者金冕', category: '傳奇霸業', emoji: '👑', cost: 1500000000000, buffDescription: '全收入 +35% 及聲望 +30%', globalIncomeBonus: 0.35, prestigeGainBonus: 0.30),
];
List<AchievementDefinition> _build100Achievements() {
  final list = <AchievementDefinition>[
    // 核心與隱藏成就 (20)
    const AchievementDefinition(id: 'ach_first_chain', title: '初次連鎖運作', honorTitle: '街區創業新秀', emoji: '🍢', description: '完成人生第一次商舖連鎖反應', metricKey: 'chains_triggered', targetValue: 1, prestigeReward: 5),
    const AchievementDefinition(id: 'ach_beat_lan', title: '收購街頭轉角位', honorTitle: '廟街商戶代表', emoji: '👩🏻‍🦱', description: '成功收購蘭姐佔據的黃金轉角位', metricKey: 'bosses_defeated', targetValue: 1, prestigeReward: 15),
    const AchievementDefinition(id: 'ach_beat_ray', title: '擊敗家族少東', honorTitle: '社區商業領袖', emoji: '🕶️', description: '累計收購 2 個競爭對手的核心舖位', metricKey: 'bosses_defeated', targetValue: 2, prestigeReward: 25),
    const AchievementDefinition(id: 'ach_beat_chan', title: '智勝證券莊家', honorTitle: '股壇資深投資者', emoji: '🦈', description: '累計收購 3 個競爭對手的核心舖位', metricKey: 'bosses_defeated', targetValue: 3, prestigeReward: 40),
    const AchievementDefinition(id: 'ach_beat_sniper', title: '穩守金融防線', honorTitle: '維港金融中堅', emoji: '🎯', description: '累計收購 4 個競爭對手的核心舖位', metricKey: 'bosses_defeated', targetValue: 4, prestigeReward: 60),
    const AchievementDefinition(id: 'ach_beat_syndicate', title: '問鼎跨國財團', honorTitle: '香江商業巨擘', emoji: '🐉', description: '累計收購 5 個競爭對手的核心舖位', metricKey: 'bosses_defeated', targetValue: 5, prestigeReward: 100),
    const AchievementDefinition(id: 'ach_secret_bankrupt1', title: '初次結業重組', honorTitle: '逆境重整者', emoji: '💸', description: '【隱藏】經歷人生第一次結業清盤', metricKey: 'bankruptcies', targetValue: 1, prestigeReward: 10, isSecret: true),
    const AchievementDefinition(id: 'ach_secret_bankrupt3', title: '百折不撓', honorTitle: '堅毅創業者', emoji: '🪳', description: '【隱藏】累計結業 3 次仍能東山再起', metricKey: 'bankruptcies', targetValue: 3, prestigeReward: 30, isSecret: true),
    const AchievementDefinition(id: 'ach_secret_ray_loss', title: '競投失利十次', honorTitle: '拍賣場常客', emoji: '🏳️', description: '【隱藏】在物業拍賣會累計失手 10 次', metricKey: 'auctions_lost', targetValue: 10, prestigeReward: 20, isSecret: true),
    const AchievementDefinition(id: 'ach_secret_ponzi_escape', title: '及時止賺退場', honorTitle: '風險控制專家', emoji: '🏃', description: '【隱藏】在短期展銷項目結束前成功結算退場', metricKey: 'ponzi_escaped', targetValue: 1, prestigeReward: 20, isSecret: true),
    const AchievementDefinition(id: 'ach_secret_ponzi_5', title: '五次精準退場', honorTitle: '短線獲利高手', emoji: '🍷', description: '【隱藏】累計在短期項目中成功結算 5 次', metricKey: 'ponzi_escaped', targetValue: 5, prestigeReward: 45, isSecret: true),
    const AchievementDefinition(id: 'ach_secret_ponzi_bust', title: '投資失利教訓', honorTitle: '謹慎投資人', emoji: '😭', description: '【隱藏】在短期項目中未能及時退場而損失本金', metricKey: 'ponzi_busted', targetValue: 1, prestigeReward: 10, isSecret: true),
    const AchievementDefinition(id: 'ach_chain_5', title: '五步連鎖傳遞', honorTitle: '連鎖規劃師', emoji: '⚡', description: '單次觸發長度達 5 步以上的連鎖反應', metricKey: 'max_chain_depth', targetValue: 5, prestigeReward: 15),
    const AchievementDefinition(id: 'ach_chain_8', title: '八步高效連鎖', honorTitle: '街區規劃專家', emoji: '💥', description: '單次觸發長度達 8 步以上的連鎖反應', metricKey: 'max_chain_depth', targetValue: 8, prestigeReward: 35),
    const AchievementDefinition(id: 'ach_chain_12', title: '十二步長鏈傳遞', honorTitle: '商業佈局大師', emoji: '🌩️', description: '單次觸發長度達 12 步以上的連鎖反應', metricKey: 'max_chain_depth', targetValue: 12, prestigeReward: 70),
    const AchievementDefinition(id: 'ach_synergy_1', title: '達成首個行業羈絆', honorTitle: '街區佈局師', emoji: '🧩', description: '同時激活至少 1 個行業協同羈絆', metricKey: 'max_active_synergies', targetValue: 1, prestigeReward: 10),
    const AchievementDefinition(id: 'ach_synergy_3', title: '三組行業協同', honorTitle: '百業聯動專家', emoji: '🎭', description: '同時激活至少 3 個行業協同羈絆', metricKey: 'max_active_synergies', targetValue: 3, prestigeReward: 30),
    const AchievementDefinition(id: 'ach_synergy_5', title: '五組行業協同', honorTitle: '多元產業領袖', emoji: '🌟', description: '同時激活至少 5 個行業協同羈絆', metricKey: 'max_active_synergies', targetValue: 5, prestigeReward: 60),
    const AchievementDefinition(id: 'ach_short_profit', title: '逆市對沖獲利', honorTitle: '對沖交易員', emoji: '📉', description: '透過沽空股票累計獲利 1 次', metricKey: 'short_wins', targetValue: 1, prestigeReward: 15),
    const AchievementDefinition(id: 'ach_market_maker', title: '運用五次層級技能', honorTitle: '市場策略家', emoji: '📣', description: '使用層級專屬技能 5 次', metricKey: 'tier_skills_used', targetValue: 5, prestigeReward: 25),
  ];

  // 身家里程碑 (20)
  final wealthTargets = <double>[
    1e4, 5e4, 1e5, 5e5, 1e6, 2.5e6, 1e7, 5e7, 1e8, 5e8,
    1e9, 5e9, 1e10, 5e10, 1e11, 2.5e11, 5e11, 7.5e11, 1e12, 5e12
  ];
  final wealthTitles = [
    '萬元創業者', '街區商戶', '十萬資產店主', '資深店東', '百萬資產家', '社區業主', '千萬企業家', '資深實業家', '億萬企業家', '五億投資人',
    '十億企業家', '五十億集團代表', '百億財團主席', '五百億企業領袖', '千億商業領袖', '亞太商界代表', '五千億集團主席', '跨國財團主席', '萬億商業巨擘', '傳奇商界領袖'
  ];
  for (var i = 0; i < 20; i++) {
    list.add(AchievementDefinition(
      id: 'ach_wealth_${i + 1}',
      title: '資產突破：${wealthTitles[i]}',
      honorTitle: wealthTitles[i],
      emoji: i >= 15 ? '👑' : (i >= 8 ? '💎' : '💰'),
      description: '最高總資產達到指定里程碑',
      metricKey: 'peak_net_worth',
      targetValue: wealthTargets[i],
      prestigeReward: (i + 1) * 5,
    ));
  }

  // 連鎖觸發次數 (15)
  final chainCounts = [10, 30, 60, 100, 200, 350, 500, 750, 1000, 1500, 2500, 4000, 6000, 8000, 10000];
  for (var i = 0; i < 15; i++) {
    list.add(AchievementDefinition(
      id: 'ach_chain_cnt_${i + 1}',
      title: '連鎖營運 Lv.${i + 1}',
      honorTitle: '資深營運家 Lv.${i + 1}',
      emoji: '⚡',
      description: '累計觸發 ${chainCounts[i]} 次商舖連鎖反應',
      metricKey: 'chains_triggered',
      targetValue: chainCounts[i].toDouble(),
      prestigeReward: 5 + i * 3,
    ));
  }

  // 拍賣得標與商業決策 (15)
  final auctionCounts = [1, 3, 5, 10, 15, 25, 40, 60];
  for (var i = 0; i < auctionCounts.length; i++) {
    list.add(AchievementDefinition(
      id: 'ach_auc_win_${i + 1}',
      title: '物業競投專家 Lv.${i + 1}',
      honorTitle: '特價物業買家 Lv.${i + 1}',
      emoji: '🔨',
      description: '在特價物業拍賣會成功投得物業 ${auctionCounts[i]} 次',
      metricKey: 'auctions_won',
      targetValue: auctionCounts[i].toDouble(),
      prestigeReward: 8 + i * 4,
    ));
  }
  final oppCounts = [3, 10, 25, 50, 100, 200, 350];
  for (var i = 0; i < oppCounts.length; i++) {
    list.add(AchievementDefinition(
      id: 'ach_opp_play_${i + 1}',
      title: '商業決策專家 Lv.${i + 1}',
      honorTitle: '策略決策者 Lv.${i + 1}',
      emoji: '🎲',
      description: '累計完成 ${oppCounts[i]} 次商業決策事件',
      metricKey: 'opportunities_taken',
      targetValue: oppCounts[i].toDouble(),
      prestigeReward: 6 + i * 4,
    ));
  }

  // 股市交易與物業收租 (15)
  final stockTradeCounts = [5, 15, 30, 60, 100, 200, 350, 500];
  for (var i = 0; i < stockTradeCounts.length; i++) {
    list.add(AchievementDefinition(
      id: 'ach_stk_trd_${i + 1}',
      title: '股壇老手 Lv.${i + 1}',
      honorTitle: '金魚缸操盤手 Lv.${i + 1}',
      emoji: '📈',
      description: '累計進行 ${stockTradeCounts[i]} 次股票買賣或孖展操作',
      metricKey: 'stock_trades',
      targetValue: stockTradeCounts[i].toDouble(),
      prestigeReward: 6 + i * 3,
    ));
  }
  final propCounts = [1, 3, 6, 10, 20, 35, 50];
  for (var i = 0; i < propCounts.length; i++) {
    list.add(AchievementDefinition(
      id: 'ach_prop_own_${i + 1}',
      title: '買樓收租王 Lv.${i + 1}',
      honorTitle: '全港大業主 Lv.${i + 1}',
      emoji: '🏢',
      description: '累計買入或改建 ${propCounts[i]} 項收租物業',
      metricKey: 'properties_bought',
      targetValue: propCounts[i].toDouble(),
      prestigeReward: 8 + i * 4,
    ));
  }

  // 家族傳承與奢侈品收藏 (15)
  final genCounts = [2, 3, 5, 8, 12, 20, 30, 50];
  for (var i = 0; i < genCounts.length; i++) {
    list.add(AchievementDefinition(
      id: 'ach_gen_${i + 1}',
      title: '開枝散葉第 ${genCounts[i]} 代',
      honorTitle: '第${genCounts[i]}代豪門掌舵人',
      emoji: '🌳',
      description: '家族傳承達到第 ${genCounts[i]} 代繼承人',
      metricKey: 'generation',
      targetValue: genCounts[i].toDouble(),
      prestigeReward: 10 + i * 5,
    ));
  }
  final luxCounts = [1, 3, 6, 10, 15, 20, 24];
  for (var i = 0; i < luxCounts.length; i++) {
    list.add(AchievementDefinition(
      id: 'ach_lux_${i + 1}',
      title: '富貴收藏家 Lv.${i + 1}',
      honorTitle: '頂級奢華鑑賞家 Lv.${i + 1}',
      emoji: '🛥️',
      description: '解鎖並收藏 ${luxCounts[i]} 件跨代奢侈品',
      metricKey: 'luxuries_owned',
      targetValue: luxCounts[i].toDouble(),
      prestigeReward: 12 + i * 6,
    ));
  }

  return list;
}

final List<AchievementDefinition> kAllAchievements = _build100Achievements();
