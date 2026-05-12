import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/models/assessment_session.dart';
import '../../core/theme/sookta_theme.dart';
import 'evaluation_form_screen.dart';

class EvaluationMenuScreen extends StatelessWidget {
  const EvaluationMenuScreen({super.key});

  static const routeName = '/evaluation-menu';

  @override
  Widget build(BuildContext context) {
    final language = AppStateScope.of(context).language ?? AppLanguage.th;
    final thai = language == AppLanguage.th;

    return Scaffold(
      appBar: AppBar(
        title: Text(thai ? 'เลือกประเภทงาน' : 'Select Job Type'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                thai
                    ? 'โปรดเลือกกิจกรรมที่ต้องการประเมิน'
                    : 'Please select an activity to evaluate',
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  itemCount: SooktaActivity.values.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, index) {
                    final activity = SooktaActivity.values[index];
                    return _ActivityCard(
                      activity: activity,
                      label: activity.label(thai: thai),
                      onTap: () => Navigator.of(context).pushNamed(
                        EvaluationFormScreen.routeName,
                        arguments: activity,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.label,
    required this.onTap,
  });

  final SooktaActivity activity;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Image.asset(
                  activity.imageAsset,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SooktaColors.darkGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
