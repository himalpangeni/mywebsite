import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static const String appId = 'ca-app-pub-6596912508636314~2012849036';
  static const String bannerAdUnitId = 'ca-app-pub-6596912508636314/6022701644';
  static const String rewardedAdUnitId = 'ca-app-pub-6596912508636314/6678827673';

  static RewardedAd? _rewardedAd;
  static int _numRewardedLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadRewardedAd();
  }

  static void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _numRewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _numRewardedLoadAttempts += 1;
          if (_numRewardedLoadAttempts <= maxFailedLoadAttempts) {
            loadRewardedAd();
          }
        },
      ),
    );
  }

  static Future<bool> showRewardedAd(BuildContext context) async {
    if (_rewardedAd == null) {
      loadRewardedAd();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready yet. Try again in a moment.')),
      );
      return false;
    }

    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadRewardedAd();
      },
    );

    await _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      rewarded = true;
    });

    return rewarded;
  }

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }
}
