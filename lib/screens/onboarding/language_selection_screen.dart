import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../app/assets.dart';
import '../../app/sookta_app.dart';
import '../../widgets/responsive_content.dart';
import 'setup_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({
    this.editMode = false,
    super.key,
  });

  static const routeName = '/language';

  final bool editMode;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final text = AppText(state.language ?? AppLanguage.th);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8E1),
      appBar: editMode
          ? AppBar(
              title: Text(text.isThai ? 'เปลี่ยนภาษา' : 'Change Language'),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                    maxWidth: 520,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.55,
                          maxHeight: constraints.maxHeight * 0.24,
                        ),
                        child: Image.asset(
                          SooktaAssets.logo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        text.welcomeTo,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      FixedTextScale(
                        child: Text(
                          text.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5C9A81),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        text.selectLanguage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
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
          },
        ),
      ),
    );
  }

  void _select(BuildContext context, AppLanguage language) {
    AppStateScope.of(context).setLanguage(language);
    if (editMode) {
      Navigator.of(context).pop();
      return;
    }
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 78),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF5C9A81).withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
