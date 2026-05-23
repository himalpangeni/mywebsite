import 'package:flutter/material.dart';

enum GameDifficulty { easy, medium, hard, veryHard, extreme }

extension GameDifficultyExtension on GameDifficulty {
  double get speedMultiplier {
    switch (this) {
      case GameDifficulty.easy: return 1.0;
      case GameDifficulty.medium: return 1.5;
      case GameDifficulty.hard: return 2.0;
      case GameDifficulty.veryHard: return 2.5;
      case GameDifficulty.extreme: return 3.0;
    }
  }

  String get label {
    switch (this) {
      case GameDifficulty.easy: return 'EASY';
      case GameDifficulty.medium: return 'MEDIUM';
      case GameDifficulty.hard: return 'HARD';
      case GameDifficulty.veryHard: return 'VERY HARD';
      case GameDifficulty.extreme: return 'EXTREME';
    }
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}
