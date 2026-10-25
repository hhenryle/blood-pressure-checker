import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/reading.dart';
import '../state/app_state.dart';
import '../utils/stats.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  int _days = 7;

  static const _sysColor = Color(0xFFD64545);
  static const _diaColor = Color(0xFF3B82F6);
  static const _pulseColor = Color(0xFF2E9E5B);

  @override
  Widget build(BuildContext context) {
    final all = context.watch<AppState>().readings;
    final data = lastDays(all, _days).reversed.toList(); // oldest first
    final start = DateTime.now().subtract(Duration(days: _days - 1));
    final origin = DateTime(start.year, start.month, start.day);

    // x axis = fractional days since the start of the window.
    double x(Reading r) => r.measuredAt.difference(origin).inMinutes / 1440.0;
    List<FlSpot> spots(num Function(Reading) f) =>
        [for (final r in data) FlSpot(x(r), f(r).toDouble())];

    LineChartBarData line(List<FlSpot> s, Color c) => LineChartBarData(
          spots: s,
          color: c,
          barWidth: 2.5,
          isCurved: false,
          dotData: FlDotData(show: data.length <= 40),
        );

    final avg = averageOf(data);
    final am = averageOf(data.where((r) => r.measuredAt.hour < 12));
    final pm = averageOf(data.where((r) => r.measuredAt.hour >= 12));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 7, label: Text('7 days')),
            ButtonSegment(value: 30, label: Text('30 days')),
            ButtonSegment(value: 90, label: Text('90 days')),
          ],
          selected: {_days},
          onSelectionChanged: (s) => setState(() => _days = s.first),
        ),
        const SizedBox(height: 16),
        if (data.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No readings in this period.')),
          )
        else ...[
          SizedBox(
            height: 260,
            child: LineChart(LineChartData(
              minX: 0,
              maxX: _days.toDouble(),
              minY: 40,
              maxY: 200,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(horizontalLines: [
                // Normal-range guides: 120 systolic, 80 diastolic.
                HorizontalLine(y: 120, color: _sysColor.withValues(alpha: 0.4), dashArray: [6, 4]),
                HorizontalLine(y: 80, color: _diaColor.withValues(alpha: 0.4), dashArray: [6, 4]),
              ]),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 36, interval: 40)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: _days == 7 ? 1 : (_days == 30 ? 7 : 15),
                    getTitlesWidget: (v, _) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                          DateFormat('d/M').format(origin.add(Duration(days: v.round()))),
                          style: const TextStyle(fontSize: 10)),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                line(spots((r) => r.systolic), _sysColor),
                line(spots((r) => r.diastolic), _diaColor),
                line(spots((r) => r.pulse), _pulseColor),
              ],
            )),
          ),
          const SizedBox(height: 8),
          const Wrap(spacing: 16, children: [
            _Legend('Systolic', _sysColor),
            _Legend('Diastolic', _diaColor),
            _Legend('Pulse', _pulseColor),
          ]),
          const SizedBox(height: 24),
          _AvgCard('Average ($_days days)', avg),
          _AvgCard('Morning average (before 12:00)', am),
          _AvgCard('Evening average (12:00 onwards)', pm),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ]);
}

class _AvgCard extends StatelessWidget {
  final String title;
  final Averages? avg;
  const _AvgCard(this.title, this.avg);

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(title),
          subtitle: avg == null ? const Text('No data') : Text('${avg!.count} readings'),
          trailing: avg == null
              ? null
              : Text(
                  '${avg!.systolic.round()}/${avg!.diastolic.round()}  ·  ♥ ${avg!.pulse.round()}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
}
