import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../app/research_profile_defaults.dart';
import '../../app/sookta_app.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/responsive_content.dart';

class FarmerManagerScreen extends StatelessWidget {
  const FarmerManagerScreen({super.key});

  static const routeName = '/farmers';

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final text = AppText(state.language ?? AppLanguage.th);
    final thai = text.isThai;
    final farmers = state.farmers;

    return Scaffold(
      appBar: AppBar(
        title: Text(thai ? 'จัดการรายชื่อชาวสวน' : 'Manage Farmers'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, text),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(thai ? 'เพิ่มคน' : 'Add'),
      ),
      body: SafeArea(
        child: farmers.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    thai
                        ? 'ยังไม่มีรายชื่อชาวสวน กดเพิ่มคนเพื่อเริ่มเก็บข้อมูล'
                        : 'No farmers yet. Add a farmer to start collecting data.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ResponsiveListView(
                maxWidth: 680,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Card(
                    color: const Color(0xFFF4FBF5),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: SooktaColors.darkGreen),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              thai
                                  ? 'เลือกชื่อก่อนประเมิน เพื่อให้ประวัติและไฟล์ export ผูกกับชาวสวนคนนั้น'
                                  : 'Select a farmer before assessment so history and exports are linked correctly.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final farmer in farmers) ...[
                    _FarmerCard(
                      farmer: farmer,
                      selected: farmer.profileId == state.activeProfileId,
                      historyCount:
                          state.historyForFarmer(farmer.profileId).length,
                      thai: thai,
                      onSelect: () => state.selectFarmer(farmer.profileId),
                      onEdit: () => _showEditor(context, text, farmer: farmer),
                      onDelete: () => _confirmDelete(context, farmer, thai),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    AppText text, {
    UserProfile? farmer,
  }) async {
    final state = AppStateScope.of(context);
    final thai = text.isThai;
    final farmerId = TextEditingController(
      text: farmer?.farmerId.isNotEmpty == true
          ? farmer!.farmerId
          : ResearchProfileDefaults.participantCode(),
    );
    final name = TextEditingController(text: farmer?.name ?? '');
    final location = TextEditingController(text: farmer?.location ?? '');
    final age = TextEditingController(text: farmer?.age ?? '');
    final weight = TextEditingController(text: farmer?.weight ?? '');
    final height = TextEditingController(text: farmer?.height ?? '');
    final income = TextEditingController(text: farmer?.incomePerYear ?? '');
    var gender = farmer?.gender ?? 'Male';
    var selectedRole = ResearchProfileDefaults.normalizedRole(
      farmer?.role ?? '',
      text.language,
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                farmer == null
                    ? (thai ? 'เพิ่มชาวสวน' : 'Add Farmer')
                    : (thai ? 'แก้ไขข้อมูล' : 'Edit Farmer'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Field(
                      controller: farmerId,
                      label: text.farmerId,
                      helperText: text.participantCodeHint,
                      suffixIcon: IconButton(
                        tooltip: thai ? 'สุ่มรหัสใหม่' : 'Generate new code',
                        onPressed: () {
                          setDialogState(() {
                            farmerId.text =
                                ResearchProfileDefaults.participantCode();
                          });
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                    _Field(controller: name, label: text.fullName),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        text.role,
                        style: const TextStyle(color: SooktaColors.darkGreen),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: text.roleFarmer,
                          label: Text(text.roleFarmer),
                        ),
                        ButtonSegment(
                          value: text.roleStaff,
                          label: Text(text.roleStaff),
                        ),
                      ],
                      selected: {
                        selectedRole == text.roleStaff
                            ? text.roleStaff
                            : text.roleFarmer,
                      },
                      onSelectionChanged: (selection) {
                        setDialogState(() => selectedRole = selection.first);
                      },
                    ),
                    const SizedBox(height: 10),
                    _Field(
                      controller: location,
                      label: text.location,
                      helperText: text.optionalLocationNote,
                    ),
                    _Field(
                      controller: age,
                      label: text.age,
                      keyboardType: TextInputType.number,
                    ),
                    _Field(
                      controller: weight,
                      label: text.weight,
                      keyboardType: TextInputType.number,
                    ),
                    _Field(
                      controller: height,
                      label: text.height,
                      keyboardType: TextInputType.number,
                    ),
                    _Field(
                      controller: income,
                      label: text.income,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'Male', label: Text(text.male)),
                        ButtonSegment(
                            value: 'Female', label: Text(text.female)),
                      ],
                      selected: {gender},
                      onSelectionChanged: (selection) {
                        setDialogState(() => gender = selection.first);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(thai ? 'ยกเลิก' : 'Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(thai ? 'บันทึก' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    final updated = UserProfile(
      profileId: farmer?.profileId ?? '',
      farmerId: farmerId.text.trim(),
      name: name.text.trim(),
      role: selectedRole,
      location: location.text.trim(),
      age: age.text.trim(),
      gender: gender,
      weight: weight.text.trim(),
      height: height.text.trim(),
      incomePerYear: income.text.trim(),
      avatarAsset: farmer?.avatarAsset,
    );
    if (farmer == null) {
      state.addFarmer(updated);
    } else {
      state.updateFarmer(updated);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    UserProfile farmer,
    bool thai,
  ) async {
    final state = AppStateScope.of(context);
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(thai ? 'ลบรายชื่อนี้?' : 'Delete this farmer?'),
        content: Text(
          thai
              ? 'ประวัติเดิมจะยังอยู่ แต่จะไม่เห็นชื่อนี้ในรายการเลือก'
              : 'Existing history remains, but this farmer will be removed from the picker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(thai ? 'ยกเลิก' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(thai ? 'ลบ' : 'Delete'),
          ),
        ],
      ),
    );
    if (delete == true) state.deleteFarmer(farmer.profileId);
  }
}

class _FarmerCard extends StatelessWidget {
  const _FarmerCard({
    required this.farmer,
    required this.selected,
    required this.historyCount,
    required this.thai,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final UserProfile farmer;
  final bool selected;
  final int historyCount;
  final bool thai;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onSelect,
        leading: CircleAvatar(
          backgroundColor:
              selected ? SooktaColors.leafGreen : Colors.grey.shade300,
          child: Icon(
            selected ? Icons.check : Icons.person_outline,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
        title: Text(
          farmer.name.isEmpty
              ? (thai ? 'ไม่ระบุชื่อ' : 'Unnamed')
              : farmer.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          [
            if (farmer.farmerId.isNotEmpty) farmer.farmerId,
            if (farmer.location.isNotEmpty) farmer.location,
            thai ? '$historyCount รายการ' : '$historyCount records',
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: thai ? 'แก้ไข' : 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: thai ? 'ลบ' : 'Delete',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.helperText,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? helperText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
