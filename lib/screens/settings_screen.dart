import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/export_service.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _addReminder(BuildContext context, AppState state) async {
    if (state.reminders.length >= NotificationService.maxReminders) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You can set up to ${NotificationService.maxReminders} reminders.')));
      return;
    }
    final t = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 8, minute: 0));
    if (t == null) return;
    await state.setReminders([...state.reminders, ReminderTime(t.hour, t.minute)]);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final export = ExportService();

    return ListView(
      children: [
        const ListTile(
          title: Text('Daily reminders',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Skipped for the rest of today once you log a reading.'),
        ),
        for (final t in state.reminders)
          ListTile(
            leading: const Icon(Icons.alarm),
            title: Text(t.label),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => state.setReminders(
                  state.reminders.where((r) => r.encode() != t.encode()).toList()),
            ),
            onTap: () async {
              final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: t.hour, minute: t.minute));
              if (picked == null) return;
              await state.setReminders([
                ...state.reminders.where((r) => r.encode() != t.encode()),
                ReminderTime(picked.hour, picked.minute),
              ]);
            },
          ),
        ListTile(
          leading: const Icon(Icons.add_alarm),
          title: const Text('Add reminder'),
          onTap: () => _addReminder(context, state),
        ),
        const Divider(),
        const ListTile(
          title: Text('Export', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Share all readings with your doctor.'),
        ),
        ListTile(
          leading: const Icon(Icons.picture_as_pdf),
          title: const Text('Share PDF report'),
          enabled: state.readings.isNotEmpty,
          onTap: () => export.sharePdf(state.readings),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart),
          title: const Text('Share CSV'),
          enabled: state.readings.isNotEmpty,
          onTap: () => export.shareCsv(state.readings),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.lock_outline),
          title: Text('Your data stays on this phone'),
          subtitle: Text('No account, no cloud.'),
        ),
      ],
    );
  }
}
