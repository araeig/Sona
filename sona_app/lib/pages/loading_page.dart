import 'package:flutter/material.dart';
import 'dart:math';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacementNamed(context, '/check');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A0A),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    // Vinyl spinner
                    Transform.rotate(
                      angle: _controller.value * 2 * pi * 3,
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: CustomPaint(
                          painter: _VinylPainter(
                              progress: _controller.value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Logo
                    const Text(
                      'SONA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'music streaming',
                      style: TextStyle(
                        color: Color(0xFF6B5560),
                        fontSize: 13,
                        letterSpacing: 4,
                      ),
                    ),
                    const Spacer(flex: 2),
                    // Progress bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 80),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor:
                                  const Color(0xFF251520),
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                Color(0xFFA0253F),
                              ),
                              minHeight: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Loading your sound…',
                            style: TextStyle(
                              color: Color(0xFF6B5560),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Pulse bars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final delay = index * 0.2;
                        final barValue =
                            ((_controller.value - delay) % 1.0)
                                .clamp(0.0, 1.0);
                        return Container(
                          width: 32,
                          height: 3,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4),
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              const Color(0xFF251520),
                              const Color(0xFFA0253F),
                              barValue,
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VinylPainter extends CustomPainter {
  final double progress;

  _VinylPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.stroke;

    paint.color = const Color(0xFF251520);
    paint.strokeWidth = 2;
    canvas.drawCircle(center, size.width / 2 - 2, paint);

    paint.color = const Color(0xFFA0253F);
    paint.strokeWidth = 1.5;
    canvas.drawCircle(center, size.width / 2 - 20, paint);

    paint.color = const Color(0xFFC4536A);
    paint.strokeWidth = 1;
    canvas.drawCircle(center, size.width / 2 - 38, paint);

    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFA0253F);
    canvas.drawCircle(center, 8, paint);

    paint.style = PaintingStyle.stroke;
    paint.color = const Color(0xFFC4536A);
    paint.strokeWidth = 3;
    paint.strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2 - 2),
      -pi / 2,
      progress * pi * 0.8,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_VinylPainter oldDelegate) =>
      oldDelegate.progress != progress;
}