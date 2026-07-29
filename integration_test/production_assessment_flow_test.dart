import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:fsookta/app/app_state.dart';
import 'package:fsookta/app/sookta_app.dart';
import 'package:fsookta/core/models/assessment_session.dart';
import 'package:fsookta/core/models/evaluation_models.dart';
import 'package:fsookta/screens/main/evaluation_form_screen.dart';
import 'package:fsookta/screens/main/initial_risk_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('readable production media reaches the result workflow',
      (tester) async {
    final directory = await getTemporaryDirectory();
    const assetPaths = <String>[
      'assets/images/example_harvesting_pose.png',
      'assets/images/example_pruning_pose.png',
      'assets/images/example_harvesting_pose.png',
      'assets/images/example_pruning_pose.png',
    ];
    final mediaFiles = <File>[];
    for (var index = 0; index < assetPaths.length; index += 1) {
      final bytes = await rootBundle.load(assetPaths[index]);
      final media =
          File('${directory.path}/production-readable-pose-$index.png');
      await media.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      mediaFiles.add(media);
    }
    addTearDown(() async {
      for (final media in mediaFiles) {
        if (await media.exists()) await media.delete();
      }
    });

    final state = SooktaAppState()..setLanguage(AppLanguage.th);
    addTearDown(state.dispose);
    await state.saveEvaluationDraft(
      EvaluationDraft(
        activity: SooktaActivity.harvesting,
        jobType: JobType.reba,
        selectedImagePaths:
            mediaFiles.map((media) => media.path).toList(growable: false),
        selectedToolId: SooktaActivity.harvesting.defaultToolOption.id,
        durationHours: 4,
        frequency: 6.5,
        workDaysPerWeek: 5,
      ),
    );

    await tester.pumpWidget(
      AppStateScope(
        state: state,
        child: MaterialApp(
          home: const EvaluationFormScreen(
            activity: SooktaActivity.harvesting,
          ),
          onGenerateRoute: (settings) {
            if (settings.name != InitialRiskScreen.routeName) return null;
            expect(settings.arguments, isA<InitialRiskPayload>());
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(
                body: Center(
                  child: Text(
                    'production result route',
                    key: ValueKey<String>('production-result-route'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    final button = find.widgetWithText(FilledButton, 'ดูผลประเมิน');
    await tester.scrollUntilVisible(
      button,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    for (var attempt = 0; attempt < 120; attempt += 1) {
      await tester.pump(const Duration(milliseconds: 500));
      final enabled = tester
          .widgetList<FilledButton>(button)
          .any((widget) => widget.onPressed != null);
      if (enabled) break;
    }
    final visibleText = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data)
        .whereType<String>()
        .where((text) => text.trim().isNotEmpty)
        .toSet()
        .join(' | ');
    expect(
      tester
          .widgetList<FilledButton>(button)
          .any((widget) => widget.onPressed != null),
      isTrue,
      reason: 'Readable bundled poses did not satisfy production readiness. '
          'Visible status: $visibleText',
    );

    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('production-result-route')),
      findsOneWidget,
    );
  });
}
