import 'package:flutter/material.dart';
import '../rendering/color_palette.dart';

class GameOverScreen extends StatefulWidget {
  final int score;
  final int highScore;
  final bool isNewHighScore;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.highScore,
    required this.isNewHighScore,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

// Single controller drives both scale-in and continuous pulse using intervals
class _GameOverScreenState extends State<GameOverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    // Phase 1: 0..600ms = elastic scale-in. Phase 2: 600..∞ = pulse via repeat
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.67, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GameColors.overlayBg,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💀', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              const Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 4,
                  shadows: [Shadow(color: Colors.red, blurRadius: 0, offset: Offset(4, 4))],
                ),
              ),
              const SizedBox(height: 24),
              if (widget.isNewHighScore) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: GameColors.titleYellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GameColors.titleYellow, width: 2),
                  ),
                  child: const Text(
                    '🏆  NEW HIGH SCORE!',
                    style: TextStyle(color: GameColors.titleYellow, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statBox('SCORE', '${widget.score}'),
                  const SizedBox(width: 24),
                  _statBox('BEST', '${widget.highScore}'),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white10,
                ),
                child: const Text(
                  '▶  Press SELECT to Play Again',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 16, letterSpacing: 2)),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
