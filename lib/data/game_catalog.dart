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
  static ShopDefinition shopById(String id) {
    return kAllShops.firstWhere(
      (s) => s.id == id,
      orElse: () => kAllShops.first,
    );
  }

  static List<ShopDefinition> shopsForTier(int maxTier) {
    return kAllShops.where((s) => s.tier <= maxTier).toList();
  }

  static RivalBossDefinition bossForTier(int tier) {
    return kAllBosses.firstWhere(
      (b) => b.tier == tier,
      orElse: () => kAllBosses.last,
    );
  }

  static FamilyTalentNode talentById(String id) {
    return kAllTalents.firstWhere((t) => t.id == id);
  }

  static LuxuryItem luxuryById(String id) {
    return kAllLuxuries.firstWhere((l) => l.id == id);
  }
}
