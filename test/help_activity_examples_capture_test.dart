import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fsookta/app/assets.dart';
import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/theme/sookta_theme.dart';
import 'package:fsookta/screens/main/help_screen.dart';

void main() {
  testWidgets('captures help activity image examples', (tester) async {
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

    tester.view.physicalSize = const Size(1290, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);
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
              textTheme: theme.textTheme.apply(fontFamily: 'Tahoma'),
              primaryTextTheme:
                  theme.primaryTextTheme.apply(fontFamily: 'Tahoma'),
            ),
            routes: {
              ReferencesScreen.routeName: (_) => const ReferencesScreen(),
            },
            home: const HelpScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _precacheHelpAssets(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('คู่มือการใช้งาน'), findsOneWidget);
    expect(find.byKey(const ValueKey('manual_pdf_page_1')), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1800));
    await tester.pumpAndSettle();
    expect(find.text('ตัวอย่างภาพที่ควรถ่ายตามหมวดงาน'), findsOneWidget);
    await tester.runAsync(
      () => _capture(captureKey, 'help_activity_examples_th'),
    );

    final fertilizingExample =
        find.byKey(const ValueKey('help_activity_example_fertilizing'));
    await tester.ensureVisible(fertilizingExample);
    await tester.pumpAndSettle();
    await tester.tap(fertilizingExample);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('asset_image_full_preview')),
      findsOneWidget,
    );
    await tester.runAsync(
      () => _capture(captureKey, 'help_activity_example_full_preview_th'),
    );
  });
}

Future<void> _precacheHelpAssets(WidgetTester tester) async {
  final context = tester.element(find.byType(HelpScreen));
  await tester.runAsync(() async {
    for (final asset in <String>{
      SooktaAssets.readablePoseExample,
      SooktaAssets.userManualPage1,
      SooktaAssets.userManualPage2,
      SooktaAssets.userManualPage3,
      SooktaAssets.userManualPage4,
      SooktaAssets.userManualPage5,
      for (final activity in SooktaActivity.values) activity.imageAsset,
      for (final activity in SooktaActivity.values)
        activity.readablePoseExampleAsset,
    }) {
      await precacheImage(AssetImage(asset), context).timeout(
        const Duration(seconds: 3),
      );
    }
  });
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
