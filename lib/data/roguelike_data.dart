import '../models/game_models.dart';

const List<RoguelikeRelic> kAllRelics = [
  // === 普通 & 罕有奇物 (12) ===
  RoguelikeRelic(
    id: 'rel_wok', name: '百年鑄鐵鑊', emoji: '🍳', rarity: RarityTier.rare,
    description: '【飲食】商舖每次觸發連鎖，該店基礎收益永久提升 6%。',
    buildHint: '核心：飲食持續成長流',
  ),
  RoguelikeRelic(
    id: 'rel_dice', name: '精緻象牙骰盅', emoji: '🎲', rarity: RarityTier.epic,
    description: '所有「蓄力三次觸發」的商舖，只需蓄力 2 次即可觸發，且額外加成提升 45%。',
    buildHint: '核心：蓄力商舖速發流',
  ),
  RoguelikeRelic(
    id: 'rel_guandi', name: '純金關帝擺件', emoji: '⚔️', rarity: RarityTier.legendary,
    description: '所有「終點結算」商舖不會中斷連鎖，結算後會向左右方向繼續傳遞一次。',
    buildHint: '核心：終點商舖雙重結算流',
  ),
  RoguelikeRelic(
    id: 'rel_blackcard', name: '尊尚黑金卡', emoji: '💳', rarity: RarityTier.epic,
    description: '持有銀行貸款或股票孖展期間，全街所有連鎖加成額外提升 40%，並減免一半貸款利息。',
    buildHint: '核心：槓桿融資營運流',
  ),
  RoguelikeRelic(
    id: 'rel_bulldozer', name: '舊區重建批文', emoji: '🚜', rarity: RarityTier.rare,
    description: '每當出售商舖或完成「三合一升星」，相鄰格位永久獲得 35% 收益加成。',
    buildHint: '核心：換位合成強化流',
  ),
  RoguelikeRelic(
    id: 'rel_neon_sign', name: '懷舊霓虹招牌', emoji: '🪧', rarity: RarityTier.common,
    description: '街區內每有一種不同行業標籤，所有連鎖收益加成提升 16%。',
    buildHint: '核心：多元行業混搭流',
  ),
  RoguelikeRelic(
    id: 'rel_red_taxi', name: '特快計程車牌照', emoji: '🚕', rarity: RarityTier.rare,
    description: '所有「定時運作」商舖的冷卻時間減少 1 秒（最低為 2 秒）。',
    buildHint: '核心：高頻率啟動流',
  ),
  RoguelikeRelic(
    id: 'rel_insider_phone', name: '經典手提電話', emoji: '📟', rarity: RarityTier.rare,
    description: '股票買賣與沽空獲利提升，且每次平倉均可帶動全街連鎖運作一次。',
    buildHint: '核心：證券投資聯動流',
  ),
  RoguelikeRelic(
    id: 'rel_land_deed', name: '早期永久地契', emoji: '📜', rarity: RarityTier.epic,
    description: '每持有一項收租物業，全街【地產】與【金融】商舖連鎖加成永久提升 18%。',
    buildHint: '核心：物業收租聯動流',
  ),
  RoguelikeRelic(
    id: 'rel_vulture_badge', name: '資產重組顧問章', emoji: '🦅', rarity: RarityTier.epic,
    description: '經濟調整（熊市）期間，全街商舖不受減產影響，並額外獲得 1.65 倍逆市收益。',
    buildHint: '核心：逆市防守經營流',
  ),
  RoguelikeRelic(
    id: 'rel_merge_crown', name: '精巧魯班鎖', emoji: '👑', rarity: RarityTier.legendary,
    description: '所有二星及三星商舖的收益加成額外提升 55%，且招租洗牌費用減半。',
    buildHint: '核心：高星級合成流',
  ),
  RoguelikeRelic(
    id: 'rel_bagua_mirror', name: '古銅風水羅盤', emoji: '☯️', rarity: RarityTier.legendary,
    description: '每行首尾格位視為相鄰，可跨邊界循環傳遞，且單次連鎖上限步數增加 3 步。',
    buildHint: '核心：長距離循環連鎖流',
  ),
  // === 進階策略奇物 (12) ===
  RoguelikeRelic(
    id: 'rel_tea_thermos', name: '不鏽鋼保溫茶壺', emoji: '🫖', rarity: RarityTier.common,
    description: '每次「接力聯動」成功傳遞，額外獲得手頭現金 2% 的回贈（設有季度上限）。',
    buildHint: '通用：長鏈現金回贈',
  ),
  RoguelikeRelic(
    id: 'rel_abacus_gold', name: '純金算盤', emoji: '🧮', rarity: RarityTier.common,
    description: '商舖招租成本減免 25%，出售商舖時退還 100% 原價。',
    buildHint: '通用：無損靈活換陣',
  ),
  RoguelikeRelic(
    id: 'rel_brass_knuckle', name: '商業競爭錦囊', emoji: '🥊', rarity: RarityTier.common,
    description: '對競爭對手的市場壓力提升為 2 倍，並按比例轉化為你的營業收入。',
    buildHint: '快攻：加速收購對手',
  ),
  RoguelikeRelic(
    id: 'rel_containers', name: '葵涌貨櫃調度令', emoji: '🚢', rarity: RarityTier.rare,
    description: '所有【物流】商舖傳遞時，會額外跳過一格同時觸發兩個目標。',
    buildHint: '核心：物流雙重傳遞流',
  ),
  RoguelikeRelic(
    id: 'rel_vip_chip', name: '貴賓會紀念籌碼', emoji: '🪙', rarity: RarityTier.epic,
    description: '每次連鎖有 30% 機率獲得 1.75 倍收益；若場上有【娛樂】商舖，機率提升至 55%。',
    buildHint: '核心：娛樂額外收益流',
  ),
  RoguelikeRelic(
    id: 'rel_short_bible', name: '對沖基金分析筆記', emoji: '📉', rarity: RarityTier.rare,
    description: '沽空股票獲利提升，且市場轉入經濟調整期時可獲額外優勢。',
    buildHint: '核心：逆市對沖流',
  ),
  RoguelikeRelic(
    id: 'rel_empty_slot_aura', name: '空間規劃圖則', emoji: '🌀', rarity: RarityTier.epic,
    description: '街區每保留 1 個空置舖位，全場已營業商舖連鎖加成額外提升 35%。',
    buildHint: '核心：精兵高星流',
  ),
  RoguelikeRelic(
    id: 'rel_combo_battery', name: '高容量蓄電裝置', emoji: '🔋', rarity: RarityTier.rare,
    description: '單次連鎖每多傳遞 1 步，後續每一格的收益加成額外提升 25%。',
    buildHint: '核心：長距離連鎖流',
  ),
  RoguelikeRelic(
    id: 'rel_corner_throne', name: '轉角地王契約', emoji: '🪑', rarity: RarityTier.legendary,
    description: '黃金轉角位的收益加成進一步提升；若競爭對手仍佔據該位，其每季加速流失份額。',
    buildHint: '核心：核心位置強化流',
  ),
  RoguelikeRelic(
    id: 'rel_ponzi_whistle', name: '合規風險顧問報告', emoji: '📯', rarity: RarityTier.common,
    description: '所有商業決策與短期投機項目回報提升 40%，並延長安全退場時間。',
    buildHint: '通用：決策回報提升',
  ),
  RoguelikeRelic(
    id: 'rel_time_watch', name: '精密陀飛輪懷錶', emoji: '⏱️', rarity: RarityTier.epic,
    description: '快進功能的冷卻時間減半，提升資金周轉效率。',
    buildHint: '核心：高效營運流',
  ),
  RoguelikeRelic(
    id: 'rel_tycoon_seal', name: '總商會榮譽印章', emoji: '🐉', rarity: RarityTier.legendary,
    description: '所有行業協同羈絆的需求數量減 1（最少需 1 間即可達成條件）。',
    buildHint: '核心：多元羈絆組合流',
  ),
];

const List<TacticalThreeChoiceEvent> kAllTacticalEvents = [
  TacticalThreeChoiceEvent(
    id: 'tac_urban_renewal',
    title: '市建局舊區重建收購',
    emoji: '🏗️',
    description: '市區重建局提出收購街區內其中一個舖位，請選擇你的應對方案：',
    options: [
      TacticalOption(
        id: 'tac_urban_1', emoji: '💥', rarity: RarityTier.epic,
        title: '配合重建：騰出 1 間商舖，全街永久 +35% 收益',
        subtitle: '移除 1 間現有商舖，街區內其餘商舖永久獲得 35% 收益加成。',
      ),
      TacticalOption(
        id: 'tac_urban_2', emoji: '⭐⭐', rarity: RarityTier.rare,
        title: '申請原址保留：首間商舖提升 1 星',
        subtitle: '支付 25% 現有現金作為改建費用，令街區首間商舖直接提升一個星級。',
      ),
      TacticalOption(
        id: 'tac_urban_3', emoji: '💰', rarity: RarityTier.common,
        title: '接受補償方案：領取現金津貼',
        subtitle: '穩健領取一筆安置補償金，即時補充營運資金。',
      ),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_fengshui_master',
    title: '商業顧問佈局建議',
    emoji: '☯️',
    description: '資深商業風水顧問到訪街區，為你的商舖格局提供三項改善建議：',
    options: [
      TacticalOption(
        id: 'tac_fs_1', emoji: '🏺', rarity: RarityTier.legendary,
        title: '重金禮聘顧問：獲取 1 件【商業奇物】',
        subtitle: '支付 45% 現有現金，隨機獲得 1 件未擁有的商業奇物。',
      ),
      TacticalOption(
        id: 'tac_fs_2', emoji: '⚡', rarity: RarityTier.rare,
        title: '舉辦促銷推廣：即時觸發 5 輪全街連鎖',
        subtitle: '立即觸發全街所有商舖運作 5 次，但競爭對手同時恢復 15% 實力。',
      ),
      TacticalOption(
        id: 'tac_fs_3', emoji: '🥊', rarity: RarityTier.rare,
        title: '針對性減價戰：削減競爭對手 45% 實力',
        subtitle: '集中資源爭奪客源，立即削減黃金轉角位競爭對手 45% 當前實力。',
      ),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_shark_consortium',
    title: '商會投資聯席會議',
    emoji: '🦈',
    description: '城中三大投資機構邀請你參與聯席會議，並提出三份合作方案：',
    options: [
      TacticalOption(
        id: 'tac_shk_1', emoji: '📈', rarity: RarityTier.epic,
        title: '聯合護盤：全線股票上升 55%',
        subtitle: '即時帶動市場所有股票上升 55% 並轉入景氣暢旺期，適合持有正股時平倉獲利。',
      ),
      TacticalOption(
        id: 'tac_shk_2', emoji: '⛈️', rarity: RarityTier.epic,
        title: '收緊信貸：令競爭對手陷入財務困境',
        subtitle: '市場轉入經濟調整期，競爭對手即時進入 30 秒半價收購狀態。',
      ),
      TacticalOption(
        id: 'tac_shk_3', emoji: '🏪', rarity: RarityTier.rare,
        title: '招商引資：獲取 2 張免費招租券',
        subtitle: '獲得 2 次免費「商舖招租三選一」機會，可免租金引入新商舖。',
      ),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_chef_competition',
    title: '全港美食文化節',
    emoji: '🍜',
    description: '電視台於街區舉辦《全港美食文化節》，吸引大批市民到訪，請選擇推廣重點：',
    options: [
      TacticalOption(
        id: 'tac_chef_1', emoji: '🔥', rarity: RarityTier.epic,
        title: '招牌菜式推廣：飲食與娛樂商舖永久 +45% 收益',
        subtitle: '街區內所有已營業的【飲食】及【娛樂】商舖基礎收益永久提升 45%。',
      ),
      TacticalOption(
        id: 'tac_chef_2', emoji: '⭐⭐', rarity: RarityTier.legendary,
        title: '開設分店：免費複製場上最高星級商舖',
        subtitle: '複製一間場上星級最高的商舖（有助湊齊三間同款商舖升星）。',
      ),
      TacticalOption(
        id: 'tac_chef_3', emoji: '🍷', rarity: RarityTier.rare,
        title: '舉辦貴賓展銷會（短期高回報項目）',
        subtitle: '投入 30% 現金啟動短期高回報展銷項目，請在熱度消退前及時結算退場。',
      ),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_triad_negotiation',
    title: '街區商戶管理協調',
    emoji: '🕶️',
    description: '街區面臨外部競爭壓力，各商戶代表希望你決定應對方向：',
    options: [
      TacticalOption(
        id: 'tac_trd_1', emoji: '🔨', rarity: RarityTier.epic,
        title: '資產競投：立即開啟「特價物業拍賣」',
        subtitle: '即時開拍一間二星精裝商舖，成功投得即可直接進駐街區。',
      ),
      TacticalOption(
        id: 'tac_trd_2', emoji: '💳', rarity: RarityTier.rare,
        title: '申請緊急過橋貸款：補充大量流動現金',
        subtitle: '手頭現金即時大幅增加，同時銀行負債相應增加（配合尊尚黑金卡效果顯著）。',
      ),
      TacticalOption(
        id: 'tac_trd_3', emoji: '🛡️', rarity: RarityTier.common,
        title: '完善街區管理：領取營運津貼並回滿行動力',
        subtitle: '獲得一筆營運補助資金，並將策略行動力回復至上限。',
      ),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_customs_raid', title: '貨櫃碼頭公開競投', emoji: '🛃',
    description: '葵青貨櫃碼頭有一批逾期貨櫃公開招標，共有三種不同貨源可供選擇：',
    options: [
      TacticalOption(id: 'tac_cus_1', emoji: '🚛', rarity: RarityTier.rare, title: '競投急凍食材櫃：有機會獲得豐厚貿易利潤', subtitle: '投入資金參與競投，成功可獲相當於本季租金 75% 的利潤，失敗則損失部分現金。'),
      TacticalOption(id: 'tac_cus_2', emoji: '💎', rarity: RarityTier.epic, title: '競投精品百貨櫃：商舖升星並送免費招租', subtitle: '隨機令場上 1 間商舖提升星級，並獲得 1 次免費招租機會。'),
      TacticalOption(id: 'tac_cus_3', emoji: '🔄', rarity: RarityTier.common, title: '轉讓提貨單：穩健收取轉手差價', subtitle: '穩健賺取相當於本季租金 25% 的現金差價，並回滿行動力。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_typhoon_signal10', title: '颱風襲港應變安排', emoji: '🌀',
    description: '天文台發出烈風信號，你需要為街區商戶決定營業及防風安排：',
    options: [
      TacticalOption(id: 'tac_typ_1', emoji: '🔥', rarity: RarityTier.epic, title: '提供應急物資服務：獲得額外營業收入', subtitle: '即時獲得一筆應急物資銷售收益。'),
      TacticalOption(id: 'tac_typ_2', emoji: '🏠', rarity: RarityTier.rare, title: '趁機升級店面設施：隨機商舖升星並獲招租券', subtitle: '為場上隨機 1 間商舖提升星級，並獲得 1 次免費招租機會。'),
      TacticalOption(id: 'tac_typ_3', emoji: '🛡️', rarity: RarityTier.common, title: '全面加固防風設施：領取防災補助', subtitle: '領取本季租金 25% 的防災補助並回滿行動力。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_tv_drama_shoot', title: '電視劇組租借場地拍攝', emoji: '🎬',
    description: '電視台劇組希望租借你的街區拍攝商戰劇集，並提出三種合作方式：',
    options: [
      TacticalOption(id: 'tac_tv_1', emoji: '🌟', rarity: RarityTier.legendary, title: '品牌冠名贊助：提升街區知名度與收益', subtitle: '藉由劇集宣傳效應，為街區帶來可觀收益。'),
      TacticalOption(id: 'tac_tv_2', emoji: '🀄', rarity: RarityTier.rare, title: '安排商舖入鏡宣傳：商舖升星並獲招租券', subtitle: '隨機提升 1 間商舖星級，並獲得 1 次免費招租機會。'),
      TacticalOption(id: 'tac_tv_3', emoji: '💵', rarity: RarityTier.common, title: '單純收取場地租金', subtitle: '穩健收取相當於本季租金 25% 的場地租金並回滿行動力。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_bank_rate_hike', title: '金管局宣佈調整基準利率', emoji: '🏦',
    description: '銀行同業拆息上升，融資成本增加，請選擇你的財務應對策略：',
    options: [
      TacticalOption(id: 'tac_bnk_1', emoji: '🦇', rarity: RarityTier.epic, title: '拓展逆市信貸業務：獲取營運補助', subtitle: '把握信貸需求，獲取一筆營運資金補助。'),
      TacticalOption(id: 'tac_bnk_2', emoji: '📉', rarity: RarityTier.rare, title: '調整商舖組合：隨機商舖升星並獲招租券', subtitle: '隨機提升場上 1 間商舖星級，並獲得 1 次免費招租機會。'),
      TacticalOption(id: 'tac_bnk_3', emoji: '🧾', rarity: RarityTier.common, title: '申請利息補貼：穩健領取津貼並回滿行動力', subtitle: '領取相當於本季租金 25% 的津貼並回滿行動力。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_night_market_fest', title: '國際夜市美食嘉年華', emoji: '🏮',
    description: '旅遊發展局於街區舉辦大型夜市嘉年華，吸引眾多旅客到訪：',
    options: [
      TacticalOption(id: 'tac_nm_1', emoji: '🍢', rarity: RarityTier.epic, title: '主推特色小食攤位：獲取嘉年華營業收益', subtitle: '把握人流高峰，即時增加營業收入。'),
      TacticalOption(id: 'tac_nm_2', emoji: '🃏', rarity: RarityTier.rare, title: '趁旺季擴充店面：隨機商舖升星並獲招租券', subtitle: '隨機提升 1 間商舖星級，並獲得 1 次免費招租機會。'),
      TacticalOption(id: 'tac_nm_3', emoji: '🥊', rarity: RarityTier.rare, title: '申請旅遊推廣資助', subtitle: '領取相當於本季租金 25% 的推廣資助並回滿行動力。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_antique_auction', title: '荷李活道古董鑑賞會', emoji: '🏺',
    description: '古董街資深收藏家舉辦私人鑑賞會，提供三項投資選擇：',
    options: [
      TacticalOption(id: 'tac_ant_1', emoji: '📜', rarity: RarityTier.legendary, title: '收購珍稀藏品：獲取鑑定收益', subtitle: '透過藏品轉讓獲得可觀的資金回報。'),
      TacticalOption(id: 'tac_ant_2', emoji: '⭐⭐', rarity: RarityTier.epic, title: '美化商舖陳設：隨機商舖升星並獲招租券', subtitle: '隨機將場上 1 間商舖提升星級，並獲得 1 次免費招租機會。'),
      TacticalOption(id: 'tac_ant_3', emoji: '🪙', rarity: RarityTier.common, title: '寄售舊藏品：穩健收取佣金', subtitle: '直接獲得相當於本季租金 25% 的佣金並回滿行動力。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_syndicate_mole', title: '競爭對手高層轉投', emoji: '🕵️',
    description: '競爭對手公司的資深經理主動接觸，希望與你達成商業合作：',
    options: [
      TacticalOption(id: 'tac_mol_1', emoji: '🔥', rarity: RarityTier.epic, title: '掌握市場情報：獲取額外商業收益', subtitle: '運用市場情報優勢，即時提升現金收益。'),
      TacticalOption(id: 'tac_mol_2', emoji: '📊', rarity: RarityTier.rare, title: '引入管理經驗：隨機商舖升星並獲招租券', subtitle: '隨機提升 1 間商舖星級，並獲得 1 次免費招租機會。'),
      TacticalOption(id: 'tac_mol_3', emoji: '💼', rarity: RarityTier.common, title: '達成顧問協議：穩健收取顧問費', subtitle: '獲得相當於本季租金 25% 的顧問收益並回滿行動力。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_horse_racing_night', title: '跑馬地慈善賽馬夜', emoji: '🐎',
    description: '馬會舉行年度慈善賽馬夜，商界名流雲集，請選擇你的參與方式：',
    options: [
      TacticalOption(id: 'tac_hrs_1', emoji: '🏆', rarity: RarityTier.legendary, title: '參與大額錦標競猜（具一定風險）', subtitle: '成功可贏取豐厚獎金，失利則損失部分現金。'),
      TacticalOption(id: 'tac_hrs_2', emoji: '🥂', rarity: RarityTier.rare, title: '於貴賓廂房拓展人脈：商舖升星並獲招租券', subtitle: '隨機提升 1 間商舖星級，並獲得 1 次免費招租機會。'),
      TacticalOption(id: 'tac_hrs_3', emoji: '🎟️', rarity: RarityTier.common, title: '承辦場內餐飲服務：穩健獲取收益', subtitle: '穩健獲得相當於本季租金 25% 的服務收益並回滿行動力。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_electric_grid_overclock', title: '街區電力設施升級工程', emoji: '⚡',
    description: '電力公司建議為街區更換高效能供電設備，提升商舖運作效率：',
    options: [
      TacticalOption(id: 'tac_elc_1', emoji: '🔋', rarity: RarityTier.epic, title: '全面升級供電網：提升營運效率', subtitle: '即時獲得設備升級帶來的額外收益。'),
      TacticalOption(id: 'tac_elc_2', emoji: '🛠️', rarity: RarityTier.rare, title: '重點強化骨幹商舖：商舖升星並獲招租券', subtitle: '隨機提升 1 間商舖星級，並獲得 1 次免費招租機會。'),
      TacticalOption(id: 'tac_elc_3', emoji: '♻️', rarity: RarityTier.common, title: '申請節能改造津貼', subtitle: '獲得相當於本季租金 25% 的環保節能津貼並回滿行動力。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_michelin_inspector', title: '國際美食指南評鑑員到訪', emoji: '⭐',
    description: '知名美食指南評鑑員低調到訪街區試菜，請選擇你的接待方案：',
    options: [
      TacticalOption(id: 'tac_mic_1', emoji: '🍜', rarity: RarityTier.epic, title: '精選上乘食材應戰：提升品牌聲譽', subtitle: '獲得美食評鑑推薦，帶來可觀營業收益。'),
      TacticalOption(id: 'tac_mic_2', emoji: '📈', rarity: RarityTier.rare, title: '藉評鑑名氣升級店面：商舖升星並獲招租券', subtitle: '隨機提升 1 間商舖星級，並獲得 1 次免費招租機會。'),
      TacticalOption(id: 'tac_mic_3', emoji: '📸', rarity: RarityTier.common, title: '授權飲食雜誌專訪', subtitle: '獲得相當於本季租金 25% 的版權收益並回滿行動力。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_cross_border_bus', title: '跨境直通巴士總站啟用', emoji: '🚄',
    description: '全新跨境巴士總站於街區旁啟用，帶來穩定旅客人流：',
    options: [
      TacticalOption(id: 'tac_cbb_1', emoji: '🏬', rarity: RarityTier.epic, title: '設立旅客購物專區：增加零售收入', subtitle: '把握跨境旅客消費，即時提升營業現金。'),
      TacticalOption(id: 'tac_cbb_2', emoji: '⭐⭐', rarity: RarityTier.rare, title: '引入知名連鎖品牌：商舖升星並獲招租券', subtitle: '隨機提升 1 間商舖星級，並獲得 1 次免費招租機會。'),
      TacticalOption(id: 'tac_cbb_3', emoji: '💱', rarity: RarityTier.common, title: '增設外幣找換服務', subtitle: '穩健獲得相當於本季租金 25% 的匯兌收益並回滿行動力。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_film_award_gala', title: '香港電影頒獎禮星光盛會', emoji: '🏆',
    description: '本年度電影頒獎禮紅地毯設於街區入口，吸引全城目光：',
    options: [
      TacticalOption(id: 'tac_fag_1', emoji: '🎰', rarity: RarityTier.epic, title: '承辦慶功晚宴：提升全街長遠收益', subtitle: '支付 20% 現金籌辦晚宴，全街商舖永久獲得 28% 收益加成。'),
      TacticalOption(id: 'tac_fag_2', emoji: '👑', rarity: RarityTier.legendary, title: '贊助盛會舞台：隨機商舖升星並獲招租券', subtitle: '隨機提升 1 間商舖星級，並獲得 1 次免費招租機會。'),
      TacticalOption(id: 'tac_fag_3', emoji: '🍾', rarity: RarityTier.common, title: '出租戶外廣告展位', subtitle: '穩健獲得相當於本季租金 25% 的廣告收益並回滿行動力。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'tac_central_reclaim_tender', title: '海濱商業地段公開招標', emoji: '🏙️',
    description: '核心海濱商業地段即將截標，多間大型機構參與競投：',
    options: [
      TacticalOption(id: 'tac_crt_1', emoji: '🐉', rarity: RarityTier.legendary, title: '參與聯合競標（高風險高回報）', subtitle: '成功中標可獲得相當於本季租金 75% 的開發收益，失利則損失部分現金。'),
      TacticalOption(id: 'tac_crt_2', emoji: '🔨', rarity: RarityTier.epic, title: '專注現有物業升級：商舖升星並獲招租券', subtitle: '隨機提升 1 間商舖星級，並獲得 1 次免費招租機會。'),
      TacticalOption(id: 'tac_crt_3', emoji: '🤝', rarity: RarityTier.common, title: '擔任項目顧問收取服務費', subtitle: '零風險獲得相當於本季租金 25% 的顧問收益並回滿行動力。'),
    ],
  ),
];
