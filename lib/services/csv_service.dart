import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/receipt.dart';
import '../models/vehicle.dart';

class CsvService {
  static final _dateFormat = DateFormat('MM/dd/yyyy');

  static Future<void> exportReceipts(
    List<Receipt> receipts, {
    required String taxPeriodLabel,
    List<Vehicle>? vehicles,
  }) async {
    if (receipts.isEmpty) return;

    final rows = <List<String>>[
      ['Date', 'Category', 'Station', 'Amount', 'Vehicle', 'Notes'],
    ];

    for (final r in receipts) {
      String? vehicleName;
      if (r.vehicleId != null && vehicles != null) {
        final v = vehicles.where((v) => v.id == r.vehicleId).firstOrNull;
        vehicleName = v?.name;
      }

      rows.add([
        _dateFormat.format(r.date),
        r.category,
        r.stationName ?? '',
        r.amount != null ? r.amount!.toStringAsFixed(2) : '',
        vehicleName ?? '',
        r.notes ?? '',
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);

    final outputDir = await getTemporaryDirectory();
    final fileName =
        'gas_receipts_${DateTime.now().millisecondsSinceEpoch}.csv';
    final outputFile = File('${outputDir.path}/$fileName');
    await outputFile.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(outputFile.path)],
      subject: 'Gas Receipts CSV - $taxPeriodLabel',
      text: 'Attached is my expense report CSV for tax filing.',
    );
  }
}
