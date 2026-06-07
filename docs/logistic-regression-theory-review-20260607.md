# Logistic Regression Theory Review

วันที่ตรวจสอบ: 2026-06-07  
ขอบเขต: ตรวจ Logistic Regression ในแอป Sookta เทียบกับแหล่งอ้างอิงที่ผู้ว่าจ้างให้

## 1. แหล่งอ้างอิงที่ใช้ตรวจ

- Data Sci Haeng EP.03: Logistic Regression ใช้แก้ปัญหา classification และให้ผลเป็นความน่าจะเป็น 0..1 ด้วย sigmoid/logit
- Data Sci Haeng EP.04: การใช้งานจริงต้องเตรียมข้อมูล, standardization, fit model, predict และอ่าน coefficient ในรูป log-odds
- Machine Learning from Scratch: parameter estimation ของ Logistic Regression ใช้ maximum likelihood; gradient ของ log-likelihood คือ `X^T(y - p)` และไม่มี closed form solution จึงต้อง optimize เช่น gradient descent/ascent หรือ solver เทียบเท่า

## 2. สมการที่ระบบใช้หลังตรวจ

โมเดล Logistic Regression ที่ใช้จริงในแอปคือโมเดลทำนายจากประวัติ 7 transaction:

```text
z = beta0 + beta1*x1 + beta2*x2 + ... + betak*xk
p(y = 1 | x) = 1 / (1 + exp(-z))
```

ใน code อยู่ที่:

- `lib/core/services/daily_injury_prediction_service.dart`
- asset coefficients: `assets/ml/daily_injury_logistic_model.json`

ผลลัพธ์ `p` ถูกนำไป map เป็นระดับ:

- `< 0.45` = low
- `0.45..0.649` = watch
- `0.65..0.819` = high
- `>= 0.82` = critical

## 3. Feature ที่เข้า Logistic Regression

ระบบใช้ประวัติ 7 transaction ล่าสุดของชาวสวนคนเดียวกัน แล้วแปลงเป็น feature ที่ normalize แล้ว เช่น:

- ค่าเฉลี่ยคะแนนก่อนปรับ
- คะแนนสูงสุดก่อนปรับ
- ค่าเฉลี่ยคะแนนหลังปรับ
- จำนวนวันที่ high หรือ very high
- จำนวนวันที่ลำตัวเป็น high
- จำนวนวันที่คอ/แขน/ข้อมือเป็น high
- จำนวนวันที่เกี่ยวข้องกับ ISO11228
- ค่า economic loss เฉลี่ยแบบ normalize
- จำนวนวันที่ทำ activity ซ้ำ
- slope ของคะแนนใน 7 วันล่าสุด

ดังนั้น Logistic Regression ตัวนี้ไม่ได้อ่านภาพโดยตรง และไม่ได้คำนวณ REBA/ISO posture score โดยตรง

## 4. สิ่งที่ปรับในรอบนี้

1. แยกชัดเจนว่า Logistic Regression ใช้เฉพาะ daily 7-transaction prediction
2. ถอด legacy `assets/ml/risk_alert_models.json` ออกจาก `pubspec.yaml` เพื่อไม่ package เข้าแอปเป็น posture model อีก
3. เพิ่ม metadata ใน `daily_injury_logistic_model.json`:
   - `modelType = binary_logistic_regression`
   - `predictionEquation`
   - `parameterEstimationRequired`
4. ปรับ code ให้มีฟังก์ชันทำนาย probability ตามสมการ logit/sigmoid โดยตรง
5. เพิ่ม unit test ที่คำนวณ expected probability จาก `intercept + sum(beta_i*x_i)` แล้วเทียบกับผลของ service

## 5. ข้อเท็จจริงเรื่อง coefficients

สมการ predict ถูกต้องตามทฤษฎีแล้ว แต่ coefficients ปัจจุบันยังเป็น template ไม่ใช่ research-trained coefficients เพราะ dataset ปัจจุบันยังไม่มี target label ประเภท:

```text
requires_medical_treatment_within_7_days
0 = ไม่มีการรักษา/ติดตามอาการใน window นั้น
1 = มีการรักษาหรือควรติดตามทางการแพทย์ใน window นั้น
```

หากทีมวิจัยส่ง label นี้มา ระบบจึงจะ train coefficients ได้ถูกต้องตาม maximum likelihood / binary cross-entropy ตามทฤษฎี

## 6. สถานะหลังตรวจ

| รายการ | สถานะ |
|---|---|
| Logistic prediction equation | ถูกต้อง |
| Sigmoid probability 0..1 | ถูกต้อง |
| Threshold classification | ถูกต้องตามค่าที่กำหนดใน asset |
| Coefficient interpretation เป็น log-odds | ถูกต้องตามแนวคิด |
| Coefficients fitted by MLE จาก research outcome labels | ยังไม่ครบ เพราะยังไม่มี label ผลการรักษารายวัน |
| Logistic ใช้กับ posture REBA/ISO | ไม่ใช้แล้ว |
| Logistic ใช้กับ daily 7 transaction | ใช้จริง |

## 7. ข้อมูลที่ต้องมีเพื่อ train ให้ถูกต้องสมบูรณ์

หนึ่งแถวของ training data ควรเป็น 1 farmer ต่อ 7 transaction window และมี:

- farmer id
- วันที่เริ่ม/สิ้นสุด window
- 12 feature ที่ระบบใช้
- target label `requires_medical_treatment_within_7_days`
- หลักฐานประกอบ เช่น อาการ, พบแพทย์, หยุดงาน, รักษา, notes จากเจ้าหน้าที่

เมื่อมีข้อมูลนี้แล้วให้ fit Logistic Regression ด้วย binary negative log-likelihood / maximum likelihood แล้ว export `intercept` และ `coefficients` กลับเข้า `assets/ml/daily_injury_logistic_model.json`

