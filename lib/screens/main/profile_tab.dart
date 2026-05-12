import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../onboarding/language_selection_screen.dart';
import '../onboarding/setup_screen.dart';
import 'contact_screen.dart';
import 'help_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    required this.text,
    required this.profile,
    super.key,
  });

  final AppText text;
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDF8E1),
      child: SafeArea(
        child: ListView(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF5C9A81),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    foregroundImage:
                        profile.avatarAsset == null ? null : AssetImage(profile.avatarAsset!),
                    child: profile.avatarAsset == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.name.isEmpty ? text.guest : profile.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: _StatCard(title: text.age, value: profile.age, unit: '')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(title: text.weight, value: profile.weight, unit: '')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(title: text.height, value: profile.height, unit: '')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StatCard(
                title: text.annualIncome,
                value: profile.incomePerYear.isEmpty ? '-' : profile.incomePerYear,
                unit: text.baht,
              ),
            ),
            const SizedBox(height: 24),
            _ProfileMenuItem(
              icon: Icons.edit,
              text: text.editProfile,
              onTap: () => Navigator.of(context).pushNamed(SetupScreen.routeName),
            ),
            _ProfileMenuItem(
              icon: Icons.language,
              text: text.isThai ? 'เปลี่ยนภาษา' : 'Change Language',
              onTap: () => Navigator.of(context).pushNamed(LanguageSelectionScreen.routeName),
            ),
            _ProfileMenuItem(
              icon: Icons.description,
              text: text.isThai ? 'เงื่อนไขการใช้งาน' : 'Terms',
              onTap: () => Navigator.of(context).pushNamed(TermsScreen.routeName),
            ),
            _ProfileMenuItem(
              icon: Icons.help_outline,
              text: text.isThai ? 'ความช่วยเหลือ' : 'Help',
              onTap: () => Navigator.of(context).pushNamed(HelpScreen.routeName),
            ),
            _ProfileMenuItem(
              icon: Icons.call,
              text: text.isThai ? 'ติดต่อเรา' : 'Contact',
              onTap: () => Navigator.of(context).pushNamed(ContactScreen.routeName),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
  });

  final String title;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 90,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C9A81),
              ),
            ),
            Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(icon, color: const Color(0xFF5C9A81)),
                const SizedBox(width: 16),
                Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
                const Icon(Icons.navigate_next, color: Colors.grey),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
