import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class SplashPage extends StatefulWidget {
  final Widget nextPage;

  const SplashPage({super.key, required this.nextPage});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(_fade);
    _controller.forward();
    Timer(const Duration(milliseconds: 2300), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: AppTheme.normalTransition,
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: AppTheme.transitionCurve,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SplashLogo(),
                  const SizedBox(height: 22),
                  Text(
                    'Absensi OB',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Presensi ringan, aman, dan modern',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      color: AppTheme.clayPrimary,
                      backgroundColor: AppTheme.clayPrimary.withValues(
                        alpha: 0.12,
                      ),
                      strokeWidth: 3,
                      strokeCap: StrokeCap.round,
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

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.gradientArmyGreen,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [AppTheme.buttonShadow, AppTheme.highlightShadow],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
            ),
          ),
          const Icon(
            Icons.face_retouching_natural_rounded,
            color: Colors.white,
            size: 46,
          ),
          Positioned(
            right: 24,
            bottom: 25,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: AppTheme.clayAccent,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
