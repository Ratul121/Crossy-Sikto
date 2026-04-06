import 'dart:async';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../game/game_state.dart';
import '../game/lane.dart';
import '../game/player.dart';
import '../rendering/game_painter.dart';
import '../ui/hud_overlay.dart';
import '../ui/menu_screen.dart';
import '../ui/game_over_screen.dart';
import '../ui/settings_panel.dart';

class CrossyGame extends StatefulWidget {
  const CrossyGame({super.key});

  @override
  State<CrossyGame> createState() => _CrossyGameState();
}

class _CrossyGameState extends State<CrossyGame> with TickerProviderStateMixin {
  // ── Game state ──────────────────────────────────────────────────────────────
  GameState _state = GameState.menu;
  late List<Lane> _lanes;
  late Player _player;
  late WorldGenerator _gen;

  double _scrollOffset = 0.0;
  double _targetScrollOffset = 0.0;
  static const double _scrollSpeed = 2.5; // Reduced from 8.0 for a much softer, smoother camera pan
  int _score = 0;
  int _highScore = 0;
  int _furthestLane = 0;
  double _gameTime = 0.0; // total elapsed play time (for animations)
  bool _showStarFlash = false; // brief flash when collecting a star
  double _starFlashTimer = 0.0;

  // ── Sizes ────────────────────────────────────────────────────────────────────
  double _sw = 1280;
  double _sh = 720;
  double get _cellW => _sw / WorldGenerator.numCols;

  // ── Game loop ────────────────────────────────────────────────────────────────
  late Ticker _ticker;
  Duration _lastTick = Duration.zero;

  // Death/respawn state
  bool _deathPaused = false;
  bool _isPaused = false;
  Timer? _deathTimer;

  // Collision cooldown: don't re-check immediately after landing
  // (gives player a brief grace period so just landing on a road tile
  //  doesn't instantly kill you before you can see where you are)
  double _collisionGraceTimer = 0.0;
  static const double _collisionGraceSeconds = 0.12;

  // Input
  final List<LogicalKeyboardKey> _inputQueue = [];

  ui.Image? _playerImage;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  final List<AudioPlayer> _starPlayers = List.generate(3, (_) => AudioPlayer());
  int _starPlayerIdx = 0;

  static double globalVolume = 1.0;
  static double _lastUnmutedVolume = 1.0;
  int _menuSelection = 0; // 0 = play, 1 = settings

  void _updateVolumes() {
    _bgMusicPlayer.setVolume(0.5 * globalVolume);
    _audioPlayer.setVolume(1.0 * globalVolume);
    for (final p in _starPlayers) {
      p.setVolume(1.0 * globalVolume);
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Configure the SFX player NOT to request audio focus
    final sfxContext = AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
    );
    
    _audioPlayer.setAudioContext(sfxContext);
    for (final p in _starPlayers) {
      p.setAudioContext(sfxContext);
    }

    _gen = WorldGenerator();
    _ticker = createTicker(_onTick)..start();
    _loadPlayerImage();
  }

  Future<void> _startBgMusic() async {
    try {
      await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgMusicPlayer.play(AssetSource('audio/bg.mp3'), volume: 0.5 * globalVolume);
    } catch (e) {
      debugPrint('Error starting bg music: $e');
    }
  }

  Future<void> _loadPlayerImage() async {
    try {
      final ByteData data = await rootBundle.load('assets/img/sikto.png');
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 100);
      final ui.FrameInfo fi = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _playerImage = fi.image;
        });
      }
    } catch (e) {
      debugPrint('Error loading custom player image: $e');
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _deathTimer?.cancel();
    _audioPlayer.dispose();
    _bgMusicPlayer.dispose();
    for (final p in _starPlayers) {
      p.dispose();
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Game loop
  // ─────────────────────────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    if (_state != GameState.playing || _deathPaused || _isPaused) {
      _lastTick = elapsed;
      return;
    }

    final dt = ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = elapsed;

    // Update obstacles
    for (final lane in _lanes) {
      lane.update(dt, _sw);
    }
    _gameTime += dt;

    // Tick star flash
    if (_showStarFlash) {
      _starFlashTimer -= dt;
      if (_starFlashTimer <= 0) _showStarFlash = false;
    }

    // Auto-scroll the camera over time (faster as difficulty increases)
    final autoScrollSpeed = 15.0 + (_gen.difficulty * 6.0);
    _targetScrollOffset += autoScrollSpeed * dt;

    // Smooth camera: lerp scrollOffset toward target
    if ((_targetScrollOffset - _scrollOffset).abs() > 0.5) {
      _scrollOffset += (_targetScrollOffset - _scrollOffset) * _scrollSpeed * dt;
    } else {
      _scrollOffset = _targetScrollOffset;
    }

    // Check bottom boundary death (crushed by auto-scroll)
    if (!_player.isDying && !_deathPaused) {
      final playerScreenY = _laneScreenY(_player.laneIndex) + _scrollOffset + WorldGenerator.laneHeight / 2;
      if (playerScreenY > _sh + WorldGenerator.laneHeight / 2) {
        _triggerDeath(hitByCar: false);
      }
    }

    // Animate player
    _player.update(dt);

    // Tick down collision grace period while player is hopping
    if (_player.hopProgress < 1.0) {
      _collisionGraceTimer = _collisionGraceSeconds;
    } else {
      _collisionGraceTimer = (_collisionGraceTimer - dt).clamp(0.0, _collisionGraceSeconds);
    }

    // Handle log riding (continuous) and collision once settled + grace expired
    if (_player.hopProgress >= 1.0 && !_player.isDying) {
      // Always ride logs (moves player with log drift every tick)
      _rideLogIfOnRiver(dt);

      // Only check car/water collision after grace period expires
      if (_collisionGraceTimer <= 0.0) {
        _checkCollisions();
      }
    }

    // Process queued input when player has landed
    if (_player.hopProgress >= 1.0 && _inputQueue.isNotEmpty && !_player.isDying && !_deathPaused) {
      _processNextInput();
    }

    _extendWorld();

    setState(() {});
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Init / reset
  // ─────────────────────────────────────────────────────────────────────────────
  void _initGame() {
    _scrollOffset = 0.0;
    _targetScrollOffset = 0.0;
    _score = 0;
    _furthestLane = 0;
    _gameTime = 0.0;
    _showStarFlash = false;
    _starFlashTimer = 0.0;
    _inputQueue.clear();
    _deathPaused = false;
    _collisionGraceTimer = _collisionGraceSeconds; // grace at start
    _lastTick = Duration.zero;

    _lanes = _gen.generate(_sw, _sh);

    // Player starts at lane index 1 (second grass lane from bottom)
    const startLaneIdx = 1;
    final startCol = WorldGenerator.numCols ~/ 2;
    final startX = _cellW * startCol + _cellW / 2;
    final startY = _laneScreenY(startLaneIdx) + WorldGenerator.laneHeight / 2;

    _player = Player(startX: startX, startY: startY);
    _player.col = startCol;
    _player.laneIndex = startLaneIdx;
    _player.currentX = startX;
    _player.currentY = startY;
    _player.prevX = startX;
    _player.prevY = startY;
    _player.hopProgress = 1.0;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Input
  // ─────────────────────────────────────────────────────────────────────────────
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (_state == GameState.menu) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() => _menuSelection = 1);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() => _menuSelection = 0);
        return KeyEventResult.handled;
      } else if (_isSelectKey(event.logicalKey)) {
        if (_menuSelection == 0) {
          setState(() {
            _initGame();
            _state = GameState.playing;
            // Only start music here if we are actually kicking off gameplay
            _startBgMusic();
          });
        } else if (_menuSelection == 1) {
          setState(() {
            _state = GameState.settings;
          });
        }
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (_state == GameState.settings) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          globalVolume = (globalVolume - 0.1).clamp(0.0, 1.0);
          _updateVolumes();
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() {
          globalVolume = (globalVolume + 0.1).clamp(0.0, 1.0);
          _updateVolumes();
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.escape || event.logicalKey == LogicalKeyboardKey.goBack) {
        setState(() => _state = GameState.menu);
        return KeyEventResult.handled;
      } else if (_isSelectKey(event.logicalKey)) {
        setState(() {
          if (globalVolume > 0) {
            _lastUnmutedVolume = globalVolume;
            globalVolume = 0.0;
          } else {
            globalVolume = _lastUnmutedVolume > 0 ? _lastUnmutedVolume : 1.0;
          }
          _updateVolumes();
        });
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }

    if (_state == GameState.dead) {
      if (_isSelectKey(event.logicalKey)) {
        setState(() {
          _initGame();
          _state = GameState.playing;
          _startBgMusic();
        });
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (_state == GameState.playing) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.arrowUp ||
          key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.arrowRight) {
        // Only queue if player is on the ground AND queue is empty
        // This prevents key-repeat from stacking multiple hops
        if (_player.hopProgress >= 1.0 && _inputQueue.isEmpty && !_player.isDying && !_deathPaused) {
          _inputQueue.add(key);
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  bool _isSelectKey(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.select ||
      k == LogicalKeyboardKey.enter ||
      k == LogicalKeyboardKey.space ||
      k == LogicalKeyboardKey.gameButtonA;

  void _processNextInput() {
    if (_inputQueue.isEmpty) return;
    final key = _inputQueue.removeAt(0);

    int newCol = _player.col;
    int newLane = _player.laneIndex;

    if (key == LogicalKeyboardKey.arrowUp) newLane++;
    if (key == LogicalKeyboardKey.arrowDown) newLane = (newLane - 1).clamp(0, _lanes.length - 1);
    if (key == LogicalKeyboardKey.arrowLeft) newCol = (newCol - 1).clamp(0, WorldGenerator.numCols - 1);
    if (key == LogicalKeyboardKey.arrowRight) newCol = (newCol + 1).clamp(0, WorldGenerator.numCols - 1);

    newLane = newLane.clamp(0, _lanes.length - 1);

    _player.col = newCol;
    _player.laneIndex = newLane;

    final targetX = _cellW * newCol + _cellW / 2;
    final targetY = _laneScreenY(newLane) + WorldGenerator.laneHeight / 2;

    _player.jumpTo(targetX, targetY);

    // Grace period restarts on each hop
    _collisionGraceTimer = _collisionGraceSeconds;

    // Score: only going to a lane you haven't reached before
    if (newLane > _furthestLane) {
      _furthestLane = newLane;
      _score++;
      // Update difficulty based on new score
      _gen.setDifficulty(_score);
    }

    // Check collectible on this lane
    if (newLane < _lanes.length) {
      final c = _lanes[newLane].collectAt(
        _cellW * newCol + _cellW / 2,
        _laneScreenY(newLane) + WorldGenerator.laneHeight / 2,
      );
      if (c != null) {
        c.collected = true;
        _score++;
        
        final sp = _starPlayers[_starPlayerIdx];
        sp.play(AssetSource('audio/star.mp3'));
        _starPlayerIdx = (_starPlayerIdx + 1) % _starPlayers.length;
      }
    }

    _updateScroll();
  }

  void _updateScroll() {
    // Compute where the player will be on screen with current scroll
    final playerScreenY = _laneScreenY(_player.laneIndex) + _targetScrollOffset + WorldGenerator.laneHeight / 2;
    final target = _sh * 0.45;
    if (playerScreenY < target) {
      // Shift target scroll so player lands at 45% from top
      _targetScrollOffset += target - playerScreenY;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Log riding (runs every tick the player is on a river lane)
  // ─────────────────────────────────────────────────────────────────────────────
  void _rideLogIfOnRiver(double dt) {
    if (_player.laneIndex >= _lanes.length) return;
    final lane = _lanes[_player.laneIndex];
    if (lane.type != LaneType.river) return;

    final px = _player.currentX;
    final py = _laneScreenY(_player.laneIndex) + WorldGenerator.laneHeight / 2;
    final log = lane.logAt(px, py);

    if (log != null) {
      // Drift player with the log (no clamping!)
      final newX = _player.currentX + log.speed * dt;
      _player.currentX = newX;
      _player.prevX = newX;
      _player.col = ((newX - _cellW / 2) / _cellW).round();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Collision (only called when settled AND grace period over)
  // ─────────────────────────────────────────────────────────────────────────────
  void _checkCollisions() {
    if (_player.laneIndex >= _lanes.length) return;
    final lane = _lanes[_player.laneIndex];
    final px = _player.currentX;
    final py = _laneScreenY(_player.laneIndex) + WorldGenerator.laneHeight / 2;

    if (lane.type == LaneType.road) {
      if (lane.collidesAt(px, py, WorldGenerator.laneHeight * 0.8)) {
        _triggerDeath(hitByCar: true);
      }
    } else if (lane.type == LaneType.river) {
      // Out of bounds on river (rode log off screen)
      if (px < -_cellW / 2 || px > _sw + _cellW / 2) {
        _triggerDeath(hitByCar: false);
        return;
      }
      // If not on any log → fell in water
      final log = lane.logAt(px, py);
      if (log == null) {
        _triggerDeath(hitByCar: false);
      }
    }
  }

  void _triggerDeath({required bool hitByCar}) {
    if (_player.isDying) return;

    _audioPlayer.play(AssetSource('audio/die.mp3'));

    _player.isDying = true;
    _player.hitByCar = hitByCar; // used by painter for squish direction

    _deathPaused = true;
    _deathTimer = Timer(const Duration(milliseconds: 1000), () {
      if (_score > _highScore) _highScore = _score;
      _bgMusicPlayer.stop();
      _audioPlayer.play(AssetSource('audio/game_over.mp3'));
      setState(() => _state = GameState.dead);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────────
  double _laneScreenY(int laneIndex) {
    return _sh - (laneIndex + 1) * WorldGenerator.laneHeight;
  }

  void _extendWorld() {
    final topNeeded = _player.laneIndex + 12;
    while (_lanes.length < topNeeded) {
      final idx = _lanes.length;
      final y = _sh - (idx + 1) * WorldGenerator.laneHeight;
      _lanes.add(_gen.addLane(idx, y, _sw));
    }
  }

  void _showQuitConfirmation() {
    setState(() => _isPaused = true);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.white24, width: 3),
            borderRadius: BorderRadius.circular(16)
          ),
          title: const Text('Quit to Menu?', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          content: const Text('Your current run will be lost.', style: TextStyle(color: Colors.white70, fontSize: 24)),
          actions: [
            TextButton(
              child: const Text('NO', style: TextStyle(fontSize: 24, color: Colors.white70)),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              autofocus: true,
              child: const Text('YES', style: TextStyle(fontSize: 24, color: Colors.amber)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  _bgMusicPlayer.stop();
                  _state = GameState.menu;
                  _isPaused = false;
                });
              },
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted && _state == GameState.playing) {
        setState(() => _isPaused = false);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _sw = constraints.maxWidth;
      _sh = constraints.maxHeight;

      return PopScope(
        canPop: _state == GameState.menu,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_state == GameState.settings) {
            setState(() => _state = GameState.menu);
          } else if (_state == GameState.dead) {
            setState(() {
              _state = GameState.menu;
              _bgMusicPlayer.stop();
            });
          } else if (_state == GameState.playing && !_deathPaused) {
            _showQuitConfirmation();
          }
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: _handleKey,
        child: Stack(
          children: [
            if (_state == GameState.playing || _state == GameState.dead)
              CustomPaint(
                size: Size(_sw, _sh),
                painter: GamePainter(
                  lanes: _lanes,
                  player: _player,
                  scrollOffset: _scrollOffset,
                  score: _score,
                  highScore: _highScore,
                  screenWidth: _sw,
                  screenHeight: _sh,
                  gameTime: _gameTime,
                  playerImage: _playerImage,
                ),
              ),

            if (_state == GameState.playing)
              HudOverlay(
                score: _score,
                highScore: _highScore,
                showStarFlash: _showStarFlash,
              ),

            if (_state == GameState.menu) MenuScreen(selectedIndex: _menuSelection),
            if (_state == GameState.settings) SettingsPanel(volume: globalVolume),

            if (_state == GameState.dead)
              GameOverScreen(
                score: _score,
                highScore: _highScore,
                isNewHighScore: _score >= _highScore && _score > 0,
              ),
          ],
        ),
      ));
    });
  }
}
