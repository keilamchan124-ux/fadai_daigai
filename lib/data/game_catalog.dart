import '../models/game_models.dart';
import 'shops_data.dart';
import 'synergies_bosses_data.dart';
import 'cards_talents_data.dart';
import 'meta_data.dart';

export 'shops_data.dart';
export 'synergies_bosses_data.dart';
export 'cards_talents_data.dart';
export 'meta_data.dart';
export 'roguelike_data.dart';

class GameCatalog {
  static final Map<String, ShopDefinition> _shopMap = {
    for (final s in kAllShops) s.id: s,
  };
  static final Map<int, RivalBossDefinition> _bossByTier = {
    for (final b in kAllBosses) b.tier: b,
  };
  static final Map<String, FamilyTalentNode> _talentMap = {
    for (final t in kAllTalents) t.id: t,
  };
  static final Map<String, LuxuryItem> _luxuryMap = {
    for (final l in kAllLuxuries) l.id: l,
  };

  static ShopDefinition shopById(String id) {
    return _shopMap[id] ?? kAllShops.first;
  }

  static List<ShopDefinition> shopsForTier(int maxTier) {
    return kAllShops.where((s) => s.tier <= maxTier).toList();
  }

  static RivalBossDefinition bossForTier(int tier) {
    return _bossByTier[tier] ?? kAllBosses.last;
  }

  static FamilyTalentNode talentById(String id) {
    return _talentMap[id] ?? kAllTalents.first;
  }

  static LuxuryItem luxuryById(String id) {
    return _luxuryMap[id] ?? kAllLuxuries.first;
  }
}
