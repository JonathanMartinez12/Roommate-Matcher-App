import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Auto-navigate after 2.5 s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/login'),
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Hero background ───────────────────────────────────────────
            Image.network(
              'https://images.unsplash.com/photo-1523240795612-9a054b0db644'
              '?w=1200&h=800&fit=crop',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.82),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppColors.navy),
            ),

            // ── Centered content ──────────────────────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.terracotta,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.terracotta.withValues(alpha: 0.4),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.home_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App name
                    Text(
                      'roomr',
                      style: GoogleFonts.inter(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -2.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tagline
                    Text(
                      'Find your perfect roommate',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Social proof
                    Text(
                      'Join 5,000+ college students',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.terracottaLight,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Pulsing CTA pill
                    FadeTransition(
                      opacity: _pulseAnim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tap anywhere to get started',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
