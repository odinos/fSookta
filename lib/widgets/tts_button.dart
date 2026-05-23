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
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _configure();
  }

  Future<void> _configure() async {
    await _tts.setLanguage(widget.thai ? 'th-TH' : 'en-US');
    await _tts.setSpeechRate(widget.thai ? 0.45 : 0.48);
    await _tts.setPitch(1);
    await _tts.awaitSpeakCompletion(false);
    _tts.setCompletionHandler(_stopIndicator);
    _tts.setCancelHandler(_stopIndicator);
    _tts.setErrorHandler((_) => _stopIndicator());
  }

  @override
  void didUpdateWidget(covariant SooktaTtsButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thai != widget.thai) {
      _tts.setLanguage(widget.thai ? 'th-TH' : 'en-US');
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
    setState(() => _speaking = true);
    await _tts.speak(widget.text);
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
