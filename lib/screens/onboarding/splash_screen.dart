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
  static const _captureRoute = String.fromEnvironment('SOOKTA_CAPTURE_ROUTE');

  var started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    _prepareAndGoNext();
  }

  Future<void> _prepareAndGoNext() async {
    final state = AppStateScope.of(context);
    await Future.wait([
      state.restore(),
      Future<void>.delayed(const Duration(milliseconds: 900)),
    ]);
    await _goNext();
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    final state = AppStateScope.of(context);
    if (_captureRoute.isNotEmpty) {
      await state.ensureResearchCaptureData();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(_captureRoute);
      return;
    }
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
