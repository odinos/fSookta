import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../app/assets.dart';
import '../../widgets/app_background.dart';
import '../../widgets/responsive_content.dart';
import 'evaluation_menu_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({
    required this.text,
    required this.profile,
    super.key,
  });

  final AppText text;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;
    final avatarRadius = compact ? 30.0 : 35.0;

    return AppBackground(
      child: SafeArea(
        child: ResponsiveListView(
          maxWidth: 620,
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.white,
                  foregroundImage: _avatarProvider(profile.avatarAsset),
                  child: profile.avatarAsset == null
                      ? Icon(Icons.person,
                          size: avatarRadius * 1.2, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.hello,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      _DisplayName(
                        name: profile.name.isEmpty ? text.guest : profile.name,
                        alignment: Alignment.centerLeft,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5C9A81),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            Text(
              text.startEvaluation,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 16),
            _HomeMenuCard(
              title: text.riskAssessment,
              icon: Icons.info,
              imageAsset: SooktaAssets.transplanting,
              onTap: () {
                Navigator.of(context).pushNamed(EvaluationMenuScreen.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _avatarProvider(String? path) {
    if (path == null) return null;
    if (path.startsWith('/')) {
      final file = File(path);
      if (!file.existsSync()) return null;
      return FileImage(file);
    }
    return AssetImage(path);
  }
}

class _DisplayName extends StatelessWidget {
  const _DisplayName({
    required this.name,
    required this.style,
    required this.alignment,
  });

  final String name;
  final TextStyle style;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: style,
      ),
    );
  }
}

class _HomeMenuCard extends StatelessWidget {
  const _HomeMenuCard({
    required this.title,
    required this.icon,
    required this.imageAsset,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: compact ? 132 : 150),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 20,
              14,
              compact ? 10 : 12,
              14,
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 50 : 60,
                  height: compact ? 50 : 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8F5E9),
                  ),
                  child: Icon(icon,
                      color: Colors.black54, size: compact ? 28 : 32),
                ),
                SizedBox(width: compact ? 12 : 18),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: compact ? 72 : 96,
                    maxHeight: compact ? 88 : 112,
                  ),
                  child: Image.asset(imageAsset, fit: BoxFit.contain),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
