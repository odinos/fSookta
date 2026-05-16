import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../app/sookta_app.dart';
import 'avatar_selection_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  static const routeName = '/setup';

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final nameController = TextEditingController();
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
    nameController.text = profile.name;
    ageController.text = profile.age;
    weightController.text = profile.weight;
    heightController.text = profile.height;
    incomeController.text = profile.incomePerYear;
    gender = profile.gender;
    loadedInitialData = true;
  }

  @override
  void dispose() {
    nameController.dispose();
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

    return Scaffold(
      appBar: AppBar(title: Text(text.addProfile)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              text.addProfile,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C9A81),
              ),
            ),
            const SizedBox(height: 20),
            _SooktaTextField(controller: nameController, label: text.fullName),
            const SizedBox(height: 12),
            _SooktaTextField(
              controller: ageController,
              label: text.age,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Text(text.gender, style: const TextStyle(color: Color(0xFF5C9A81))),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _GenderButton(
                  label: text.male,
                  selected: gender == 'Male',
                  onTap: () => setState(() => gender = 'Male'),
                ),
                _GenderButton(
                  label: text.female,
                  selected: gender == 'Female',
                  onTap: () => setState(() => gender = 'Female'),
                ),
              ],
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
              child: Text(text.next, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAndContinue() {
    AppStateScope.of(context).saveProfile(
      UserProfile(
        name: nameController.text,
        age: ageController.text,
        gender: gender,
        weight: weightController.text,
        height: heightController.text,
        incomePerYear: incomeController.text,
      ),
    );
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
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
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
