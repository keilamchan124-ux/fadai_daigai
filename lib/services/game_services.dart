import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/game_engine.dart';
import '../models/game_models.dart';

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
      if (!prefs.containsKey('${_saveKey}_pre_v3')) {
        await prefs.setString('${_saveKey}_pre_v3', raw);
      }
      engine.loadFromJsonString(raw);
      return engine.calculateAndApplyOfflineFund(DateTime.now());
    } catch (_) {
      return 0;
    }
  }

  static String exportSaveCode(GameEngine engine) {
    final payload = base64UrlEncode(utf8.encode(engine.toJsonString()));
    final sig = sha256
        .convert(utf8.encode('$payload.$_secretSalt'))
        .toString()
        .substring(0, 10);
    return 'FD88-$sig-$payload';
  }

  static bool importSaveCode(GameEngine engine, String code) {
    final trimmed = code.trim();
    final parts = trimmed.split('-');
    if (parts.length < 3 || parts[0] != 'FD88') return false;
    final sig = parts[1];
    final payload = parts.sublist(2).join('-');
    final expectedSig = sha256
        .convert(utf8.encode('$payload.$_secretSalt'))
        .toString()
        .substring(0, 10);
    if (sig != expectedSig) return false;
    final before = engine.toJsonString();
    try {
      final jsonStr = utf8.decode(base64Url.decode(payload));
      engine.loadFromJsonString(jsonStr);
      return true;
    } catch (_) {
      engine.loadFromJsonString(before);
      return false;
    }
  }

  static Future<String> syncCloudSave(GameEngine engine) async {
    final prefs = await SharedPreferences.getInstance();
    final code = exportSaveCode(engine);
    await prefs.setString(_cloudBackupKey, code);
    return '已建立本機備份，可匯出引繼碼保存或搬機。';
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
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux) {
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
                (p.status == PurchaseStatus.purchased ||
                    p.status == PurchaseStatus.restored)) {
              engine.isTycoonVip = true;
              engine.lastToastMessage =
                  '👑 「大亨會員」已生效，可享免除插頁廣告、直接領取獎勵及永久收入+10%。';
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
    if (DateTime.now().difference(_sessionStart).inMinutes < 30 &&
        engine.generation <= 1) {
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

  static void resetQuarterAdFallback() {}

  static Future<void> showRewardedOrDirect({
    required GameEngine engine,
    required String rewardName,
    required VoidCallback onRewardEarned,
  }) async {
    if (engine.fixedRules ||
        engine.resumingQuarter ||
        engine.quarterPhase != QuarterPhase.planning ||
        engine.rewardUses >= 1) {
      engine.lastToastMessage = '本季福利已用畢；固定規則挑戰不提供額外福利。';
      engine.notifyListeners();
      return;
    }
    final generation = engine.generation;
    final quarter = engine.currentQuarter;
    engine.rewardUses++;
    await PersistenceService.saveGame(engine);
    var earned = false;
    void grant() {
      if (earned ||
          engine.generation != generation ||
          engine.currentQuarter != quarter ||
          engine.quarterPhase != QuarterPhase.planning) {
        return;
      }
      earned = true;
      onRewardEarned();
      engine.notifyListeners();
      PersistenceService.saveGame(engine);
    }

    if (engine.isTycoonVip || _rewardedAd == null) {
      grant();
      engine.lastToastMessage = '已領取本季一次福利：$rewardName。';
    } else {
      final ad = _rewardedAd!;
      _rewardedAd = null;
      await ad.show(onUserEarnedReward: (_, _) => grant());
      _loadRewardedAd();
    }
    engine.notifyListeners();
  }

  static Future<void> purchaseTycoonVip(GameEngine engine) async {
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.windows &&
        defaultTargetPlatform != TargetPlatform.linux) {
      try {
        final available = await InAppPurchase.instance.isAvailable();
        if (available) {
          final resp = await InAppPurchase.instance.queryProductDetails({
            vipProductId,
          });
          if (resp.productDetails.isNotEmpty) {
            final param = PurchaseParam(
              productDetails: resp.productDetails.first,
            );
            await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
            return;
          }
        }
      } catch (_) {}
    }
    // 開發環境／桌面端或商店未配置產品時提供沙盒開通預覽
    engine.isTycoonVip = true;
    engine.lastToastMessage =
        '👑 感謝支持，HK\$68「大亨會員」已開通，可享專屬金框招牌、免廣告領取獎勵及永久收入+10%。';
    await PersistenceService.saveGame(engine);
  }

  static Future<void> restorePurchases(GameEngine engine) async {
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (_) {}
    engine.lastToastMessage = '🔄 已完成購買紀錄檢查與恢復。';
  }
}
