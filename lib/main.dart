import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const TicTacToeApp());

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TicTacToePage(),
    );
  }
}

class TicTacToePage extends StatefulWidget {
  const TicTacToePage({super.key});
  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage>
    with SingleTickerProviderStateMixin {
  List<String> board = List.filled(9, '');
  bool isXTurn = true;
  int xScore = 0;
  int oScore = 0;
  List<int> winningLine = [];

  List<double> _cellScales = List.filled(9, 1.0);

  final List<FireworkParticle> _particles = [];
  late final AnimationController _fireworksController;

  @override
  void initState() {
    super.initState();
    _fireworksController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1000),
        )..addListener(() {
          for (final p in _particles) p.update();
          _particles.removeWhere((p) => p.life <= 0);
          if (_particles.isEmpty && _fireworksController.isAnimating) {
            _fireworksController.stop();
          }
          setState(() {});
        });
  }

  @override
  void dispose() {
    _fireworksController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (board[index] != '' || winningLine.isNotEmpty || _isDraw()) return;

    setState(() {
      _cellScales[index] = 0.85;
    });
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {
          _cellScales[index] = 1.0;
        });
      }
    });

    setState(() {
      board[index] = isXTurn ? 'X' : 'O';
      isXTurn = !isXTurn;
      _checkWinner();
    });
  }

  bool _isDraw() => !board.contains('') && winningLine.isEmpty;

  void _checkWinner() {
    final lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    for (var line in lines) {
      final a = board[line[0]];
      final b = board[line[1]];
      final c = board[line[2]];
      if (a != '' && a == b && a == c) {
        setState(() {
          winningLine = List<int>.from(line);
          if (a == 'X')
            xScore++;
          else
            oScore++;
        });

        SchedulerBinding.instance.addPostFrameCallback((_) {
          _startFireworks(a);
        });

        Future.delayed(
          const Duration(milliseconds: 350),
          () => _showWinDialog(a),
        );
        return;
      }
    }

    if (_isDraw()) {
      Future.delayed(
        const Duration(milliseconds: 120),
        () => _showDrawDialog(),
      );
    }
  }

  void _startFireworks(String player) {
    if (!mounted) return;
    final media = MediaQuery.of(context).size;
    double gridSize = media.width * 0.8;
    gridSize = math.min(gridSize, 360);
    gridSize = math.min(gridSize, media.height * 0.6);
    final cellSize = gridSize / 3.0;

    final color = player == 'X'
        ? const Color.fromARGB(255, 186, 255, 255)
        : Colors.orangeAccent;

    for (final idx in winningLine) {
      final row = idx ~/ 3;
      final col = idx % 3;
      final cx = col * cellSize + cellSize / 2;
      final cy = row * cellSize + cellSize / 2;
      for (int i = 0; i < 18; i++) {
        _particles.add(FireworkParticle(cx, cy, _randomColorFor(color)));
      }
    }

    _fireworksController.forward(from: 0.0);
  }

  Color _randomColorFor(Color base) {
    final rnd = math.Random();
    if (rnd.nextBool()) return base;
    final palette = [
      Colors.yellowAccent,
      Colors.redAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
    ];
    return palette[rnd.nextInt(palette.length)];
  }

  void _showWinDialog(String winner) {
    if (!mounted) return;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Player $winner wins!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetBoard();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDrawDialog() {
    if (!mounted) return;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Draw!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetBoard();
            },
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _resetBoard() {
    setState(() {
      board = List.filled(9, '');
      winningLine = [];
      isXTurn = true;
      _particles.clear();
    });
    _fireworksController.reset();
    _cellScales = List.filled(9, 1.0);
  }

  void _clearScoreBoard() {
    setState(() {
      xScore = 0;
      oScore = 0;
      _resetBoard();
    });
  }

  Widget _scoreBox(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    double gridSize = media.width * 0.8;
    gridSize = math.min(gridSize, 360);
    gridSize = math.min(gridSize, media.height * 0.6);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 0, 91, 71), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _scoreBox(
                          'Player X',
                          xScore,
                          const Color.fromARGB(255, 104, 155, 243),
                        ),
                        const SizedBox(width: 28),
                        _scoreBox('Player O', oScore, Colors.orangeAccent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    winningLine.isNotEmpty
                        ? 'Winner: ${board[winningLine[0]]}'
                        : (_isDraw()
                              ? "It's a draw!"
                              : 'Turn: ${isXTurn ? 'X' : 'O'}'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: gridSize,
                    height: gridSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                      color: Colors.white.withOpacity(0.05),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: GridView.builder(
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                              ),
                          itemCount: 9,
                          itemBuilder: (context, index) {
                            final mark = board[index];
                            final isWinningCell = winningLine.contains(index);

                            return GestureDetector(
                              onTap: () => _handleTap(index),
                              child: AnimatedScale(
                                scale: _cellScales[index],
                                duration: const Duration(milliseconds: 120),
                                curve: Curves.easeOutBack,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isWinningCell
                                              ? Colors.cyanAccent
                                              : Colors.white30,
                                          width: isWinningCell ? 3 : 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          mark,
                                          style: TextStyle(
                                            fontSize: 56,
                                            fontWeight: FontWeight.w900,
                                            color: mark == 'X'
                                                ? const Color.fromARGB(
                                                    255,
                                                    138,
                                                    211,
                                                    255,
                                                  )
                                                : Colors.orangeAccent,
                                            shadows: isWinningCell
                                                ? [
                                                    Shadow(
                                                      color: Colors
                                                          .cyanAccent
                                                          .shade100,
                                                      blurRadius: 18,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _resetBoard,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                'Restart Game',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _clearScoreBoard,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: const Text(
                                'Reset Scoreboard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: gridSize,
                    height: gridSize,
                    child: CustomPaint(painter: FireworksPainter(_particles)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Made by Karan',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FireworkParticle {
  static final math.Random _rnd = math.Random();

  double x, y;
  final double vx, vy;
  final Color color;
  double life;

  FireworkParticle(this.x, this.y, this.color)
    : life = 1.0,
      vx = (_rnd.nextDouble() - 0.5) * 6,
      vy = (_rnd.nextDouble() - 0.5) * 6;

  void update() {
    x += vx;
    y += vy;
    life -= 0.04;
  }
}

class FireworksPainter extends CustomPainter {
  final List<FireworkParticle> particles;
  FireworksPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      paint.color = p.color.withOpacity(p.life.clamp(0, 1));
      canvas.drawCircle(Offset(p.x, p.y), 4 * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FireworksPainter oldDelegate) => true;
}
