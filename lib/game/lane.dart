import 'dart:math';
import 'dart:ui';

enum LaneType { grass, road, river }

// Road vehicle sub-types
enum VehicleType { car, bus, truck, motorcycle }

// River obstacle sub-types
enum RiverType { log, lilypad, crocodile }

class Obstacle {
  double x;
  final double y;
  final double speed;
  final double width;
  final double height;
  final int colorIndex;
  final VehicleType vehicleType;
  final RiverType riverType;

  Obstacle({
    required this.x,
    required this.y,
    required this.speed,
    required this.width,
    required this.height,
    required this.colorIndex,
    this.vehicleType = VehicleType.car,
    this.riverType = RiverType.log,
  });

  void update(double dt, double screenWidth) {
    x += speed * dt;
    const double padding = 250.0;
    final double cycle = screenWidth + padding * 2;
    if (speed > 0 && x > screenWidth + padding) {
      x -= cycle;
    } else if (speed < 0 && x < -padding) {
      x += cycle;
    }
  }

  Rect get rect => Rect.fromLTWH(x, y - height / 2, width, height);
}

// A collectible star on a grass lane
class Collectible {
  double x;
  final double y;
  bool collected;
  double pulsePhase; // for bobbing animation

  Collectible({required this.x, required this.y})
    : collected = false,
      pulsePhase = 0.0;

  Rect get rect => Rect.fromCenter(center: Offset(x, y), width: 36, height: 36);

  void update(double dt) {
    pulsePhase += dt * 3.0;
  }
}

class Lane {
  final LaneType type;
  final double y;
  final double height;
  final List<Obstacle> obstacles;
  final List<Collectible> collectibles;
  final double speed;

  Lane({
    required this.type,
    required this.y,
    required this.height,
    required this.obstacles,
    List<Collectible>? collectibles,
    this.speed = 0,
  }) : collectibles = collectibles ?? [];

  void update(double dt, double screenWidth) {
    for (final obs in obstacles) obs.update(dt, screenWidth);
    for (final c in collectibles) c.update(dt);
  }

  Obstacle? logAt(double px, double py) {
    for (final obs in obstacles) {
      if (obs.rect.contains(Offset(px, py))) return obs;
    }
    return null;
  }

  bool collidesAt(double px, double py, double playerSize) {
    final playerRect = Rect.fromCenter(
      center: Offset(px, py),
      width: playerSize * 0.65,
      height: playerSize * 0.65,
    );
    for (final obs in obstacles) {
      if (obs.rect.overlaps(playerRect)) return true;
    }
    return false;
  }

  // Returns a collectible if the player steps on it
  Collectible? collectAt(double px, double py) {
    for (final c in collectibles) {
      if (!c.collected && c.rect.contains(Offset(px, py))) return c;
    }
    return null;
  }
}

class WorldGenerator {
  static const int numCols = 9;
  static const double laneHeight = 88.0;
  final Random _rng = Random();

  // Difficulty: 0 = easy (start), increases with score
  int _difficulty = 0;
  int get difficulty => _difficulty;
  bool _lastRiverGoRight =
      false; // Ensures adjacent rivers alternate directions

  void setDifficulty(int score) {
    _difficulty = (score ~/ 5).clamp(0, 8); // Difficulty scales up faster
  }

  List<Lane> generate(double screenWidth, double screenHeight) {
    final lanes = <Lane>[];
    for (int i = 0; i < 30; i++) {
      final y = screenHeight - (i + 1) * laneHeight;
      lanes.add(_buildLane(i, y, screenWidth));
    }
    return lanes;
  }

  Lane _buildLane(int index, double y, double screenWidth) {
    // Always start with 3 easy grass lanes at the bottom
    if (index < 3) {
      return Lane(
        type: LaneType.grass,
        y: y,
        height: laneHeight,
        obstacles: [],
        collectibles: index == 1 ? _buildCollectibles(y, screenWidth) : [],
      );
    }

    // Kid-friendly pattern: more grass between hazards
    // Increases road/river density with difficulty
    final patterns = _difficulty <= 1
        ? [
            LaneType.road,
            LaneType.grass,
            LaneType.grass,
            LaneType.river,
            LaneType.grass,
            LaneType.grass,
          ]
        : _difficulty <= 3
        ? [
            LaneType.road,
            LaneType.road,
            LaneType.grass,
            LaneType.river,
            LaneType.grass,
          ]
        : [
            LaneType.road,
            LaneType.road,
            LaneType.grass,
            LaneType.river,
            LaneType.river,
            LaneType.grass,
          ];

    final type = patterns[index % patterns.length];

    switch (type) {
      case LaneType.grass:
        final collectibles = _rng.nextDouble() < 0.55
            ? _buildCollectibles(y, screenWidth)
            : <Collectible>[];
        return Lane(
          type: LaneType.grass,
          y: y,
          height: laneHeight,
          obstacles: [],
          collectibles: collectibles,
        );
      case LaneType.road:
        return _buildRoadLane(y, screenWidth);
      case LaneType.river:
        _lastRiverGoRight = !_lastRiverGoRight;
        return _buildRiverLane(y, screenWidth, _lastRiverGoRight);
    }
  }

  List<Collectible> _buildCollectibles(double laneY, double screenWidth) {
    final cellW = screenWidth / numCols;
    final col = _rng.nextInt(numCols);
    return [Collectible(x: col * cellW + cellW / 2, y: laneY + laneHeight / 2)];
  }

  Lane _buildRoadLane(double y, double screenWidth) {
    final goRight = _rng.nextBool();
    // Speed scales gently with difficulty
    final minSpeed = 140.0 + _difficulty * 20.0;
    final maxSpeed = 200.0 + _difficulty * 30.0;
    final baseSpeed = minSpeed + _rng.nextDouble() * (maxSpeed - minSpeed);
    final speed = goRight ? baseSpeed : -baseSpeed;

    // Vehicle type: random with fun distribution
    final vehicleTypes = [
      VehicleType.car,
      VehicleType.car,
      VehicleType.car,
      VehicleType.bus,
      VehicleType.truck,
      VehicleType.motorcycle,
    ];
    final count = 2 + _rng.nextInt(3); // 2–4 vehicles
    final obstacles = <Obstacle>[];

    const minGap = 70.0;
    double cursor = _rng.nextDouble() * (screenWidth * 0.25);

    for (int i = 0; i < count; i++) {
      final vType = vehicleTypes[_rng.nextInt(vehicleTypes.length)];
      final (vWidth, vHeight) = _vehicleSize(vType);
      obstacles.add(
        Obstacle(
          x: cursor,
          y: y + laneHeight / 2,
          speed: speed,
          width: vWidth,
          height: vHeight,
          colorIndex: _rng.nextInt(6),
          vehicleType: vType,
        ),
      );
      cursor += vWidth + minGap + _rng.nextDouble() * 140.0;
    }
    return Lane(
      type: LaneType.road,
      y: y,
      height: laneHeight,
      obstacles: obstacles,
      speed: speed,
    );
  }

  (double, double) _vehicleSize(VehicleType type) => switch (type) {
    VehicleType.car => (100.0 + _rng.nextDouble() * 30, 52.0),
    VehicleType.bus => (180.0 + _rng.nextDouble() * 40, 58.0),
    VehicleType.truck => (160.0 + _rng.nextDouble() * 30, 60.0),
    VehicleType.motorcycle => (55.0 + _rng.nextDouble() * 15, 40.0),
  };

  Lane _buildRiverLane(double y, double screenWidth, bool goRight) {
    final speed =
        (100.0 + _rng.nextDouble() * 50.0 + _difficulty * 12) *
        (goRight ? 1 : -1);

    // River types: mostly logs, occasionally lily pads and crocs
    final riverTypes = [
      RiverType.log,
      RiverType.log,
      RiverType.lilypad,
      RiverType.crocodile,
    ];
    final rType = riverTypes[_rng.nextInt(riverTypes.length)];

    // Higher density to ensure they are always reachable
    final count = 3 + _rng.nextInt(3);
    final obstacles = <Obstacle>[];
    double cursor = _rng.nextDouble() * (screenWidth * 0.15);

    for (int i = 0; i < count; i++) {
      final width = rType == RiverType.lilypad
          ? 60.0 + _rng.nextDouble() * 20
          : 90.0 + _rng.nextDouble() * 60.0; // Shorter logs = harder to land on
      obstacles.add(
        Obstacle(
          x: cursor,
          y: y + laneHeight / 2,
          speed: speed,
          width: width,
          height: rType == RiverType.lilypad ? 52.0 : 46.0,
          colorIndex: 0,
          riverType: rType,
        ),
      );
      cursor += width + 70.0 + _rng.nextDouble() * 100.0; // Slightly larger gap
    }
    return Lane(
      type: LaneType.river,
      y: y,
      height: laneHeight,
      obstacles: obstacles,
      speed: speed,
    );
  }

  Lane addLane(int index, double y, double screenWidth) {
    return _buildLane(index, y, screenWidth);
  }
}
