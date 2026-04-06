import 'package:flutter/material.dart';
import '../rendering/color_palette.dart';

class SettingsPanel extends StatelessWidget {
  final double volume;

  const SettingsPanel({super.key, required this.volume});

  @override
  Widget build(BuildContext context) {
    int bars = (volume * 10).round();
    bool isMuted = bars == 0;

    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
          decoration: BoxDecoration(
            color: GameColors.overlayBg,
            border: Border.all(color: Colors.white24, width: 4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'AUDIO SETTINGS',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                isMuted ? '🔇' : '🔊',
                style: const TextStyle(fontSize: 100),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Less ◄  ', style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(10, (index) {
                      bool active = index < bars;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 24,
                        height: active ? 64 : 32,
                        decoration: BoxDecoration(
                          color: active ? GameColors.titleYellow : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Text('  ► More', style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('SELECT: Mute  |  UP/BACK: Return', 
                  style: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
