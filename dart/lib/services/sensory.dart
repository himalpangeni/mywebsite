import 'package:flutter/services.dart';

class SensoryService {
  static int _lastImpact = 0;

  static bool _shouldThrottled() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastImpact < 50) return true;
    _lastImpact = now;
    return false;
  }

  static Future<void> lightImpact() async {
    if (_shouldThrottled()) return;
    try { await HapticFeedback.lightImpact(); } catch (_) {}
  }

  static Future<void> mediumImpact() async {
    if (_shouldThrottled()) return;
    try { await HapticFeedback.mediumImpact(); } catch (_) {}
  }

  static Future<void> heavyImpact() async {
    if (_shouldThrottled()) return;
    try { await HapticFeedback.heavyImpact(); } catch (_) {}
  }

  static Future<void> success() async {
    try { await HapticFeedback.vibrate(); } catch (_) {}
  }

  static Future<void> error() async {
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  static Future<void> vibrateImpact() async => mediumImpact();
}
