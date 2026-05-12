import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/theme/sookta_theme.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  static const routeName = '/contact';

  @override
  Widget build(BuildContext context) {
    final thai = (AppStateScope.of(context).language ?? AppLanguage.th) == AppLanguage.th;
    return Scaffold(
      appBar: AppBar(title: Text(thai ? 'ติดต่อเรา' : 'Contact Us')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: Color(0xFFE8F5E9),
                      child: Icon(Icons.school, size: 38, color: SooktaColors.darkGreen),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      thai ? 'ผู้รับผิดชอบโครงการ' : 'Project Owner',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'นางอภิสรา เลา',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      thai
                          ? 'คณะสาธารณสุขศาสตร์ มหาวิทยาลัยธรรมศาสตร์'
                          : 'Faculty of Public Health, Thammasat University',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _ContactRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: 'apisara.chaisi@dome.tu.ac.th',
            ),
            const _ContactRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: '0985162941',
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(thai ? 'เวอร์ชัน' : 'Version'),
                subtitle: const Text('0.1.0+1'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: SooktaColors.darkGreen),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
