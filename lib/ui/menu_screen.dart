import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../rendering/color_palette.dart';

class MenuScreen extends StatefulWidget {
  final int selectedIndex;

  const MenuScreen({super.key, required this.selectedIndex});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: CustomPaint(painter: _MenuBackgroundPainter()),
        ),
        ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/img/sikto.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              'CROSSY SIKTO',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                color: GameColors.titleYellow,
                letterSpacing: 4,
                shadows: [
                  Shadow(color: GameColors.titleShadow, blurRadius: 0, offset: Offset(4, 4)),
                  Shadow(color: Colors.black45, blurRadius: 12, offset: Offset(2, 6)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Prompt
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMenuButton('▶  Press SELECT to Play', 0),
                  const SizedBox(height: 16),
                  _buildMenuButton('⚙  Settings', 1),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _controlHint('↑ ↓ ← →', 'Move chicken'),
            const SizedBox(height: 8),
            _controlHint('SELECT', 'Start / Restart'),
          ],
        ),
      ),
    ),
    ),
    ),
      ],
    );
  }

  Widget _buildMenuButton(String label, int index) {
    final isSelected = widget.selectedIndex == index;
    final scale = isSelected ? _pulseAnim.value : 1.0;
    
    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? GameColors.titleYellow : Colors.white24,
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? GameColors.titleYellow.withOpacity(0.12) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 26,
            color: isSelected ? GameColors.titleYellow : Colors.white54,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _controlHint(String key, String desc) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 18)),
      ],
    );
  }
}

class _MenuBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grassPaint = Paint()..color = const Color(0xFF7CB342); // light green
    final roadPaint = Paint()..color = const Color(0xFF424242);  // dark grey
    final carPaintRed = Paint()..color = Colors.red;
    final carPaintBlue = Paint()..color = Colors.blue;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), grassPaint);

    double laneH = 60.0;
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.3, size.width, laneH * 2), roadPaint);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.7, size.width, laneH), roadPaint);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.2, size.height * 0.3 + 10, 80, 40), const Radius.circular(8)), carPaintRed);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.6, size.height * 0.3 + 70, 80, 40), const Radius.circular(8)), carPaintBlue);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.4, size.height * 0.7 + 10, 80, 40), const Radius.circular(8)), carPaintRed);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
