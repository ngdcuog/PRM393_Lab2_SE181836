import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/dashboard_data.dart';

class PdfExportService {
  final _storage = FirebaseStorage.instance;

  Future<String> exportDashboardAsPdf(DashboardData data) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Research Report: ${data.topic}',
                    style: const pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Dashboard Statistics', style: const pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Bullet(text: 'Total Publications: ${data.totalPublications}'),
                pw.Bullet(text: 'Average Citations: ${data.avgCitations.toStringAsFixed(2)}'),
                pw.Bullet(text: 'Top Author: ${data.topAuthor}'),
                pw.Bullet(text: 'Top Journal: ${data.topJournal}'),
                pw.Bullet(text: 'Most Active Year: ${data.mostActiveYear}'),
              ],
            );
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'reports/report_$timestamp.pdf';
      
      // 1. Chia sẻ PDF cho người dùng lưu (Tính năng thêm)
      await Printing.sharePdf(bytes: pdfBytes, filename: 'report_$timestamp.pdf');

      // 2. Upload thật lên Firebase Storage
      final ref = _storage.ref().child(fileName);
      await ref.putData(pdfBytes, SettableMetadata(contentType: 'application/pdf'));

      // 3. Lấy URL thật từ Firebase
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload PDF to Firebase Storage: $e');
    }
  }
}
