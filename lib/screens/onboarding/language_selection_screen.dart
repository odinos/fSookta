import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../app/assets.dart';
import '../../app/sookta_app.dart';
import 'setup_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  static const routeName = '/language';

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final text = AppText(state.language ?? AppLanguage.th);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8E1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                SooktaAssets.logo,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Text(
                text.welcomeTo,
                style: const TextStyle(fontSize: 20, color: Colors.grey),
              ),
              Text(
                text.appName,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C9A81),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                text.selectLanguage,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _LanguageOptionCard(
                title: text.thai,
                subtitle: 'ภาษาไทย',
                flag: 'TH',
                onTap: () => _select(context, AppLanguage.th),
              ),
              const SizedBox(height: 16),
              _LanguageOptionCard(
                title: text.english,
                subtitle: 'English',
                flag: 'EN',
                onTap: () => _select(context, AppLanguage.en),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _select(BuildContext context, AppLanguage language) {
    AppStateScope.of(context).setLanguage(language);
    Navigator.of(context).pushReplacementNamed(SetupScreen.routeName);
  }
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.title,
    required this.subtitle,
    required this.flag,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String flag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 85,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: Text(
                    flag,
                    style: const TextStyle(
                      color: Color(0xFF5C9A81),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF5C9A81).withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
