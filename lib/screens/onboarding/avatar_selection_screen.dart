import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_state.dart';
import '../../app/app_text.dart';
import '../../app/assets.dart';
import '../../app/sookta_app.dart';
import '../../core/services/local_image_store.dart';
import '../main/camera_capture_screen.dart';
import '../main/main_tabs_screen.dart';

class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key});

  static const routeName = '/avatar';

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  static const avatars = [
    SooktaAssets.male01,
    SooktaAssets.female01,
    SooktaAssets.male02,
    SooktaAssets.female02,
  ];

  final imagePicker = ImagePicker();
  String? selectedAvatar;
  var pickingAvatar = false;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final text = AppText(state.language ?? AppLanguage.th);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                text.avatarTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5C9A81),
                ),
              ),
              Text(text.avatarSubtitle,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              CircleAvatar(
                radius: 75,
                backgroundColor: Colors.grey.shade300,
                foregroundImage: _avatarProvider(selectedAvatar),
                child: selectedAvatar == null
                    ? const Icon(Icons.person, size: 80, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FilledButton.icon(
                    onPressed: pickingAvatar ? null : _captureAvatar,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(text.takePhoto),
                  ),
                  OutlinedButton.icon(
                    onPressed: pickingAvatar ? null : _pickAvatarFromGallery,
                    icon: const Icon(Icons.image),
                    label: Text(text.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text.avatarHint,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                itemCount: avatars.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final avatar = avatars[index];
                  final selected = selectedAvatar == avatar;
                  return _AvatarTile(
                    asset: avatar,
                    selected: selected,
                    onTap: () => setState(() => selectedAvatar = avatar),
                  );
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: selectedAvatar == null ? null : _finish,
                  child: Text(text.confirmAvatar,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureAvatar() async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );
    if (path != null) await _saveAvatarPath(path);
  }

  Future<void> _pickAvatarFromGallery() async {
    final photo = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (photo != null) await _saveAvatarPath(photo.path);
  }

  Future<void> _saveAvatarPath(String path) async {
    setState(() => pickingAvatar = true);
    try {
      final savedPath = await LocalImageStore.saveImageFile(
        path,
        prefix: 'sookta_avatar',
      );
      if (mounted) setState(() => selectedAvatar = savedPath);
    } finally {
      if (mounted) setState(() => pickingAvatar = false);
    }
  }

  ImageProvider? _avatarProvider(String? path) {
    if (path == null) return null;
    if (path.startsWith('/')) return FileImage(File(path));
    return AssetImage(path);
  }

  void _finish() {
    AppStateScope.of(context).saveAvatarAndFinish(selectedAvatar!);
    Navigator.of(context).pushNamedAndRemoveUntil(
      MainTabsScreen.routeName,
      (route) => false,
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: selected ? 3 : 1,
                color:
                    selected ? const Color(0xFF5C9A81) : Colors.grey.shade300,
              ),
            ),
            child: ClipOval(child: Image.asset(asset, fit: BoxFit.cover)),
          ),
          if (selected)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF5C9A81).withValues(alpha: 0.3),
              ),
              child: const Icon(Icons.check, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
