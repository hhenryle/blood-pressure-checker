import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../utils/bp_category.dart';
import '../widgets/reading_tile.dart';
import 'add_reading_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final latest = state.latest;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddReadingScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add reading'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Today', style: Theme.of(context).textTheme.headlineSmall),
          Text(DateFormat('EEEE, d MMM').format(DateTime.now())),
          const SizedBox(height: 16),
          Card(
            color: state.loggedToday
                ? Colors.green.withValues(alpha: 0.12)
                : Colors.orange.withValues(alpha: 0.15),
            child: ListTile(
              leading: Icon(state.loggedToday ? Icons.check_circle : Icons.alarm,
                  color: state.loggedToday ? Colors.green : Colors.orange),
              title: Text(state.loggedToday
                  ? 'Done for today'
                  : 'No reading logged today yet'),
              subtitle: Text('Streak: ${state.streak} day${state.streak == 1 ? '' : 's'}'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Latest reading', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (latest == null)
            const Card(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Tap "Add reading" to log your first one.')),
            ))
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Text('${latest.systolic}/${latest.diastolic}',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Text('mmHg'),
                  const SizedBox(height: 8),
                  Text('♥ ${latest.pulse} bpm'),
                  const SizedBox(height: 8),
                  CategoryBadge(BpCategory.classify(latest.systolic, latest.diastolic)),
                  const SizedBox(height: 8),
                  Text(DateFormat('d MMM, HH:mm').format(latest.measuredAt),
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
