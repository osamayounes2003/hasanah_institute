import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AdminExportService {
  const AdminExportService();

  List<int> exportStudentsExcel(List<Map<String, Object?>> rows) {
    final excel = Excel.createExcel();
    final sheet = excel['الطلاب'];
    sheet.appendRow([
      TextCellValue('الاسم'),
      TextCellValue('المعرّف'),
      TextCellValue('النقاط'),
    ]);
    for (final row in rows) {
      sheet.appendRow([
        TextCellValue('${row['name']}'),
        TextCellValue('${row['student_id'] ?? row['id'] ?? ''}'),
        IntCellValue((row['points'] as num?)?.toInt() ?? 0),
      ]);
    }
    return excel.encode() ?? <int>[];
  }

  Future<Uint8List> exportStatsPdf(List<Map<String, Object?>> rows) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Hasanah Stats Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            ...rows.map(
              (row) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  '${row['name']} - ${row['points']} points',
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }
}
