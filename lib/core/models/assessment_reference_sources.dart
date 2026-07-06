class AssessmentReferenceSources {
  const AssessmentReferenceSources._();

  static const exportSchemaVersion = 'sookta-export-references-v1';

  static const scopeNoteTh =
      'ผลประเมินนี้ใช้เพื่อสื่อสารความเสี่ยงทางการยศาสตร์ การเรียนรู้ และการติดตามงานวิจัย ไม่ใช่การวินิจฉัยโรคหรือใบรับรองทางการแพทย์';
  static const scopeNoteEn =
      'This assessment supports ergonomic risk communication, learning, and research follow-up; it is not medical diagnosis or medical certification.';

  static const calculationStandardNoteTh =
      'การคำนวณอ้างอิง REBA สำหรับท่าทางร่างกาย และใช้ ISO 11228 ร่วมกับงานยก/ขนย้ายหรือดัน/ลากตามลักษณะงานจริง';
  static const calculationStandardNoteEn =
      'The calculation references REBA for body posture and uses ISO 11228 for lifting/carrying or pushing/pulling tasks when applicable.';

  static const references = [
    'Hignett, S., & McAtamney, L. (2000). Rapid Entire Body Assessment (REBA). Applied Ergonomics, 31(2), 201-205.',
    'ErgoPlus. REBA: A Step-by-Step Guide - Rapid Entire Body Assessment. https://ergo-plus.com/wp-content/uploads/REBA-A-Step-by-Step-Guide.pdf',
    'ISO 11228-1:2021 - Ergonomics - Manual handling - Part 1: Lifting, holding and carrying.',
    'ISO 11228-2:2007 - Ergonomics - Manual handling - Part 2: Pushing and pulling.',
    'ISO 11228-3:2007 - Ergonomics - Manual handling - Part 3: Handling of low loads at high frequency.',
    'International Labour Organization. (2014). Ergonomic Checkpoints in Agriculture (2nd ed.). ILO.',
    'Zadry, H.R., Kamil, M., & Saputra, N. (2025). Design and evaluation of a novel user-centred cassava extractor.',
  ];

  static String joinedReferences() => references.join(' | ');

  static List<List<Object?>> csvRows({required bool thai}) {
    return [
      [],
      [
        thai
            ? 'แหล่งอ้างอิงที่ใช้ในการประเมิน'
            : 'Assessment reference sources',
      ],
      [thai ? 'รายการ' : 'Reference', thai ? 'รายละเอียด' : 'Detail'],
      for (var index = 0; index < references.length; index += 1)
        [index + 1, references[index]],
      [
        thai ? 'ขอบเขตการใช้งาน' : 'Scope note',
        thai ? scopeNoteTh : scopeNoteEn,
      ],
      [
        thai ? 'มาตรฐานการคำนวณ' : 'Calculation standard note',
        thai ? calculationStandardNoteTh : calculationStandardNoteEn,
      ],
      ['Export schema version', exportSchemaVersion],
    ];
  }
}
