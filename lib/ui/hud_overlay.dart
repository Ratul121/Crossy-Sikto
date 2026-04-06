import 'package:flutter/material.dart';

class HudOverlay extends StatelessWidget {
  final int score;
  final int highScore;
  final bool showStarFlash;

  const HudOverlay({
    super.key,
    required this.score,
    required this.highScore,
    this.showStarFlash = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main HUD bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.72), Colors.transparent],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SCORE', style: _labelStyle),
                    Text('$score', style: _valueStyle),
                  ],
                ),
                // High Score
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('BEST', style: _labelStyle),
                    Text('$highScore', style: _valueStyle),
                  ],
                ),
              ],
            ),
          ),
        ),

      ],
    );
  }

  static const _labelStyle = TextStyle(
    color: Colors.white60,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
  );
  static const _valueStyle = TextStyle(
    color: Colors.white,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: 1,
  );
}
