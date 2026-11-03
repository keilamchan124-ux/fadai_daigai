import '../models/game_models.dart';

TacticalOption option(String id, String title, String detail) =>
    TacticalOption(id: id, title: title, subtitle: detail, emoji: '📋');
final List<TacticalThreeChoiceEvent> kQuarterEvents = [
  TacticalThreeChoiceEvent(
    id: 'film',
    title: '劇組借場',
    emoji: '🎬',
    description: '選擇商舖及合作安排。',
    options: [
      option('film_a', '借出指定商舖', '本季停業，下季該舖收益 +80%。'),
      option('film_b', '全街宣傳', '支付本季租金 15%，本季全街收益 +15%。'),
      option('film_c', '收取場租', '即收本季租金 10%。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'renew',
    title: '舊區重建',
    emoji: '🏗️',
    description: '調整資產，改善長遠收入。',
    options: [
      option('renew_a', '拆除指定商舖', '相鄰現有商舖永久收益 +15%，同類加成不重複。'),
      option('renew_b', '設備翻新', '支付租金 20%，指定商舖提升一次現金強化。'),
      option('renew_c', '保留現狀', '不改變資產。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'credit',
    title: '街坊賒帳',
    emoji: '🥣',
    description: '現金周轉與熟客生意之間取捨。',
    options: [
      option('credit_a', '建立熟客關係', '本季飲食 -15%，以後飲食 +10%，不重複疊加。'),
      option('credit_b', '收回貨款', '即收租金 10%。'),
      option('credit_c', '研發招牌菜', '支付租金 10%，指定飲食舖基礎產出永久 +20%。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'storm',
    title: '颱風安排',
    emoji: '🌀',
    description: '決定本季營運方式。',
    options: [
      option('storm_a', '支付防風費', '支付租金 10%，本季正常營業。'),
      option('storm_b', '應急供應', '本季物流 -20%、飲食 +20%。'),
      option('storm_c', '保守營業', '本季全場 -5%，下季獲一次免費重抽。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'contract',
    title: '商會合約',
    emoji: '📜',
    description: '獎勵只在本季完成條件後發放。',
    options: [
      option('contract_a', '接下連鎖合約', '本季完成 5 步連鎖，下季獲免費招租券。'),
      option('contract_b', '穩健融資承諾', '選擇後本季不再借貸，結算獲租金 15%。'),
      option('contract_c', '婉拒合約', '不承擔條件。'),
    ],
  ),
  TacticalThreeChoiceEvent(
    id: 'debt',
    title: '債務重組',
    emoji: '🏦',
    description: '減輕本金或本季利息。',
    options: [
      option('debt_a', '提前還款', '償還 20% 貸款本金，本季其餘銀行利息減半。'),
      option('debt_b', '出售資產清債', '指定商舖退款全數還債，再豁免餘下貸款 10%。'),
      option('debt_c', '維持原狀', '保持現有借貸。'),
    ],
  ),
];
