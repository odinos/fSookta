# Research Drive Media Catalog

Source folder:
`https://drive.google.com/drive/folders/1N1ZvbzwXGfRSL6_bghHndltduzGjL482`

This catalog records the media currently available for building the fSookta
research dataset. It does not claim that these files are sufficient for a
production research-trained model yet. The immediate purpose is to support
offline feature extraction, REBA/ISO pseudo-labeling, and later expert labeling.

## Summary

| Activity | Sessions | Videos | Images | Total media | Notes |
|---|---:|---:|---:|---:|---|
| Transplanting | 5 | 4 | 0 | 4 | One empty session: `1.5` |
| Fertilizing | 6 | 12 | 0 | 12 | Good video-only activity set |
| Pesticide spraying | 5 | 3 | 11 | 14 | One empty session: `3.3`; `3.2` is image-only |
| Pruning | 7 | 17 | 14 | 31 | Strongest mixed media set |
| Harvesting | 7 | 13 | 17 | 30 | Strong mixed media set |
| On-farm transport | 6 | 10 | 11 | 21 | Good mixed media set |
| **Total** | **36** | **59** | **53** | **112** | 34 non-empty sessions |

## Best Starting Sessions

- `4.1` Pruning: 6 videos, 3 images
- `4.3` Pruning: 3 videos, 11 images
- `5.3` Harvesting: 3 videos, 5 images
- `5.4` Harvesting: 1 video, 9 images
- `6.2` On-farm transport: 2 videos, 4 images

These are good first candidates because they contain both still images and
videos, which helps validate both static MoveNet extraction and frame-sampled
video extraction.

## Dataset Readiness

The media can be used as a dataset seed for:

- MoveNet keypoint extraction
- 51-value joint feature vectors using
  `assets/models/joint_feature_schema.json`
- REBA/ISO pseudo-label generation
- Activity classification metadata
- Later Logistic Regression and XGBoost training

The media is not enough by itself for a validated research-trained model. The
model still needs expert or outcome labels, for example:

- Expert-reviewed REBA/ISO score
- Reported pain body part
- Actual treatment cost
- Lost work days or lost income
- Before/after intervention outcome
- Consent and anonymized participant/session metadata

## Recommended Extraction Plan

1. Use `data/research/drive_media_catalog.csv` as the session manifest.
2. For image-only and mixed sessions, run one MoveNet extraction per image.
3. For video sessions, sample frames every 1 second at first.
4. Save one row per extracted frame/image with:
   - `activity`
   - `session_id`
   - `source_file_id`
   - `source_file_name`
   - `frame_timestamp_ms`
   - `joint_feature_0` through `joint_feature_50`
   - `pseudo_reba_score`
   - `pseudo_risk_level`
   - `label_source`
5. Keep all trained model artifacts marked as pending until expert labels are
   available.
