
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../widgets/ad_manager.dart';
import '../games/2048/game.dart';
import '../games/tennis/game.dart';
import '../games/bounce_ball/game.dart';
import '../games/solitaire/game.dart';
import '../games/drive_me/game.dart';
import '../games/neon_tank/game.dart';
import '../games/puzzle_blacksmith/game.dart';

import '../games/car_parking/game.dart';
import '../games/glow_hockey/game.dart';
import '../games/ludo_club/ludo_setup_screen.dart';
import '../games/neon_snake/game.dart';
import '../games/pac_neon/game.dart';
import '../games/music_tiles/game.dart';
import '../games/stack_builder/game.dart';
import '../games/tic_tac_toe/config.dart';
import '../games/tic_tac_toe/game.dart';
import '../games/chess/config.dart';
import '../games/chess/game.dart';
import '../games/uno_light/config.dart';
import '../games/uno_light/game.dart';
import '../games/boy_vs_girl/game.dart';
import '../games/smash_hit/game.dart';
import '../games/ball_blast/game.dart';
import '../games/angry_weapon/game.dart';
import '../games/aquapark/game.dart';
import '../games/baby_crossing/game.dart';
import '../games/crazy_run/game.dart';
import '../games/cyber_runner/game.dart';
import '../games/flappy_bird/game.dart';
import '../games/island_jump/game.dart';
import '../games/magnet_knight/game.dart';
import '../games/paddle_clash/game.dart';
import '../games/pixel_words/game.dart';
import '../games/shortcut_slider/game.dart';
import '../games/slide_shakes/game.dart';
import '../games/tiny_royale/game.dart';
import '../games/vampire_job/game.dart';
import '../games/zombie_rescue/game.dart';
import '../games/number_merge/game.dart';

import 'parallax_background.dart';
import 'depth_grid_tile.dart';
import '../../models/difficulty.dart';
import 'difficulty_selection.dart';
import 'universal_game_over.dart';
import 'privacy_policy.dart';

class GameHub extends StatefulWidget {
  const GameHub({super.key});

  @override
  State<GameHub> createState() => _GameHubState();
}

class _GameHubState extends State<GameHub> {
  final ScrollController _scrollController = ScrollController();
  late List<_GameDef> _cachedGames;
  int _restartKey = 0; 
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _cachedGames = _getGameDefinitions(context);
    _bannerAd = AdManager.createBannerAd();
  }


  Future<void> _startGame(
    BuildContext context,
    String title,
    Widget Function(GameDifficulty) builder, {
    bool bypassDifficulty = false,
    GameDifficulty? defaultDifficulty,
  }) async {
    _restartKey++;

    if (bypassDifficulty) {
      Navigator.push(
        context,
        _CinematicRoute(
          builder: (context) =>
              builder(defaultDifficulty ?? GameDifficulty.medium),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DifficultySelection(
        gameTitle: title,
        onSelected: (difficulty) {
          Navigator.pop(context);
          Navigator.push(
            context,
            _CinematicRoute(builder: (context) => builder(difficulty)),
          );
        },
      ),
    );
  }


  Future<void> _showRewardedAdAndContinue(
      BuildContext context, VoidCallback continueAction) async {
    final adWatched = await AdManager.showRewardedAd(context);
    if (adWatched) {
      continueAction();
      FocusManager.instance.primaryFocus?.unfocus();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not watched – continue unavailable')),
      );
    }
  }

  void _startBoyVsGirl(BuildContext context) {
    _restartKey++;
    _startGame(
      context,
      'Boy vs Girl',
      (d) => GameWidget(
            key: ValueKey('boyvsgirl_$_restartKey'),
            game: BoyVsGirlGame(difficulty: d, mode: GameMode.pve),
            overlayBuilderMap: {
              'GameOver': (c, BoyVsGirlGame g) => UniversalGameOver(
                  gameTitle: 'Boy vs Girl',
                  score: (g.boy.health * 10).toInt(),
                  isVictory: g.winner.isNotEmpty && g.winner.contains('WINS'),
                  onContinue: () => _showRewardedAdAndContinue(c, g.resumeGame),
                  onRestart: g.restart,
                  onHome: () => Navigator.pop(c))
            }),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ParallaxBackground(scrollController: _scrollController),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount =
                                (constraints.maxWidth / 180).floor().clamp(2, 5);
                            final games = _cachedGames;
                            final tileHeight = (constraints.maxWidth / crossAxisCount) / 0.85;

                            return CustomScrollView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 30),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      mainAxisSpacing: 30,
                                      crossAxisSpacing: 25,
                                      childAspectRatio: 0.85,
                                    ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final game = games[index];
                                        final row = index ~/ crossAxisCount;
                                        final col = index % crossAxisCount;
                                        final yPos = 120 + row * (tileHeight + 30);
                                        final xPos = 20 + col * (constraints.maxWidth / crossAxisCount);

                                        return DepthGridTile(
                                          title: game.title,
                                          icon: game.icon,
                                          color: game.color,
                                          onTap: game.onTap,
                                          scrollController: _scrollController,
                                          xPos: xPos,
                                          yPos: yPos,
                                          imageAsset: game.imageAsset,
                                        );
                                      },
                                      childCount: games.length,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
              ],
            ),
          ),
          if (_bannerAd != null)
            SafeArea(
              child: SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Colors.cyanAccent),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen())),
          ),
          Stack(
            alignment: Alignment.center,
            children: [

              Opacity(
                opacity: 0.5,
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: _buildHeaderText(Colors.cyanAccent),
                ),
              ),

              Opacity(
                opacity: 0.5,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: _buildHeaderText(Colors.pinkAccent),
                ),
              ),

              _buildHeaderText(Colors.white),
            ],
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildHeaderText(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('RETRO FUN',
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w300,
                letterSpacing: 8)),
        Text('CRATE',
            style: TextStyle(
                color: color,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 10)),
      ],
    );
  }

  List<_GameDef> _getGameDefinitions(BuildContext context) {


    return [
      _GameDef(
        'CHESS',
        Icons.castle,
        Colors.amberAccent,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (configContext) => ChessConfigScreen(
              onStart: (vsBot, playWhite, difficulty) {
                Navigator.pop(configContext);
                Future.microtask(() {
                  _startGame(
                    context,
                    'Chess',
                    (selectedDifficulty) => GameWidget(
                      key: ValueKey('chess_$_restartKey'),
                      game: ChessGame(
                        difficulty: selectedDifficulty,
                        vsBot: vsBot,
                        playerIsWhite: playWhite,
                      ),
                      initialActiveOverlays: const ['ChessControls'],
                      overlayBuilderMap: {
                        'GameOver': (context, ChessGame game) =>
                            UniversalGameOver(
                              gameTitle: 'Chess',
                              score: 0,
                              isVictory: !game.whiteToMove,
                              scoreLabel: game.result,
                              onContinue: () => _showRewardedAdAndContinue(
                                  context, game.resumeGame),
                              onRestart: game.restart,
                              onHome: () => Navigator.pop(context),
                            ),
                        'ChessControls': (context, ChessGame game) => Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                    IconButton(
                                      icon: const Icon(Icons.undo,
                                          color: Colors.white),
                                      onPressed: () => game.undoLastMove(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.lightbulb,
                                          color: Colors.yellowAccent),
                                      onPressed: () => game.showHint(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.refresh,
                                          color: Colors.white),
                                      onPressed: () => game.resetGame(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.screen_rotation,
                                          color: Colors.white),
                                      onPressed: () => game.flipBoard(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    },
                  ),
                  bypassDifficulty: true,
                  defaultDifficulty: difficulty,
                );
                });
              },
            ),
          ),
        ),
        imageAsset: 'assets/images/chess_logo_final.png',
      ),
      _GameDef(
          'TIC TAC TOE',
          Icons.tag,
          Colors.blueAccent,
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => TicTacToeConfigScreen(
                      onStart: (side, vsBot, diff) => _startGame(
                          context,
                          'Tic Tac Toe',
                          (_) => GameWidget(
                                  key: ValueKey('tictac_$_restartKey'),
                                  game: TicTacToeGame(
                                      difficulty: diff,
                                      playerSide: side,
                                      isVsBot: vsBot),
                                  overlayBuilderMap: {
                                    'GameOver': (c, TicTacToeGame g) =>
                                        UniversalGameOver(
                                            gameTitle: 'Tic Tac Toe',
                                            score: g.winner == g.playerSide
                                                ? 1
                                                : 0,
                                            isVictory: g.winner == g.playerSide,
                                            scoreLabel: 'WINS',
                                            onRestart: g.restart,
                                            onHome: () => Navigator.pop(c))
                                  }),
                          bypassDifficulty: true))))),
      _GameDef(
          'DRIVE ME',
          Icons.directions_car,
          Colors.cyan,
          () => _startGame(
              context,
              'Drive Me',
              (d) => GameWidget(
                  key: ValueKey('drive_$_restartKey'),
                  game: DriveMeGame(difficulty: d),
                  overlayBuilderMap: {
                    'GameOver': (c, DriveMeGame g) => UniversalGameOver(
                        gameTitle: 'Drive Me',
                        score: g.score,
                        onContinue: () => _showRewardedAdAndContinue(c, g.resumeGame),
                        onRestart: g.restart,
                        onHome: () => Navigator.pop(c)),
                  }),
              bypassDifficulty: false)),
      _GameDef(
          'NEON TANK',
          Icons.sports_esports,
          Colors.lime,
          () => _startGame(
              context,
              'Neon Tank',
              (d) => GameWidget(
                  key: ValueKey('tank_$_restartKey'),
                  game: NeonTankGame(difficulty: d),
                  overlayBuilderMap: {
                    'GameOver': (c, NeonTankGame g) => UniversalGameOver(
                        gameTitle: 'Neon Tank',
                        score: g.score,
                        onContinue: () => _showRewardedAdAndContinue(c, g.resumeGame),
                        onRestart: g.restart,
                        onHome: () => Navigator.pop(c)),
                  }),
              bypassDifficulty: false)),
      _GameDef(
          'PADDLE CLASH',
          Icons.sports_esports,
          Colors.blue,
          () => _startGame(
              context,
              'Paddle Clash',
              (d) => GameWidget(
                      key: ValueKey('paddle_$_restartKey'),
                      game: PaddleClashGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, PaddleClashGame g) => UniversalGameOver(
                            gameTitle: 'Paddle Clash',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
        'LUDO CLUB',
        Icons.casino,
        Colors.red,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LudoSetupScreen()),
        ),
      ),
      _GameDef(
          'FLAPPY BIRD',
          Icons.flutter_dash,
          Colors.cyan,
          () => _startGame(
              context,
              'Flappy Bird',
              (d) => GameWidget(
                      key: ValueKey('flappy_$_restartKey'),
                      game: FlappyBirdGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, FlappyBirdGame g) => UniversalGameOver(
                            gameTitle: 'Flappy Bird',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'BABY CROSSING',
          Icons.child_care,
          Colors.pink,
          () => _startGame(
              context,
              'Baby Crossing',
              (d) => GameWidget(
                      key: ValueKey('baby_$_restartKey'),
                      game: BabyCrossingGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, BabyCrossingGame g) =>
                            UniversalGameOver(
                                gameTitle: 'Baby Crossing',
                                score: g.score,
                                isVictory: g.playerWon,
                                onContinue: g.playerWon
                                    ? null
                                    : () => _showRewardedAdAndContinue(
                                        c, g.resumeGame),
                                onRestart: g.restart,
                                onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'MUSIC TILES',
          Icons.music_note,
          Colors.deepPurpleAccent,
          () => _startGame(
              context,
              'Music Tiles',
              (d) => GameWidget(
                      key: ValueKey('music_$_restartKey'),
                      game: MusicTilesGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, MusicTilesGame g) => UniversalGameOver(
                            gameTitle: 'Music Tiles',
                            score: g.score,
                            onRestart: g.restart,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onHome: () => Navigator.pop(c))
                      }),
              bypassDifficulty: true)),
      _GameDef(
          'NEON SNAKE',
          Icons.gesture,
          Colors.greenAccent,
          () => _startGame(
              context,
              'Neon Snake',
              (d) => GameWidget(
                      key: ValueKey('snake_$_restartKey'),
                      game: NeonSnakeGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, NeonSnakeGame g) =>
                            UniversalGameOver(
                                gameTitle: 'Neon Snake',
                                score: g.score,
                                onContinue: () =>
                                    _showRewardedAdAndContinue(c, g.resumeGame),
                                onRestart: g.restart,
                                onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          '2048 ARCADE',
          Icons.grid_3x3,
          Colors.orangeAccent,
          () => _startGame(
              context,
              '2048 Arcade',
              (d) => GameWidget(
                      key: ValueKey('2048_$_restartKey'),
                      game: Game2048(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, Game2048 g) => UniversalGameOver(
                            gameTitle: '2048 Arcade',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }),
              bypassDifficulty: true)),

      _GameDef(
          'GLOW HOCKEY',
          Icons.sports_hockey,
          Colors.cyanAccent,
          () => _startGame(
              context,
              'Glow Hockey',
              (d) => GameWidget(
                      key: ValueKey('glow_$_restartKey'),
                      game: GlowHockeyGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, GlowHockeyGame g) => UniversalGameOver(
                            gameTitle: 'Glow Hockey',
                            score: g.playerScore,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'BOUNCE BALL',
          Icons.circle_outlined,
          Colors.pinkAccent,
          () => _startGame(
              context,
              'Bounce Ball',
              (d) => GameWidget(
                      key: ValueKey('bounce_$_restartKey'),
                      game: BounceBallGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, BounceBallGame g) => UniversalGameOver(
                            gameTitle: 'Bounce Ball',
                            score: g.score,
                            isVictory: g.bricks.every((b) => b.isDestroyed),
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onNextLevel: g.nextLevel,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'PAC NEON',
          Icons.vignette,
          Colors.yellow,
          () => _startGame(
              context,
              'Pac Neon',
              (d) => GameWidget(
                      key: ValueKey('pac_$_restartKey'),
                      game: PacNeonGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, PacNeonGame g) => UniversalGameOver(
                            gameTitle: 'Pac Neon',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'TENNIS',
          Icons.sports_tennis,
          Colors.greenAccent,
          () => _startGame(
              context,
              'Tennis',
              (d) => GameWidget(
                      key: ValueKey('tennis_$_restartKey'),
                      game: TennisGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, TennisGame g) => UniversalGameOver(
                            gameTitle: 'Tennis',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'UNO RUSH',
          Icons.casino,
          Colors.blueAccent,
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => UnoConfigScreen(
                      onStart: (totalPlayers, difficulty) => _startGame(
                          context,
                          'Uno Rush',
                          (selectedDifficulty) => GameWidget(
                                  key: ValueKey('uno_$_restartKey'),
                                  game: UnoLightGame(
                                      difficulty: selectedDifficulty,
                                      botCount: totalPlayers - 1),
                                  overlayBuilderMap: {
                                    'GameOver': (c, UnoLightGame g) =>
                                        UniversalGameOver(
                                            gameTitle: 'Uno Rush',
                                            score: g.score,
                                            isVictory: g.playerWon,
                                            onContinue: () =>
                                                _showRewardedAdAndContinue(c, g.resumeGame),
                                            onRestart: g.restart,
                                            onHome: () => Navigator.pop(c))
                                  }),
                          bypassDifficulty: true,
                          defaultDifficulty: difficulty))))),
      _GameDef(
          'SOLDIER SOLITAIRE',
          Icons.view_column,
          Colors.amber,
          () => _startGame(
              context,
              'Soldier Solitaire',
              (d) => GameWidget(
                      key: ValueKey('soldier_$_restartKey'),
                      game: SolitaireGame(difficulty: d as GameDifficulty),
                      initialActiveOverlays: const ['SolitaireControls'],
                      overlayBuilderMap: {
                        'DeadEnd': (c, SolitaireGame g) => Positioned.fill(
                            child: Container(
                              color: Colors.black54,
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24, width: 2)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('No More Possible Cards', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.undo),
                                          label: const Text('Undo Last Move', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                          onPressed: () {
                                            g.undoLastMove();
                                            g.overlays.remove('DeadEnd');
                                            g.resumeGame();
                                          },
                                        ),
                                        const SizedBox(width: 16),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.fast_rewind),
                                          label: const Text('Undo All', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                                          onPressed: () {
                                            g.undoAllMoves();
                                            g.overlays.remove('DeadEnd');
                                            g.resumeGame();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )),
                        'GameOver': (c, SolitaireGame g) => UniversalGameOver(
                            gameTitle: 'Soldier Solitaire',
                            score: 0,
                            isVictory: true,
                            scoreLabel: 'VICTORY',
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c)),
                        'SolitaireControls': (c, SolitaireGame g) => Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(40)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.undo, color: Colors.white),
                                      onPressed: () => g.undoLastMove(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.fast_rewind, color: Colors.orangeAccent),
                                      onPressed: () => g.undoAllMoves(),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.lightbulb, color: Colors.yellowAccent),
                                      onPressed: () => g.showHint(),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      }),
              bypassDifficulty: true)),
      _GameDef(
          'STACK BUILDER',
          Icons.layers,
          Colors.indigoAccent,
          () => _startGame(
              context,
              'Stack Builder',
              (d) => GameWidget(
                      key: ValueKey('stackb_$_restartKey'),
                      game: StackBuilderGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, StackBuilderGame g) =>
                            UniversalGameOver(
                                gameTitle: 'Stack Builder',
                                score: g.score,
                                onContinue: () =>
                                    _showRewardedAdAndContinue(c, g.resumeGame),
                                onRestart: g.restart,
                                onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'CAR PARKING',
          Icons.local_parking,
          Colors.blueGrey,
          () => _startGame(
              context,
              'Car Parking',
              (d) => GameWidget(
                      key: ValueKey('car_$_restartKey'),
                      game: CarParkingGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, CarParkingGame g) => UniversalGameOver(
                            gameTitle: 'Car Parking',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'BOY VS GIRL',
          Icons.face,
          Colors.pinkAccent,
          () => _startBoyVsGirl(context)),
      _GameDef(
          'SMASH HIT',
          Icons.gavel,
          Colors.cyan,
          () => _startGame(
              context,
              'Smash Hit',
              (d) => GameWidget(
                      key: ValueKey('smash_$_restartKey'),
                      game: SmashHitGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, SmashHitGame g) => UniversalGameOver(
                            gameTitle: 'Smash Hit',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'BALL BLAST',
          Icons.track_changes,
          Colors.indigo,
          () => _startGame(
              context,
              'Ball Blast',
              (d) => GameWidget(
                      key: ValueKey('blast_$_restartKey'),
                      game: BallBlastGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, BallBlastGame g) => UniversalGameOver(
                            gameTitle: 'Ball Blast',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'ANGRY WEAPON',
          Icons.gps_fixed,
          Colors.redAccent,
          () => _startGame(
              context,
              'Angry Weapon',
              (d) => GameWidget(
                      key: ValueKey('angry_$_restartKey'),
                      game: AngryWeaponGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, AngryWeaponGame g) => UniversalGameOver(
                            gameTitle: 'Angry Weapon',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'AQUAPARK',
          Icons.pool,
          Colors.blue,
          () => _startGame(
              context,
              'Aquapark',
              (d) => GameWidget(
                      key: ValueKey('aqua_$_restartKey'),
                      game: AquaparkGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, AquaparkGame g) => UniversalGameOver(
                            gameTitle: 'Aquapark',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'CRAZY RUN',
          Icons.run_circle,
          Colors.orange,
          () => _startGame(
              context,
              'Crazy Run',
              (d) => GameWidget(
                      key: ValueKey('crazy_$_restartKey'),
                      game: CrazyRunGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, CrazyRunGame g) => UniversalGameOver(
                            gameTitle: 'Crazy Run',
                            score: g.score ~/ 10,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'CYBER RUNNER',
          Icons.bolt,
          Colors.cyan,
          () => _startGame(
              context,
              'Cyber Runner',
              (d) => GameWidget(
                      key: ValueKey('cyber_$_restartKey'),
                      game: CyberRunnerGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, CyberRunnerGame g) => UniversalGameOver(
                            gameTitle: 'Cyber Runner',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'ISLAND JUMP',
          Icons.landscape,
          Colors.green,
          () => _startGame(
              context,
              'Island Jump',
              (d) => GameWidget(
                      key: ValueKey('island_$_restartKey'),
                      game: IslandJumpGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, IslandJumpGame g) => UniversalGameOver(
                            gameTitle: 'Island Jump',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'MAGNET KNIGHT',
          Icons.shield,
          Colors.blueGrey,
          () => _startGame(
              context,
              'Magnet Knight',
              (d) => GameWidget(
                      key: ValueKey('magnet_$_restartKey'),
                      game: MagnetKnightGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, MagnetKnightGame g) =>
                            UniversalGameOver(
                                gameTitle: 'Magnet Knight',
                                score: g.score,
                                onContinue: () =>
                                    _showRewardedAdAndContinue(c, g.resumeGame),
                                onRestart: g.restart,
                                onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'PIXEL WORDS',
          Icons.restaurant_menu,
          Colors.orange,
          () => _startGame(
              context,
              'Pixel Words',
              (d) => GameWidget(
                      key: ValueKey('pixel_$_restartKey'),
                      game: PixelWordsGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, PixelWordsGame g) => UniversalGameOver(
                            gameTitle: 'Pixel Words',
                            score: g.ordersCompleted,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'SHORTCUT SLIDER',
          Icons.linear_scale,
          Colors.blue,
          () => _startGame(
              context,
              'Shortcut Slider',
              (d) => GameWidget(
                      key: ValueKey('shortcut_$_restartKey'),
                      game: ShortcutSliderGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, ShortcutSliderGame g) =>
                            UniversalGameOver(
                                gameTitle: 'Shortcut Slider',
                                score: g.score,
                                onContinue: () =>
                                    _showRewardedAdAndContinue(c, g.resumeGame),
                                onRestart: g.restart,
                                onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'SLIDE SHAKES',
          Icons.liquor,
          Colors.pink,
          () => _startGame(
              context,
              'Slide Shakes',
              (d) => GameWidget(
                      key: ValueKey('slide_$_restartKey'),
                      game: SlideShakesGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, SlideShakesGame g) => UniversalGameOver(
                            gameTitle: 'Slide Shakes',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'TINY ROYALE',
          Icons.military_tech,
          Colors.red,
          () => _startGame(
              context,
              'Tiny Royale',
              (d) => GameWidget(
                      key: ValueKey('tiny_$_restartKey'),
                      game: TinyRoyaleGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, TinyRoyaleGame g) => UniversalGameOver(
                            gameTitle: 'Tiny Royale',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'VAMPIRE JOB',
          Icons.nightlight,
          Colors.deepPurple,
          () => _startGame(
              context,
              'Vampire Job',
              (d) => GameWidget(
                      key: ValueKey('vampire_$_restartKey'),
                      game: VampireJobGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, VampireJobGame g) => UniversalGameOver(
                            gameTitle: 'Vampire Job',
                            score: g.coffeeCount,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'ZOMBIE RESCUE',
          Icons.medical_services,
          Colors.green,
          () => _startGame(
              context,
              'Zombie Rescue',
              (d) => GameWidget(
                      key: ValueKey('zombieres_$_restartKey'),
                      game: ZombieRescueGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, ZombieRescueGame g) =>
                            UniversalGameOver(
                                gameTitle: 'Zombie Rescue',
                                score: g.score,
                                onContinue: () =>
                                    _showRewardedAdAndContinue(c, g.resumeGame),
                                onRestart: g.restart,
                                onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'NUMBER MERGE',
          Icons.join_inner,
          Colors.orangeAccent,
          () => _startGame(
              context,
              'Number Merge',
              (d) => GameWidget(
                      key: ValueKey('number_$_restartKey'),
                      game: NumberMergeGame(difficulty: d),
                      overlayBuilderMap: {
                        'GameOver': (c, NumberMergeGame g) => UniversalGameOver(
                            gameTitle: 'Number Merge',
                            score: g.score,
                            onContinue: () =>
                                _showRewardedAdAndContinue(c, g.resumeGame),
                            onRestart: g.restart,
                            onHome: () => Navigator.pop(c))
                      }))),
      _GameDef(
          'PUZZLE BLACKSMITH',
          Icons.construction,
          Colors.orange,
          () => _startGame(
              context,
              'Puzzle Blacksmith',
              (d) => GameWidget(
                  key: ValueKey('blacksmith_$_restartKey'),
                  game: PuzzleBlacksmithGame(difficulty: d),
                  overlayBuilderMap: {
                    'GameOver': (c, PuzzleBlacksmithGame g) => UniversalGameOver(
                        gameTitle: 'Puzzle Blacksmith',
                        score: g.weaponsForged,
                        scoreLabel: 'FORGED',
                        onContinue: () => _showRewardedAdAndContinue(c, g.resumeGame),
                        onRestart: g.restart,
                        onHome: () => Navigator.pop(c)),
                  }),
              bypassDifficulty: false)),
    ];
  }
}


class _GameDef {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? imageAsset;
  _GameDef(this.title, this.icon, this.color, this.onTap, {this.imageAsset});
}

class _CinematicRoute extends PageRouteBuilder {
  final WidgetBuilder builder;
  _CinematicRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleCurve =
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
            final fadeCurve =
                CurvedAnimation(parent: animation, curve: Curves.easeIn);
            return ScaleTransition(
              scale: Tween<double>(begin: 0.85, end: 1.0).animate(scaleCurve),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(fadeCurve),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: (1.0 - animation.value) * 15,
                      sigmaY: (1.0 - animation.value) * 15),
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
}
