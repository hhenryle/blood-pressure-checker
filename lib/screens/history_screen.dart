import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/reading.dart';
import '../state/app_state.dart';
import '../widgets/reading_tile.dart';
import 'add_reading_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.readings.isEmpty) {
      return const Center(child: Text('No readings yet.'));
    }

    // Readings are already sorted newest first; group by calendar day.
    final groups = <DateTime, List<Reading>>{};
    for (final r in state.readings) {
      final day = DateTime(r.measuredAt.year, r.measuredAt.month, r.measuredAt.day);
      groups.putIfAbsent(day, () => []).add(r);
    }
    final days = groups.keys.toList();

    return ListView.builder(
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(DateFormat('EEEE, d MMM yyyy').format(day),
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final r in groups[day]!)
              Dismissible(
                key: ValueKey(r.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async =>
                    await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete reading?'),
                        content: Text('${r.systolic}/${r.diastolic} will be removed.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete')),
                        ],
                      ),
                    ) ??
                    false,
                onDismissed: (_) => state.deleteReading(r.id!),
                child: ReadingTile(
                  r,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AddReadingScreen(existing: r))),
                ),
              ),
          ],
        );
      },
    );
  }
}
