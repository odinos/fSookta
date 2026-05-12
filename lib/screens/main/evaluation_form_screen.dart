import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/models/assessment_session.dart';
import '../../core/models/evaluation_models.dart';
import '../../core/services/ergo_calculator.dart';
import '../../core/theme/sookta_theme.dart';
import 'initial_risk_screen.dart';

class EvaluationFormScreen extends StatefulWidget {
  const EvaluationFormScreen({
    required this.activity,
    super.key,
  });

  static const routeName = '/evaluation-form';

  final SooktaActivity activity;

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final loadWeightController = TextEditingController(text: '10');
  final horizontalController = TextEditingController(text: '25');
  final verticalController = TextEditingController(text: '75');
  final transportController = TextEditingController(text: '4');
  final initialForceController = TextEditingController(text: '18');
  final sustainForceController = TextEditingController(text: '8');

  var imageCount = 0;
  var selectedDurationHours = 1.0;
  var selectedFrequency = 0.2;
  late JobType selectedJobType;
  var rebaInput = const RebaInputData(
    trunkScore: 3,
    neckScore: 1,
    legScore: 1,
    upperArmScore: 2,
    lowerArmScore: 1,
    wristScore: 1,
  );

  @override
  void initState() {
    super.initState();
    selectedJobType = widget.activity.defaultJobType;
  }

  @override
  void dispose() {
    loadWeightController.dispose();
    horizontalController.dispose();
    verticalController.dispose();
    transportController.dispose();
    initialForceController.dispose();
    sustainForceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final language = state.language ?? AppLanguage.th;
    final thai = language == AppLanguage.th;
    final activityName = widget.activity.label(thai: thai);

    return Scaffold(
      appBar: AppBar(title: Text(thai ? 'แบบฟอร์มประเมิน' : 'Evaluation Form')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              thai ? 'กิจกรรม: $activityName' : 'Activity: $activityName',
              style: const TextStyle(
                color: SooktaColors.darkGreen,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _ImageSlots(
              imageCount: imageCount,
              onAdd: imageCount >= 4 ? null : () => setState(() => imageCount++),
              onRemove: imageCount == 0 ? null : () => setState(() => imageCount--),
              thai: thai,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: thai ? 'ข้อมูลการทำงาน' : 'Work Information',
              children: [
                SegmentedButton<JobType>(
                  segments: [
                    ButtonSegment(
                      value: JobType.reba,
                      label: Text(thai ? 'REBA' : 'REBA'),
                      icon: const Icon(Icons.accessibility_new),
                    ),
                    ButtonSegment(
                      value: JobType.lifting,
                      label: Text(thai ? 'ยก/แบก' : 'Lift'),
                      icon: const Icon(Icons.inventory_2_outlined),
                    ),
                    ButtonSegment(
                      value: JobType.pushPull,
                      label: Text(thai ? 'ดัน/ดึง' : 'Push'),
                      icon: const Icon(Icons.open_with),
                    ),
                  ],
                  selected: {selectedJobType},
                  onSelectionChanged: (value) {
                    setState(() => selectedJobType = value.first);
                  },
                ),
                const SizedBox(height: 12),
                _ChoiceRow<double>(
                  label: thai ? 'ระยะเวลา' : 'Duration',
                  value: selectedDurationHours,
                  items: const {
                    1.0: '1 hr',
                    2.0: '2 hrs',
                    4.0: '4 hrs',
                    8.0: '8 hrs',
                  },
                  onChanged: (value) => setState(() => selectedDurationHours = value),
                ),
                _ChoiceRow<double>(
                  label: thai ? 'ความถี่' : 'Frequency',
                  value: selectedFrequency,
                  items: const {
                    0.2: '< 0.2/min',
                    2.0: '1-4/min',
                    6.5: '> 6/min',
                  },
                  onChanged: (value) => setState(() => selectedFrequency = value),
                ),
              ],
            ),
            if (selectedJobType == JobType.reba) ...[
              const SizedBox(height: 16),
              _RebaCard(
                thai: thai,
                input: rebaInput,
                onChanged: (input) => setState(() => rebaInput = input),
                onAutoFill: () {
                  setState(() {
                    imageCount = imageCount == 0 ? 1 : imageCount;
                    rebaInput = rebaInput.copyWith(
                      trunkScore: 3,
                      neckScore: 2,
                      upperArmScore: 3,
                      lowerArmScore: 1,
                      wristScore: 2,
                      legScore: 2,
                      loadScore: 1,
                      activityScore: 1,
                    );
                  });
                },
              ),
            ] else ...[
              const SizedBox(height: 16),
              _IsoCard(
                thai: thai,
                jobType: selectedJobType,
                loadWeightController: loadWeightController,
                horizontalController: horizontalController,
                verticalController: verticalController,
                transportController: transportController,
                initialForceController: initialForceController,
                sustainForceController: sustainForceController,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _analyze,
              icon: const Icon(Icons.analytics_outlined),
              label: Text(thai ? 'เริ่มวิเคราะห์ความเสี่ยง' : 'Start Risk Analysis'),
            ),
          ],
        ),
      ),
    );
  }

  void _analyze() {
    final state = AppStateScope.of(context);
    final thai = (state.language ?? AppLanguage.th) == AppLanguage.th;
    final activityName = widget.activity.label(thai: thai);
    final gender = state.profile.gender.toLowerCase();
    final dailyIncome = state.dailyIncome.toDouble();
    final ergoInput = ErgoInputData(
      jobType: selectedJobType,
      gender: gender,
      dailyIncome: dailyIncome,
      loadWeight: _number(loadWeightController, 10),
      horizontalDist: _number(horizontalController, 25),
      verticalHeight: _number(verticalController, 75),
      liftFrequency: selectedFrequency,
      durationHours: selectedDurationHours,
      transportDistance: _number(transportController, 4),
      initialForce: _number(initialForceController, 18),
      sustainForce: _number(sustainForceController, 8),
    );
    final rebaData = rebaInput.copyWith(dailyIncome: dailyIncome);
    final result = switch (selectedJobType) {
      JobType.reba => ErgoCalculator.calculateRebaRisk(rebaData),
      JobType.lifting => ErgoCalculator.calculateLiftingRisk(ergoInput),
      JobType.pushPull => ErgoCalculator.calculatePushPullRisk(ergoInput),
    };

    Navigator.of(context).pushNamed(
      InitialRiskScreen.routeName,
      arguments: InitialRiskPayload(
        activity: widget.activity,
        activityName: activityName,
        jobType: selectedJobType,
        before: result,
        ergoInput: ergoInput,
        rebaInput: rebaData,
      ),
    );
  }

  double _number(TextEditingController controller, double fallback) {
    return double.tryParse(controller.text.trim()) ?? fallback;
  }
}

class _ImageSlots extends StatelessWidget {
  const _ImageSlots({
    required this.imageCount,
    required this.onAdd,
    required this.onRemove,
    required this.thai,
  });

  final int imageCount;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: thai ? 'รูปภาพประกอบ ($imageCount/4)' : 'Images ($imageCount/4)',
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final filled = index < imageCount;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: filled ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: filled ? SooktaColors.leafGreen : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: Icon(
                  filled ? Icons.image : Icons.add_photo_alternate_outlined,
                  color: filled ? SooktaColors.darkGreen : Colors.grey,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.camera_alt),
                label: Text(thai ? 'ถ่าย/เพิ่มรูปจำลอง' : 'Add mock photo'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ],
    );
  }
}

class _RebaCard extends StatelessWidget {
  const _RebaCard({
    required this.thai,
    required this.input,
    required this.onChanged,
    required this.onAutoFill,
  });

  final bool thai;
  final RebaInputData input;
  final ValueChanged<RebaInputData> onChanged;
  final VoidCallback onAutoFill;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: thai ? 'คะแนนท่าทาง REBA' : 'REBA Posture Scores',
      children: [
        OutlinedButton.icon(
          onPressed: onAutoFill,
          icon: const Icon(Icons.auto_awesome),
          label: Text(thai ? 'เติมค่าจาก AI ตัวอย่าง' : 'Demo AI auto-fill'),
        ),
        _ScoreSlider(
          label: thai ? 'ลำตัว' : 'Trunk',
          value: input.trunkScore,
          min: 1,
          max: 4,
          onChanged: (value) => onChanged(input.copyWith(trunkScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'คอ' : 'Neck',
          value: input.neckScore,
          min: 1,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(neckScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'ขา' : 'Legs',
          value: input.legScore,
          min: 1,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(legScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'ต้นแขน' : 'Upper Arm',
          value: input.upperArmScore,
          min: 1,
          max: 4,
          onChanged: (value) => onChanged(input.copyWith(upperArmScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'ข้อมือ' : 'Wrist',
          value: input.wristScore,
          min: 1,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(wristScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'น้ำหนักที่ถือ' : 'Load',
          value: input.loadScore,
          min: 0,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(loadScore: value)),
        ),
      ],
    );
  }
}

class _IsoCard extends StatelessWidget {
  const _IsoCard({
    required this.thai,
    required this.jobType,
    required this.loadWeightController,
    required this.horizontalController,
    required this.verticalController,
    required this.transportController,
    required this.initialForceController,
    required this.sustainForceController,
  });

  final bool thai;
  final JobType jobType;
  final TextEditingController loadWeightController;
  final TextEditingController horizontalController;
  final TextEditingController verticalController;
  final TextEditingController transportController;
  final TextEditingController initialForceController;
  final TextEditingController sustainForceController;

  @override
  Widget build(BuildContext context) {
    final lifting = jobType == JobType.lifting;
    return _SectionCard(
      title: lifting
          ? (thai ? 'ข้อมูล ISO 11228 งานยก' : 'ISO 11228 Lifting')
          : (thai ? 'ข้อมูลแรงดัน/ดึง' : 'Push/Pull Force'),
      children: [
        if (lifting) ...[
          _NumberField(
            controller: loadWeightController,
            label: thai ? 'น้ำหนักวัตถุ (kg)' : 'Load weight (kg)',
          ),
          _NumberField(
            controller: horizontalController,
            label: thai ? 'ระยะห่าง H (cm)' : 'Distance H (cm)',
          ),
          _NumberField(
            controller: verticalController,
            label: thai ? 'ความสูง V (cm)' : 'Height V (cm)',
          ),
          _NumberField(
            controller: transportController,
            label: thai ? 'ระยะทางขนย้าย (m)' : 'Transport distance (m)',
          ),
        ] else ...[
          _NumberField(
            controller: initialForceController,
            label: thai ? 'แรงเริ่มต้น (N)' : 'Initial force (N)',
          ),
          _NumberField(
            controller: sustainForceController,
            label: thai ? 'แรงต่อเนื่อง (N)' : 'Sustained force (N)',
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: items.entries
            .map(
              (entry) => DropdownMenuItem<T>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _ScoreSlider extends StatelessWidget {
  const _ScoreSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value'),
        Slider(
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          value: value.toDouble(),
          label: '$value',
          onChanged: (value) => onChanged(value.round()),
        ),
      ],
    );
  }
}
