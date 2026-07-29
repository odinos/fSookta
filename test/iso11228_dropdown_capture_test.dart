import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/core/theme/sookta_theme.dart';
import 'package:fsookta/screens/main/evaluation_form_screen.dart';

void main() {
  testWidgets('captures ISO11228-2 dropdown inputs for manual', (tester) async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async {
        if (call.method == 'getVoices') return <Map<String, Object?>>[];
        if (call.method == 'getLanguages') return <String>['th-TH', 'en-US'];
        if (call.method == 'getDefaultVoice') return <String, Object?>{};
        return 1;
      },
    );
    await tester.runAsync(_loadRobotoTestFont);
    await tester.runAsync(_loadMaterialIconsTestFont);
    await _captureScenario(
      tester: tester,
      activity: SooktaActivity.pesticide,
      language: AppLanguage.en,
      fontFamily: 'Roboto',
      expectedForceLabel: 'Initial push/pull force',
      suffix: 'en',
      profile: const UserProfile(
        farmerId: 'FARM-001',
        name: 'Sample farmer',
        role: 'farmer',
        age: '45',
        gender: 'Female',
        weight: '55',
        height: '158',
        incomePerYear: '120000',
      ),
    );
  });

  testWidgets('captures Thai ISO11228-2 dropdown inputs for manual',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async {
        if (call.method == 'getVoices') return <Map<String, Object?>>[];
        if (call.method == 'getLanguages') return <String>['th-TH', 'en-US'];
        if (call.method == 'getDefaultVoice') return <String, Object?>{};
        return 1;
      },
    );
    await tester.runAsync(_loadTahomaTestFont);
    await tester.runAsync(_loadMaterialIconsTestFont);
    await _captureScenario(
      tester: tester,
      activity: SooktaActivity.pesticide,
      language: AppLanguage.th,
      fontFamily: 'Tahoma',
      expectedForceLabel: 'แรงเริ่มต้นดัน/ลาก',
      suffix: 'th',
      profile: const UserProfile(
        farmerId: 'FARM-001',
        name: 'ตัวอย่างชาวสวน',
        role: 'ชาวสวน',
        age: '45',
        gender: 'Female',
        weight: '55',
        height: '158',
        incomePerYear: '120000',
      ),
    );
  });

  testWidgets('captures Thai dropdown inputs for every activity',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async {
        if (call.method == 'getVoices') return <Map<String, Object?>>[];
        if (call.method == 'getLanguages') return <String>['th-TH', 'en-US'];
        if (call.method == 'getDefaultVoice') return <String, Object?>{};
        return 1;
      },
    );
    await tester.runAsync(_loadTahomaTestFont);
    await tester.runAsync(_loadMaterialIconsTestFont);
    for (final activity in SooktaActivity.values) {
      await _captureScenario(
        tester: tester,
        activity: activity,
        language: AppLanguage.th,
        fontFamily: 'Tahoma',
        expectedForceLabel: activity.defaultJobType == JobType.pushPull
            ? 'แรงเริ่มต้นดัน/ลาก'
            : null,
        suffix: 'th_${activity.name}',
        profile: const UserProfile(
          farmerId: 'FARM-001',
          name: 'ตัวอย่างชาวสวน',
          role: 'ชาวสวน',
          age: '45',
          gender: 'Female',
          weight: '55',
          height: '158',
          incomePerYear: '120000',
        ),
        openInitialForceMenu: false,
      );
    }
  });
}

Future<void> _captureScenario({
  required WidgetTester tester,
  required SooktaActivity activity,
  required AppLanguage language,
  required String fontFamily,
  required String suffix,
  required UserProfile profile,
  String? expectedForceLabel,
  bool openInitialForceMenu = true,
}) async {
  final state = SooktaAppState()
    ..setLanguage(language)
    ..saveProfile(profile);
  addTearDown(state.dispose);

  tester.view.physicalSize = const Size(1290, 9000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final theme = buildSooktaTheme();
  final captureKey = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: captureKey,
      child: AppStateScope(
        state: state,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme.copyWith(
            textTheme: theme.textTheme.apply(fontFamily: fontFamily),
            primaryTextTheme:
                theme.primaryTextTheme.apply(fontFamily: fontFamily),
          ),
          home: EvaluationFormScreen(
            activity: activity,
            initiallyShowAdvancedDetails: true,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();

  expect(find.textContaining(activity.label(thai: language == AppLanguage.th)),
      findsWidgets);
  if (expectedForceLabel != null) {
    expect(find.text(expectedForceLabel), findsOneWidget);
  }

  await tester.runAsync(
    () => _capture(captureKey, 'iso11228_2_dropdowns_closed_$suffix'),
  );

  if (openInitialForceMenu) {
    await tester.tap(find.byType(DropdownButtonFormField<double>).at(3));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => _capture(captureKey, 'iso11228_2_initial_force_options_$suffix'),
    );
  }
}

Future<void> _loadRobotoTestFont() async {
  final bytes = await File(
    '/Users/kpc/develop/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  ).readAsBytes();
  final loader = FontLoader('Roboto')
    ..addFont(
      Future.value(
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
      ),
    );
  await loader.load();
}

Future<void> _loadTahomaTestFont() async {
  final bytes =
      await File('/System/Library/Fonts/Supplemental/Tahoma.ttf').readAsBytes();
  final loader = FontLoader('Tahoma')
    ..addFont(
      Future.value(
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
      ),
    );
  await loader.load();
}

Future<void> _loadMaterialIconsTestFont() async {
  final bytes = await File(
    '/Users/kpc/develop/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytes();
  final loader = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes),
      ),
    );
  await loader.load();
}

Future<void> _capture(GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  if (byteData == null) {
    throw StateError('Unable to encode screenshot: $name');
  }
  final file = File('build/manual_screenshots/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
}
