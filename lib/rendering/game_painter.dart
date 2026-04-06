import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../game/lane.dart';
import '../game/player.dart';
import '../rendering/color_palette.dart';

class GamePainter extends CustomPainter {
  final List<Lane> lanes;
  final Player player;
  final double scrollOffset;
  final int score;
  final int highScore;
  final double screenWidth;
  final double screenHeight;
  final double gameTime; // used for animations
  final ui.Image? playerImage;

  GamePainter({
    required this.lanes,
    required this.player,
    required this.scrollOffset,
    required this.score,
    required this.highScore,
    required this.screenWidth,
    required this.screenHeight,
    this.gameTime = 0,
    this.playerImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawLanes(canvas, size);
    _drawCollectibles(canvas);
    _drawObstacles(canvas);
    _drawPlayer(canvas);
  }

  // ─── Lanes ─────────────────────────────────────────────────────────────────
  void _drawLanes(Canvas canvas, Size size) {
    final paint = Paint();
    for (int i = 0; i < lanes.length; i++) {
      final lane = lanes[i];
      final laneY = lane.y + scrollOffset;
      if (laneY > size.height + WorldGenerator.laneHeight * 2) continue;
      if (laneY < -WorldGenerator.laneHeight * 2) continue;

      final rect = Rect.fromLTWH(0, laneY, size.width, WorldGenerator.laneHeight);

      switch (lane.type) {
        case LaneType.grass:
          paint.color = i.isEven ? GameColors.grassLight : GameColors.grassDark;
          canvas.drawRect(rect, paint);
          // Grass texture stripes
          paint.color = GameColors.grassStripe.withValues(alpha: 0.25);
          for (double sx = 0; sx < size.width; sx += 28) {
            canvas.drawRect(Rect.fromLTWH(sx, laneY + 8, 12, WorldGenerator.laneHeight - 16), paint);
          }
          // Tiny random flowers
          paint.color = GameColors.flowerPink.withValues(alpha: 0.7);
          final seed = (i * 137) % 1000;
          for (int f = 0; f < 5; f++) {
            final fx = ((seed + f * 211) % 1000) / 1000.0 * size.width;
            final fy = laneY + 14 + (f % 3) * 18.0;
            canvas.drawCircle(Offset(fx, fy), 4, paint);
          }
          break;

        case LaneType.road:
          paint.color = i.isEven ? GameColors.road : GameColors.roadStripe;
          canvas.drawRect(rect, paint);
          // Pavement edge lines
          paint.color = GameColors.pavement.withValues(alpha: 0.4);
          canvas.drawRect(Rect.fromLTWH(0, laneY, size.width, 4), paint);
          canvas.drawRect(Rect.fromLTWH(0, laneY + WorldGenerator.laneHeight - 4, size.width, 4), paint);
          // Dashed center line
          paint.color = GameColors.roadLine.withValues(alpha: 0.55);
          paint.strokeWidth = 3;
          paint.style = PaintingStyle.stroke;
          const dashW = 32.0, gapW = 22.0;
          double dx = 0;
          while (dx < size.width) {
            canvas.drawLine(
              Offset(dx, laneY + WorldGenerator.laneHeight / 2),
              Offset(min(dx + dashW, size.width), laneY + WorldGenerator.laneHeight / 2),
              paint,
            );
            dx += dashW + gapW;
          }
          paint.style = PaintingStyle.fill;
          break;

        case LaneType.river:
          paint.color = i.isEven ? GameColors.riverLight : GameColors.riverDark;
          canvas.drawRect(rect, paint);
          // Animated ripples using gameTime
          paint.color = Colors.white.withValues(alpha: 0.12);
          for (double rx = (-gameTime * 30) % 80; rx < size.width; rx += 80) {
            canvas.drawOval(
              Rect.fromCenter(center: Offset(rx, laneY + WorldGenerator.laneHeight * 0.4), width: 50, height: 10),
              paint,
            );
            canvas.drawOval(
              Rect.fromCenter(center: Offset(rx + 40, laneY + WorldGenerator.laneHeight * 0.7), width: 34, height: 7),
              paint,
            );
          }
          break;
      }
    }
  }

  // ─── Collectible Stars ──────────────────────────────────────────────────────
  void _drawCollectibles(Canvas canvas) {
    final paint = Paint();
    for (final lane in lanes) {
      final laneScreenY = lane.y + scrollOffset;
      if (laneScreenY > screenHeight + WorldGenerator.laneHeight) continue;
      if (laneScreenY < -WorldGenerator.laneHeight * 2) continue;

      for (final c in lane.collectibles) {
        if (c.collected) continue;
        final cy = c.y + scrollOffset;
        final bob = sin(c.pulsePhase) * 3.0;

        // Glow
        paint.color = GameColors.starGlow.withValues(alpha: 0.4);
        canvas.drawCircle(Offset(c.x, cy + bob), 22, paint);

        // Draw 5-pointed star
        _drawStar(canvas, paint, c.x, cy + bob, 16, 8);
      }
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double cx, double cy, double outerR, double innerR) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = (i * pi / 5) - pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    paint.color = GameColors.starGold;
    canvas.drawPath(path, paint);
    paint.color = GameColors.starOuter;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;
    canvas.drawPath(path, paint);
    paint.style = PaintingStyle.fill;
  }

  // ─── Obstacles ─────────────────────────────────────────────────────────────
  void _drawObstacles(Canvas canvas) {
    final paint = Paint();
    for (final lane in lanes) {
      final laneScreenY = lane.y + scrollOffset;
      if (laneScreenY > screenHeight + WorldGenerator.laneHeight) continue;
      if (laneScreenY < -WorldGenerator.laneHeight * 2) continue;

      for (final obs in lane.obstacles) {
        final obsRect = Rect.fromLTWH(obs.x, obs.y + scrollOffset - obs.height / 2, obs.width, obs.height);

        if (lane.type == LaneType.road) {
          switch (obs.vehicleType) {
            case VehicleType.car:       _drawCar(canvas, paint, obsRect, obs.colorIndex, obs.speed > 0);
            case VehicleType.bus:       _drawBus(canvas, paint, obsRect, obs.speed > 0);
            case VehicleType.truck:     _drawTruck(canvas, paint, obsRect, obs.speed > 0);
            case VehicleType.motorcycle:_drawMotorcycle(canvas, paint, obsRect, obs.colorIndex, obs.speed > 0);
          }
        } else if (lane.type == LaneType.river) {
          switch (obs.riverType) {
            case RiverType.log:         _drawLog(canvas, paint, obsRect);
            case RiverType.lilypad:     _drawLilyPad(canvas, paint, obsRect);
            case RiverType.crocodile:   _drawCrocodile(canvas, paint, obsRect, obs.speed > 0);
          }
        }
      }
    }
  }

  // Car
  void _drawCar(Canvas canvas, Paint paint, Rect rect, int colorIndex, bool facingRight) {
    final color = GameColors.carColors[colorIndex % GameColors.carColors.length];
    paint.color = color;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), paint);

    // Roof
    final roofRect = Rect.fromLTWH(rect.left + rect.width * 0.2, rect.top + 5, rect.width * 0.6, rect.height * 0.42);
    paint.color = color.withValues(alpha: 0.75);
    canvas.drawRRect(RRect.fromRectAndRadius(roofRect, const Radius.circular(8)), paint);

    // Windshield
    final wsX = facingRight ? roofRect.left + 4 : roofRect.left + roofRect.width * 0.35;
    paint.color = GameColors.carWindow.withValues(alpha: 0.9);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(wsX, roofRect.top + 3, roofRect.width * 0.42, roofRect.height - 6),
      const Radius.circular(4)), paint);

    _drawWheels(canvas, paint, rect);
    _drawHeadlights(canvas, paint, rect, facingRight, color);
  }

  // School Bus
  void _drawBus(Canvas canvas, Paint paint, Rect rect, bool facingRight) {
    // Body
    paint.color = GameColors.busYellow;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);

    // Roof strip
    paint.color = GameColors.busDark;
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width, 8), paint);

    // Windows (evenly spaced)
    paint.color = GameColors.carWindow.withValues(alpha: 0.85);
    final winW = 22.0;
    final winH = rect.height * 0.38;
    final winY = rect.top + 12;
    double wx = rect.left + 12;
    while (wx + winW < rect.right - 20) {
      canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(wx, winY, winW, winH), const Radius.circular(4)), paint);
      wx += winW + 8;
    }

    // SCHOOL label
    final tp = TextPainter(
      text: TextSpan(text: 'SCHOOL', style: TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(rect.left + (rect.width - tp.width) / 2, rect.bottom - tp.height - 5));

    _drawWheels(canvas, paint, rect, wheelCount: 4);
  }

  // Truck
  void _drawTruck(Canvas canvas, Paint paint, Rect rect, bool facingRight) {
    // Trailer (back 65%)
    final trailerW = rect.width * 0.62;
    final trailerX = facingRight ? rect.left : rect.left + rect.width * 0.38;
    final trailerRect = Rect.fromLTWH(trailerX, rect.top + 4, trailerW, rect.height - 4);
    paint.color = GameColors.truckBody;
    canvas.drawRRect(RRect.fromRectAndRadius(trailerRect, const Radius.circular(6)), paint);
    // Trailer stripe
    paint.color = Colors.white24;
    canvas.drawRect(Rect.fromLTWH(trailerRect.left + 6, trailerRect.top + trailerRect.height * 0.3,
        trailerRect.width - 12, trailerRect.height * 0.35), paint);

    // Cabin (front 35%)
    final cabinX = facingRight ? rect.right - rect.width * 0.38 : rect.left;
    final cabinRect = Rect.fromLTWH(cabinX, rect.top, rect.width * 0.38, rect.height);
    paint.color = GameColors.truckCabin;
    canvas.drawRRect(RRect.fromRectAndRadius(cabinRect, const Radius.circular(8)), paint);
    // Windshield
    paint.color = GameColors.carWindow.withValues(alpha: 0.85);
    final wsX = facingRight ? cabinRect.left + 6 : cabinRect.left + 4;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(wsX, cabinRect.top + 6, cabinRect.width - 12, cabinRect.height * 0.45),
      const Radius.circular(4)), paint);

    _drawWheels(canvas, paint, rect, wheelCount: 4);
    _drawHeadlights(canvas, paint, rect, facingRight, GameColors.truckCabin);
  }

  // Motorcycle
  void _drawMotorcycle(Canvas canvas, Paint paint, Rect rect, int colorIndex, bool facingRight) {
    final color = GameColors.carColors[colorIndex % GameColors.carColors.length];
    // Body frame
    paint.color = GameColors.motorcycleBody;
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left + rect.width * 0.15, rect.top + rect.height * 0.15, rect.width * 0.7, rect.height * 0.5),
      const Radius.circular(6)), paint);

    // Rider helmet
    paint.color = color;
    canvas.drawCircle(Offset(rect.center.dx, rect.top + rect.height * 0.2), rect.height * 0.28, paint);

    // Visor
    paint.color = Colors.black54;
    canvas.drawRect(Rect.fromLTWH(
      rect.center.dx - 8, rect.top + rect.height * 0.1, 16, 6), paint);

    // Big wheels
    paint.color = GameColors.carWheelDark;
    const wr = 14.0;
    canvas.drawCircle(Offset(rect.left + wr + 2, rect.bottom - 4), wr, paint);
    canvas.drawCircle(Offset(rect.right - wr - 2, rect.bottom - 4), wr, paint);
    paint.color = Colors.grey.shade600;
    canvas.drawCircle(Offset(rect.left + wr + 2, rect.bottom - 4), wr * 0.5, paint);
    canvas.drawCircle(Offset(rect.right - wr - 2, rect.bottom - 4), wr * 0.5, paint);
  }

  // Log
  void _drawLog(Canvas canvas, Paint paint, Rect rect) {
    paint.color = GameColors.logBody;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
    paint.color = GameColors.logRing;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    for (double rx = rect.left + 16; rx < rect.right - 10; rx += 24) {
      canvas.drawOval(Rect.fromCenter(center: Offset(rx, rect.center.dy), width: 14, height: rect.height * 0.6), paint);
    }
    paint.style = PaintingStyle.fill;
    paint.color = GameColors.logHighlight.withValues(alpha: 0.35);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(rect.left + 6, rect.top + 4, rect.width - 12, 7), const Radius.circular(4)), paint);
  }

  // Lily Pad
  void _drawLilyPad(Canvas canvas, Paint paint, Rect rect) {
    // Main pad (oval)
    paint.color = GameColors.lilypadGreen;
    canvas.drawOval(rect, paint);
    // Darker ring
    paint.color = GameColors.lilypadDark;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
    canvas.drawOval(rect.deflate(4), paint);
    paint.style = PaintingStyle.fill;
    // Notch (V cut)
    final notchPath = Path()
      ..moveTo(rect.center.dx, rect.center.dy)
      ..lineTo(rect.center.dx - 10, rect.top + 4)
      ..lineTo(rect.center.dx + 10, rect.top + 4)
      ..close();
    paint.color = GameColors.riverLight.withValues(alpha: 0.6);
    canvas.drawPath(notchPath, paint);
    // Flower in center
    paint.color = GameColors.lilyFlower;
    canvas.drawCircle(rect.center, 8, paint);
    paint.color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(rect.center, 4, paint);
  }

  // Crocodile
  void _drawCrocodile(Canvas canvas, Paint paint, Rect rect, bool facingRight) {
    // Body
    paint.color = GameColors.crocBody;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), paint);

    // Scales pattern
    paint.color = GameColors.crocScale;
    for (double sx = rect.left + 12; sx < rect.right - 10; sx += 18) {
      canvas.drawCircle(Offset(sx, rect.center.dy - 6), 6, paint);
      canvas.drawCircle(Offset(sx + 9, rect.center.dy + 4), 5, paint);
    }

    // Snout
    final snoutX = facingRight ? rect.right - 24 : rect.left;
    final snoutRect = Rect.fromLTWH(snoutX, rect.top + rect.height * 0.3, 24, rect.height * 0.4);
    paint.color = GameColors.crocBody;
    canvas.drawRRect(RRect.fromRectAndRadius(snoutRect, const Radius.circular(6)), paint);

    // Teeth
    paint.color = Colors.white;
    for (int t = 0; t < 3; t++) {
      final tx = snoutRect.left + 4 + t * 7.0;
      final path = Path()
        ..moveTo(tx, snoutRect.top)
        ..lineTo(tx + 3, snoutRect.top - 5)
        ..lineTo(tx + 6, snoutRect.top)
        ..close();
      canvas.drawPath(path, paint);
    }

    // Eyes (yellow with pupil)
    final eyeOffset = facingRight ? rect.right - 38 : rect.left + 22;
    paint.color = GameColors.crocEye;
    canvas.drawCircle(Offset(eyeOffset, rect.top + 6), 7, paint);
    paint.color = Colors.black;
    canvas.drawCircle(Offset(eyeOffset + (facingRight ? 2 : -2), rect.top + 6), 3, paint);
  }

  // Shared wheel helper
  void _drawWheels(Canvas canvas, Paint paint, Rect rect, {int wheelCount = 2}) {
    paint.color = GameColors.carWheelDark;
    const wr = 9.0;
    final positions = wheelCount == 2
        ? [rect.left + 18.0, rect.right - 18.0]
        : [rect.left + 16.0, rect.left + rect.width * 0.38, rect.right - rect.width * 0.38, rect.right - 16.0];
    for (final wx in positions) {
      canvas.drawCircle(Offset(wx, rect.bottom - 2), wr, paint);
      paint.color = Colors.grey.shade600;
      canvas.drawCircle(Offset(wx, rect.bottom - 2), wr * 0.45, paint);
      paint.color = GameColors.carWheelDark;
    }
  }

  void _drawHeadlights(Canvas canvas, Paint paint, Rect rect, bool facingRight, Color bodyColor) {
    paint.color = Colors.yellow.shade300;
    final hlX = facingRight ? rect.right - 5 : rect.left + 5;
    canvas.drawCircle(Offset(hlX, rect.center.dy - 7), 5, paint);
    canvas.drawCircle(Offset(hlX, rect.center.dy + 7), 5, paint);
  }

  // ─── Player ────────────────────────────────────────────────────────────────
  void _drawPlayer(Canvas canvas) {
    final pos = player.visualPosition;
    final drawX = pos.dx;
    final drawY = pos.dy + scrollOffset + (player.isDying ? 0.0 : player.hopArcOffset);

    final scaleX = player.squishScaleX;
    final scaleY = player.squishScaleY;
    final opacity = player.squishOpacity;

    canvas.save();
    canvas.translate(drawX, drawY + 28);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-drawX, -(drawY + 28));

    if (playerImage != null) {
      final paint = Paint();
      if (opacity < 1.0) {
        paint.color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0));
      }
      
      const double s = 28.0;
      
      // Shadow
      final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.18 * opacity.clamp(0.0, 1.0));
      canvas.drawOval(Rect.fromCenter(center: Offset(drawX, drawY + s * 0.92), width: s * 1.4, height: s * 0.38), shadowPaint);

      final src = Rect.fromLTWH(0, 0, playerImage!.width.toDouble(), playerImage!.height.toDouble());
      final double w = s * 2.4; 
      final double h = w * (playerImage!.height / playerImage!.width);
      final dst = Rect.fromCenter(center: Offset(drawX, drawY), width: w, height: h);
      
      canvas.drawImageRect(playerImage!, src, dst, paint);
    } else {
      _drawChicken(canvas, drawX, drawY, opacity: opacity);
    }

    canvas.restore();
  }

  void _drawChicken(Canvas canvas, double cx, double cy, {double opacity = 1.0}) {
    final paint = Paint();
    const s = 28.0;
    final op = opacity.clamp(0.0, 1.0);

    // Shadow
    paint.color = Colors.black.withValues(alpha: 0.18 * op);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + s * 0.92), width: s * 1.4, height: s * 0.38), paint);

    // Body
    paint.color = GameColors.chickenBody.withValues(alpha: op);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: s * 1.2, height: s * 1.1), paint);

    // Wing
    paint.color = GameColors.chickenWing.withValues(alpha: op);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - s * 0.35, cy + s * 0.05), width: s * 0.55, height: s * 0.7), paint);

    // Head
    paint.color = GameColors.chickenBody.withValues(alpha: op);
    canvas.drawCircle(Offset(cx + s * 0.25, cy - s * 0.55), s * 0.42, paint);

    // Comb
    paint.color = GameColors.chickenComb.withValues(alpha: op);
    canvas.drawCircle(Offset(cx + s * 0.18, cy - s * 0.95), s * 0.14, paint);
    canvas.drawCircle(Offset(cx + s * 0.28, cy - s * 1.0), s * 0.17, paint);
    canvas.drawCircle(Offset(cx + s * 0.38, cy - s * 0.95), s * 0.13, paint);

    // Beak
    final beakPath = Path()
      ..moveTo(cx + s * 0.63, cy - s * 0.52)
      ..lineTo(cx + s * 0.85, cy - s * 0.44)
      ..lineTo(cx + s * 0.63, cy - s * 0.38)
      ..close();
    paint.color = GameColors.chickenBeak.withValues(alpha: op);
    canvas.drawPath(beakPath, paint);

    // Eye
    paint.color = GameColors.chickenEye.withValues(alpha: op);
    canvas.drawCircle(Offset(cx + s * 0.38, cy - s * 0.58), s * 0.1, paint);
    paint.color = Colors.white.withValues(alpha: op);
    canvas.drawCircle(Offset(cx + s * 0.41, cy - s * 0.61), s * 0.04, paint);

    // Feet
    paint.color = GameColors.chickenBeak.withValues(alpha: op);
    paint.strokeWidth = 2.5;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx - s * 0.15, cy + s * 0.5), Offset(cx - s * 0.15, cy + s * 0.8), paint);
    canvas.drawLine(Offset(cx - s * 0.15, cy + s * 0.8), Offset(cx - s * 0.35, cy + s * 0.9), paint);
    canvas.drawLine(Offset(cx - s * 0.15, cy + s * 0.8), Offset(cx + s * 0.0, cy + s * 0.95), paint);
    canvas.drawLine(Offset(cx + s * 0.12, cy + s * 0.5), Offset(cx + s * 0.12, cy + s * 0.8), paint);
    canvas.drawLine(Offset(cx + s * 0.12, cy + s * 0.8), Offset(cx - s * 0.08, cy + s * 0.9), paint);
    canvas.drawLine(Offset(cx + s * 0.12, cy + s * 0.8), Offset(cx + s * 0.28, cy + s * 0.95), paint);
    paint.style = PaintingStyle.fill;
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) => true;
}
