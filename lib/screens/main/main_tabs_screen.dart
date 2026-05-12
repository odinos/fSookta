import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../app/sookta_app.dart';
import '../../core/theme/sookta_theme.dart';
import 'history_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';

class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  static const routeName = '/main';

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final text = AppText(state.language ?? AppLanguage.th);
    final tabs = [
      HomeTab(text: text, profile: state.profile),
      HistoryTab(text: text),
      ProfileTab(text: text, profile: state.profile),
    ];

    return Scaffold(
      body: tabs[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        backgroundColor: SooktaColors.leafGreen,
        indicatorColor: Colors.white,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined, color: Colors.white),
            selectedIcon: const Icon(Icons.home, color: SooktaColors.leafGreen),
            label: text.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history, color: Colors.white),
            selectedIcon: const Icon(Icons.history, color: SooktaColors.leafGreen),
            label: text.history,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            selectedIcon: const Icon(
              Icons.account_circle,
              color: SooktaColors.leafGreen,
            ),
            label: text.profile,
          ),
        ],
      ),
    );
  }
}
