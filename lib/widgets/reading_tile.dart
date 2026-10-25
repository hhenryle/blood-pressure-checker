import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reading.dart';
import '../utils/bp_category.dart';

class CategoryBadge extends StatelessWidget {
  final BpCategory category;
  const CategoryBadge(this.category, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(category.label,
            style: TextStyle(
                color: category.color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

class ReadingTile extends StatelessWidget {
  final Reading reading;
  final VoidCallback? onTap;
  const ReadingTile(this.reading, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cat = BpCategory.classify(reading.systolic, reading.diastolic);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(backgroundColor: cat.color, radius: 6),
      title: Text('${reading.systolic}/${reading.diastolic} mmHg  ·  ${reading.pulse} bpm',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text([
        DateFormat('HH:mm').format(reading.measuredAt),
        if (reading.tags.isNotEmpty) reading.tags.join(', '),
        if (reading.note?.isNotEmpty ?? false) reading.note!,
      ].join('  ·  ')),
      trailing: CategoryBadge(cat),
    );
  }
}
