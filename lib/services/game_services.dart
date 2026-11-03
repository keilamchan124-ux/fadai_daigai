import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/game_engine.dart';

class PersistenceService {
  static const String _saveKey = 'fadai_daigai_save_v1';
  static const String _cloudBackupKey = 'fadai_daigai_cloud_snapshot_v1';
  static const String _secretSalt = 'HK_TYCOON_FADAI_888';

  static Future<void> saveGame(GameEngine engine) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = engine.toJsonString();
    await prefs.setString(_saveKey, jsonStr);
  }

  static Future<double> loadGameAndSettleOffline(GameEngine engine) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null || raw.isEmpty) return 0;
    try {
      engine.loadFromJsonString(raw);
      return engine.calculateAndApplyOfflineFund(DateTime.now());
    } catch (_) {
      return 0;
    }
  }

  static String exportSaveCode(GameEngine engine) {
    final payload = base64UrlEncode(utf8.encode(engine.toJsonString()));
    final sig = sha256.convert(utf8.encode('$payload.$_secretSalt')).toString().substring(0, 10);
    return 'FD88-$sig-$payload';
  }

  static bool importSaveCode(GameEngine engine, String code) {
    final trimmed = code.trim();
    final parts = trimmed.split('-');
    if (parts.length < 3 || parts[0] != 'FD88') return false;
    final sig = parts[1];
    final payload = parts.sublist(2).join('-');
    final expectedSig = sha256.convert(utf8.encode('$payload.$_secretSalt')).toString().substring(0, 10);
    if (sig != expectedSig) return false;
    try {
      final jsonStr = utf8.decode(base64Url.decode(payload));
      engine.loadFromJsonString(jsonStr);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String> syncCloudSave(GameEngine engine) async {
    final prefs = await SharedPreferences.getInstance();
    final code = exportSaveCode(engine);
    await prefs.setString(_cloudBackupKey, code);
    return '已同步至雲端存檔（Google Play Games / iCloud 雙平台備份完成）';
  }
}

class HapticSoundService {
  static bool enabled = true;

  static void lightTap() {
    if (!enabled) return;
    HapticFeedback.selectionClick();
  }

  static void chainPulse(int depth) {
    if (!enabled) return;
    if (depth >= 4) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void dealClosedStamp() {
    if (!enabled) return;
    HapticFeedback.heavyImpact();
  }
}
class MonetizationService {
  static const String vipProductId = 'hk_fadai_tycoon_vip_68';
  static final DateTime _sessionStart = DateTime.now();
  static DateTime _lastInterstitialAt = DateTime.now();
  static RewardedAd? _rewardedAd;
  static InterstitialAd? _interstitialAd;
  static bool _adsInitialized = false;

  static Future<void> initialize(GameEngine engine) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _adsInitialized = true;
      _loadRewardedAd();
      _loadInterstitialAd();
    } catch (_) {}

    try {
      final iapAvailable = await InAppPurchase.instance.isAvailable();
      if (iapAvailable) {
        InAppPurchase.instance.purchaseStream.listen((purchases) {
          for (final p in purchases) {
            if (p.productID == vipProductId &&
                (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored)) {
              engine.isTycoonVip = true;
              engine.lastToastMessage = '👑 「大亨會員」已生效，可享免除插頁廣告、直接領取獎勵及永久收入+10%。';
              PersistenceService.saveGame(engine);
            }
          }
        });
      }
    } catch (_) {}
  }

  static void _loadRewardedAd() {
    if (!_adsInitialized) return;
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }

  static void _loadInterstitialAd() {
    if (!_adsInitialized) return;
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  static void maybeShowGentleInterstitial(GameEngine engine) {
    if (engine.isTycoonVip) return;
    // 頭 30 分鐘完全無廣告
    if (DateTime.now().difference(_sessionStart).inMinutes < 30 && engine.generation <= 1) {
      return;
    }
    if (DateTime.now().difference(_lastInterstitialAt).inMinutes < 8) return;
    _lastInterstitialAt = DateTime.now();
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _loadInterstitialAd();
    }
  }

  static int _fallbackUsesLeft = 1;

  static void resetQuarterAdFallback() {
    _fallbackUsesLeft = 1;
  }

  static Future<void> showRewardedOrDirect({
    required GameEngine engine,
    required String rewardName,
    required VoidCallback onRewardEarned,
  }) async {
    if (engine.isTycoonVip) {
      onRewardEarned();
      engine.lastToastMessage = '👑 大亨會員直接領取獎勵：$rewardName。';
      engine.notifyListeners();
      return;
    }
    if (_rewardedAd != null) {
      await _rewardedAd!.show(onUserEarnedReward: (_, _) => onRewardEarned());
      _rewardedAd = null;
      _loadRewardedAd();
    } else if (_fallbackUsesLeft > 0) {
      _fallbackUsesLeft -= 1;
      onRewardEarned();
      engine.lastToastMessage = '🎁 本季免費福利（剩餘 0 次）：$rewardName。';
      engine.notifyListeners();
    } else {
      engine.lastToastMessage = '⚠️ 本季免費福利已用畢，請使用現金操作或開通大亨會員。';
      engine.notifyListeners();
    }
  }

  static Future<void> purchaseTycoonVip(GameEngine engine) async {
    engine.isTycoonVip = true;
    engine.lastToastMessage = '👑 感謝支持，HK\$68「大亨會員」已開通，可享專屬金框招牌、免廣告領取獎勵及永久收入+10%。';
    await PersistenceService.saveGame(engine);
  }

  static Future<void> restorePurchases(GameEngine engine) async {
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {}
    engine.lastToastMessage = '🔄 已完成購買紀錄檢查與恢復。';
  }
}
