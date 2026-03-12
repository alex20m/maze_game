import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MazeGame extends FlameGame with PanDetector {
  MazeGame({
    required this.levelNumber,
    required this.onLevelFinished,
  });

  final int levelNumber;
  final void Function(bool success) onLevelFinished;

  late PlayerBall _player;
  late ExitArea _exit;
  late final Vector2 _mazeSize;
  late final List<Wall> _walls;
  late final double _ballRadius;
  bool _finished = false;

  Vector2? _dragOrigin;
  @override
  Color backgroundColor() => const Color(0xFF101820);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _mazeSize = size.isZero() ? Vector2(800, 600) : size;

    final level = _buildLevel(_mazeSize, levelNumber);
    _walls = level.walls;
    _ballRadius = level.ballRadius;

    _player = PlayerBall(
      position: level.start,
      radius: _ballRadius,
    );
    add(_player);

    _exit = ExitArea(
      position: level.exit,
      size: level.exitSize,
    );
    add(_exit);
    for (final wall in _walls) {
      add(wall);
    }
  }

  _MazeLevel _buildLevel(Vector2 mazeSize, int level) {
    // Grid size is fixed (odd numbers) so the maze generation works properly.
    // Higher levels increase maze density by using a larger grid.
    final rows = switch (level) { 1 => 15, 2 => 19, _ => 23 };
    final cols = switch (level) { 1 => 21, 2 => 27, _ => 31 };

    final cellWidth = mazeSize.x / cols;
    final cellHeight = mazeSize.y / rows;

    // Keep the ball comfortably smaller than corridors.
    final ballRadius = math.min(cellWidth, cellHeight) * 0.22;

    final rng = math.Random(1000 + level * 1337);
    final maze = _generateMaze(rows: rows, cols: cols, rng: rng);

    final walls = <Wall>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (!maze[r][c]) continue;
        walls.add(
          Wall(
            position: Vector2((c + 0.5) * cellWidth, (r + 0.5) * cellHeight),
            size: Vector2(cellWidth, cellHeight),
          ),
        );
      }
    }

    // Start and exit are guaranteed to be open by the generator.
    final startCell = Vector2(1.5 * cellWidth, 1.5 * cellHeight);
    final exitCell = Vector2((cols - 1.5) * cellWidth, (rows - 1.5) * cellHeight);

    // Slightly smaller than a cell so it's reachable in corridors.
    final exitSize = Vector2(cellWidth * 0.7, cellHeight * 0.7);

    return _MazeLevel(
      walls: walls,
      start: startCell,
      exit: exitCell,
      exitSize: exitSize,
      ballRadius: ballRadius,
    );
  }

  Vector2 _inputDirection = Vector2.zero();

  static const _joystickMaxDistance = 90.0;

  @override
  void onPanStart(DragStartInfo info) {
    _dragOrigin = info.eventPosition.global;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final origin = _dragOrigin;
    if (origin == null) return;
    final v = info.eventPosition.global - origin;
    if (v.length2 == 0) return;
    final strength = (v.length / _joystickMaxDistance).clamp(0.0, 1.0);
    _inputDirection = v.normalized() * strength;
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _dragOrigin = null;
    _inputDirection = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_finished) return;

    if (_inputDirection.length2 == 0) return;

    final speed = 150 + (levelNumber - 1) * 25;
    final movement = _inputDirection * (speed * dt);

    final radius = _player.radius;

    // Movement bounds so the ball stays inside the maze area.
    final bounds = Rect.fromLTRB(
      radius,
      radius,
      _mazeSize.x - radius,
      _mazeSize.y - radius,
    );

    Vector2 newPosition = _player.position.clone();

    bool _circleIntersectsRect({
      required Vector2 circleCenter,
      required double circleRadius,
      required Rect rect,
    }) {
      final closestX = circleCenter.x.clamp(rect.left, rect.right);
      final closestY = circleCenter.y.clamp(rect.top, rect.bottom);
      final dx = circleCenter.x - closestX;
      final dy = circleCenter.y - closestY;
      return (dx * dx + dy * dy) <= (circleRadius * circleRadius);
    }

    bool _collidesAt(Vector2 candidate) {
      for (final wall in _walls) {
        if (_circleIntersectsRect(
          circleCenter: candidate,
          circleRadius: radius,
          rect: wall.hitbox,
        )) {
          return true;
        }
      }
      return false;
    }

    // Move horizontally first.
    final candidateX = Vector2(
      (newPosition.x + movement.x).clamp(bounds.left, bounds.right),
      newPosition.y,
    );
    if (!_collidesAt(candidateX)) {
      newPosition = candidateX;
    }

    // Then move vertically.
    final candidateY = Vector2(
      newPosition.x,
      (newPosition.y + movement.y).clamp(bounds.top, bounds.bottom),
    );
    if (!_collidesAt(candidateY)) {
      newPosition = candidateY;
    }

    _player.position.setFrom(newPosition);

    if (_player.toRect().overlaps(_exit.toRect())) {
      _finished = true;
      onLevelFinished(true);
    }
  }
}

class PlayerBall extends PositionComponent with HasGameRef<MazeGame> {
  PlayerBall({
    required Vector2 position,
    required double radius,
  })  : _radius = radius,
        super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  final double _radius;

  double get radius => _radius;

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.orangeAccent;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), _radius, paint);
  }
}

class Wall extends PositionComponent with HasGameRef<MazeGame> {
  Wall({
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  Rect get hitbox => Rect.fromCenter(
        center: Offset(position.x, position.y),
        width: size.x,
        height: size.y,
      );

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.grey.shade800;
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(4)),
      paint,
    );
  }
}

class ExitArea extends PositionComponent {
  ExitArea({
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final borderPaint = Paint()
      ..color = Colors.lightGreenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.lightGreenAccent.withOpacity(0.2),
          Colors.green.withOpacity(0.1),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);
  }
}

List<List<bool>> _generateMaze({
  required int rows,
  required int cols,
  required math.Random rng,
}) {
  // true = wall, false = empty
  final grid = List.generate(rows, (_) => List<bool>.filled(cols, true));

  bool inBounds(int r, int c) => r > 0 && c > 0 && r < rows - 1 && c < cols - 1;

  void carve(int r, int c) {
    grid[r][c] = false;
  }

  // Start cell.
  carve(1, 1);

  // Depth-first backtracker maze generation, moving in steps of 2 cells.
  final stack = <(int r, int c)>[(1, 1)];
  const dirs = <(int dr, int dc)>[
    (-2, 0),
    (2, 0),
    (0, -2),
    (0, 2),
  ];

  while (stack.isNotEmpty) {
    final current = stack.last;
    final r = current.$1;
    final c = current.$2;

    final options = <(int nr, int nc, int wr, int wc)>[];
    final shuffledDirs = dirs.toList()..shuffle(rng);
    for (final d in shuffledDirs) {
      final nr = r + d.$1;
      final nc = c + d.$2;
      if (!inBounds(nr, nc)) continue;
      if (grid[nr][nc] == false) continue; // already carved
      options.add((nr, nc, r + d.$1 ~/ 2, c + d.$2 ~/ 2));
    }

    if (options.isEmpty) {
      stack.removeLast();
      continue;
    }

    final pick = options[rng.nextInt(options.length)];
    carve(pick.$3, pick.$4); // knock down wall between
    carve(pick.$1, pick.$2);
    stack.add((pick.$1, pick.$2));
  }

  // Ensure exit is open and reachable (it will be, but keep it explicit).
  grid[rows - 2][cols - 2] = false;
  grid[rows - 2][cols - 3] = false;
  grid[rows - 3][cols - 2] = false;

  return grid;
}

class _MazeLevel {
  _MazeLevel({
    required this.walls,
    required this.start,
    required this.exit,
    required this.exitSize,
    required this.ballRadius,
  });

  final List<Wall> walls;
  final Vector2 start;
  final Vector2 exit;
  final Vector2 exitSize;
  final double ballRadius;
}

