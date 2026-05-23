import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SooktaTtsButton extends StatefulWidget {
  const SooktaTtsButton({
    required this.text,
    required this.thai,
    this.size = 36,
    super.key,
  });

  final String text;
  final bool thai;
  final double size;

  @override
  State<SooktaTtsButton> createState() => _SooktaTtsButtonState();
}

class _SooktaTtsButtonState extends State<SooktaTtsButton> {
  late final FlutterTts _tts;
  late Future<void> _configured;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _configured = _configure();
  }

  Future<void> _configure() async {
    if (Platform.isIOS) {
      await _tts.setSharedInstance(true);
      await _tts.autoStopSharedSession(false);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );
    }
    await _tts.setVolume(1.0);
    await _tts.setLanguage(widget.thai ? 'th-TH' : 'en-US');
    await _tts.setSpeechRate(widget.thai ? 0.45 : 0.48);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    _tts.setStartHandler(() {
      if (mounted) setState(() => _speaking = true);
    });
    _tts.setCompletionHandler(_stopIndicator);
    _tts.setCancelHandler(_stopIndicator);
    _tts.setErrorHandler((_) => _stopIndicator());
  }

  @override
  void didUpdateWidget(covariant SooktaTtsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thai != widget.thai) {
      _configured = _configure();
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_speaking) {
      await _tts.stop();
      _stopIndicator();
      return;
    }
    if (widget.text.trim().isEmpty) return;
    try {
      await _configured;
      if (!mounted) return;
      setState(() => _speaking = true);
      final result = await _tts.speak(widget.text.trim());
      if (result == 0) {
        _showTtsError();
      }
    } catch (_) {
      _showTtsError();
    }
  }

  void _showTtsError() {
    _stopIndicator();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.thai
              ? 'ยังเปิดเสียงอ่านข้อความไม่ได้ กรุณาเพิ่มเสียงเครื่องแล้วลองอีกครั้ง'
              : 'Could not play speech. Turn up device volume and try again.',
        ),
      ),
    );
  }

  void _stopIndicator() {
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.thai ? 'อ่านข้อความ' : 'Read aloud';
    return Tooltip(
      message: label,
      child: IconButton(
        iconSize: widget.size * 0.56,
        constraints: BoxConstraints.tightFor(
          width: widget.size,
          height: widget.size,
        ),
        padding: EdgeInsets.zero,
        onPressed: _toggle,
        icon: Icon(_speaking ? Icons.stop_circle : Icons.volume_up),
        color: const Color(0xFF5C9A81),
        tooltip: label,
      ),
    );
  }
}
