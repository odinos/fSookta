import 'dart:math';

import 'app_state.dart';

class ResearchProfileDefaults {
  const ResearchProfileDefaults._();

  static final Random _random = Random.secure();

  static String participantCode() {
    final value = _random.nextInt(900000) + 100000;
    return 'FSK-$value';
  }

  static String roleFarmer(AppLanguage language) {
    return language == AppLanguage.th ? 'ชาวสวน' : 'Farmer';
  }

  static String roleStaff(AppLanguage language) {
    return language == AppLanguage.th ? 'เจ้าหน้าที่' : 'Research staff';
  }

  static String normalizedRole(String value, AppLanguage language) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('เจ้า') ||
        normalized.contains('staff') ||
        normalized.contains('research') ||
        normalized.contains('officer')) {
      return roleStaff(language);
    }
    return roleFarmer(language);
  }
}
