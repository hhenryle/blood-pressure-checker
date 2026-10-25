import 'package:flutter/material.dart';

enum BpCategory {
  normal('Normal', Color(0xFF2E9E5B)),
  elevated('Elevated', Color(0xFFC9A400)),
  stage1('Stage 1', Color(0xFFE67E22)),
  stage2('Stage 2', Color(0xFFD64545)),
  crisis('Crisis', Color(0xFF8E1B1B));

  final String label;
  final Color color;
  const BpCategory(this.label, this.color);

  /// AHA classification. The higher of the two values decides the category.
  static BpCategory classify(int systolic, int diastolic) {
    if (systolic > 180 || diastolic > 120) return BpCategory.crisis;
    if (systolic >= 140 || diastolic >= 90) return BpCategory.stage2;
    if (systolic >= 130 || diastolic >= 80) return BpCategory.stage1;
    if (systolic >= 120) return BpCategory.elevated;
    return BpCategory.normal;
  }
}
