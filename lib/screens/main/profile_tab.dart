import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../widgets/responsive_content.dart';
import 'farmer_manager_screen.dart';
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
    final width = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final compact = width < 380;
    final avatarRadius = compact ? 48.0 : 60.0;
    final headerHeight =
        (compact ? 190.0 : 220.0) + ((textScale - 1).clamp(0.0, 1.0) * 48);
    final statSpacing = compact ? 8.0 : 12.0;

    return Container(
      color: const Color(0xFFFDF8E1),
      child: SafeArea(
        child: ResponsiveListView(
          maxWidth: 620,
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: headerHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF5C9A81),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.white,
                    foregroundImage: _avatarProvider(profile.avatarAsset),
                    child: profile.avatarAsset == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: _DisplayName(
                        name: profile.name.isEmpty ? text.guest : profile.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
                  Expanded(
                    child: _StatCard(
                      title: text.age,
                      value: profile.age,
                      unit: '',
                    ),
                  ),
                  SizedBox(width: statSpacing),
                  Expanded(
                    child: _StatCard(
                      title: text.weight,
                      value: profile.weight,
                      unit: '',
                    ),
                  ),
                  SizedBox(width: statSpacing),
                  Expanded(
                    child: _StatCard(
                      title: text.height,
                      value: profile.height,
                      unit: '',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _StatCard(
                title: text.annualIncome,
                value:
                    profile.incomePerYear.isEmpty ? '-' : profile.incomePerYear,
                unit: text.baht,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _ProfileLine(
                        label: text.farmerId,
                        value: profile.farmerId,
                      ),
                      _ProfileLine(label: text.role, value: profile.role),
                      _ProfileLine(
                        label: text.location,
                        value: profile.location,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _ProfileMenuItem(
              icon: Icons.groups_2_outlined,
              text: text.isThai ? 'จัดการรายชื่อชาวสวน' : 'Manage Farmers',
              onTap: () => Navigator.of(context).pushNamed(
                FarmerManagerScreen.routeName,
              ),
            ),
            _ProfileMenuItem(
              icon: Icons.edit,
              text: text.editProfile,
              onTap: () => Navigator.of(context).pushNamed(
                SetupScreen.routeName,
                arguments: true,
              ),
            ),
            _ProfileMenuItem(
              icon: Icons.language,
              text: text.isThai ? 'เปลี่ยนภาษา' : 'Change Language',
              onTap: () => Navigator.of(context).pushNamed(
                  LanguageSelectionScreen.routeName,
                  arguments: true),
            ),
            _ProfileMenuItem(
              icon: Icons.description,
              text: text.isThai ? 'เงื่อนไขการใช้งาน' : 'Terms',
              onTap: () =>
                  Navigator.of(context).pushNamed(TermsScreen.routeName),
            ),
            _ProfileMenuItem(
              icon: Icons.help_outline,
              text: text.isThai ? 'ความช่วยเหลือ' : 'Help',
              onTap: () =>
                  Navigator.of(context).pushNamed(HelpScreen.routeName),
            ),
            _ProfileMenuItem(
              icon: Icons.call,
              text: text.isThai ? 'ติดต่อเรา' : 'Contact',
              onTap: () =>
                  Navigator.of(context).pushNamed(ContactScreen.routeName),
            ),
            const SizedBox(height: 40),
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

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisplayName extends StatelessWidget {
  const _DisplayName({
    required this.name,
    required this.style,
  });

  final String name;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      textAlign: TextAlign.center,
      style: style,
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 90),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value.isEmpty ? '-' : value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C9A81),
                ),
              ),
              Text(
                unit,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(icon, color: const Color(0xFF5C9A81)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
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
