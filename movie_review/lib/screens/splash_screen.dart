// ============================================================
// screens/splash_screen.dart — Cinematic opening animation (web-safe)
// ============================================================
import 'dart:math';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _reelController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _particleController;

  late Animation<double> _reelRotation;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _glowPulse;
  late Animation<double> _particleProgress;

  // Pre-generate particles once so they don't change per repaint
  final List<_Particle> _particles = _generateParticles();

  static List<_Particle> _generateParticles() {
    final rng = Random(42);
    return List.generate(
      50,
      (i) => _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 3 + 1,
        speed: rng.nextDouble() * 0.4 + 0.1,
        opacity: rng.nextDouble() * 0.6 + 0.1,
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _reelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _reelRotation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _reelController, curve: Curves.easeInOut),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _glowPulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _particleProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _reelController.forward();
    _particleController.forward();
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _reelController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050714),
      body: Stack(
        children: [
          // Particle background
          AnimatedBuilder(
            animation: _particleProgress,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particleProgress.value, _particles),
              child: const SizedBox.expand(),
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Film reel icon with animated glow
                AnimatedBuilder(
                  animation: Listenable.merge([_reelRotation, _glowPulse]),
                  builder: (_, __) => Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700)
                              .withValues(alpha: _glowPulse.value * 0.55),
                          blurRadius: 45,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Transform.rotate(
                      angle: _reelRotation.value,
                      child: const Icon(
                        Icons.movie_filter_rounded,
                        color: Color(0xFFFFD700),
                        size: 90,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                // Logo
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFF8DC),
                              Color(0xFFFFD700),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'CineReview',
                            style: TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 2,
                          width: 200,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFFFFD700),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // Tagline
                ClipRect(
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: FadeTransition(
                      opacity: _taglineFade,
                      child: const Text(
                        'Malayalam & English Cinema',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 15,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Progress bar at bottom
          Positioned(
            bottom: 60,
            left: 60,
            right: 60,
            child: AnimatedBuilder(
              animation: _particleProgress,
              builder: (_, __) => Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _particleProgress.value,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFD700),
                      ),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading cinema...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  const _ParticlePainter(this.progress, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final yOffset = (p.y - progress * p.speed) % 1.0;
      double opacity;
      if (progress < 0.1) {
        opacity = (progress / 0.1) * p.opacity;
      } else if (progress > 0.85) {
        opacity = ((1 - progress) / 0.15) * p.opacity;
      } else {
        opacity = p.opacity;
      }
      paint.color =
          const Color(0xFFFFD700).withValues(alpha: opacity.clamp(0.0, 1.0));
      canvas.drawCircle(
        Offset(p.x * size.width, yOffset * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, size, speed, opacity;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}
