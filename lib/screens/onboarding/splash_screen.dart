import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/assets.dart';
import '../../app/sookta_app.dart';
import 'language_selection_screen.dart';
import 'setup_screen.dart';
import '../main/main_tabs_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 900), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    final state = AppStateScope.of(context);
    final route = state.setupCompleted
        ? MainTabsScreen.routeName
        : state.hasLanguage
            ? SetupScreen.routeName
            : LanguageSelectionScreen.routeName;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8E1),
      body: Center(
        child: Image.asset(
          SooktaAssets.logo,
          width: 250,
          height: 250,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
