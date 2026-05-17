# Research Dataset Extraction

This pipeline turns local Drive media into a MoveNet feature dataset that can
later be labeled and used to train Logistic Regression and XGBoost models.

It intentionally lives outside the Flutter app so research dependencies such as
OpenCV and TensorFlow do not affect iOS/App Store builds.

## Inputs

- Session manifest: `data/research/drive_media_catalog.csv`
- Local media root: `data/research/media/`
- MoveNet model: `assets/ml/movenet_thunder.tflite`
- Feature schema: `assets/models/joint_feature_schema.json`

Put downloaded media in one of these layouts:

```text
data/research/media/pruning/4.1/*.jpg
data/research/media/pruning/4.1/*.mov
data/research/media/4.1/*.mp4
data/research/media/4. Pruning (7)/4.1/*.jpg
```

Raw media and extracted outputs are ignored by git.

## Dry Run

Use this first to confirm that local media is discoverable:

```bash
python3 tools/research_dataset/extract_pose_dataset.py --dry-run
```

Outputs:

- `data/research/extracted/media_inventory.csv`
- `data/research/extracted/missing_media_sessions.csv`
- `data/research/extracted/dataset_extraction_report.json`

## Download Priority Media

The first file-level Drive manifest is:

```text
data/research/drive_priority_file_catalog.csv
```

It covers priority sessions `4.1`, `4.3`, `5.3`, `5.4`, and `6.2`.

For a quick first pass, download images only:

```bash
python3 tools/research_dataset/download_drive_media.py --images-only
```

Download videos separately when there is enough disk space and time:

```bash
python3 tools/research_dataset/download_drive_media.py --videos-only
```

## Run MoveNet Extraction

Install research-only dependencies:

```bash
python3 -m pip install -r tools/research_dataset/requirements.txt
```

Then run:

```bash
python3 tools/research_dataset/extract_pose_dataset.py \
  --frame-interval-sec 1.0 \
  --min-pose-score 0.2
```

Main output:

```text
data/research/extracted/pose_feature_dataset.csv
```

Each row contains:

- activity/session metadata
- image path or sampled video frame timestamp
- pose confidence and extraction status
- 51 canonical MoveNet features in `x, y, score` order
- empty label columns reserved for expert labels

Only rows with `pose_status=ok` should be used for initial model experiments.
Rows marked `low_confidence`, `read_failed`, or `inference_failed` should be
reviewed or excluded.

## QA And Label Template

After extraction, generate QA files and an expert-label template:

```bash
python3 tools/research_dataset/qa_pose_dataset.py
```

Outputs:

- `data/research/extracted/qa/qa_summary.json`
- `data/research/extracted/qa/qa_by_activity_session.csv`
- `data/research/extracted/qa/low_confidence_review.csv`
- `data/research/extracted/qa/expert_label_template.csv`

The label template keeps one row per extracted image/frame and leaves research
fields blank for expert review, including REBA score, risk level, body part,
pain score, treatment cost, lost income, lost work days, and recommendation.
Rows with weak pose confidence are marked `suggested_include_for_training=no`
so they can be reviewed before model training.

The template also includes the ERGO process fields from Notion:

- REBA posture and adjustment fields such as trunk twist, trunk side flexion,
  wrist twist, coupling, and activity.
- ISO 11228-1 lifting fields such as load weight, lift frequency, duration,
  vertical position, horizontal distance, RWL, and Lifting Index.
- ISO 11228-2 push/pull fields such as initial/sustained force and the
  corresponding force limits.

## Labeling Gate

The extractor does not create a validated AI model by itself. The output still
needs labels before training:

- expert REBA/ISO score
- risk level
- body part affected
- cost/lost income outcome when available
- participant/session consent metadata

Until those labels exist, generated model artifacts should remain marked as
research-pending, not research-trained.
