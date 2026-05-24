# ML Training Reference Sources

Updated: 2026-05-24

This document records the local reference set used to guide fSookta ergonomic
model training, label design, and recommendation evidence. The PDFs remain
outside the repository because ISO standards and some guides can be
copyright-protected. The committed registry stores only metadata, local paths,
hashes, and intended use.

Machine-readable registry:

```text
data/research/reference_sources/training_reference_sources.json
```

## Source Set

| Source ID | Local file | Used for |
|---|---|---|
| `iso_11228_1_2021` | `/Users/kpc/Documents/Doc/fortrain/ISO-11228-1-2021.pdf` | Lifting, lowering, carrying, and transport-distance features for ISO 11228 structured labels |
| `iso_11228_2_2007` | `/Users/kpc/Documents/Doc/fortrain/ISO-11228-2-2007.pdf` | Push/pull force features and future push/pull risk labels |
| `iso_11228_3_2007` | `/Users/kpc/Documents/Doc/fortrain/ISO-11228-3-2007.pdf` | Repetitive low-load upper-limb work, recovery, frequency, and duration features |
| `reba_step_by_step_ergo_plus` | `/Users/kpc/Documents/Doc/fortrain/REBA-A-Step-by-Step-Guide.pdf` | Secondary REBA scoring explanation and REBA label QA checklist |
| `ilo_ergonomic_checkpoints_agriculture` | `/Users/kpc/Documents/Doc/fortrain/wcms_168042.pdf` | Farmer-friendly recommendation categories and controls for agriculture |

## How They Feed The App

The current MoveNet Logistic Regression artifact remains a REBA-focused posture
model:

```text
MoveNet 51 features
-> REBA angle feature engineering
-> Logistic Regression
-> risk level and risky body parts
```

The new ISO and agriculture-reference documents are used for the next training
layer:

```text
REBA pose model output
+ structured evaluation fields
+ ISO 11228 labels
+ recommendation-control categories
-> risk-alert model / future XGBoost model
```

## Feature Mapping

ISO 11228-1 should guide lifting/carrying features:

- load weight
- horizontal distance
- vertical position
- lifting frequency
- duration
- carrying or transport distance
- derived lifting index or risk band

ISO 11228-2 should guide push/pull features:

- initial force
- sustained force
- push/pull distance
- frequency or repetitions
- duration
- handle height
- derived force ratio or risk band

ISO 11228-3 should guide repetitive upper-limb features:

- repetition rate
- cycle time
- force exertion level
- recovery time
- shoulder/arm/wrist posture
- task duration

The REBA guide is used only as a secondary QA reference because the app already
uses research-team REBA-2 labels where available.

The agriculture checkpoints document is used for recommendation evidence:

- reduce deep bending and overreaching
- keep frequently used work close to the body
- reduce manual load, carrying distance, and repeated force
- use carts, better tools, and work-height changes
- add rest/recovery or task variation
- improve paths, footing, and work organization

## Guardrails

- Do not commit the ISO PDFs or reproduce substantial text from them.
- Use the registry hashes to confirm the local source version before retraining.
- Keep ISO labels separate from pose-only REBA labels unless the model is
  explicitly designed as a multi-task or structured-input model.
- Treat recommendation score reductions in the app as simulation estimates, not
  clinical or legal claims.
