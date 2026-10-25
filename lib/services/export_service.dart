import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/reading.dart';
import '../utils/bp_category.dart';
import '../utils/stats.dart';

class ExportService {
  static final _fmt = DateFormat('yyyy-MM-dd HH:mm');

  static String _csvCell(String? v) {
    final s = v ?? '';
    return s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  static String buildCsv(List<Reading> readings) {
    final b = StringBuffer('date,systolic,diastolic,pulse,category,arm,position,tags,note\n');
    for (final r in readings) {
      b.writeln([
        _fmt.format(r.measuredAt),
        r.systolic,
        r.diastolic,
        r.pulse,
        BpCategory.classify(r.systolic, r.diastolic).label,
        r.arm,
        r.position,
        _csvCell(r.tags.join(';')),
        _csvCell(r.note),
      ].map((e) => e ?? '').join(','));
    }
    return b.toString();
  }

  Future<void> shareCsv(List<Reading> readings) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/blood_pressure.csv');
    await file.writeAsString(buildCsv(readings));
    await Share.shareXFiles([XFile(file.path)], subject: 'Blood pressure records');
  }

  Future<void> sharePdf(List<Reading> readings) async {
    final doc = pw.Document();
    final avg = averageOf(readings);
    final rows = readings
        .map((r) => [
              _fmt.format(r.measuredAt),
              '${r.systolic}/${r.diastolic}',
              '${r.pulse}',
              BpCategory.classify(r.systolic, r.diastolic).label,
              r.note ?? '',
            ])
        .toList();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (_) => [
        pw.Header(level: 0, child: pw.Text('Blood pressure report')),
        pw.Text('Generated ${_fmt.format(DateTime.now())}  -  ${readings.length} readings'),
        if (avg != null)
          pw.Text(
              'Average: ${avg.systolic.round()}/${avg.diastolic.round()} mmHg, pulse ${avg.pulse.round()} bpm'),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'BP (mmHg)', 'Pulse', 'Category', 'Note'],
          data: rows,
          cellStyle: const pw.TextStyle(fontSize: 9),
        ),
      ],
    ));

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/blood_pressure.pdf');
    await file.writeAsBytes(await doc.save());
    await Share.shareXFiles([XFile(file.path)], subject: 'Blood pressure report');
  }
}
