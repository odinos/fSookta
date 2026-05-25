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
    'act_iso_keep_load_close':
        'Keep the load close to the body before lifting or carrying',
    'act_iso_lift_height':
        'Place the load around knuckle-to-elbow height before lifting',
    'act_iso_reduce_frequency':
        'Reduce lifting frequency or split the task into shorter rounds',
    'act_iso_improve_grip':
        'Use containers or handles that are easy to grip securely',
    'act_iso_plan_recovery':
        'Plan short recovery breaks or rotate tasks during repeated work',
    'act_use_cart_distance':
        'Use a cart or handling aid for long distance transport',
    'act_check_wheels': 'Check cart wheels for friction',
    'act_use_legs': 'Use leg muscles, not back',
    'act_iso_push_smooth':
        'Push or pull smoothly and avoid sudden jerking force',
    'act_iso_push_handle_height':
        'Adjust handles near elbow height so the body can push steadily',
    'act_iso_reduce_push_distance':
        'Shorten push/pull distance or divide the route into shorter sections',
    'act_iso_floor_level':
        'Keep floors firm, level, dry, and clear of obstacles',
    'act_iso_push_not_pull':
        'Push with body weight when possible instead of pulling with the arms',
    'act_reduce_load_tool': 'Reduce load or use assist tools',
    'act_avoid_bend': 'Avoid deep bending or use back support',
    'act_avoid_twist': 'Avoid twisting or side bending while working',
    'act_adj_eye_level': 'Adjust work to eye level',
    'act_reduce_arm_raise': 'Reduce prolonged arm raising',
    'act_adj_wrist': 'Keep wrist in neutral position',
    'act_rest_stretch': 'Take breaks to stretch muscles',
    'act_iso_job_rotation':
        'Rotate tasks so the same muscles are not used continuously',
    'act_iso_neutral_reach':
        'Keep hands near the body and avoid extreme reach or joint positions',
    'act_iso_tool_handle_fit':
        'Use padded, non-slip tool handles sized for a secure grip',
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
    'act_ref_weight_low':
        'Check lifting weight: men 20-45 years up to 25 kg; men under 20 or over 45 up to 20 kg; women 20-45 up to 20 kg; women under 20 or over 45 up to 15 kg.',
    'act_ref_weight_medium':
        'Reduce lifting weight: men 20-45 years up to 18 kg; men under 20 or over 45 up to 15 kg; women 20-45 up to 15 kg; women under 20 or over 45 up to 11 kg.',
    'act_ref_weight_high':
        'Reduce lifting weight immediately: men 20-45 years up to 13 kg; men under 20 or over 45 up to 10 kg; women 20-45 up to 10 kg; women under 20 or over 45 up to 8 kg. Use handling aids if heavier.',
    'act_transplant_ref_low':
        'Posture is acceptable. Alternate standing and squatting every 20 minutes and check seedling-bed height near waist level.',
    'act_transplant_ref_medium':
        'Raise the seedling bed to reduce bending, use a squat cushion or low stool, change posture every 15 minutes, and lift seedlings with the legs.',
    'act_transplant_ref_high':
        'Improve immediately: raise the seedling bed to waist level, use a low stool or squatting support, and rest every 15-20 minutes.',
    'act_fert_ref_low':
        'Use a cart when fertilizer must be moved far, and change posture every 30 minutes.',
    'act_fert_ref_medium':
        'Split fertilizer into smaller containers, use a cart, avoid twisting while lifting, and wear non-slip footwear.',
    'act_fert_ref_high':
        'Reduce fertilizer weight per trip, use a conveyor or cart, rest 10 minutes every hour, and avoid continuous work on slopes.',
    'act_pesticide_ref_low':
        'Fit sprayer straps properly, use a lightweight nozzle, and rest 5 minutes every hour.',
    'act_pesticide_ref_medium':
        'Limit continuous spraying to 1 hour, rest 15 minutes, switch the hand/side holding the wand, and wear non-slip footwear.',
    'act_pesticide_ref_high':
        'If the sprayer tank exceeds the recommended weight, use a wheeled aid or long-hose nozzle and rotate with a coworker every 30 minutes.',
    'act_pruning_ref_low':
        'Use sharp lightweight shears, switch arms every 10-15 minutes, and avoid keeping arms above the head for long periods.',
    'act_pruning_ref_medium':
        'Use long-handled shears to reduce reaching, use a ladder for high branches, switch arms, and rest 5 minutes every 30 minutes.',
    'act_pruning_ref_high':
        'Use mechanical pruning tools when possible. If shears are used, rest 10 minutes every 20 minutes, rotate as a team, and avoid twisting while cutting.',
    'act_harvest_ref_low':
        'Change posture between standing and squatting every 20 minutes, use soft gloves, and place baskets on a raised stand.',
    'act_harvest_ref_medium':
        'Use padded gloves, reduce bending by raising the basket, rest 5 minutes every 30 minutes, and watch for hand numbness.',
    'act_harvest_ref_high':
        'Use a ladder for high branches, avoid climbing, rest 10 minutes every 20 minutes, and stop immediately if hand or back pain occurs.',
    'act_transport_ref_low':
        'Use a cart every time, lift by bending the knees with a straight back, avoid twisting, and wear non-slip footwear.',
    'act_transport_ref_medium':
        'Reduce sack weight, use a cart, improve the path, and turn with the feet instead of twisting the waist.',
    'act_transport_ref_high':
        'Reduce sack weight, use a wagon or large-wheel cart, add non-slip flooring, rest 10-15 minutes every 30 minutes, and practice team lifting technique.',
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
    'act_iso_keep_load_close': 'วางของให้ชิดลำตัวก่อนยกหรือขนย้าย',
    'act_iso_lift_height': 'จัดของให้อยู่ระดับประมาณข้อนิ้วถึงข้อศอกก่อนยก',
    'act_iso_reduce_frequency': 'ลดความถี่ในการยก หรือแบ่งงานเป็นรอบสั้นลง',
    'act_iso_improve_grip': 'ใช้ภาชนะหรือด้ามจับที่จับได้ถนัดและมั่นคง',
    'act_iso_plan_recovery': 'วางแผนพักสั้น ๆ หรือสลับงานเมื่อต้องทำซ้ำหลายรอบ',
    'act_use_cart_distance': 'ใช้รถเข็นหรืออุปกรณ์ช่วยขนย้ายเมื่อต้องขนไกล',
    'act_check_wheels': 'ตรวจสอบล้อรถเข็นว่าฝืดหรือไม่',
    'act_use_legs': 'ใช้แรงจากขาในการออกแรง ไม่ใช่หลัง',
    'act_iso_push_smooth': 'ออกแรงดันหรือลากอย่างต่อเนื่อง ไม่กระชาก',
    'act_iso_push_handle_height':
        'ปรับด้ามจับให้อยู่ใกล้ระดับข้อศอก เพื่อใช้แรงได้มั่นคง',
    'act_iso_reduce_push_distance':
        'ลดระยะทางดัน/ลาก หรือแบ่งเส้นทางเป็นช่วงสั้นลง',
    'act_iso_floor_level':
        'จัดพื้นทางเดินให้เรียบ แห้ง ไม่ลื่น และไม่มีสิ่งกีดขวาง',
    'act_iso_push_not_pull':
        'ถ้าทำได้ให้ดันโดยใช้น้ำหนักตัว แทนการลากด้วยแรงแขน',
    'act_reduce_load_tool': 'ลดน้ำหนักสิ่งของ หรือใช้เครื่องทุ่นแรง',
    'act_avoid_bend': 'หลีกเลี่ยงการก้มหลังมาก หรือใช้เข็มขัดพยุงหลัง',
    'act_avoid_twist': 'หลีกเลี่ยงการบิดลำตัวหรือเอียงตัวขณะทำงาน',
    'act_adj_eye_level': 'ปรับงานให้อยู่ระดับสายตา ลดการก้มคอ',
    'act_reduce_arm_raise': 'ลดการยกแขนสูงเหนือไหล่เป็นเวลานาน',
    'act_adj_wrist': 'ปรับด้ามจับเครื่องมือให้ข้อมืออยู่ในแนวตรง',
    'act_rest_stretch': 'ควรพักเบรกเพื่อยืดเหยียดกล้ามเนื้อ',
    'act_iso_job_rotation':
        'สลับงานเพื่อลดการใช้กล้ามเนื้อกลุ่มเดิมต่อเนื่องนานเกินไป',
    'act_iso_neutral_reach':
        'ทำงานใกล้ลำตัว ลดการเอื้อมไกลหรือขยับข้อไปสุดช่วง',
    'act_iso_tool_handle_fit':
        'ใช้ด้ามจับที่ไม่ลื่น มีขนาดพอดีมือ และลดแรงบีบจับ',
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
    'act_ref_weight_low':
        'ตรวจสอบน้ำหนักที่ยก: ชาย 20-45 ปี ไม่เกิน 25 กก.; ชายอายุต่ำกว่า 20 หรือมากกว่า 45 ปี ไม่เกิน 20 กก.; หญิง 20-45 ปี ไม่เกิน 20 กก.; หญิงอายุต่ำกว่า 20 หรือมากกว่า 45 ปี ไม่เกิน 15 กก.',
    'act_ref_weight_medium':
        'ปรับน้ำหนักที่ยก: ชาย 20-45 ปี ไม่เกิน 18 กก.; ชายอายุต่ำกว่า 20 หรือมากกว่า 45 ปี ไม่เกิน 15 กก.; หญิง 20-45 ปี ไม่เกิน 15 กก.; หญิงอายุต่ำกว่า 20 หรือมากกว่า 45 ปี ไม่เกิน 11 กก.',
    'act_ref_weight_high':
        'ลดน้ำหนักที่ยกทันที: ชาย 20-45 ปี ไม่เกิน 13 กก.; ชายอายุต่ำกว่า 20 หรือมากกว่า 45 ปี ไม่เกิน 10 กก.; หญิง 20-45 ปี ไม่เกิน 10 กก.; หญิงอายุต่ำกว่า 20 หรือมากกว่า 45 ปี ไม่เกิน 8 กก. ถ้าเกินนี้ให้ใช้อุปกรณ์ช่วย',
    'act_transplant_ref_low':
        'ท่าทางดีอยู่แล้ว ควรสลับยืนกับนั่งยองทุก 20 นาที และตรวจสอบความสูงของแปลงเพาะชำให้พอดีกับเอว',
    'act_transplant_ref_medium':
        'ลดการก้มโดยยกแปลงเพาะชำให้สูงขึ้น ใช้เบาะรองนั่งยองหรือเก้าอี้เตี้ย สลับท่าทุก 15 นาที และฝึกยกต้นกล้าโดยใช้ขา',
    'act_transplant_ref_high':
        'ปรับปรุงทันที: ยกแปลงเพาะชำให้สูงระดับเอว ใช้อุปกรณ์นั่งยองหรือเก้าอี้เตี้ย และพักทุก 15-20 นาที',
    'act_fert_ref_low':
        'ใช้รถเข็นถ้าต้องเคลื่อนย้ายปุ๋ยไกล และหมั่นเปลี่ยนท่าทางทุก 30 นาที',
    'act_fert_ref_medium':
        'แบ่งปุ๋ยใส่ภาชนะเล็ก ใช้รถเข็น หลีกเลี่ยงการบิดตัวขณะยก และใส่รองเท้ากันลื่น',
    'act_fert_ref_high':
        'ลดน้ำหนักปุ๋ยต่อครั้ง ใช้สายพานหรือรถเข็น จัดพัก 10 นาทีทุกชั่วโมง และหลีกเลี่ยงการทำงานบนพื้นที่ลาดชันต่อเนื่อง',
    'act_pesticide_ref_low':
        'ปรับสายสะพายเครื่องพ่นให้พอดี ใช้หัวฉีดน้ำหนักเบา และพัก 5 นาทีทุกชั่วโมง',
    'act_pesticide_ref_medium':
        'ลดระยะเวลาพ่นต่อเนื่องไม่เกิน 1 ชั่วโมง แล้วพัก 15 นาที สลับข้างที่ถือท่อพ่น และใส่รองเท้ากันลื่น',
    'act_pesticide_ref_high':
        'ถ้าถังพ่นหนักเกินน้ำหนักที่แนะนำ ให้ใช้อุปกรณ์ล้อเข็นหรือหัวฉีดแบบต่อท่อยาว และหมุนเวียนงานกับเพื่อนทุก 30 นาที',
    'act_pruning_ref_low':
        'ใช้กรรไกรคมและน้ำหนักเบา สลับแขนทุก 10-15 นาที และอย่ายกแขนเหนือศีรษะนาน',
    'act_pruning_ref_medium':
        'ใช้กรรไกรแบบก้านยาวเพื่อลดการเอื้อม ใช้บันไดสำหรับกิ่งสูง สลับแขน และพัก 5 นาทีทุก 30 นาที',
    'act_pruning_ref_high':
        'เปลี่ยนมาใช้เครื่องตัดกิ่งแบบกลไกช่วย ถ้าใช้กรรไกรต้องพัก 10 นาทีทุก 20 นาที ทำงานเป็นทีมเพื่อหมุนเวียน และหลีกเลี่ยงการตัดในท่าบิดตัว',
    'act_harvest_ref_low':
        'เปลี่ยนท่า ยืน-นั่งยอง ทุก 20 นาที ใช้ถุงมือนุ่ม และตั้งตะกร้าบนแท่นสูง',
    'act_harvest_ref_medium':
        'ใช้ถุงมือลดแรงกด ลดการก้มโดยปรับความสูงตะกร้า พัก 5 นาทีทุก 30 นาที และสังเกตอาการชาที่มือ',
    'act_harvest_ref_high':
        'ถ้าเก็บผลจากกิ่งสูงต้องใช้บันได หลีกเลี่ยงการปีน หยุดพัก 10 นาทีทุก 20 นาที และถ้ามีอาการปวดมือหรือหลังให้หยุดงานทันที',
    'act_transport_ref_low':
        'ใช้รถเข็นทุกครั้ง ยกของโดยงอเข่า หลังตรง ไม่บิดตัว และสวมรองเท้ากันลื่น',
    'act_transport_ref_medium':
        'ลดน้ำหนักกระสอบ ใช้รถเข็น ปรับปรุงทางเดิน และเปลี่ยนทิศทางโดยหมุนเท้าแทนการบิดเอว',
    'act_transport_ref_high':
        'ลดน้ำหนักกระสอบ ใช้เกวียนหรือรถเข็นล้อใหญ่ ปูพื้นกันลื่น จัดพัก 10-15 นาทีทุก 30 นาที และฝึกเทคนิคการยกที่ถูกต้องร่วมกับเพื่อน',
  };
}
