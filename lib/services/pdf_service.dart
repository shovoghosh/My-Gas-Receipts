import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/receipt.dart';

class PdfService {
  static final _dateFormat = DateFormat('MM/dd/yyyy');

  static Future<void> exportReceipts(
    List<Receipt> receipts, {
    required String taxPeriodLabel,
  }) async {
    if (receipts.isEmpty) return;

    final pdf = pw.Document();

    final totalAmount = receipts
        .where((r) => r.amount != null)
        .fold<double>(0.0, (sum, r) => sum + (r.amount ?? 0));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Gasoline Receipt Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Tax Period: $taxPeriodLabel',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Total Receipts: ${receipts.length}'),
            pw.Text(
              'Total Expenses: \$${totalAmount.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Station', 'Amount'],
              data: receipts.map((r) => [
                _dateFormat.format(r.date),
                r.stationName ?? '-',
                r.amount != null
                    ? '\$${r.amount!.toStringAsFixed(2)}'
                    : '-'
              ]).toList(),
            ),
          ],
        ),
      ),
    );

    for (final receipt in receipts) {
      final file = File(receipt.imagePath);
      if (!await file.exists()) continue;

      final imageBytes = await file.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Receipt #${receipt.id}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Date: ${_dateFormat.format(receipt.date)}'),
              if (receipt.stationName != null)
                pw.Text('Station: ${receipt.stationName}'),
              if (receipt.amount != null)
                pw.Text('Amount: \$${receipt.amount!.toStringAsFixed(2)}'),
              if (receipt.notes != null && receipt.notes!.isNotEmpty)
                pw.Text('Notes: ${receipt.notes}'),
              pw.SizedBox(height: 12),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final outputDir = await getTemporaryDirectory();
    final fileName =
        'gas_receipts_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final outputFile = File('${outputDir.path}/$fileName');
    await outputFile.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(outputFile.path)],
      subject: 'Gas Receipts - $taxPeriodLabel',
      text: 'Attached is my gasoline receipt report for tax filing.',
    );
  }
}
