import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../app/assets.dart';
import '../../widgets/app_background.dart';
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
    return AppBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  foregroundImage:
                      profile.avatarAsset == null ? null : AssetImage(profile.avatarAsset!),
                  child: profile.avatarAsset == null
                      ? const Icon(Icons.person, size: 42, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.hello,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      Text(
                        profile.name.isEmpty ? text.guest : profile.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 150,
          child: Row(
            children: [
              const SizedBox(width: 20),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F5E9),
                ),
                child: Icon(icon, color: Colors.black54, size: 32),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Image.asset(imageAsset, width: 96, fit: BoxFit.contain),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
