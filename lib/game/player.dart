import 'dart:ui';

class Player {
  // Grid position
  int col;
  int laneIndex;

  // Animation lerp
  double prevX;
  double prevY;
  double currentX;
  double currentY;

  double hopProgress = 1.0;
  static const double hopDuration = 0.15;

  // Death
  bool isDying = false;
  bool hitByCar = false; // true = squish sideways, false (water) = squish flat
  double deathAnimProgress = 0.0;
  static const double deathAnimDuration = 0.5;

  Player({required double startX, required double startY, int cols = 9})
      : col = cols ~/ 2,
        laneIndex = 0,
        prevX = startX,
        prevY = startY,
        currentX = startX,
        currentY = startY;

  void jumpTo(double x, double y) {
    prevX = currentX;
    prevY = currentY;
    currentX = x;
    currentY = y;
    hopProgress = 0.0;
  }

  void update(double dt) {
    if (hopProgress < 1.0) {
      hopProgress = (hopProgress + dt / hopDuration).clamp(0.0, 1.0);
    }
    if (isDying) {
      deathAnimProgress = (deathAnimProgress + dt / deathAnimDuration).clamp(0.0, 1.0);
    }
  }

  Offset get visualPosition {
    final t = _easeOutQuad(hopProgress);
    return Offset(
      lerpDouble(prevX, currentX, t)!,
      lerpDouble(prevY, currentY, t)!,
    );
  }

  double get hopArcOffset {
    if (hopProgress >= 1.0) return 0.0;
    final t = hopProgress;
    return -20.0 * 4 * t * (1 - t);
  }

  // Squish scale based on death type and progress
  double get squishScaleX {
    if (!isDying) return 1.0;
    final t = deathAnimProgress;
    return hitByCar ? (1.0 + t * 0.7) : (1.0 - t * 0.3); // car: widen; water: compress
  }

  double get squishScaleY {
    if (!isDying) return 1.0;
    final t = deathAnimProgress;
    return hitByCar ? (1.0 - t * 0.8) : (1.0 - t * 0.65); // both: flatten
  }

  double get squishOpacity {
    if (!isDying) return 1.0;
    if (deathAnimProgress < 0.7) return 1.0;
    return 1.0 - ((deathAnimProgress - 0.7) / 0.3);
  }

  static double _easeOutQuad(double t) => 1 - (1 - t) * (1 - t);
}
