import 'package:flutter/material.dart';

import '../core/theme/sookta_theme.dart';
import '../screens/onboarding/avatar_selection_screen.dart';
import '../screens/onboarding/language_selection_screen.dart';
import '../screens/onboarding/setup_screen.dart';
import '../screens/onboarding/splash_screen.dart';
import '../screens/main/contact_screen.dart';
import '../screens/main/evaluation_form_screen.dart';
import '../screens/main/evaluation_menu_screen.dart';
import '../screens/main/final_result_screen.dart';
import '../screens/main/help_screen.dart';
import '../screens/main/history_detail_screen.dart';
import '../screens/main/initial_risk_screen.dart';
import '../screens/main/main_tabs_screen.dart';
import '../screens/main/route_error_screen.dart';
import '../core/models/assessment_session.dart';
import 'app_state.dart';

class SooktaApp extends StatefulWidget {
  const SooktaApp({super.key});

  @override
  State<SooktaApp> createState() => _SooktaAppState();
}

class _SooktaAppState extends State<SooktaApp> {
  final appState = SooktaAppState();

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: appState,
      child: MaterialApp(
        title: 'Sookta',
        debugShowCheckedModeBanner: false,
        theme: buildSooktaTheme(),
        routes: {
          SplashScreen.routeName: (_) => const SplashScreen(),
          LanguageSelectionScreen.routeName: (_) => const LanguageSelectionScreen(),
          SetupScreen.routeName: (_) => const SetupScreen(),
          AvatarSelectionScreen.routeName: (_) => const AvatarSelectionScreen(),
          MainTabsScreen.routeName: (_) => const MainTabsScreen(),
          EvaluationMenuScreen.routeName: (_) => const EvaluationMenuScreen(),
          HelpScreen.routeName: (_) => const HelpScreen(),
          TermsScreen.routeName: (_) => const TermsScreen(),
          ContactScreen.routeName: (_) => const ContactScreen(),
        },
        onGenerateRoute: _generateRoute,
        initialRoute: SplashScreen.routeName,
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    return switch (settings.name) {
      EvaluationFormScreen.routeName => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => EvaluationFormScreen(
            activity: settings.arguments is SooktaActivity
                ? settings.arguments! as SooktaActivity
                : SooktaActivity.transplanting,
          ),
        ),
      InitialRiskScreen.routeName => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            final args = settings.arguments;
            if (args is InitialRiskPayload) {
              return InitialRiskScreen(payload: args);
            }
            return const RouteErrorScreen(
              message: 'Assessment data not found. Please start a new evaluation.',
            );
          },
        ),
      FinalResultScreen.routeName => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            final args = settings.arguments;
            if (args is AssessmentBundle) {
              return FinalResultScreen(bundle: args);
            }
            return const RouteErrorScreen(
              message: 'Result data not found. Please start a new evaluation.',
            );
          },
        ),
      HistoryDetailScreen.routeName => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => HistoryDetailScreen(
            historyId: settings.arguments is int ? settings.arguments! as int : -1,
          ),
        ),
      _ => null,
    };
  }
}

class AppStateScope extends InheritedNotifier<SooktaAppState> {
  const AppStateScope({
    required SooktaAppState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static SooktaAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree');
    return scope!.notifier!;
  }
}
