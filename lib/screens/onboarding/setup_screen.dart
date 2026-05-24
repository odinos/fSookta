import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../app/sookta_app.dart';
import '../../widgets/responsive_content.dart';
import 'avatar_selection_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    this.editMode = false,
    super.key,
  });

  static const routeName = '/setup';

  final bool editMode;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final farmerIdController = TextEditingController();
  final nameController = TextEditingController();
  final roleController = TextEditingController();
  final locationController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final incomeController = TextEditingController();
  String gender = 'Male';
  bool loadedInitialData = false;

  @override
  void initState() {
    super.initState();
    nameController.addListener(_refresh);
    ageController.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (loadedInitialData) return;
    final profile = AppStateScope.of(context).profile;
    farmerIdController.text = profile.farmerId;
    nameController.text = profile.name;
    roleController.text = profile.role;
    locationController.text = profile.location;
    ageController.text = profile.age;
    weightController.text = profile.weight;
    heightController.text = profile.height;
    incomeController.text = profile.incomePerYear;
    gender = profile.gender;
    loadedInitialData = true;
  }

  @override
  void dispose() {
    farmerIdController.dispose();
    nameController.dispose();
    roleController.dispose();
    locationController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    incomeController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final text = AppText(state.language ?? AppLanguage.th);

    final title = widget.editMode ? text.editProfile : text.addProfile;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ResponsiveListView(
          maxWidth: 560,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C9A81),
              ),
            ),
            const SizedBox(height: 20),
            _SooktaTextField(
              controller: farmerIdController,
              label: text.farmerId,
            ),
            const SizedBox(height: 12),
            _SooktaTextField(controller: nameController, label: text.fullName),
            const SizedBox(height: 12),
            _SooktaTextField(controller: roleController, label: text.role),
            const SizedBox(height: 12),
            _SooktaTextField(
              controller: locationController,
              label: text.location,
            ),
            const SizedBox(height: 12),
            _SooktaTextField(
              controller: ageController,
              label: text.age,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Text(text.gender, style: const TextStyle(color: Color(0xFF5C9A81))),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final buttonWidth =
                    ((constraints.maxWidth - 12) / 2).clamp(120.0, 240.0);
                return Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _GenderButton(
                      width: buttonWidth,
                      label: text.male,
                      selected: gender == 'Male',
                      onTap: () => setState(() => gender = 'Male'),
                    ),
                    _GenderButton(
                      width: buttonWidth,
                      label: text.female,
                      selected: gender == 'Female',
                      onTap: () => setState(() => gender = 'Female'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _SooktaTextField(
              controller: weightController,
              label: text.weight,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _SooktaTextField(
              controller: heightController,
              label: text.height,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _SooktaTextField(
              controller: incomeController,
              label: text.income,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 4),
            Text(text.incomeNote,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 40),
            FilledButton(
              onPressed:
                  nameController.text.isEmpty || ageController.text.isEmpty
                      ? null
                      : _saveAndContinue,
              child: Text(
                widget.editMode ? text.save : text.next,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAndContinue() {
    final currentProfile = AppStateScope.of(context).profile;
    AppStateScope.of(context).saveProfile(
      UserProfile(
        farmerId: farmerIdController.text.trim(),
        name: nameController.text,
        role: roleController.text.trim(),
        location: locationController.text.trim(),
        age: ageController.text,
        gender: gender,
        weight: weightController.text,
        height: heightController.text,
        incomePerYear: incomeController.text,
        avatarAsset: currentProfile.avatarAsset,
      ),
    );
    if (widget.editMode) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushNamed(AvatarSelectionScreen.routeName);
  }
}

class _SooktaTextField extends StatelessWidget {
  const _SooktaTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5C9A81)),
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.width,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor:
              selected ? const Color(0xFF8CC63F) : Colors.grey.shade300,
          foregroundColor: selected ? Colors.white : Colors.black,
        ),
        child: Text(label),
      ),
    );
  }
}
