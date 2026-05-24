enum SooktaLocale {
  th,
  en,
}

class SooktaStrings {
  const SooktaStrings(this.locale);

  final SooktaLocale locale;

  String get(String key) {
    final table = locale == SooktaLocale.th ? _th : _en;
    return table[key] ?? _en[key] ?? key;
  }

  static const _en = <String, String>{
    'app_name': 'Sookta',
    'job_transplanting': 'Transplanting',
    'job_fertilizing': 'Fertilizing',
    'job_pesticide': 'Pesticide Spraying',
    'job_pruning': 'Pruning',
    'job_harvesting': 'Harvesting',
    'job_transport': 'On-farm Transport',
    'sugg_safe': 'Safe / Appropriate',
    'sugg_improve': 'Needs Improvement',
    'sugg_force_ok': 'Force is appropriate',
    'sugg_force_warn': 'Force near limit, be careful',
    'sugg_force_danger': 'Force exceeds limit, high risk',
    'sugg_reba_low': 'Low Risk: Action not necessary',
    'sugg_reba_med': 'Medium Risk: Check and change soon',
    'sugg_reba_high': 'High Risk: Change soon',
    'sugg_reba_vhigh': 'Very High Risk: Change immediately!',
    'act_reduce_weight': 'Reduce load weight',
    'act_use_cart_distance':
        'Use a cart or handling aid for long distance transport',
    'act_check_wheels': 'Check cart wheels for friction',
    'act_use_legs': 'Use leg muscles, not back',
    'act_reduce_load_tool': 'Reduce load or use assist tools',
    'act_avoid_bend': 'Avoid deep bending or use back support',
    'act_avoid_twist': 'Avoid twisting or side bending while working',
    'act_adj_eye_level': 'Adjust work to eye level',
    'act_reduce_arm_raise': 'Reduce prolonged arm raising',
    'act_adj_wrist': 'Keep wrist in neutral position',
    'act_rest_stretch': 'Take breaks to stretch muscles',
    'act_transplant_raise_bed':
        'Raise seedling trays or work height to reduce deep bending',
    'act_transplant_low_stool':
        'Use a low stool or knee pad instead of squatting for long periods',
    'act_extra_spray_strap': 'Adjust sprayer straps tightly',
    'act_extra_spray_switch': 'Switch shoulders to balance load',
    'act_spray_extension':
        'Use an extension wand so the arm does not stay raised or overreached',
    'act_extra_prune_ladder': 'Use stable ladder instead of reaching',
    'act_extra_prune_tool': 'Use long-handled pruning shears',
    'act_harvest_empty_often':
        'Empty the basket more often to reduce accumulated carrying load',
    'act_harvest_move_closer':
        'Move closer to the plant before picking instead of overreaching',
    'act_extra_fert_cart': 'Use cart instead of carrying sacks',
    'act_fert_split_load': 'Split fertilizer into smaller loads per round',
    'act_transport_two_person':
        'Ask another person to help lift heavy produce when needed',
    'act_transport_clear_path':
        'Clear the path and keep the walking surface even before transport',
  };

  static const _th = <String, String>{
    'app_name': 'สุขท่า',
    'job_transplanting': 'การปลูกกล้า',
    'job_fertilizing': 'การใส่ปุ๋ย',
    'job_pesticide': 'การฉีดพ่นสารกำจัดศัตรูพืช',
    'job_pruning': 'การตัดแต่งกิ่ง',
    'job_harvesting': 'การเก็บเกี่ยว',
    'job_transport': 'การขนย้ายผลผลิต',
    'sugg_safe': 'เหมาะสม',
    'sugg_improve': 'ควรปรับปรุง',
    'sugg_force_ok': 'แรงที่ใช้เหมาะสม',
    'sugg_force_warn': 'แรงใกล้ขีดจำกัด ควรระมัดระวัง',
    'sugg_force_danger': 'ใช้แรงเกินมาตรฐาน เสี่ยงบาดเจ็บ',
    'sugg_reba_low': 'ความเสี่ยงต่ำ: ไม่จำเป็นต้องแก้ไข',
    'sugg_reba_med': 'ความเสี่ยงปานกลาง: ควรตรวจสอบและแก้ไขเร็วๆ นี้',
    'sugg_reba_high': 'ความเสี่ยงสูง: จำเป็นต้องแก้ไขโดยเร็ว',
    'sugg_reba_vhigh': 'ความเสี่ยงสูงมาก: ต้องแก้ไขทันที!',
    'act_reduce_weight': 'ลดน้ำหนักที่ยก',
    'act_use_cart_distance': 'ใช้รถเข็นหรืออุปกรณ์ช่วยขนย้ายเมื่อต้องขนไกล',
    'act_check_wheels': 'ตรวจสอบล้อรถเข็นว่าฝืดหรือไม่',
    'act_use_legs': 'ใช้แรงจากขาในการออกแรง ไม่ใช่หลัง',
    'act_reduce_load_tool': 'ลดน้ำหนักสิ่งของ หรือใช้เครื่องทุ่นแรง',
    'act_avoid_bend': 'หลีกเลี่ยงการก้มหลังมาก หรือใช้เข็มขัดพยุงหลัง',
    'act_avoid_twist': 'หลีกเลี่ยงการบิดลำตัวหรือเอียงตัวขณะทำงาน',
    'act_adj_eye_level': 'ปรับงานให้อยู่ระดับสายตา ลดการก้มคอ',
    'act_reduce_arm_raise': 'ลดการยกแขนสูงเหนือไหล่เป็นเวลานาน',
    'act_adj_wrist': 'ปรับด้ามจับเครื่องมือให้ข้อมืออยู่ในแนวตรง',
    'act_rest_stretch': 'ควรพักเบรกเพื่อยืดเหยียดกล้ามเนื้อ',
    'act_transplant_raise_bed':
        'ยกถาดกล้าหรือพื้นที่ทำงานให้สูงขึ้น เพื่อลดการก้มหลังลึก',
    'act_transplant_low_stool':
        'ใช้เก้าอี้เตี้ยหรือเบาะรองเข่า แทนการนั่งยองนาน ๆ',
    'act_extra_spray_strap': 'ปรับสายสะพายเครื่องพ่นยาให้กระชับ',
    'act_extra_spray_switch': 'สลับข้างสะพายถังเพื่อลดการกดทับไหล่เดียว',
    'act_spray_extension': 'ใช้ด้ามต่อหัวพ่น เพื่อลดการยกแขนสูงหรือเอื้อมไกล',
    'act_extra_prune_ladder': 'ใช้บันไดที่มั่นคงแทนการเอื้อมสุดแขน',
    'act_extra_prune_tool': 'ใช้กรรไกรตัดกิ่งด้ามยาว',
    'act_harvest_empty_often':
        'เทผลผลิตออกจากตะกร้าให้บ่อยขึ้น เพื่อลดน้ำหนักสะสม',
    'act_harvest_move_closer': 'ขยับเข้าใกล้ต้นก่อนเก็บ เพื่อลดการเอื้อมไกล',
    'act_extra_fert_cart': 'ใช้รถเข็นบรรทุกกระสอบปุ๋ยแทนการแบก',
    'act_fert_split_load': 'แบ่งปุ๋ยเป็นน้ำหนักน้อยลงในแต่ละรอบ',
    'act_transport_two_person': 'ให้คนช่วยยกเมื่อผลผลิตหนักเกินไป',
    'act_transport_clear_path':
        'จัดทางเดินให้เรียบและไม่มีสิ่งกีดขวางก่อนขนย้าย',
  };
}
