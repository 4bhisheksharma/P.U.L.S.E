import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pulse/services/app_bootstrap.dart';
import 'package:pulse/theme/my_app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minSplashDuration = Duration(milliseconds: 1800);

  String _status = 'Starting P.U.L.S.E...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await Future.wait([
        AppBootstrap.run(
          onStatus: (status) {
            if (mounted) setState(() => _status = status);
          },
        ),
        Future<void>.delayed(_minSplashDuration),
      ]);

      if (!mounted) return;
      widget.onComplete();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _status = 'Something went wrong. Tap to retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: MyAppTheme.backgroundColor,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _hasError
                ? () {
                    AppBootstrap.reset();
                    setState(() {
                      _hasError = false;
                      _status = 'Retrying...';
                    });
                    _bootstrap();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/icon.png',
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'P.U.L.S.E',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Personal Unseen Locker for Special Experience',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Lottie.asset(
                      'assets/lottie/loading.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _status,
                      key: ValueKey(_status),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _hasError
                            ? MyAppTheme.errorColor
                            : MyAppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
