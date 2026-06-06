import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../app/research_profile_defaults.dart';
import '../../app/sookta_app.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/tts_button.dart';
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
  final locationController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  final incomeController = TextEditingController();
  String gender = 'Male';
  String selectedRole = '';
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
    final language = AppStateScope.of(context).language ?? AppLanguage.th;
    farmerIdController.text = profile.farmerId.isEmpty
        ? ResearchProfileDefaults.participantCode()
        : profile.farmerId;
    nameController.text = profile.name;
    selectedRole = ResearchProfileDefaults.normalizedRole(
      profile.role,
      language,
    );
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
            const SizedBox(height: 12),
            _SetupVoiceGuideCard(
              thai: text.isThai,
              editMode: widget.editMode,
            ),
            const SizedBox(height: 20),
            _SooktaTextField(
              controller: farmerIdController,
              label: text.farmerId,
              helperText: text.participantCodeHint,
              thai: text.isThai,
              ttsText: text.isThai
                  ? '${text.farmerId}. ${text.participantCodeHint}'
                  : '${text.farmerId}. ${text.participantCodeHint}',
              suffixIcon: IconButton(
                tooltip: text.isThai ? 'สุ่มรหัสใหม่' : 'Generate new code',
                onPressed: () {
                  setState(() {
                    farmerIdController.text =
                        ResearchProfileDefaults.participantCode();
                  });
                },
                icon: const Icon(Icons.refresh),
              ),
            ),
            const SizedBox(height: 12),
            _SooktaTextField(
              controller: nameController,
              label: text.fullName,
              thai: text.isThai,
              ttsText: text.isThai
                  ? '${text.fullName}. กรอกชื่อผู้เข้าร่วมวิจัยหรือชื่อที่ใช้ระบุตัวตนในพื้นที่'
                  : '${text.fullName}. Enter the participant name or field identifier.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    text.role,
                    style: const TextStyle(color: Color(0xFF5C9A81)),
                  ),
                ),
                SooktaTtsButton(
                  thai: text.isThai,
                  text: text.isThai
                      ? '${text.role}. เลือกบทบาทเป็น ${text.roleFarmer} หรือ ${text.roleStaff}'
                      : '${text.role}. Choose ${text.roleFarmer} or ${text.roleStaff}.',
                  size: 34,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                    value: text.roleFarmer, label: Text(text.roleFarmer)),
                ButtonSegment(
                    value: text.roleStaff, label: Text(text.roleStaff)),
              ],
              selected: {
                selectedRole == text.roleStaff
                    ? text.roleStaff
                    : text.roleFarmer,
              },
              onSelectionChanged: (selection) {
                setState(() => selectedRole = selection.first);
              },
            ),
            const SizedBox(height: 12),
            _SooktaTextField(
              controller: locationController,
              label: text.location,
              helperText: text.optionalLocationNote,
              thai: text.isThai,
              ttsText: text.isThai
                  ? '${text.location}. ${text.optionalLocationNote}'
                  : '${text.location}. ${text.optionalLocationNote}',
            ),
            const SizedBox(height: 12),
            _SooktaTextField(
              controller: ageController,
              label: text.age,
              keyboardType: TextInputType.number,
              thai: text.isThai,
              ttsText: text.isThai
                  ? '${text.age}. กรอกอายุเป็นตัวเลข ใช้สำหรับข้อมูลรายงาน'
                  : '${text.age}. Enter age as a number for report data.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    text.gender,
                    style: const TextStyle(color: Color(0xFF5C9A81)),
                  ),
                ),
                SooktaTtsButton(
                  thai: text.isThai,
                  text: text.isThai
                      ? '${text.gender}. เลือกเพศชายหรือเพศหญิง ระบบใช้เพศในสูตรบางส่วนของงานยกและงานดันดึง'
                      : '${text.gender}. Choose male or female. The app uses gender in selected lifting and push-pull calculations.',
                  size: 34,
                ),
              ],
            ),
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
              thai: text.isThai,
              ttsText: text.isThai
                  ? '${text.weight}. กรอกน้ำหนักตัวเป็นตัวเลข ใช้สำหรับข้อมูลรายงาน'
                  : '${text.weight}. Enter body weight as a number for report data.',
            ),
            const SizedBox(height: 12),
            _SooktaTextField(
              controller: heightController,
              label: text.height,
              keyboardType: TextInputType.number,
              thai: text.isThai,
              ttsText: text.isThai
                  ? '${text.height}. กรอกส่วนสูงเป็นตัวเลข ใช้สำหรับข้อมูลรายงาน'
                  : '${text.height}. Enter height as a number for report data.',
            ),
            const SizedBox(height: 12),
            _SooktaTextField(
              controller: incomeController,
              label: text.income,
              keyboardType: TextInputType.number,
              thai: text.isThai,
              ttsText: text.isThai
                  ? '${text.income}. ${text.incomeNote}'
                  : '${text.income}. ${text.incomeNote}',
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
        profileId: currentProfile.profileId,
        farmerId: farmerIdController.text.trim(),
        name: nameController.text,
        role: selectedRole.trim(),
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

class _SetupVoiceGuideCard extends StatelessWidget {
  const _SetupVoiceGuideCard({
    required this.thai,
    required this.editMode,
  });

  final bool thai;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    final title = thai
        ? (editMode ? 'คำแนะนำการแก้ไขข้อมูล' : 'คำแนะนำการกรอกข้อมูล')
        : (editMode ? 'Profile editing guide' : 'Profile setup guide');
    final body = thai
        ? 'กรอกรหัสผู้เข้าร่วม ชื่อ บทบาท อายุ เพศ น้ำหนัก ส่วนสูง และรายได้ต่อปี ข้อมูลอายุ น้ำหนัก และส่วนสูงใช้เก็บในรายงาน ส่วนเพศและรายได้ใช้ประกอบการคำนวณบางส่วน หากไม่ทราบพื้นที่ สามารถเว้นว่างได้'
        : 'Enter participant code, name, role, age, gender, weight, height, and annual income. Age, weight, and height are stored for reports. Gender and income are used in selected calculations. Location can be left blank if unknown.';
    return Card(
      color: const Color(0xFFEAF5EF),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.record_voice_over_outlined,
                color: Color(0xFF5C9A81)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            SooktaTtsButton(text: '$title. $body', thai: thai, size: 42),
          ],
        ),
      ),
    );
  }
}

class _SooktaTextField extends StatelessWidget {
  const _SooktaTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.helperText,
    this.suffixIcon,
    this.ttsText,
    this.thai,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? helperText;
  final Widget? suffixIcon;
  final String? ttsText;
  final bool? thai;

  @override
  Widget build(BuildContext context) {
    final readText = ttsText?.trim();
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        suffixIcon: suffixIcon,
        suffixIconConstraints: suffixIcon == null
            ? null
            : const BoxConstraints(minWidth: 48, minHeight: 48),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5C9A81)),
        ),
      ),
    );
    if (readText == null || readText.isEmpty) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SooktaTtsButton(
              text: readText,
              thai: thai ?? true,
              size: 30,
            ),
          ),
        ),
      ],
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
