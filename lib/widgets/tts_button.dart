import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
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
  static const _thaiRate = 0.36;
  static const _englishRate = 0.42;

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
      final sharedResult = await _tts.setSharedInstance(true);
      final categoryResult = await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );
      await _tts.autoStopSharedSession(false);
      _debug('iOS audio shared=$sharedResult category=$categoryResult');
    }
    final volumeResult = await _tts.setVolume(1.0);
    final languageResult = await _configureVoice();
    _debug('volume=$volumeResult voiceOrLanguage=$languageResult');
    await _tts.setSpeechRate(widget.thai ? _thaiRate : _englishRate);
    await _tts.setPitch(widget.thai ? 0.96 : 0.98);
    await _tts.awaitSpeakCompletion(true);
    _tts.setStartHandler(() {
      _debug('start speaking');
      if (mounted) setState(() => _speaking = true);
    });
    _tts.setCompletionHandler(() {
      _debug('completed speaking');
      _stopIndicator();
    });
    _tts.setCancelHandler(() {
      _debug('cancelled speaking');
      _stopIndicator();
    });
    _tts.setErrorHandler((message) {
      _debug('tts error: $message');
      _stopIndicator();
    });
  }

  Future<dynamic> _configureVoice() async {
    final desiredLocale = widget.thai ? 'th-TH' : 'en-US';
    if (Platform.isIOS) {
      final voices = await _tts.getVoices;
      final voice = _bestVoiceForLocale(voices, desiredLocale);
      _debug('available voices=${voices is List ? voices.length : 'unknown'} '
          'desired=$desiredLocale selected=$voice');
      if (voice != null) {
        return _tts.setVoice(voice);
      }
    }
    final available = await _tts.isLanguageAvailable(desiredLocale);
    _debug('language $desiredLocale available=$available');
    return _tts.setLanguage(desiredLocale);
  }

  Map<String, String>? _bestVoiceForLocale(dynamic voices, String locale) {
    if (voices is! List) return null;
    final normalizedLocale = locale.toLowerCase();
    final matching = voices.whereType<Map>().where((voice) {
      final voiceLocale = voice['locale']?.toString().toLowerCase();
      return voiceLocale == normalizedLocale ||
          voiceLocale?.startsWith(normalizedLocale.split('-').first) == true;
    }).toList();
    if (matching.isEmpty) return null;
    matching.sort((a, b) => _voiceRank(b).compareTo(_voiceRank(a)));
    return matching.first.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }

  int _voiceRank(Map<dynamic, dynamic> voice) {
    final quality = voice['quality']?.toString() ?? '';
    final name = voice['name']?.toString().toLowerCase() ?? '';
    var rank = _qualityRank(quality) * 10;
    if (name.contains('premium')) rank += 5;
    if (name.contains('enhanced')) rank += 4;
    if (name.contains('siri')) rank += 3;
    if (name.contains('compact')) rank -= 3;
    return rank;
  }

  int _qualityRank(String quality) {
    final lower = quality.toLowerCase();
    if (lower.contains('premium')) return 3;
    if (lower.contains('enhanced')) return 2;
    return 1;
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
      final text = _speechText(widget.text, widget.thai);
      _debug('speak requested chars=${text.length} thai=${widget.thai}');
      final result = await _tts.speak(text);
      _debug('speak result=$result');
      if (result == 0) {
        _showTtsError();
      }
    } catch (_) {
      _showTtsError();
    }
  }

  String _speechText(String raw, bool thai) {
    var text = raw
        .replaceAll(RegExp(r'https?:\/\/\S+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('•', '. ')
        .replaceAll('→', thai ? ' ไปเป็น ' : ' to ')
        .replaceAll('->', thai ? ' ไปเป็น ' : ' to ')
        .replaceAll('/', thai ? ' และ ' : ' and ')
        .trim();
    if (thai) {
      text = text
          .replaceAll('REBA', 'รีบา')
          .replaceAll('ISO11228', 'ไอ เอส โอ หนึ่ง หนึ่ง สอง สอง แปด')
          .replaceAll('ISO 11228', 'ไอ เอส โอ หนึ่ง หนึ่ง สอง สอง แปด')
          .replaceAll('XGBoost', 'เอ็กซ์ จี บูสต์')
          .replaceAll('MoveNet', 'มูฟเน็ต')
          .replaceAll('TFLite', 'ที เอฟ ไลต์')
          .replaceAll('H/V', 'เอช และ วี')
          .replaceAll(RegExp(r'\bkg\b', caseSensitive: false), 'กิโลกรัม')
          .replaceAll('กก.', 'กิโลกรัม')
          .replaceAll('ชม.', 'ชั่วโมง')
          .replaceAll(RegExp(r'\bN\b'), 'นิวตัน')
          .replaceAll('THB', 'บาท');
    } else {
      text = text
          .replaceAll('REBA', 'R E B A')
          .replaceAll('ISO11228', 'ISO eleven two twenty eight')
          .replaceAll('ISO 11228', 'ISO eleven two twenty eight')
          .replaceAll('XGBoost', 'X G Boost')
          .replaceAll('MoveNet', 'Move Net')
          .replaceAll('H/V', 'H and V');
    }
    return text;
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

  void _debug(String message) {
    if (kDebugMode) debugPrint('SooktaTTS: $message');
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.thai ? 'อ่านข้อความ' : 'Read aloud';
    return Semantics(
      label: label,
      button: true,
      enabled: true,
      onTap: _toggle,
      child: ExcludeSemantics(
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
        ),
      ),
    );
  }
}
