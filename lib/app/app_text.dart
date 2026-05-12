import 'app_state.dart';

class AppText {
  const AppText(this.language);

  final AppLanguage language;

  bool get isThai => language == AppLanguage.th;

  String get appName => isThai ? 'สุขท่า' : 'Sookta';
  String get welcomeTo => isThai ? 'ยินดีต้อนรับสู่' : 'Welcome to';
  String get selectLanguage =>
      isThai ? 'กรุณาเลือกภาษาเพื่อเริ่มต้นใช้งาน' : 'Please select language to start';
  String get thai => isThai ? 'ภาษาไทย' : 'Thai';
  String get english => isThai ? 'ภาษาอังกฤษ' : 'English';
  String get next => isThai ? 'ถัดไป' : 'Next';
  String get save => isThai ? 'บันทึกข้อมูล' : 'Save Data';
  String get addProfile => isThai ? 'เพิ่มข้อมูลของคุณ' : 'Add Your Profile';
  String get editProfile => isThai ? 'แก้ไขข้อมูลของคุณ' : 'Edit Your Profile';
  String get fullName => isThai ? 'ชื่อ-นามสกุล' : 'Full Name';
  String get age => isThai ? 'อายุ (ปี)' : 'Age (Years)';
  String get gender => isThai ? 'เพศ' : 'Gender';
  String get male => isThai ? 'ชาย' : 'Male';
  String get female => isThai ? 'หญิง' : 'Female';
  String get weight => isThai ? 'น้ำหนัก (กก.)' : 'Weight (kg)';
  String get height => isThai ? 'ส่วนสูง (ซม.)' : 'Height (cm)';
  String get income => isThai ? 'รายได้เฉลี่ยต่อปี (บาท)' : 'Annual Income (THB)';
  String get incomeNote =>
      isThai ? '* ใช้สำหรับการประเมินความสูญเสียทางเศรษฐกิจ' : '* Used for economic loss estimation';
  String get avatarTitle => isThai ? 'เลือกรูปโปรไฟล์' : 'Select Profile Picture';
  String get avatarSubtitle =>
      isThai ? 'เลือกรูปแทนตัว หรือถ่ายภาพของคุณ' : 'Choose an avatar or take a photo';
  String get avatarHint => isThai ? 'เลือกจากรายการด้านล่าง' : 'Select from the list below';
  String get confirmAvatar => isThai ? 'ยืนยันรูปโปรไฟล์' : 'Confirm Profile Picture';
  String get takePhoto => isThai ? 'ถ่ายภาพ' : 'Take Photo';
  String get gallery => isThai ? 'อัลบั้ม' : 'Gallery';
  String get home => isThai ? 'หน้าแรก' : 'Home';
  String get history => isThai ? 'ผลตรวจ' : 'History';
  String get profile => isThai ? 'ข้อมูลส่วนตัว' : 'Profile';
  String get hello => isThai ? 'สวัสดี,' : 'Hello,';
  String get guest => isThai ? 'ผู้ใช้งาน' : 'Guest';
  String get startEvaluation => isThai ? 'เริ่มทำแบบประเมิน' : 'Start Evaluation';
  String get riskAssessment => isThai ? 'ประเมินความเสี่ยง' : 'Risk Assessment';
  String get noHistory => isThai ? 'ยังไม่มีประวัติการประเมิน' : 'No assessment history yet';
  String get annualIncome => isThai ? 'รายได้เฉลี่ย/ปี' : 'Annual Income';
  String get baht => isThai ? 'บาท' : 'THB';
}
