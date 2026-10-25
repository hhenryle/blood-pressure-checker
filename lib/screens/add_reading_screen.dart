import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/reading.dart';
import '../state/app_state.dart';
import '../utils/bp_category.dart';

class AddReadingScreen extends StatefulWidget {
  final Reading? existing;
  const AddReadingScreen({super.key, this.existing});

  @override
  State<AddReadingScreen> createState() => _AddReadingScreenState();
}

class _AddReadingScreenState extends State<AddReadingScreen> {
  static const _allTags = ['After exercise', 'After medication', 'Stressed', 'After meal', 'Tired'];

  final _form = GlobalKey<FormState>();
  late final TextEditingController _sys;
  late final TextEditingController _dia;
  late final TextEditingController _pulse;
  late final TextEditingController _note;
  late DateTime _when;
  String? _arm;
  String? _position;
  late Set<String> _tags;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _sys = TextEditingController(text: r?.systolic.toString() ?? '');
    _dia = TextEditingController(text: r?.diastolic.toString() ?? '');
    _pulse = TextEditingController(text: r?.pulse.toString() ?? '');
    _note = TextEditingController(text: r?.note ?? '');
    _when = r?.measuredAt ?? DateTime.now();
    _arm = r?.arm;
    _position = r?.position;
    _tags = {...?r?.tags};
  }

  late ScaffoldMessengerState _messenger;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    // The messenger outlives this screen; clear our snackbar so it does not cover Home's button.
    final messenger = _messenger;
    WidgetsBinding.instance.addPostFrameCallback((_) => messenger.hideCurrentSnackBar());
    _sys.dispose();
    _dia.dispose();
    _pulse.dispose();
    _note.dispose();
    super.dispose();
  }

  String? _range(String? v, int min, int max) {
    final n = int.tryParse(v ?? '');
    if (n == null) return 'Required';
    if (n < min || n > max) return '$min–$max';
    return null;
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_when));
    if (time == null) return;
    setState(() => _when =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final sys = int.parse(_sys.text);
    final dia = int.parse(_dia.text);
    if (sys <= dia) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Systolic must be higher than diastolic.')));
      return;
    }
    final state = context.read<AppState>();
    final nav = Navigator.of(context);
    final reading = Reading(
      id: widget.existing?.id,
      systolic: sys,
      diastolic: dia,
      pulse: int.parse(_pulse.text),
      measuredAt: _when,
      arm: _arm,
      position: _position,
      tags: _tags.toList(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    if (widget.existing == null) {
      await state.addReading(reading);
    } else {
      await state.updateReading(reading);
    }
    if (!mounted) return;
    if (BpCategory.classify(sys, dia) == BpCategory.crisis) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.warning_amber, color: Colors.red, size: 36),
          title: const Text('Very high reading'),
          content: const Text(
              'This reading is in the hypertensive crisis range. Rest for a few minutes and measure again. '
              'If it stays this high, or you have chest pain, shortness of breath, or a severe headache, seek medical help immediately.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('OK'))
          ],
        ),
      );
    }
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    Widget numberField(TextEditingController c, String label, int min, int max) =>
        Expanded(
          child: TextFormField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
            decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
            validator: (v) => _range(v, min, max),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add reading' : 'Edit reading'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              numberField(_sys, 'Systolic', 50, 300),
              const SizedBox(width: 12),
              numberField(_dia, 'Diastolic', 30, 200),
              const SizedBox(width: 12),
              numberField(_pulse, 'Pulse', 30, 250),
            ]),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(DateFormat('EEE d MMM yyyy, HH:mm').format(_when)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _pickDateTime,
            ),
            const Divider(),
            Text('Arm', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              emptySelectionAllowed: true,
              segments: const [
                ButtonSegment(value: 'left', label: Text('Left')),
                ButtonSegment(value: 'right', label: Text('Right')),
              ],
              selected: {if (_arm != null) _arm!},
              onSelectionChanged: (s) => setState(() => _arm = s.isEmpty ? null : s.first),
            ),
            const SizedBox(height: 16),
            Text('Position', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              emptySelectionAllowed: true,
              segments: const [
                ButtonSegment(value: 'sitting', label: Text('Sitting')),
                ButtonSegment(value: 'standing', label: Text('Standing')),
                ButtonSegment(value: 'lying', label: Text('Lying')),
              ],
              selected: {if (_position != null) _position!},
              onSelectionChanged: (s) =>
                  setState(() => _position = s.isEmpty ? null : s.first),
            ),
            const SizedBox(height: 16),
            Text('Tags', style: Theme.of(context).textTheme.labelLarge),
            Wrap(
              spacing: 8,
              children: [
                for (final t in _allTags)
                  FilterChip(
                    label: Text(t),
                    selected: _tags.contains(t),
                    onSelected: (on) =>
                        setState(() => on ? _tags.add(t) : _tags.remove(t)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Note (optional)', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }
}
