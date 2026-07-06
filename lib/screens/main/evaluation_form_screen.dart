import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_state.dart';
import '../../app/sookta_app.dart';
import '../../core/ergonomics_risk_prediction/ergonomics_risk_prediction.dart'
    as risk_ml;
import '../../core/models/assessment_session.dart';
import '../../core/models/evaluation_models.dart';
import '../../core/services/ergo_calculator.dart';
import '../../core/services/firebase_telemetry_service.dart';
import '../../core/services/pose_estimation_service.dart';
import '../../core/services/video_frame_extraction_service.dart';
import '../../core/theme/sookta_theme.dart';
import '../../widgets/responsive_content.dart';
import '../../widgets/tts_button.dart';
import 'camera_capture_screen.dart';
import 'initial_risk_screen.dart';

class EvaluationFormScreen extends StatefulWidget {
  const EvaluationFormScreen({
    required this.activity,
    this.initiallyShowAdvancedDetails = false,
    super.key,
  });

  static const routeName = '/evaluation-form';

  final SooktaActivity activity;
  final bool initiallyShowAdvancedDetails;

  @override
  State<EvaluationFormScreen> createState() => _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends State<EvaluationFormScreen> {
  final horizontalController = TextEditingController(text: '25');
  final verticalController = TextEditingController(text: '75');
  final transportController = TextEditingController(text: '4');
  final imagePicker = ImagePicker();
  final poseService = PoseEstimationService();
  final videoFrameService = const VideoFrameExtractionService();
  risk_ml.JointFeatureSchema? jointFeatureSchema;
  risk_ml.MoveNetJointFeatureExtractor? jointFeatureExtractor;
  risk_ml.XGBoostOnnxPredictor? xGBoostPredictor;
  Timer? draftSaveTimer;

  final selectedImagePaths = <String>[];
  final latestPoseEstimates = <PoseEstimate>[];
  final latestFrameAnalyses = <PoseRebaFrameAnalysis>[];
  final latestFrameTimestampMs = <int>[];
  var selectedDurationHours = 1.0;
  var selectedFrequency = 0.2;
  var selectedStaticHoldLevel = 0;
  var selectedWorkDaysPerWeek = 3.0;
  var selectedLoadWeight = 10.0;
  var selectedPushPullDistance = 10.0;
  var selectedInitialForce = 18.0;
  var selectedSustainForce = 10.0;
  var showAdvancedDetails = false;
  var poseBusy = false;
  var poseAssessmentReady = false;
  String? poseStatus;
  late String selectedToolId;
  AiRiskAlert? latestXGBoostAlert;
  MotionAnalysisSummary? latestMotionSummary;
  var latestCaptureSourceKind = 'photo_set';
  int? latestVideoDurationMs;
  late JobType selectedJobType;
  var draftApplied = false;
  var restoredDraft = false;
  var hydratingDraft = false;
  var rebaInput = const RebaInputData(
    trunkScore: 3,
    neckScore: 1,
    legScore: 1,
    upperArmScore: 2,
    lowerArmScore: 1,
    wristScore: 1,
  );

  @override
  void initState() {
    super.initState();
    selectedJobType = widget.activity.defaultJobType;
    selectedToolId = widget.activity.defaultToolOption.id;
    showAdvancedDetails = widget.initiallyShowAdvancedDetails;
    _applyActivityDefaults();
    horizontalController.addListener(_onNumberTextChanged);
    verticalController.addListener(_onNumberTextChanged);
    transportController.addListener(_onNumberTextChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (draftApplied) return;
    draftApplied = true;
    final draft = AppStateScope.of(context).evaluationDraft;
    if (draft == null || draft.activity != widget.activity) return;
    hydratingDraft = true;
    _applyEvaluationDraft(draft);
    hydratingDraft = false;
  }

  void _applyActivityDefaults() {
    switch (widget.activity) {
      case SooktaActivity.transplanting:
        selectedDurationHours = 4.0;
        selectedFrequency = 2.0;
        selectedStaticHoldLevel = 1;
        selectedWorkDaysPerWeek = 5.0;
        rebaInput = rebaInput.copyWith(activityScore: 1);
      case SooktaActivity.fertilizing:
        selectedDurationHours = 2.0;
        selectedFrequency = 2.0;
        selectedWorkDaysPerWeek = 3.0;
        selectedLoadWeight = 15.0;
        transportController.text = '6';
        rebaInput = rebaInput.copyWith(
          activityScore: 1,
          loadScore: 1,
          couplingScore: 1,
        );
      case SooktaActivity.pesticide:
        selectedDurationHours = 2.0;
        selectedFrequency = 0.2;
        selectedWorkDaysPerWeek = 5.0;
        selectedPushPullDistance = 20.0;
        selectedInitialForce = 18.0;
        selectedSustainForce = 10.0;
        rebaInput = rebaInput.copyWith(
          activityScore: 1,
          loadScore: 1,
          couplingScore: 1,
        );
      case SooktaActivity.pruning:
        selectedDurationHours = 2.0;
        selectedFrequency = 2.0;
        selectedWorkDaysPerWeek = 5.0;
        rebaInput = rebaInput.copyWith(
          activityScore: 1,
          wristScore: 2,
        );
      case SooktaActivity.harvesting:
        selectedDurationHours = 4.0;
        selectedFrequency = 6.5;
        selectedWorkDaysPerWeek = 5.0;
        selectedLoadWeight = 10.0;
        rebaInput = rebaInput.copyWith(
          activityScore: 1,
          loadScore: 1,
        );
      case SooktaActivity.transport:
        selectedDurationHours = 2.0;
        selectedFrequency = 2.0;
        selectedWorkDaysPerWeek = 4.0;
        selectedLoadWeight = 20.0;
        selectedPushPullDistance = 30.0;
        selectedInitialForce = 20.0;
        selectedSustainForce = 12.0;
        transportController.text = '8';
        rebaInput = rebaInput.copyWith(
          activityScore: 1,
          loadScore: 2,
          couplingScore: 1,
        );
    }
    _applySelectedToolDefaults();
    rebaInput = rebaInput.copyWith(
      activityScore: _activityScoreFromWorkload(),
      loadScore: _loadScoreFromKg(selectedLoadWeight),
    );
  }

  void _applyEvaluationDraft(EvaluationDraft draft) {
    selectedJobType = draft.jobType;
    selectedToolId = widget.activity.toolOptions
            .any((option) => option.id == draft.selectedToolId)
        ? draft.selectedToolId
        : widget.activity.defaultToolOption.id;
    selectedImagePaths
      ..clear()
      ..addAll(draft.selectedImagePaths.take(4));
    selectedDurationHours = draft.durationHours;
    selectedFrequency = draft.frequency;
    selectedStaticHoldLevel = draft.staticHoldLevel;
    selectedWorkDaysPerWeek = draft.workDaysPerWeek;
    selectedLoadWeight = draft.loadWeight;
    selectedPushPullDistance = draft.pushPullDistance;
    selectedInitialForce = draft.initialForce;
    selectedSustainForce = draft.sustainForce;
    horizontalController.text = draft.horizontalDistanceText;
    verticalController.text = draft.verticalHeightText;
    transportController.text = draft.transportDistanceText;
    showAdvancedDetails = draft.showAdvancedDetails;
    rebaInput = draft.rebaInput;
    restoredDraft = true;
    poseStatus = null;
    poseAssessmentReady = false;
    latestXGBoostAlert = null;
    latestMotionSummary = null;
    latestPoseEstimates.clear();
    latestFrameAnalyses.clear();
    latestFrameTimestampMs.clear();
  }

  EvaluationDraft _currentDraft() {
    return EvaluationDraft(
      activity: widget.activity,
      jobType: selectedJobType,
      selectedImagePaths: selectedImagePaths.toList(growable: false),
      selectedToolId: selectedToolId,
      durationHours: selectedDurationHours,
      frequency: selectedFrequency,
      staticHoldLevel: selectedStaticHoldLevel,
      workDaysPerWeek: selectedWorkDaysPerWeek,
      loadWeight: selectedLoadWeight,
      pushPullDistance: selectedPushPullDistance,
      initialForce: selectedInitialForce,
      sustainForce: selectedSustainForce,
      horizontalDistanceText: horizontalController.text,
      verticalHeightText: verticalController.text,
      transportDistanceText: transportController.text,
      showAdvancedDetails: showAdvancedDetails,
      rebaInput: rebaInput,
    );
  }

  void _scheduleDraftSave() {
    if (!mounted || hydratingDraft) return;
    draftSaveTimer?.cancel();
    draftSaveTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      unawaited(AppStateScope.of(context).saveEvaluationDraft(_currentDraft()));
    });
  }

  @override
  void dispose() {
    draftSaveTimer?.cancel();
    horizontalController.removeListener(_onNumberTextChanged);
    verticalController.removeListener(_onNumberTextChanged);
    transportController.removeListener(_onNumberTextChanged);
    horizontalController.dispose();
    verticalController.dispose();
    transportController.dispose();
    poseService.dispose();
    xGBoostPredictor?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final language = state.language ?? AppLanguage.th;
    final thai = language == AppLanguage.th;
    final activityName = widget.activity.label(thai: thai);
    final validationIssues = _requiredDataIssues(thai);
    final canAnalyze = selectedImagePaths.isNotEmpty &&
        poseAssessmentReady &&
        !poseBusy &&
        validationIssues.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(thai ? 'แบบฟอร์มประเมิน' : 'Evaluation Form')),
      body: SafeArea(
        child: ResponsiveListView(
          maxWidth: 680,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              thai ? 'กิจกรรม: $activityName' : 'Activity: $activityName',
              style: const TextStyle(
                color: SooktaColors.darkGreen,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (restoredDraft) ...[
              const SizedBox(height: 8),
              _DraftRestoredNotice(thai: thai),
            ],
            const SizedBox(height: 8),
            _EvaluationVoiceGuide(
              thai: thai,
              activityName: activityName,
              jobType: selectedJobType,
              durationHours: selectedDurationHours,
              frequency: selectedFrequency,
              loadWeight: selectedLoadWeight,
              toolLabel: selectedTool.label(thai: thai),
              initialForce: selectedInitialForce,
              sustainForce: selectedSustainForce,
              pushPullDistance: selectedPushPullDistance,
            ),
            const SizedBox(height: 16),
            _ImageSlots(
              activity: widget.activity,
              imagePaths: selectedImagePaths,
              onCamera: selectedImagePaths.length >= 4 ? null : _capturePhoto,
              onGallery:
                  selectedImagePaths.length >= 4 ? null : _pickGalleryPhoto,
              onVideoCamera: poseBusy ? null : _captureVideo,
              onVideoGallery: poseBusy ? null : _pickGalleryVideo,
              onSlotTap: _pickGalleryForSlot,
              onSlotRemove: _removeImageAt,
              thai: thai,
            ),
            const SizedBox(height: 16),
            _SimpleAssessmentCard(
              thai: thai,
              activityName: activityName,
              jobType: selectedJobType,
              imageCount: selectedImagePaths.length,
              poseBusy: poseBusy,
              poseReady: poseAssessmentReady,
              poseStatus: poseStatus,
              durationHours: selectedDurationHours,
              frequency: selectedFrequency,
              loadWeight: selectedLoadWeight,
              toolLabel: selectedTool.label(thai: thai),
              initialForce: selectedInitialForce,
              sustainForce: selectedSustainForce,
              pushPullDistance: selectedPushPullDistance,
              validationIssues: validationIssues,
              onAnalyze: canAnalyze ? _analyze : null,
            ),
            if (latestFrameAnalyses.isNotEmpty) ...[
              const SizedBox(height: 16),
              _PoseFrameAnalysisCard(
                thai: thai,
                frames: latestFrameAnalyses,
                worstImageIndex: _worstFrame(latestFrameAnalyses)?.imageIndex,
                motionSummary: latestMotionSummary,
              ),
            ],
            const SizedBox(height: 16),
            _AdvancedDetailsCard(
              thai: thai,
              expanded: showAdvancedDetails,
              onExpansionChanged: (value) {
                setState(() => showAdvancedDetails = value);
                _scheduleDraftSave();
              },
              children: [
                _SectionCard(
                  title: thai
                      ? 'ข้อมูลหน้างานที่ใช้คำนวณ'
                      : 'Work Details Used for Scoring',
                  children: [
                    Text(
                      thai
                          ? 'ชาวสวนหรือเจ้าหน้าที่สามารถเลือกค่าที่ตรงกับงานจริง เช่น น้ำหนัก ระยะเวลา ความถี่ หรือแรงดัน/ลาก เพราะค่าเหล่านี้มีผลต่อคะแนน REBA และ ISO11228 หากไม่แน่ใจให้ใช้ค่าเริ่มต้น'
                          : 'Farmers or staff can choose the values that match the real task, such as load, duration, frequency, or push/pull force. These values affect REBA and ISO11228 scores. If unsure, keep the default values.',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<JobType>(
                      segments: [
                        ButtonSegment(
                          value: JobType.reba,
                          label: Text(thai ? 'ท่าทาง' : 'Posture'),
                          icon: const Icon(Icons.accessibility_new),
                        ),
                        ButtonSegment(
                          value: JobType.lifting,
                          label: Text(thai ? 'ยก/แบก' : 'Lift'),
                          icon: const Icon(Icons.inventory_2_outlined),
                        ),
                        ButtonSegment(
                          value: JobType.pushPull,
                          label: Text(thai ? 'ดัน/ดึง' : 'Push'),
                          icon: const Icon(Icons.open_with),
                        ),
                      ],
                      selected: {selectedJobType},
                      onSelectionChanged: (value) {
                        setState(() {
                          selectedJobType = value.first;
                          rebaInput = rebaInput.copyWith(
                            loadScore: _loadScoreFromKg(selectedLoadWeight),
                          );
                          poseStatus = null;
                          poseAssessmentReady = false;
                        });
                        _scheduleDraftSave();
                        if (selectedImagePaths.isNotEmpty) {
                          _applyPoseEstimates();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _ChoiceRow<double>(
                      label: thai ? 'ระยะเวลาประมาณ' : 'Estimated duration',
                      value: selectedDurationHours,
                      items: {
                        0.5: thai ? '<30 นาที' : '<30 min',
                        1.0: thai ? '30 นาที-1 ชม.' : '30 min-1 hr',
                        2.0: thai ? '1-2 ชม.' : '1-2 hrs',
                        4.0: thai ? '>2 ชม.' : '>2 hrs',
                      },
                      onChanged: _setDurationHours,
                    ),
                    _ChoiceRow<double>(
                      label: thai ? 'ทำซ้ำบ่อยแค่ไหน' : 'Repetition',
                      value: selectedFrequency,
                      items: {
                        0.2: thai ? 'ไม่ซ้ำ' : 'Not repeated',
                        2.0: thai ? '<4 ครั้ง/นาที' : '<4 times/min',
                        6.5: thai ? '4-10 ครั้ง/นาที' : '4-10 times/min',
                        12.0: thai ? '>10 ครั้ง/นาที' : '>10 times/min',
                      },
                      onChanged: _setFrequency,
                    ),
                    _ChoiceRow<int>(
                      label: thai ? 'ค้างท่าหรือไม่' : 'Static posture',
                      value: selectedStaticHoldLevel,
                      items: {
                        0: thai ? 'ไม่ค้าง' : 'No hold',
                        1: thai ? 'ค้าง 30 วินาที-1 นาที' : '30 sec-1 min',
                        2: thai ? 'ค้าง >1 นาที' : '>1 min',
                      },
                      onChanged: _setStaticHold,
                    ),
                    _ChoiceRow<double>(
                      label: thai ? 'ทำกี่วันต่อสัปดาห์' : 'Days per week',
                      value: selectedWorkDaysPerWeek,
                      items: {
                        1.0: thai ? '1-2 วัน/สัปดาห์' : '1-2 days/week',
                        3.0: thai ? '3-4 วัน/สัปดาห์' : '3-4 days/week',
                        4.0: thai ? '4 วัน/สัปดาห์' : '4 days/week',
                        5.0: thai ? '5 วัน/สัปดาห์' : '5 days/week',
                        6.0: thai ? '6-7 วัน/สัปดาห์' : '6-7 days/week',
                      },
                      onChanged: (value) {
                        setState(() => selectedWorkDaysPerWeek = value);
                        _scheduleDraftSave();
                      },
                    ),
                    _ChoiceRow<String>(
                      label: thai
                          ? 'เครื่องมือ/น้ำหนักที่ใช้'
                          : 'Tool / load used',
                      value: selectedToolId,
                      items: {
                        for (final option in widget.activity.toolOptions)
                          option.id: option.label(thai: thai),
                      },
                      onChanged: _setTool,
                    ),
                    _LockedLoadSummary(
                      thai: thai,
                      toolLabel: selectedTool.label(thai: thai),
                      loadKgText: _formatKg(selectedLoadWeight),
                    ),
                    _ChoiceRow<int>(
                      label: thai ? 'คุณภาพการจับ' : 'Coupling quality',
                      value: rebaInput.couplingScore,
                      items: {
                        0: thai ? 'ดี (+0)' : 'Good (+0)',
                        1: thai ? 'ปานกลาง (+1)' : 'Fair (+1)',
                        2: thai ? 'ไม่ดี (+2)' : 'Poor (+2)',
                      },
                      onChanged: (value) {
                        setState(() {
                          rebaInput = rebaInput.copyWith(couplingScore: value);
                        });
                        _scheduleDraftSave();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (selectedJobType == JobType.reba)
                  _RebaCard(
                    thai: thai,
                    input: rebaInput,
                    poseBusy: poseBusy,
                    poseStatus: poseStatus,
                    onChanged: (input) {
                      setState(() => rebaInput = input);
                      _scheduleDraftSave();
                    },
                    onAutoFill: selectedImagePaths.isEmpty || poseBusy
                        ? null
                        : _applyPoseEstimates,
                  )
                else
                  _IsoCard(
                    thai: thai,
                    jobType: selectedJobType,
                    horizontalController: horizontalController,
                    verticalController: verticalController,
                    transportController: transportController,
                    initialForce: selectedInitialForce,
                    sustainForce: selectedSustainForce,
                    pushPullDistance: selectedPushPullDistance,
                    onInitialForceChanged: _setInitialForce,
                    onSustainForceChanged: _setSustainForce,
                    onPushPullDistanceChanged: _setPushPullDistance,
                  ),
              ],
            ),
            if (showAdvancedDetails) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: canAnalyze ? _analyze : null,
                icon: poseBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.analytics_outlined),
                label: Text(thai ? 'ดูผลประเมิน' : 'View Assessment'),
              ),
              if (!canAnalyze) ...[
                const SizedBox(height: 8),
                Text(
                  poseBusy
                      ? (thai
                          ? 'กำลังอ่านรูปภาพ รอสักครู่'
                          : 'Reading the photo. Please wait.')
                      : (selectedImagePaths.isNotEmpty && !poseAssessmentReady)
                          ? (thai
                              ? 'ต้องใช้รูปที่เห็นบุคคลและท่าทางชัดเจนก่อน จึงจะแสดงผลประเมินได้'
                              : 'Use a clear photo with a readable person posture before viewing results.')
                          : (thai
                              ? 'ถ่ายรูปหรือเลือกรูปก่อน ระบบจะช่วยคำนวณให้'
                              : 'Take or choose a photo first. The app will calculate the rest.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );
    if (path != null) {
      await _addImage(path);
      unawaited(FirebaseTelemetryService.logImageAdded(
        source: 'camera',
        imageCount: selectedImagePaths.length,
      ));
    }
  }

  Future<void> _pickGalleryPhoto() async {
    await _pickGalleryForSlot(-1);
  }

  Future<void> _pickGalleryForSlot(int slotIndex) async {
    final photo = await imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (photo != null) {
      await _addImage(photo.path, slotIndex: slotIndex);
      unawaited(FirebaseTelemetryService.logImageAdded(
        source: 'gallery',
        imageCount: selectedImagePaths.length,
      ));
    }
  }

  Future<void> _captureVideo() async {
    final video = await imagePicker.pickVideo(
      source: ImageSource.camera,
      maxDuration: VideoFrameExtractionService.maxDuration,
    );
    if (video != null) {
      await _replaceImagesFromVideo(video.path, source: 'video_camera');
    }
  }

  Future<void> _pickGalleryVideo() async {
    final video = await imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: VideoFrameExtractionService.maxDuration,
    );
    if (video != null) {
      await _replaceImagesFromVideo(video.path, source: 'video_gallery');
    }
  }

  Future<void> _replaceImagesFromVideo(
    String videoPath, {
    required String source,
  }) async {
    if (poseBusy) return;
    final thai = (AppStateScope.of(context).language ?? AppLanguage.th) ==
        AppLanguage.th;
    setState(() {
      poseBusy = true;
      poseAssessmentReady = false;
      poseStatus = thai
          ? 'กำลังวิเคราะห์วิดีโอแบบหลายเฟรม ไม่เกิน 20 วินาที...'
          : 'Analyzing a multi-frame video up to 20 seconds...';
      latestXGBoostAlert = null;
      latestMotionSummary = null;
      latestPoseEstimates.clear();
      latestFrameAnalyses.clear();
      latestFrameTimestampMs.clear();
    });

    try {
      final result = await videoFrameService.extractFrames(videoPath);
      if (!mounted) return;
      setState(() {
        selectedImagePaths
          ..clear()
          ..addAll(result.framePaths);
        latestCaptureSourceKind = source;
        latestVideoDurationMs = result.durationMs;
        latestFrameTimestampMs
          ..clear()
          ..addAll(result.frameTimestampMs);
        poseStatus = thai
            ? 'ได้เฟรมจากวิดีโอ ${result.framePaths.length} เฟรม จาก ${result.durationSeconds.toStringAsFixed(1)} วินาที กำลังอ่านท่าทาง...'
            : 'Sampled ${result.framePaths.length} frames from ${result.durationSeconds.toStringAsFixed(1)} seconds of video. Reading posture...';
      });
      unawaited(FirebaseTelemetryService.logImageAdded(
        source: source,
        imageCount: selectedImagePaths.length,
      ));
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        poseStatus = _videoErrorText(thai, error.message);
      });
      return;
    } on VideoFrameExtractionException catch (error) {
      if (!mounted) return;
      setState(() {
        poseStatus = _videoErrorText(thai, error.message);
      });
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        poseStatus = _videoErrorText(thai, error.toString());
      });
      return;
    } finally {
      if (mounted) setState(() => poseBusy = false);
    }

    await _applyPoseEstimates();
  }

  String _videoErrorText(bool thai, String? message) {
    final normalized = (message ?? '').toLowerCase();
    if (normalized.contains('20') || normalized.contains('shorter')) {
      return thai
          ? 'ยังประเมินไม่ได้: วิดีโอต้องยาวไม่เกิน 20 วินาที กรุณาถ่ายใหม่หรือเลือกไฟล์ที่สั้นลง'
          : 'Cannot assess yet: video must be 20 seconds or shorter. Record again or choose a shorter file.';
    }
    return thai
        ? 'วิเคราะห์วิดีโอไม่สำเร็จ กรุณาใช้วิดีโอที่เห็นบุคคลชัดเจนและยาวไม่เกิน 20 วินาที'
        : 'Video analysis failed. Use a clear worker-posture video that is 20 seconds or shorter.';
  }

  Future<void> _addImage(String path, {int slotIndex = -1}) async {
    if (selectedImagePaths.length >= 4 &&
        (slotIndex < 0 || slotIndex >= selectedImagePaths.length)) {
      return;
    }
    setState(() {
      if (slotIndex >= 0 && slotIndex < selectedImagePaths.length) {
        selectedImagePaths[slotIndex] = path;
      } else if (slotIndex == selectedImagePaths.length &&
          selectedImagePaths.length < 4) {
        selectedImagePaths.add(path);
      } else if (selectedImagePaths.length < 4) {
        selectedImagePaths.add(path);
      }
      poseStatus = null;
      poseAssessmentReady = false;
      latestXGBoostAlert = null;
      latestMotionSummary = null;
      latestCaptureSourceKind = 'photo_set';
      latestVideoDurationMs = null;
      latestPoseEstimates.clear();
      latestFrameAnalyses.clear();
      latestFrameTimestampMs.clear();
    });
    _scheduleDraftSave();
    await _applyPoseEstimates();
  }

  Future<void> _removeImageAt(int index) async {
    if (index < 0 || index >= selectedImagePaths.length) return;
    setState(() {
      selectedImagePaths.removeAt(index);
      poseStatus = null;
      poseAssessmentReady = false;
      latestXGBoostAlert = null;
      latestMotionSummary = null;
      latestCaptureSourceKind = 'photo_set';
      latestVideoDurationMs = null;
      latestPoseEstimates.clear();
      latestFrameAnalyses.clear();
      latestFrameTimestampMs.clear();
    });
    _scheduleDraftSave();
    if (selectedImagePaths.isNotEmpty) {
      await _applyPoseEstimates();
    }
  }

  Future<void> _applyPoseEstimates() async {
    if (selectedImagePaths.isEmpty || poseBusy) return;

    setState(() {
      poseBusy = true;
      poseAssessmentReady = false;
      final thai = (AppStateScope.of(context).language ?? AppLanguage.th) ==
          AppLanguage.th;
      poseStatus = thai ? 'กำลังวิเคราะห์ภาพ...' : 'Analyzing photo...';
    });

    try {
      final estimates = <PoseEstimate>[];
      for (final path in selectedImagePaths) {
        final estimate = await poseService.estimatePoseFromFile(path);
        if (estimate != null) estimates.add(estimate);
      }

      if (!mounted) return;
      final thai = (AppStateScope.of(context).language ?? AppLanguage.th) ==
          AppLanguage.th;
      if (estimates.isEmpty) {
        setState(() {
          poseAssessmentReady = false;
          latestPoseEstimates.clear();
          latestFrameAnalyses.clear();
          latestXGBoostAlert = null;
          latestMotionSummary = null;
          poseStatus = thai
              ? 'ยังประเมินไม่ได้: ไม่พบคนหรืออ่านท่าทางไม่ได้ กรุณาใช้รูปที่เห็นบุคคลและท่าทางชัดเจน'
              : 'Cannot assess yet: no readable person posture was detected. Use a clear full-body photo.';
        });
        return;
      }

      final frameAnalyses = await _analyzePoseFrames(estimates);
      final inferred = _inferWorstRebaInput(frameAnalyses);
      final xgbAlert = await _predictXGBoostAlert(frameAnalyses);
      final motionSummary = _buildMotionSummary(frameAnalyses);

      if (selectedJobType == JobType.reba) {
        setState(() {
          latestPoseEstimates
            ..clear()
            ..addAll(estimates);
          latestFrameAnalyses
            ..clear()
            ..addAll(frameAnalyses);
          latestXGBoostAlert = xgbAlert;
          latestMotionSummary = motionSummary;
          rebaInput = inferred;
          poseAssessmentReady = true;
          poseStatus = _poseReadyStatus(
            thai: thai,
            motionSummary: motionSummary,
            fallbackThai:
                'ระบบประเมินคะแนน REBA จากภาพและตรวจเทียบด้วย XGBoost แล้ว',
            fallbackEnglish:
                'REBA scores updated from photos and checked with XGBoost.',
          );
        });
      } else if (selectedJobType == JobType.lifting) {
        final dimensions =
            poseService.estimateLiftingDimensions(estimates.last);
        setState(() {
          latestPoseEstimates
            ..clear()
            ..addAll(estimates);
          latestFrameAnalyses
            ..clear()
            ..addAll(frameAnalyses);
          latestXGBoostAlert = xgbAlert;
          latestMotionSummary = motionSummary;
          rebaInput = inferred;
          if (dimensions == null) {
            poseAssessmentReady = false;
            poseStatus = thai
                ? 'ยังประเมินไม่ได้: พบคนในภาพ แต่ยังอ่านระยะ H/V ไม่ได้ กรุณาใช้รูปที่เห็นท่าทางและตำแหน่งมือชัดเจน'
                : 'Cannot assess yet: a person was detected, but H/V distances could not be estimated. Use a clearer posture photo.';
          } else {
            horizontalController.text =
                dimensions.horizontalCm.round().toString();
            verticalController.text = dimensions.verticalCm.round().toString();
            poseAssessmentReady = true;
            poseStatus = _poseReadyStatus(
              thai: thai,
              motionSummary: motionSummary,
              fallbackThai: 'ระบบอ่านระยะ H/V และคะแนน REBA จากภาพแล้ว',
              fallbackEnglish:
                  'H/V distances and REBA posture scores updated from the latest photo.',
            );
          }
        });
      } else {
        setState(() {
          latestPoseEstimates
            ..clear()
            ..addAll(estimates);
          latestFrameAnalyses
            ..clear()
            ..addAll(frameAnalyses);
          latestXGBoostAlert = xgbAlert;
          latestMotionSummary = motionSummary;
          rebaInput = inferred;
          poseAssessmentReady = true;
          poseStatus = _poseReadyStatus(
            thai: thai,
            motionSummary: motionSummary,
            fallbackThai: 'ระบบประเมินท่าทางจากภาพแล้ว',
            fallbackEnglish: 'Posture scores updated from photos.',
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      final thai = (AppStateScope.of(context).language ?? AppLanguage.th) ==
          AppLanguage.th;
      unawaited(FirebaseTelemetryService.logEvent(
        'pose_analysis_failed',
        {
          'platform': Platform.operatingSystem,
          'message': e.toString(),
        },
      ));
      setState(() {
        poseAssessmentReady = false;
        latestXGBoostAlert = null;
        latestMotionSummary = null;
        latestPoseEstimates.clear();
        latestFrameAnalyses.clear();
        poseStatus = _poseAnalysisErrorText(thai, e);
      });
    } finally {
      if (mounted) setState(() => poseBusy = false);
    }
  }

  String _poseAnalysisErrorText(bool thai, Object error) {
    final raw = error.toString().toLowerCase();
    final nativeMlUnavailable = raw.contains('tflite') ||
        raw.contains('tensorflow') ||
        raw.contains('dlsym') ||
        raw.contains('symbol not found');
    if (nativeMlUnavailable) {
      return thai
          ? 'ยังประเมินไม่ได้: ระบบอ่านท่าทางบนเครื่องนี้ไม่พร้อม กรุณาปิดแอปแล้วเปิดใหม่ หากยังพบปัญหาให้ติดตั้งเวอร์ชันล่าสุด'
          : 'Cannot assess yet: posture analysis is not ready on this device. Close and reopen the app. If it still happens, install the latest version.';
    }
    return thai
        ? 'ยังประเมินไม่ได้: กรุณาใช้รูปที่เห็นบุคคลและท่าทางชัดเจน แล้วลองอีกครั้ง'
        : 'Cannot assess yet: use a clear photo with a readable person posture, then try again.';
  }

  Future<void> _analyze() async {
    final state = AppStateScope.of(context);
    final thai = (state.language ?? AppLanguage.th) == AppLanguage.th;
    final validationIssues = _requiredDataIssues(thai);
    if (validationIssues.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            thai
                ? 'กรุณาตรวจข้อมูลก่อนประเมิน: ${validationIssues.first}'
                : 'Check required data before assessment: ${validationIssues.first}',
          ),
        ),
      );
      return;
    }
    if (selectedImagePaths.isEmpty || poseBusy || !poseAssessmentReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            thai
                ? 'ยังประเมินไม่ได้ กรุณาใช้รูปที่เห็นบุคคลและท่าทางชัดเจนก่อน เพื่อหลีกเลี่ยงตัวเลขที่ไม่น่าเชื่อถือ'
                : 'Cannot assess yet. Use a clear photo with a readable person posture to avoid unreliable numbers.',
          ),
        ),
      );
      return;
    }
    final activityName = widget.activity.label(thai: thai);
    final gender = state.profile.gender.toLowerCase();
    final dailyIncome = state.dailyIncome.toDouble();
    final horizontalDistance = _numberValue(horizontalController.text) ?? 25;
    final verticalHeight = _numberValue(verticalController.text) ?? 75;
    final transportDistance = _numberValue(transportController.text) ?? 4;
    final ergoInput = ErgoInputData(
      jobType: selectedJobType,
      gender: gender,
      dailyIncome: dailyIncome,
      toolId: selectedTool.id,
      toolLabelTh: selectedTool.labelTh,
      toolLabelEn: selectedTool.labelEn,
      toolWeightKg: selectedTool.weightKg,
      toolWeightBandCode: selectedTool.weightBandCode,
      loadWeight: selectedLoadWeight,
      horizontalDist: horizontalDistance,
      verticalHeight: verticalHeight,
      liftFrequency: selectedFrequency,
      durationHours: selectedDurationHours,
      workDaysPerWeek: selectedWorkDaysPerWeek,
      transportDistance: selectedJobType == JobType.pushPull
          ? selectedPushPullDistance
          : transportDistance,
      initialForce: selectedInitialForce,
      sustainForce: selectedSustainForce,
    );
    final rebaData = rebaInput.copyWith(dailyIncome: dailyIncome);
    final rebaResult = ErgoCalculator.calculateRebaRisk(rebaData);
    final isoMethod = switch (selectedJobType) {
      JobType.lifting => AssessmentMethod.iso11228Lifting,
      JobType.pushPull => AssessmentMethod.iso11228PushPull,
      JobType.reba => null,
    };
    final isoResult = switch (selectedJobType) {
      JobType.lifting => ErgoCalculator.calculateLiftingRisk(ergoInput),
      JobType.pushPull => ErgoCalculator.calculatePushPullRisk(ergoInput),
      JobType.reba => null,
    };
    var result = isoResult == null
        ? rebaResult
        : ErgoCalculator.calculateCombinedRebaIsoRisk(
            rebaResult: rebaResult,
            isoResult: isoResult,
            dailyIncome: dailyIncome,
          );
    final primaryMethod = isoResult == null
        ? AssessmentMethod.reba
        : AssessmentMethod.rebaIsoCombined;

    unawaited(FirebaseTelemetryService.logAssessmentCalculated(
      activity: widget.activity.name,
      jobType: selectedJobType.name,
      primaryMethod: primaryMethod.name,
      riskLevel: result.riskLevel.name,
      score: result.userScore,
      imageCount: selectedImagePaths.length,
      usesIso11228: isoResult != null,
    ));

    final xgbAlert = latestXGBoostAlert;
    if (xgbAlert != null) {
      result = _applyXGBoostGuardrail(result, xgbAlert);
    }
    final breakdown = AssessmentBreakdown(
      primaryMethod: primaryMethod,
      rebaInput: rebaData,
      rebaResult: rebaResult,
      ergoInput: ergoInput,
      isoMethod: isoMethod,
      isoResult: isoResult,
      poseFrames: latestFrameAnalyses.toList(growable: false),
      worstPoseImageIndex: _worstFrame(latestFrameAnalyses)?.imageIndex,
      motionSummary: latestMotionSummary,
    );

    if (!mounted) return;

    Navigator.of(context).pushNamed(
      InitialRiskScreen.routeName,
      arguments: InitialRiskPayload(
        activity: widget.activity,
        activityName: activityName,
        jobType: selectedJobType,
        before: result,
        ergoInput: ergoInput,
        rebaInput: rebaData,
        breakdown: breakdown,
      ),
    );
  }

  List<String> _requiredDataIssues(bool thai) {
    final issues = <String>[];
    if (selectedDurationHours <= 0) {
      issues.add(thai
          ? 'ระยะเวลาทำงานต้องมากกว่า 0'
          : 'Work duration must be greater than 0');
    }
    if (selectedFrequency < 0) {
      issues.add(thai
          ? 'ความถี่งานต้องไม่ติดลบ'
          : 'Work frequency cannot be negative');
    }
    if (selectedWorkDaysPerWeek <= 0) {
      issues.add(thai
          ? 'จำนวนวันทำงานต่อสัปดาห์ต้องมากกว่า 0'
          : 'Work days per week must be greater than 0');
    }
    final knownTool = widget.activity.toolOptions
        .any((option) => option.id == selectedToolId);
    if (!knownTool) {
      issues.add(thai
          ? 'กรุณาเลือกเครื่องมือ/น้ำหนักที่ใช้'
          : 'Choose the tool or load used');
    }
    if (selectedJobType == JobType.lifting) {
      _addPositiveNumberIssue(
        issues,
        thai: thai,
        valueText: horizontalController.text,
        thaiLabel: 'ระยะห่าง H',
        englishLabel: 'Distance H',
      );
      _addPositiveNumberIssue(
        issues,
        thai: thai,
        valueText: verticalController.text,
        thaiLabel: 'ความสูง V',
        englishLabel: 'Height V',
      );
      _addPositiveNumberIssue(
        issues,
        thai: thai,
        valueText: transportController.text,
        thaiLabel: 'ระยะทางขนย้าย',
        englishLabel: 'Transport distance',
      );
    } else if (selectedJobType == JobType.pushPull) {
      if (selectedInitialForce <= 0) {
        issues.add(thai
            ? 'แรงเริ่มต้นดัน/ลากต้องมากกว่า 0'
            : 'Initial push/pull force must be greater than 0');
      }
      if (selectedSustainForce <= 0) {
        issues.add(thai
            ? 'แรงต่อเนื่องดัน/ลากต้องมากกว่า 0'
            : 'Sustained push/pull force must be greater than 0');
      }
      if (selectedPushPullDistance <= 0) {
        issues.add(thai
            ? 'ระยะดัน/ลากต้องมากกว่า 0'
            : 'Push/pull distance must be greater than 0');
      }
    }
    return issues;
  }

  void _addPositiveNumberIssue(
    List<String> issues, {
    required bool thai,
    required String valueText,
    required String thaiLabel,
    required String englishLabel,
  }) {
    final value = _numberValue(valueText);
    if (value == null || value <= 0) {
      issues.add(thai
          ? '$thaiLabel ต้องเป็นตัวเลขมากกว่า 0'
          : '$englishLabel must be a number greater than 0');
    }
  }

  double? _numberValue(String valueText) {
    final normalized = valueText.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void _onNumberTextChanged() {
    if (!mounted || hydratingDraft) {
      _scheduleDraftSave();
      return;
    }
    setState(() {});
    _scheduleDraftSave();
  }

  void _setDurationHours(double value) {
    setState(() {
      selectedDurationHours = value;
      _syncActivityScore();
    });
    _scheduleDraftSave();
  }

  void _setFrequency(double value) {
    setState(() {
      selectedFrequency = value;
      _syncActivityScore();
    });
    _scheduleDraftSave();
  }

  void _setStaticHold(int value) {
    setState(() {
      selectedStaticHoldLevel = value;
      _syncActivityScore();
    });
    _scheduleDraftSave();
  }

  void _setPushPullDistance(double value) {
    setState(() => selectedPushPullDistance = value);
    _scheduleDraftSave();
  }

  void _setInitialForce(double value) {
    setState(() => selectedInitialForce = value);
    _scheduleDraftSave();
  }

  void _setSustainForce(double value) {
    setState(() => selectedSustainForce = value);
    _scheduleDraftSave();
  }

  ActivityToolOption get selectedTool =>
      widget.activity.toolOptionById(selectedToolId);

  void _applySelectedToolDefaults() {
    final tool = selectedTool;
    selectedLoadWeight = tool.weightKg;
    rebaInput = rebaInput.copyWith(loadScore: _loadScoreFromKg(tool.weightKg));
  }

  void _setTool(String value) {
    setState(() {
      selectedToolId = value;
      _applySelectedToolDefaults();
    });
    _scheduleDraftSave();
  }

  void _syncActivityScore() {
    rebaInput = rebaInput.copyWith(
      activityScore: _activityScoreFromWorkload(),
    );
  }

  int _activityScoreFromWorkload() {
    var score = 0;
    if (selectedStaticHoldLevel >= 2) {
      score += 1;
    }
    if (selectedFrequency > 4) {
      score += 1;
    }
    if (selectedFrequency >= 12 || selectedDurationHours >= 4) {
      score += 1;
    }
    return score.clamp(0, 3).toInt();
  }

  int _loadScoreFromKg(double kg) {
    if (kg <= 5) return 0;
    if (kg <= 15) return 1;
    return 2;
  }

  String _formatKg(double kg) {
    if (kg == kg.roundToDouble()) return kg.round().toString();
    return kg.toStringAsFixed(1);
  }

  Future<List<PoseRebaFrameAnalysis>> _analyzePoseFrames(
    List<PoseEstimate> estimates,
  ) async {
    risk_ml.MoveNetJointFeatureExtractor? extractor;
    try {
      final schema = jointFeatureSchema ??
          await const risk_ml.JointFeatureSchemaLoader().load();
      jointFeatureSchema = schema;
      extractor =
          jointFeatureExtractor ?? risk_ml.MoveNetJointFeatureExtractor(schema);
      jointFeatureExtractor = extractor;
    } catch (_) {
      extractor = null;
    }
    return [
      for (var i = 0; i < estimates.length; i++)
        ErgoCalculator.analyzeRebaPose(
          estimates[i].person,
          rebaInput,
          imageIndex: i + 1,
          timestampMs: i < latestFrameTimestampMs.length
              ? latestFrameTimestampMs[i]
              : null,
          jointFeatures: extractor?.extract(estimates[i].person) ?? const [],
        ),
    ];
  }

  MotionAnalysisSummary? _buildMotionSummary(
    List<PoseRebaFrameAnalysis> frameAnalyses,
  ) {
    if (frameAnalyses.isEmpty ||
        !latestCaptureSourceKind.startsWith('video_')) {
      return null;
    }
    final durationMs = latestVideoDurationMs ?? 0;
    final durationSeconds = durationMs > 0 ? durationMs / 1000 : 0.0;
    final sampledFrameCount = latestFrameTimestampMs.isNotEmpty
        ? latestFrameTimestampMs.length
        : selectedImagePaths.length;
    final readableFrameCount = frameAnalyses.length;
    final highRiskFrameCount = frameAnalyses
        .where((frame) =>
            frame.riskLevel.index >= RiskLevel.high.index ||
            frame.rebaScore >= 7)
        .length;
    final deepTrunkFlexionFrameCount = frameAnalyses
        .where((frame) => (frame.trunkFlexionDeg ?? 0) >= 60)
        .length;
    final neckRiskFrameCount =
        _segmentRiskFrameCount(frameAnalyses, _neckRiskDetected);
    final trunkRiskFrameCount =
        _segmentRiskFrameCount(frameAnalyses, _trunkRiskDetected);
    final upperArmRiskFrameCount =
        _segmentRiskFrameCount(frameAnalyses, _upperArmRiskDetected);
    final lowerArmRiskFrameCount =
        _segmentRiskFrameCount(frameAnalyses, _lowerArmRiskDetected);
    final wristRiskFrameCount =
        _segmentRiskFrameCount(frameAnalyses, _wristRiskDetected);
    final legRiskFrameCount =
        _segmentRiskFrameCount(frameAnalyses, _legRiskDetected);
    final anySegmentRiskFrameCount =
        _segmentRiskFrameCount(frameAnalyses, _anyRebaSegmentRiskDetected);
    final highRiskFrameRatio =
        readableFrameCount == 0 ? 0.0 : highRiskFrameCount / readableFrameCount;
    final deepTrunkFlexionRatio = readableFrameCount == 0
        ? 0.0
        : deepTrunkFlexionFrameCount / readableFrameCount;
    final anySegmentRiskFrameRatio =
        _ratio(anySegmentRiskFrameCount, readableFrameCount);
    final neckRiskFrameRatio = _ratio(neckRiskFrameCount, readableFrameCount);
    final trunkRiskFrameRatio = _ratio(trunkRiskFrameCount, readableFrameCount);
    final upperArmRiskFrameRatio =
        _ratio(upperArmRiskFrameCount, readableFrameCount);
    final lowerArmRiskFrameRatio =
        _ratio(lowerArmRiskFrameCount, readableFrameCount);
    final wristRiskFrameRatio = _ratio(wristRiskFrameCount, readableFrameCount);
    final legRiskFrameRatio = _ratio(legRiskFrameCount, readableFrameCount);
    final movementChangeCount = _movementChangeCount(frameAnalyses);
    final pattern = _motionPattern(
      highRiskFrameRatio: highRiskFrameRatio,
      anySegmentRiskFrameRatio: anySegmentRiskFrameRatio,
      deepTrunkFlexionRatio: deepTrunkFlexionRatio,
      movementChangeCount: movementChangeCount,
      highRiskFrameCount: highRiskFrameCount,
      anySegmentRiskFrameCount: anySegmentRiskFrameCount,
      deepTrunkFlexionFrameCount: deepTrunkFlexionFrameCount,
    );

    return MotionAnalysisSummary(
      sourceKind: latestCaptureSourceKind,
      durationMs: durationMs,
      sampledFrameCount: sampledFrameCount,
      readableFrameCount: readableFrameCount,
      sampleRateFps:
          durationSeconds > 0 ? sampledFrameCount / durationSeconds : 0,
      highRiskFrameCount: highRiskFrameCount,
      highRiskFrameRatio: highRiskFrameRatio,
      deepTrunkFlexionFrameCount: deepTrunkFlexionFrameCount,
      deepTrunkFlexionRatio: deepTrunkFlexionRatio,
      estimatedHighRiskSeconds: highRiskFrameRatio * durationSeconds,
      estimatedDeepTrunkSeconds: deepTrunkFlexionRatio * durationSeconds,
      movementChangeCount: movementChangeCount,
      pattern: pattern,
      anySegmentRiskFrameCount: anySegmentRiskFrameCount,
      anySegmentRiskFrameRatio: anySegmentRiskFrameRatio,
      estimatedSegmentRiskSeconds: anySegmentRiskFrameRatio * durationSeconds,
      neckRiskFrameCount: neckRiskFrameCount,
      neckRiskFrameRatio: neckRiskFrameRatio,
      trunkRiskFrameCount: trunkRiskFrameCount,
      trunkRiskFrameRatio: trunkRiskFrameRatio,
      upperArmRiskFrameCount: upperArmRiskFrameCount,
      upperArmRiskFrameRatio: upperArmRiskFrameRatio,
      lowerArmRiskFrameCount: lowerArmRiskFrameCount,
      lowerArmRiskFrameRatio: lowerArmRiskFrameRatio,
      wristRiskFrameCount: wristRiskFrameCount,
      wristRiskFrameRatio: wristRiskFrameRatio,
      legRiskFrameCount: legRiskFrameCount,
      legRiskFrameRatio: legRiskFrameRatio,
      dominantRiskBodyPart: _dominantRiskBodyPart({
        'neck': neckRiskFrameCount,
        'trunk': trunkRiskFrameCount,
        'upper_arm': upperArmRiskFrameCount,
        'lower_arm': lowerArmRiskFrameCount,
        'wrist': wristRiskFrameCount,
        'legs': legRiskFrameCount,
      }),
      maxNeckFlexionDeg:
          _maxFrameValue(frameAnalyses.map((frame) => frame.neckFlexionDeg)),
      avgNeckFlexionDeg:
          _avgFrameValue(frameAnalyses.map((frame) => frame.neckFlexionDeg)),
      maxTrunkFlexionDeg:
          _maxFrameValue(frameAnalyses.map((frame) => frame.trunkFlexionDeg)),
      avgTrunkFlexionDeg:
          _avgFrameValue(frameAnalyses.map((frame) => frame.trunkFlexionDeg)),
      maxUpperArmFlexionDeg: _maxFrameValue(
        frameAnalyses.map((frame) => frame.upperArmFlexionDeg),
      ),
      avgUpperArmFlexionDeg: _avgFrameValue(
        frameAnalyses.map((frame) => frame.upperArmFlexionDeg),
      ),
    );
  }

  String _poseReadyStatus({
    required bool thai,
    required MotionAnalysisSummary? motionSummary,
    required String fallbackThai,
    required String fallbackEnglish,
  }) {
    final summary = motionSummary;
    if (summary == null || !summary.isVideo) {
      return thai ? fallbackThai : fallbackEnglish;
    }
    final highRiskPercent = (summary.highRiskFrameRatio * 100).round();
    final segmentPercent = (summary.anySegmentRiskFrameRatio * 100).round();
    final dominant = _bodyPartLabel(summary.dominantRiskBodyPart, thai);
    return thai
        ? 'วิเคราะห์วิดีโอ ${summary.readableFrameCount} เฟรมแล้ว เลือก Worst Posture จากคะแนน REBA สูงสุด พบเฟรมเสี่ยงสูง $highRiskPercent% และมีคะแนนย่อย REBA เสี่ยงในส่วนร่างกาย $segmentPercent% จุดเด่นคือ $dominant'
        : 'Video analysis completed on ${summary.readableFrameCount} frames. The app selected the highest-REBA worst posture, with $highRiskPercent% high-risk frames and $segmentPercent% frames showing REBA body-segment risk. Dominant segment: $dominant.';
  }

  MotionPattern _motionPattern({
    required double highRiskFrameRatio,
    required double anySegmentRiskFrameRatio,
    required double deepTrunkFlexionRatio,
    required int movementChangeCount,
    required int highRiskFrameCount,
    required int anySegmentRiskFrameCount,
    required int deepTrunkFlexionFrameCount,
  }) {
    if (highRiskFrameRatio >= 0.75 ||
        anySegmentRiskFrameRatio >= 0.75 ||
        deepTrunkFlexionRatio >= 0.75) {
      return MotionPattern.staticHighRiskHold;
    }
    if (movementChangeCount >= 2 ||
        highRiskFrameRatio >= 0.5 ||
        anySegmentRiskFrameRatio >= 0.5 ||
        deepTrunkFlexionRatio >= 0.5) {
      return MotionPattern.repeatedRiskMovement;
    }
    if (highRiskFrameCount > 0 ||
        anySegmentRiskFrameCount > 0 ||
        deepTrunkFlexionFrameCount > 0) {
      return MotionPattern.intermittentWorstPosture;
    }
    return MotionPattern.stableLowRisk;
  }

  int _segmentRiskFrameCount(
    List<PoseRebaFrameAnalysis> frames,
    bool Function(PoseRebaFrameAnalysis frame) predicate,
  ) {
    return frames.where(predicate).length;
  }

  double _ratio(int count, int total) => total == 0 ? 0.0 : count / total;

  bool _anyRebaSegmentRiskDetected(PoseRebaFrameAnalysis frame) {
    return _neckRiskDetected(frame) ||
        _trunkRiskDetected(frame) ||
        _upperArmRiskDetected(frame) ||
        _lowerArmRiskDetected(frame) ||
        _wristRiskDetected(frame) ||
        _legRiskDetected(frame);
  }

  bool _neckRiskDetected(PoseRebaFrameAnalysis frame) {
    return frame.rebaInput.neckScore >= 2 ||
        frame.neckSideBending ||
        frame.neckTwisting;
  }

  bool _trunkRiskDetected(PoseRebaFrameAnalysis frame) {
    return frame.rebaInput.trunkScore >= 3 ||
        frame.rebaInput.adjustedTrunkScore >= 3 ||
        frame.trunkSideBending ||
        frame.trunkTwisting;
  }

  bool _upperArmRiskDetected(PoseRebaFrameAnalysis frame) {
    return frame.rebaInput.upperArmScore >= 2 ||
        frame.upperArmAbduction ||
        frame.shoulderElevation;
  }

  bool _lowerArmRiskDetected(PoseRebaFrameAnalysis frame) {
    return frame.rebaInput.lowerArmScore >= 2;
  }

  bool _wristRiskDetected(PoseRebaFrameAnalysis frame) {
    return frame.rebaInput.adjustedWristScore >= 2 ||
        frame.rebaInput.wristTwist;
  }

  bool _legRiskDetected(PoseRebaFrameAnalysis frame) {
    return frame.rebaInput.legScore >= 2;
  }

  String? _dominantRiskBodyPart(Map<String, int> counts) {
    final risky = counts.entries.where((entry) => entry.value > 0).toList();
    if (risky.isEmpty) return null;
    risky.sort((a, b) => b.value.compareTo(a.value));
    return risky.first.key;
  }

  String _bodyPartLabel(String? key, bool thai) {
    if (key == null) return thai ? 'ไม่พบส่วนเด่น' : 'none';
    if (thai) {
      return switch (key) {
        'neck' => 'คอ',
        'trunk' => 'ลำตัว/หลัง',
        'upper_arm' => 'ต้นแขน/ไหล่',
        'lower_arm' => 'ปลายแขน',
        'wrist' => 'ข้อมือ',
        'legs' => 'ขา/เข่า',
        _ => key,
      };
    }
    return switch (key) {
      'neck' => 'neck',
      'trunk' => 'trunk/back',
      'upper_arm' => 'upper arm/shoulder',
      'lower_arm' => 'lower arm',
      'wrist' => 'wrist',
      'legs' => 'legs/knees',
      _ => key,
    };
  }

  int _movementChangeCount(List<PoseRebaFrameAnalysis> frames) {
    var changes = 0;
    for (var index = 1; index < frames.length; index++) {
      final previous = frames[index - 1];
      final current = frames[index];
      final deltas = [
        _angleDelta(previous.trunkFlexionDeg, current.trunkFlexionDeg),
        _angleDelta(previous.neckFlexionDeg, current.neckFlexionDeg),
        _angleDelta(previous.upperArmFlexionDeg, current.upperArmFlexionDeg),
      ].where((value) => value > 0).toList();
      if (deltas.isEmpty) continue;
      final maxDelta = deltas.reduce(math.max);
      final totalDelta = deltas.fold<double>(0, (sum, value) => sum + value);
      if (maxDelta >= 20 || totalDelta >= 35) changes += 1;
    }
    return changes;
  }

  double _angleDelta(double? previous, double? current) {
    if (previous == null || current == null) return 0;
    return (current - previous).abs();
  }

  double? _maxFrameValue(Iterable<double?> values) {
    double? result;
    for (final value in values) {
      if (value == null || value.isNaN) continue;
      result = result == null ? value : math.max(result, value);
    }
    return result;
  }

  double? _avgFrameValue(Iterable<double?> values) {
    var sum = 0.0;
    var count = 0;
    for (final value in values) {
      if (value == null || value.isNaN) continue;
      sum += value;
      count += 1;
    }
    return count == 0 ? null : sum / count;
  }

  RebaInputData _inferWorstRebaInput(
    List<PoseRebaFrameAnalysis> frameAnalyses,
  ) {
    final worst = _worstFrame(frameAnalyses);
    return worst?.rebaInput ?? rebaInput;
  }

  PoseRebaFrameAnalysis? _worstFrame(
    List<PoseRebaFrameAnalysis> frameAnalyses,
  ) {
    if (frameAnalyses.isEmpty) return null;
    return frameAnalyses.reduce(
      (current, next) => next.rebaScore > current.rebaScore ? next : current,
    );
  }

  Future<AiRiskAlert?> _predictXGBoostAlert(
    List<PoseRebaFrameAnalysis> frameAnalyses,
  ) async {
    if (frameAnalyses.isEmpty) return null;
    try {
      final schema = jointFeatureSchema ??
          await const risk_ml.JointFeatureSchemaLoader().load();
      jointFeatureSchema = schema;
      final predictor = xGBoostPredictor ??
          risk_ml.XGBoostOnnxPredictor(featureSchema: schema);
      xGBoostPredictor = predictor;
      await predictor.initModel();

      risk_ml.RiskAssessmentResult? strongest;
      for (final frame in frameAnalyses) {
        if (frame.jointFeatures.isEmpty) continue;
        final result = await predictor.predictRiskLevel(frame.jointFeatures);
        if (strongest == null ||
            result.level.index > strongest.level.index ||
            (result.level.index == strongest.level.index &&
                result.confidenceScore > strongest.confidenceScore)) {
          strongest = result;
        }
      }
      if (strongest == null) return null;
      final probability = strongest.confidenceScore.clamp(0.0, 1.0).toDouble();
      return AiRiskAlert(
        probability: probability,
        logisticProbability: 0,
        xgBoostProbability: probability,
        level: _alertLevelFromRisk(strongest.level),
        modelVersion: 'reba-iso-xgboost-onnx-2026-06-07',
        modelSource: 'research_team_reba2_iso11228_calibrated_xgboost',
        featureImportance: const [],
      );
    } catch (_) {
      return null;
    }
  }

  ErgoResult _applyXGBoostGuardrail(ErgoResult result, AiRiskAlert alert) {
    final xgbRisk = _riskLevelFromAlert(alert.level);
    if (xgbRisk.index <= result.riskLevel.index) {
      return result.copyWith(aiRiskAlert: alert);
    }
    final calibratedScore = switch (xgbRisk) {
      RiskLevel.low => result.userScore,
      RiskLevel.medium => math.max(result.userScore, 4),
      RiskLevel.high => math.max(result.userScore, 7),
      RiskLevel.veryHigh => math.max(result.userScore, 9),
    };
    return result.copyWith(
      riskLevel: xgbRisk,
      userScore: calibratedScore,
      userScoreColor: xgbRisk.colorHex,
      suggestionKey: xgbRisk == RiskLevel.low ? 'sugg_safe' : 'sugg_improve',
      aiRiskAlert: alert,
    );
  }

  AiAlertLevel _alertLevelFromRisk(risk_ml.RiskLevel risk) {
    return switch (risk.name) {
      'veryHigh' => AiAlertLevel.critical,
      'high' => AiAlertLevel.high,
      'medium' => AiAlertLevel.watch,
      _ => AiAlertLevel.low,
    };
  }

  RiskLevel _riskLevelFromAlert(AiAlertLevel level) {
    return switch (level) {
      AiAlertLevel.critical => RiskLevel.veryHigh,
      AiAlertLevel.high => RiskLevel.high,
      AiAlertLevel.watch => RiskLevel.medium,
      AiAlertLevel.low => RiskLevel.low,
    };
  }
}

class _EvaluationVoiceGuide extends StatelessWidget {
  const _EvaluationVoiceGuide({
    required this.thai,
    required this.activityName,
    required this.jobType,
    required this.durationHours,
    required this.frequency,
    required this.loadWeight,
    required this.toolLabel,
    required this.initialForce,
    required this.sustainForce,
    required this.pushPullDistance,
  });

  final bool thai;
  final String activityName;
  final JobType jobType;
  final double durationHours;
  final double frequency;
  final double loadWeight;
  final String toolLabel;
  final double initialForce;
  final double sustainForce;
  final double pushPullDistance;

  @override
  Widget build(BuildContext context) {
    final guide = thai
        ? 'กิจกรรม $activityName ขั้นตอนนี้ให้ถ่ายรูป เลือกรูป หรือถ่ายวิดีโอไม่เกินยี่สิบวินาทีที่เห็นคนทำงานชัดเจน ระบบจะอ่านท่าทางและตั้งค่าประเมินให้อัตโนมัติ วิธีประเมินคือ ${_jobLabel(jobType, true)} ค่าเริ่มต้นคือ ${_defaultSummary(true)} เครื่องมือคือ $toolLabel'
        : 'Activity $activityName. Take photos, choose photos, or record a video up to twenty seconds that clearly shows the worker. The app reads posture and prepares the assessment automatically. Assessment method is ${_jobLabel(jobType, false)}. Defaults are ${_defaultSummary(false)}. Tool is $toolLabel.';
    return Card(
      color: const Color(0xFFEAF5EF),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.record_voice_over_outlined,
                color: SooktaColors.darkGreen),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                thai
                    ? 'กดลำโพงเพื่อฟังขั้นตอนประเมินกิจกรรมนี้'
                    : 'Tap the speaker to hear this assessment step.',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            SooktaTtsButton(text: guide, thai: thai, size: 42),
          ],
        ),
      ),
    );
  }

  String _defaultSummary(bool thai) {
    final duration = switch (durationHours) {
      <= 0.5 => thai ? 'น้อยกว่า 30 นาที' : 'less than 30 minutes',
      <= 1.0 => thai ? '30 นาทีถึง 1 ชั่วโมง' : '30 minutes to 1 hour',
      <= 2.0 => thai ? '1 ถึง 2 ชั่วโมง' : '1 to 2 hours',
      _ => thai ? 'มากกว่า 2 ชั่วโมง' : 'more than 2 hours',
    };
    final repetition = switch (frequency) {
      <= 0.2 => thai ? 'ไม่ซ้ำ' : 'not repeated',
      < 4.0 => thai ? 'น้อยกว่า 4 ครั้งต่อนาที' : 'less than 4 times/min',
      <= 10.0 => thai ? '4 ถึง 10 ครั้งต่อนาที' : '4 to 10 times/min',
      _ => thai ? 'มากกว่า 10 ครั้งต่อนาที' : 'more than 10 times/min',
    };
    if (jobType == JobType.lifting) {
      return thai
          ? '$duration, $repetition, น้ำหนักประมาณ ${loadWeight.round()} กิโลกรัม'
          : '$duration, $repetition, about ${loadWeight.round()} kilograms';
    }
    if (jobType == JobType.pushPull) {
      return thai
          ? '$duration, $repetition, แรงเริ่มต้น ${initialForce.round()} นิวตัน แรงต่อเนื่อง ${sustainForce.round()} นิวตัน ระยะ ${pushPullDistance.round()} เมตร'
          : '$duration, $repetition, initial force ${initialForce.round()} newtons, sustained force ${sustainForce.round()} newtons, distance ${pushPullDistance.round()} meters';
    }
    return '$duration, $repetition';
  }
}

class _DraftRestoredNotice extends StatelessWidget {
  const _DraftRestoredNotice({required this.thai});

  final bool thai;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        border: Border.all(color: const Color(0xFFD6E7DD)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: SooktaColors.darkGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              thai ? 'นำข้อมูลแบบร่างกลับมาแล้ว' : 'Draft details restored',
              style: const TextStyle(
                color: SooktaColors.darkGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageSlots extends StatelessWidget {
  const _ImageSlots({
    required this.activity,
    required this.imagePaths,
    required this.onCamera,
    required this.onGallery,
    required this.onVideoCamera,
    required this.onVideoGallery,
    required this.onSlotTap,
    required this.onSlotRemove,
    required this.thai,
  });

  final SooktaActivity activity;
  final List<String> imagePaths;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onVideoCamera;
  final VoidCallback? onVideoGallery;
  final ValueChanged<int> onSlotTap;
  final ValueChanged<int> onSlotRemove;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final slotCount = imagePaths.length > 4
        ? math.min(imagePaths.length, VideoFrameExtractionService.maxFrames)
        : 4;
    final slotLimit =
        imagePaths.length > 4 ? VideoFrameExtractionService.maxFrames : 4;
    return _SectionCard(
      title: thai
          ? '1. ถ่ายรูปหรือวิดีโอท่าทางทำงาน (${imagePaths.length}/$slotLimit)'
          : '1. Capture Work Posture (${imagePaths.length}/$slotLimit)',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                thai ? 'คำแนะนำรูปภาพ' : 'Photo guidance',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SooktaTtsButton(
              thai: thai,
              text: thai
                  ? 'ถ่ายรูป หรือถ่ายวิดีโอไม่เกินยี่สิบวินาที ให้เห็นคนทำงานชัดเจน เห็นศีรษะ หลัง แขน มือ ขา และเท้าได้มากที่สุด ระบบจะสุ่มภาพจากวิดีโอไม่เกินแปดเฟรม สรุปการเคลื่อนไหว และเลือกท่าที่เสี่ยงที่สุดมาประเมิน ถ้าระบบอ่านท่าทางไม่ได้ ให้ถ่ายใหม่หรือเลือกไฟล์ใหม่'
                  : 'Take photos, or record a video up to twenty seconds. Show the worker clearly, including the head, back, arms, hands, legs, and feet as much as possible. The app samples up to eight video frames, summarizes motion, and assesses the riskiest posture. If the app cannot read the posture, retake or choose another file.',
              size: 36,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          thai
              ? 'ใช้รูปชัด 1-4 รูป หรือวิดีโอสั้นไม่เกิน 20 วินาที ระบบจะอ่านท่าทาง สรุปการเคลื่อนไหว และตั้งค่าประเมินให้อัตโนมัติ'
              : 'Use 1-4 clear photos or a short video up to 20 seconds. The app reads posture, summarizes motion, and fills the assessment automatically.',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        _ReadablePoseExample(activity: activity, thai: thai),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 340 ? 1 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slotCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: columns == 1 ? 2.6 : 1.45,
              ),
              itemBuilder: (context, index) {
                final filled = index < imagePaths.length;
                final enabled = filled || index == imagePaths.length;
                return InkWell(
                  onTap: enabled && !filled ? () => onSlotTap(index) : null,
                  borderRadius: BorderRadius.circular(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: filled
                          ? const Color(0xFFE8F5E9)
                          : enabled
                              ? Colors.grey.shade100
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: filled
                            ? SooktaColors.leafGreen
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: filled
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(imagePaths[index]),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                    color: SooktaColors.darkGreen,
                                  ),
                                ),
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: IconButton.filled(
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.red.withValues(alpha: 0.86),
                                      foregroundColor: Colors.white,
                                      fixedSize: const Size(30, 30),
                                      minimumSize: const Size(30, 30),
                                      padding: EdgeInsets.zero,
                                    ),
                                    onPressed: () => onSlotRemove(index),
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: Icon(
                                enabled
                                    ? Icons.add_a_photo_outlined
                                    : Icons.image_outlined,
                                color: enabled
                                    ? Colors.grey
                                    : Colors.grey.shade400,
                              ),
                            ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 340;
            return Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: stacked
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 10) / 2,
                  child: FilledButton.icon(
                    onPressed: onCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(thai ? 'ถ่ายรูป' : 'Camera'),
                  ),
                ),
                SizedBox(
                  width: stacked
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 10) / 2,
                  child: OutlinedButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(thai ? 'อัลบั้ม' : 'Gallery'),
                  ),
                ),
                SizedBox(
                  width: stacked
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 10) / 2,
                  child: FilledButton.tonalIcon(
                    onPressed: onVideoCamera,
                    icon: const Icon(Icons.videocam_outlined),
                    label: Text(thai ? 'ถ่ายวิดีโอ' : 'Record video'),
                  ),
                ),
                SizedBox(
                  width: stacked
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 10) / 2,
                  child: OutlinedButton.icon(
                    onPressed: onVideoGallery,
                    icon: const Icon(Icons.video_library_outlined),
                    label: Text(thai ? 'เลือกวิดีโอ' : 'Choose video'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ReadablePoseExample extends StatelessWidget {
  const _ReadablePoseExample({
    required this.activity,
    required this.thai,
  });

  final SooktaActivity activity;
  final bool thai;

  @override
  Widget build(BuildContext context) {
    final activityLabel = activity.label(thai: thai);
    final imageAsset = activity.readablePoseExampleAsset;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6E7DD)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final image = _ReadablePosePreviewImage(
            activityLabel: activityLabel,
            imageAsset: imageAsset,
            thai: thai,
            width: compact ? constraints.maxWidth : 128,
            height: compact ? 190 : 116,
          );
          final text = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thai
                      ? 'ตัวอย่างภาพ: $activityLabel'
                      : 'Example: $activityLabel',
                  style: const TextStyle(
                    color: SooktaColors.darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  thai
                      ? 'ถ่ายให้เห็นคนทำงานเกือบทั้งตัว แสงชัด และอย่าให้ใบไม้ เครื่องมือ หรือคนอื่นบังศีรษะ หลัง แขน มือ และขา'
                      : 'Capture almost the full worker with clear light. Avoid leaves, tools, or other people covering the head, back, arms, hands, and legs.',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image,
                const SizedBox(height: 8),
                Row(children: [text]),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              image,
              const SizedBox(width: 12),
              text,
            ],
          );
        },
      ),
    );
  }
}

class _ReadablePosePreviewImage extends StatelessWidget {
  const _ReadablePosePreviewImage({
    required this.activityLabel,
    required this.imageAsset,
    required this.thai,
    required this.width,
    required this.height,
  });

  final String activityLabel;
  final String imageAsset;
  final bool thai;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: thai
          ? 'ดูตัวอย่างภาพที่อ่านง่ายแบบเต็มจอ'
          : 'View readable example full screen',
      child: InkWell(
        onTap: () => _showReadablePosePreview(
          context,
          imageAsset: imageAsset,
          activityLabel: activityLabel,
          thai: thai,
        ),
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: width,
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF7FBF8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showReadablePosePreview(
  BuildContext context, {
  required String imageAsset,
  required String activityLabel,
  required bool thai,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog.fullscreen(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(
                  thai
                      ? 'ตัวอย่างภาพ: $activityLabel'
                      : 'Example: $activityLabel',
                ),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    tooltip: thai ? 'ปิด' : 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  key: const ValueKey('readable_pose_full_preview'),
                  minScale: 0.7,
                  maxScale: 4,
                  child: Center(
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Text(
                  thai
                      ? 'ถ่ายให้เห็นคนทำงานเกือบทั้งตัวและไม่ให้สิ่งของบังข้อสำคัญ เพื่อให้ระบบอ่านท่าทางได้แม่นขึ้น'
                      : 'Capture almost the full worker without blocking key joints so the app can read posture more reliably.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LockedLoadSummary extends StatelessWidget {
  const _LockedLoadSummary({
    required this.thai,
    required this.toolLabel,
    required this.loadKgText,
  });

  final bool thai;
  final String toolLabel;
  final String loadKgText;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6E7DD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: SooktaColors.darkGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text:
                    thai ? 'น้ำหนักใช้ตามเครื่องมือ: ' : 'Load follows tool: ',
                style: const TextStyle(color: Colors.black54),
                children: [
                  TextSpan(
                    text: thai
                        ? '$toolLabel ($loadKgText กก.)'
                        : '$toolLabel ($loadKgText kg)',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleAssessmentCard extends StatelessWidget {
  const _SimpleAssessmentCard({
    required this.thai,
    required this.activityName,
    required this.jobType,
    required this.imageCount,
    required this.poseBusy,
    required this.poseReady,
    required this.poseStatus,
    required this.durationHours,
    required this.frequency,
    required this.loadWeight,
    required this.toolLabel,
    required this.initialForce,
    required this.sustainForce,
    required this.pushPullDistance,
    required this.validationIssues,
    required this.onAnalyze,
  });

  final bool thai;
  final String activityName;
  final JobType jobType;
  final int imageCount;
  final bool poseBusy;
  final bool poseReady;
  final String? poseStatus;
  final double durationHours;
  final double frequency;
  final double loadWeight;
  final String toolLabel;
  final double initialForce;
  final double sustainForce;
  final double pushPullDistance;
  final List<String> validationIssues;
  final VoidCallback? onAnalyze;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageCount > 0;
    final ready = hasImage && poseReady && !poseBusy;
    final blocked = hasImage && !poseReady && !poseBusy;
    final color = ready
        ? SooktaColors.leafGreen
        : blocked
            ? Colors.red.shade700
            : Colors.amber.shade700;
    final statusSpeech = thai
        ? '${ready ? 'ระบบตั้งค่าประเมินให้แล้ว' : blocked ? 'ยังประเมินไม่ได้' : 'ถ่ายรูปหรือวิดีโอก่อน แล้วระบบจะช่วยคำนวณ'} ${poseStatus ?? 'ต้องมีรูปหรือวิดีโอที่เห็นบุคคลและท่าทางชัดเจนก่อน ระบบจึงจะแสดงตัวเลขประเมิน'} กิจกรรม $activityName วิธีประเมิน ${_jobLabel(jobType, true)} ค่าพื้นฐาน ${_defaultSummary(true)} เครื่องมือ $toolLabel'
        : '${ready ? 'The app prepared the assessment.' : blocked ? 'Cannot assess yet.' : 'Take a photo or video and the app will calculate.'} ${poseStatus ?? 'A clear person-posture photo or video is required before the app shows assessment numbers.'} Activity $activityName. Assessment method ${_jobLabel(jobType, false)}. Defaults ${_defaultSummary(false)}. Tool $toolLabel.';
    return Card(
      color: ready
          ? const Color(0xFFEFF8EF)
          : blocked
              ? const Color(0xFFFFF1F1)
              : const Color(0xFFFFFBEE),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  ready
                      ? Icons.check_circle_outline
                      : blocked
                          ? Icons.warning_amber_rounded
                          : Icons.touch_app_outlined,
                  color: color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        thai
                            ? (ready
                                ? 'ระบบตั้งค่าประเมินให้แล้ว'
                                : blocked
                                    ? 'ยังประเมินไม่ได้'
                                    : 'ถ่ายรูปหรือวิดีโอก่อน แล้วระบบจะช่วยคำนวณ')
                            : (ready
                                ? 'The app prepared the assessment'
                                : blocked
                                    ? 'Cannot assess yet'
                                    : 'Take a photo or video and the app will calculate'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        poseBusy
                            ? (thai
                                ? 'กำลังอ่านท่าทางจากรูปภาพ...'
                                : 'Reading posture from the photo...')
                            : (poseStatus ??
                                (thai
                                    ? 'ต้องมีรูปหรือวิดีโอที่เห็นบุคคลและท่าทางชัดเจนก่อน ระบบจึงจะแสดงตัวเลขประเมิน'
                                    : 'A clear person-posture photo or video is required before the app shows assessment numbers.')),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                SooktaTtsButton(text: statusSpeech, thai: thai, size: 38),
              ],
            ),
            if (poseBusy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 14),
            _SimpleFactRow(
              icon: Icons.work_outline,
              label: thai ? 'กิจกรรม' : 'Activity',
              value: activityName,
            ),
            _SimpleFactRow(
              icon: Icons.auto_awesome,
              label: thai ? 'วิธีประเมิน' : 'Assessment',
              value: _jobLabel(jobType, thai),
            ),
            _SimpleFactRow(
              icon: Icons.schedule,
              label: thai ? 'ค่าพื้นฐาน' : 'Defaults',
              value: _defaultSummary(thai),
            ),
            _SimpleFactRow(
              icon: Icons.inventory_2_outlined,
              label: thai ? 'เครื่องมือ/น้ำหนัก' : 'Tool / load',
              value: toolLabel,
            ),
            if (validationIssues.isNotEmpty) ...[
              const SizedBox(height: 8),
              _RequiredDataNotice(
                thai: thai,
                issues: validationIssues,
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onAnalyze,
              icon: const Icon(Icons.arrow_forward),
              label: Text(thai ? 'ดูผลประเมิน' : 'View Assessment'),
            ),
          ],
        ),
      ),
    );
  }

  String _defaultSummary(bool thai) {
    final duration = switch (durationHours) {
      <= 0.5 => thai ? '<30 นาที' : '<30 min',
      <= 1.0 => thai ? '30 นาที-1 ชม.' : '30 min-1 hr',
      <= 2.0 => thai ? '1-2 ชม.' : '1-2 hrs',
      _ => thai ? '>2 ชม.' : '>2 hrs',
    };
    final repetition = switch (frequency) {
      <= 0.2 => thai ? 'ไม่ซ้ำ' : 'not repeated',
      < 4.0 => thai ? '<4 ครั้ง/นาที' : '<4 times/min',
      <= 10.0 => thai ? '4-10 ครั้ง/นาที' : '4-10 times/min',
      _ => thai ? '>10 ครั้ง/นาที' : '>10 times/min',
    };
    if (jobType == JobType.lifting) {
      return thai
          ? '$duration, $repetition, น้ำหนักประมาณ ${loadWeight.round()} กก.'
          : '$duration, $repetition, about ${loadWeight.round()} kg';
    }
    if (jobType == JobType.pushPull) {
      return thai
          ? '$duration, $repetition, แรง ${initialForce.round()}/${sustainForce.round()} N, ระยะ ${pushPullDistance.round()} ม.'
          : '$duration, $repetition, force ${initialForce.round()}/${sustainForce.round()} N, distance ${pushPullDistance.round()} m';
    }
    return '$duration, $repetition';
  }
}

class _SimpleFactRow extends StatelessWidget {
  const _SimpleFactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: SooktaColors.darkGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label: ',
                style: const TextStyle(color: Colors.black54),
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequiredDataNotice extends StatelessWidget {
  const _RequiredDataNotice({
    required this.thai,
    required this.issues,
  });

  final bool thai;
  final List<String> issues;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade800,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    thai
                        ? 'กรุณาตรวจข้อมูลก่อนประเมิน'
                        : 'Check required data before assessment',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final issue in issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $issue'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdvancedDetailsCard extends StatelessWidget {
  const _AdvancedDetailsCard({
    required this.thai,
    required this.expanded,
    required this.onExpansionChanged,
    required this.children,
  });

  final bool thai;
  final bool expanded;
  final ValueChanged<bool> onExpansionChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: onExpansionChanged,
        leading: const Icon(Icons.tune, color: SooktaColors.darkGreen),
        title: Text(
          thai ? 'กรุณาปรับรายละเอียดงานจริง' : 'Adjust Real Work Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          thai
              ? 'เลือกค่าที่ใกล้เคียงงานจริงที่สุด ระบบจะใช้ค่านี้คำนวณคะแนน'
              : 'Choose values closest to the real task. The app uses them for scoring.',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: children,
      ),
    );
  }
}

class _PoseFrameAnalysisCard extends StatelessWidget {
  const _PoseFrameAnalysisCard({
    required this.thai,
    required this.frames,
    required this.worstImageIndex,
    required this.motionSummary,
  });

  final bool thai;
  final List<PoseRebaFrameAnalysis> frames;
  final int? worstImageIndex;
  final MotionAnalysisSummary? motionSummary;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: thai ? 'ผลวิเคราะห์รายภาพจาก AI' : 'Per-photo AI posture analysis',
      children: [
        if (motionSummary != null && motionSummary!.isVideo) ...[
          _VideoMotionSummaryPanel(
            thai: thai,
            summary: motionSummary!,
          ),
          const SizedBox(height: 12),
        ],
        Text(
          thai
              ? 'ระบบเลือกภาพที่มีคะแนน REBA สูงที่สุดเป็น Worst Posture สำหรับคำนวณผลหลัก'
              : 'The app uses the photo with the highest REBA score as the worst posture for the main result.',
          style: const TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 10),
        ...frames.map(
          (frame) {
            final worst = frame.imageIndex == worstImageIndex;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: worst ? const Color(0xFFFFF7E0) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: worst ? Colors.amber.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thai
                              ? 'ภาพที่ ${frame.imageIndex}'
                              : 'Photo ${frame.imageIndex}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (worst)
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            thai ? 'Worst Posture' : 'Worst Posture',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MiniMetric(
                        label: thai ? 'คอ' : 'Neck',
                        value: _deg(frame.neckFlexionDeg),
                      ),
                      _MiniMetric(
                        label: thai ? 'ลำตัว' : 'Trunk',
                        value: _deg(frame.trunkFlexionDeg),
                      ),
                      _MiniMetric(
                        label: thai ? 'ต้นแขน' : 'Upper arm',
                        value: _deg(frame.upperArmFlexionDeg),
                      ),
                      _MiniMetric(
                        label: thai ? 'ปลายแขน' : 'Lower arm',
                        value: _deg(frame.lowerArmAngleDeg),
                      ),
                      _MiniMetric(
                        label: thai ? 'เข่า' : 'Knee',
                        value: _deg(frame.kneeAngleDeg),
                      ),
                      _MiniMetric(
                        label: 'REBA',
                        value: '${frame.rebaScore}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _modifiers(frame),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _deg(double? value) {
    if (value == null || value.isNaN) return '-';
    return '${value.round()}°';
  }

  String _modifiers(PoseRebaFrameAnalysis frame) {
    final items = <String>[
      if (frame.neckSideBending) thai ? 'คอเอียง' : 'neck side bend',
      if (frame.neckTwisting) thai ? 'คอบิด' : 'neck twist',
      if (frame.trunkSideBending) thai ? 'ลำตัวเอียง' : 'trunk side bend',
      if (frame.trunkTwisting) thai ? 'ลำตัวบิด' : 'trunk twist',
      if (frame.upperArmAbduction) thai ? 'แขนกาง' : 'arm abduction',
      if (frame.shoulderElevation)
        thai ? 'ยกไหล่/ยกแขนสูง' : 'shoulder/arm raised',
    ];
    if (items.isEmpty) {
      return thai
          ? 'ไม่พบตัวเพิ่มคะแนนจากการบิด/เอียงในภาพนี้'
          : 'No twist/side-bend modifier was detected in this photo.';
    }
    return thai
        ? 'ตัวเพิ่มคะแนน: ${items.join(', ')}'
        : 'Modifiers: ${items.join(', ')}';
  }
}

class _VideoMotionSummaryPanel extends StatelessWidget {
  const _VideoMotionSummaryPanel({
    required this.thai,
    required this.summary,
  });

  final bool thai;
  final MotionAnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8EF),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: SooktaColors.leafGreen.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.motion_photos_auto_outlined,
                  color: SooktaColors.darkGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    thai
                        ? 'สรุปการเคลื่อนไหวจากวิดีโอ'
                        : 'Video-derived motion summary',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              thai
                  ? 'แอปไม่ได้ประเมินทุกเฟรมต่อเนื่อง แต่สุ่มเฟรมหลายจุดจากวิดีโอแล้วสรุปช่วงที่เสี่ยงที่สุด'
                  : 'The app does not score every video frame continuously. It samples multiple points from the video and summarizes the riskiest posture windows.',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MiniMetric(
                  label: thai ? 'ความยาว' : 'Duration',
                  value: '${(summary.durationMs / 1000).toStringAsFixed(1)}s',
                ),
                _MiniMetric(
                  label: thai ? 'เฟรมที่อ่านได้' : 'Readable',
                  value:
                      '${summary.readableFrameCount}/${summary.sampledFrameCount}',
                ),
                _MiniMetric(
                  label: thai ? 'REBA สูง' : 'High risk',
                  value: _percent(summary.highRiskFrameRatio),
                ),
                _MiniMetric(
                  label: thai ? 'ส่วนร่างกายเสี่ยง' : 'Segment risk',
                  value: _percent(summary.anySegmentRiskFrameRatio),
                ),
                _MiniMetric(
                  label: thai ? 'จุดเด่น' : 'Dominant',
                  value: _bodyPartLabel(summary.dominantRiskBodyPart, thai),
                ),
                _MiniMetric(
                  label: thai ? 'เวลาเสี่ยงย่อย' : 'Segment time',
                  value:
                      '${summary.estimatedSegmentRiskSeconds.toStringAsFixed(1)}s',
                ),
                _MiniMetric(
                  label: thai ? 'เวลาเสี่ยงรวม' : 'High-risk time',
                  value:
                      '${summary.estimatedHighRiskSeconds.toStringAsFixed(1)}s',
                ),
                _MiniMetric(
                  label: thai ? 'ลำตัวสูงสุด' : 'Max trunk',
                  value: _deg(summary.maxTrunkFlexionDeg),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MiniMetric(
                  label: thai ? 'คอ' : 'Neck',
                  value: _percent(summary.neckRiskFrameRatio),
                ),
                _MiniMetric(
                  label: thai ? 'ลำตัว' : 'Trunk',
                  value: _percent(summary.trunkRiskFrameRatio),
                ),
                _MiniMetric(
                  label: thai ? 'ต้นแขน' : 'Upper arm',
                  value: _percent(summary.upperArmRiskFrameRatio),
                ),
                _MiniMetric(
                  label: thai ? 'ปลายแขน' : 'Lower arm',
                  value: _percent(summary.lowerArmRiskFrameRatio),
                ),
                _MiniMetric(
                  label: thai ? 'ข้อมือ' : 'Wrist',
                  value: _percent(summary.wristRiskFrameRatio),
                ),
                _MiniMetric(
                  label: thai ? 'ขา/เข่า' : 'Legs',
                  value: _percent(summary.legRiskFrameRatio),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              thai
                  ? 'รูปแบบ: ${_patternLabel(summary.pattern, thai)} • เปลี่ยนท่าชัดเจน ${summary.movementChangeCount} ครั้ง'
                  : 'Pattern: ${_patternLabel(summary.pattern, thai)} • ${summary.movementChangeCount} clear posture changes',
              style: const TextStyle(color: SooktaColors.darkGreen),
            ),
          ],
        ),
      ),
    );
  }

  String _percent(double ratio) => '${(ratio * 100).round()}%';

  String _deg(double? value) {
    if (value == null || value.isNaN) return '-';
    return '${value.round()}°';
  }

  String _patternLabel(MotionPattern pattern, bool thai) {
    if (thai) {
      return switch (pattern) {
        MotionPattern.stableLowRisk => 'ท่าทางค่อนข้างคงที่และเสี่ยงต่ำ',
        MotionPattern.intermittentWorstPosture => 'มีช่วงท่าเสี่ยงเป็นบางจุด',
        MotionPattern.repeatedRiskMovement => 'มีการเคลื่อนไหวเสี่ยงซ้ำ',
        MotionPattern.staticHighRiskHold => 'ค้างท่าเสี่ยงสูงหลายช่วง',
      };
    }
    return switch (pattern) {
      MotionPattern.stableLowRisk => 'stable lower-risk posture',
      MotionPattern.intermittentWorstPosture => 'intermittent worst posture',
      MotionPattern.repeatedRiskMovement => 'repeated risk movement',
      MotionPattern.staticHighRiskHold => 'static high-risk hold',
    };
  }

  String _bodyPartLabel(String? key, bool thai) {
    if (key == null) return thai ? 'ไม่พบส่วนเด่น' : 'none';
    if (thai) {
      return switch (key) {
        'neck' => 'คอ',
        'trunk' => 'ลำตัว/หลัง',
        'upper_arm' => 'ต้นแขน/ไหล่',
        'lower_arm' => 'ปลายแขน',
        'wrist' => 'ข้อมือ',
        'legs' => 'ขา/เข่า',
        _ => key,
      };
    }
    return switch (key) {
      'neck' => 'neck',
      'trunk' => 'trunk/back',
      'upper_arm' => 'upper arm/shoulder',
      'lower_arm' => 'lower arm',
      'wrist' => 'wrist',
      'legs' => 'legs/knees',
      _ => key,
    };
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text('$label: $value'),
      ),
    );
  }
}

String _jobLabel(JobType jobType, bool thai) {
  return switch (jobType) {
    JobType.reba => thai ? 'ดูท่าทางจากรูป' : 'Posture from photo',
    JobType.lifting => thai ? 'งานยก/แบก' : 'Lifting',
    JobType.pushPull => thai ? 'งานดัน/ดึง' : 'Push or pull',
  };
}

class _RebaCard extends StatelessWidget {
  const _RebaCard({
    required this.thai,
    required this.input,
    required this.poseBusy,
    required this.poseStatus,
    required this.onChanged,
    required this.onAutoFill,
  });

  final bool thai;
  final RebaInputData input;
  final bool poseBusy;
  final String? poseStatus;
  final ValueChanged<RebaInputData> onChanged;
  final VoidCallback? onAutoFill;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: thai ? 'คะแนนท่าทาง REBA' : 'REBA Posture Scores',
      children: [
        OutlinedButton.icon(
          onPressed: onAutoFill,
          icon: poseBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(thai ? 'ประเมิน REBA จากภาพ' : 'Assess REBA from photos'),
        ),
        if (poseStatus != null) ...[
          const SizedBox(height: 8),
          Text(
            poseStatus!,
            style: const TextStyle(color: SooktaColors.darkGreen),
          ),
        ],
        _ScoreSlider(
          label: thai ? 'ลำตัว' : 'Trunk',
          value: input.trunkScore,
          min: 1,
          max: 4,
          onChanged: (value) => onChanged(input.copyWith(trunkScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'คอ' : 'Neck',
          value: input.neckScore,
          min: 1,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(neckScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'ขา' : 'Legs',
          value: input.legScore,
          min: 1,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(legScore: value)),
        ),
        _CheckTile(
          label: thai ? 'ลำตัวบิด' : 'Trunk twist',
          value: input.trunkTwist,
          onChanged: (value) => onChanged(input.copyWith(trunkTwist: value)),
        ),
        _CheckTile(
          label: thai ? 'ลำตัวเอียงข้าง' : 'Trunk side flexion',
          value: input.trunkSideFlex,
          onChanged: (value) => onChanged(input.copyWith(trunkSideFlex: value)),
        ),
        _ScoreSlider(
          label: thai ? 'ต้นแขน' : 'Upper Arm',
          value: input.upperArmScore,
          min: 1,
          max: 4,
          onChanged: (value) => onChanged(input.copyWith(upperArmScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'ปลายแขน' : 'Lower Arm',
          value: input.lowerArmScore,
          min: 1,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(lowerArmScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'ข้อมือ' : 'Wrist',
          value: input.wristScore,
          min: 1,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(wristScore: value)),
        ),
        _CheckTile(
          label: thai ? 'ข้อมือบิด' : 'Wrist twist',
          value: input.wristTwist,
          onChanged: (value) => onChanged(input.copyWith(wristTwist: value)),
        ),
        _ScoreSlider(
          label: thai ? 'น้ำหนักที่ถือ' : 'Load',
          value: input.loadScore,
          min: 0,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(loadScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'การจับยึด' : 'Coupling',
          value: input.couplingScore,
          min: 0,
          max: 2,
          onChanged: (value) => onChanged(input.copyWith(couplingScore: value)),
        ),
        _ScoreSlider(
          label: thai ? 'กิจกรรมซ้ำ/ค้างท่า' : 'Activity',
          value: input.activityScore,
          min: 0,
          max: 3,
          onChanged: (value) => onChanged(input.copyWith(activityScore: value)),
        ),
      ],
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: (checked) => onChanged(checked ?? false),
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class _IsoCard extends StatelessWidget {
  const _IsoCard({
    required this.thai,
    required this.jobType,
    required this.horizontalController,
    required this.verticalController,
    required this.transportController,
    required this.initialForce,
    required this.sustainForce,
    required this.pushPullDistance,
    required this.onInitialForceChanged,
    required this.onSustainForceChanged,
    required this.onPushPullDistanceChanged,
  });

  final bool thai;
  final JobType jobType;
  final TextEditingController horizontalController;
  final TextEditingController verticalController;
  final TextEditingController transportController;
  final double initialForce;
  final double sustainForce;
  final double pushPullDistance;
  final ValueChanged<double> onInitialForceChanged;
  final ValueChanged<double> onSustainForceChanged;
  final ValueChanged<double> onPushPullDistanceChanged;

  @override
  Widget build(BuildContext context) {
    final lifting = jobType == JobType.lifting;
    return _SectionCard(
      title: lifting
          ? (thai ? 'ข้อมูล ISO 11228 งานยก' : 'ISO 11228 Lifting')
          : (thai ? 'ข้อมูลแรงดัน/ดึง' : 'Push/Pull Force'),
      children: [
        if (lifting) ...[
          _NumberField(
            controller: horizontalController,
            label: thai ? 'ระยะห่าง H (cm)' : 'Distance H (cm)',
          ),
          _NumberField(
            controller: verticalController,
            label: thai ? 'ความสูง V (cm)' : 'Height V (cm)',
          ),
          _NumberField(
            controller: transportController,
            label: thai ? 'ระยะทางขนย้าย (m)' : 'Transport distance (m)',
          ),
        ] else ...[
          Text(
            thai
                ? 'ค่าดัน/ลากเหล่านี้กล้องอ่านไม่ได้โดยตรง กรุณาเลือกค่าที่ใกล้เคียงกับงานจริงที่สุด หากไม่แน่ใจให้ใช้ค่าเริ่มต้น'
                : 'Photos and video cannot directly measure these push/pull values. Choose the closest real-task values. If unsure, keep the defaults.',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          _ChoiceRow<double>(
            label: thai ? 'แรงเริ่มต้นดัน/ลาก' : 'Initial push/pull force',
            value: initialForce,
            items: {
              8.0: thai ? 'เบามาก (8 N)' : 'Very light (8 N)',
              12.0: thai ? 'เบา (12 N)' : 'Light (12 N)',
              18.0: thai ? 'ปานกลาง (18 N)' : 'Moderate (18 N)',
              20.0: thai
                  ? 'ค่าเริ่มต้นงานขนย้าย (20 N)'
                  : 'Transport default (20 N)',
              25.0: thai ? 'หนัก (25 N)' : 'Heavy (25 N)',
              35.0: thai ? 'หนักมาก (35 N)' : 'Very heavy (35 N)',
            },
            onChanged: onInitialForceChanged,
          ),
          _ChoiceRow<double>(
            label: thai ? 'แรงต่อเนื่องดัน/ลาก' : 'Sustained push/pull force',
            value: sustainForce,
            items: {
              4.0: thai ? 'เบามาก (4 N)' : 'Very light (4 N)',
              6.0: thai ? 'เบา (6 N)' : 'Light (6 N)',
              10.0: thai ? 'ปานกลาง (10 N)' : 'Moderate (10 N)',
              12.0: thai
                  ? 'ค่าเริ่มต้นงานขนย้าย (12 N)'
                  : 'Transport default (12 N)',
              15.0: thai ? 'หนัก (15 N)' : 'Heavy (15 N)',
              22.0: thai ? 'หนักมาก (22 N)' : 'Very heavy (22 N)',
            },
            onChanged: onSustainForceChanged,
          ),
          _ChoiceRow<double>(
            label: thai ? 'ระยะดัน/ลาก' : 'Push/pull distance',
            value: pushPullDistance,
            items: {
              2.0: thai ? 'ใกล้มาก (ไม่เกิน 2 ม.)' : 'Very short (up to 2 m)',
              10.0: thai ? 'ใกล้ (2-10 ม.)' : 'Short (2-10 m)',
              20.0: thai ? 'ปานกลาง (10-20 ม.)' : 'Moderate (10-20 m)',
              30.0: thai ? 'ไกล (>20 ม.)' : 'Long (>20 m)',
            },
            onChanged: onPushPullDistanceChanged,
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<T>(
        key: ValueKey<String>('${label}_${value.hashCode}'),
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: items.entries
            .map(
              (entry) => DropdownMenuItem<T>(
                value: entry.key,
                child: Text(
                  entry.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _ScoreSlider extends StatelessWidget {
  const _ScoreSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value'),
        Slider(
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          value: value.toDouble(),
          label: '$value',
          onChanged: (value) => onChanged(value.round()),
        ),
      ],
    );
  }
}
