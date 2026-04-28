import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_category.dart';
import '../providers/receipt_provider.dart';
import '../services/csv_service.dart';
import '../services/pdf_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isExporting = false;
  bool _isPdf = true;
  bool _archiveAfterExport = false;
  String? _selectedCategory;
  int? _selectedVehicleId;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _export() async {
    final provider = context.read<ReceiptProvider>();

    // Temporarily apply filters to get the right subset
    provider.setDateFilter(_startDate, _endDate);
    if (_selectedCategory != null) {
      provider.setCategoryFilter(_selectedCategory);
    }
    if (_selectedVehicleId != null) {
      provider.setVehicleFilter(_selectedVehicleId);
    }

    await provider.loadReceipts();
    final filtered = provider.receipts.toList();

    if (!mounted) return;

    if (filtered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No receipts in selected range')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final label =
          '${DateFormat('MM/dd/yyyy').format(_startDate)} - ${DateFormat('MM/dd/yyyy').format(_endDate)}';

      if (_isPdf) {
        await PdfService.exportReceipts(filtered, taxPeriodLabel: label);
      } else {
        await CsvService.exportReceipts(
          filtered,
          taxPeriodLabel: label,
          vehicles: provider.vehicles,
        );
      }

      if (_archiveAfterExport) {
        final ids = filtered.map((r) => r.id!).toList();
        await provider.archiveReceipts(ids);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Export Receipts')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('PDF'),
                  icon: Icon(Icons.picture_as_pdf),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('CSV'),
                  icon: Icon(Icons.table_chart),
                ),
              ],
              selected: {_isPdf},
              onSelectionChanged: (set) => setState(() => _isPdf = set.first),
            ),
            const SizedBox(height: 24),
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('MM/dd/yyyy').format(_startDate),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _pickEndDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('MM/dd/yyyy').format(_endDate),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (provider.vehicles.isNotEmpty)
              DropdownButtonFormField<int?>(
                value: _selectedVehicleId,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Filter',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Vehicles'),
                  ),
                  ...provider.vehicles.map((v) {
                    return DropdownMenuItem(
                      value: v.id,
                      child: Text(v.name),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => _selectedVehicleId = v),
              ),
            if (provider.vehicles.isNotEmpty) const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category Filter',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...ExpenseCategory.all.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(ExpenseCategory.displayName(c)),
                  );
                }),
              ],
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Archive receipts after export'),
              subtitle: const Text('Marks exported receipts as archived'),
              value: _archiveAfterExport,
              onChanged: (v) => setState(() => _archiveAfterExport = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Spacer(),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('This Quarter'),
                  onPressed: () {
                    final now = DateTime.now();
                    final q = ((now.month - 1) ~/ 3);
                    setState(() {
                      _startDate = DateTime(now.year, q * 3 + 1, 1);
                      _endDate = now;
                    });
                  },
                ),
                ActionChip(
                  label: const Text('Last Quarter'),
                  onPressed: () {
                    final now = DateTime.now();
                    final q = ((now.month - 1) ~/ 3) - 1;
                    final year = now.year + (q < 0 ? -1 : 0);
                    final adjustedQ = q < 0 ? 3 : q;
                    setState(() {
                      _startDate = DateTime(year, adjustedQ * 3 + 1, 1);
                      _endDate = DateTime(year, (adjustedQ + 1) * 3 + 1, 1)
                          .subtract(const Duration(days: 1));
                    });
                  },
                ),
                ActionChip(
                  label: const Text('YTD'),
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _startDate = DateTime(now.year, 1, 1);
                      _endDate = now;
                    });
                  },
                ),
                ActionChip(
                  label: const Text('Last 30 Days'),
                  onPressed: () {
                    setState(() {
                      _endDate = DateTime.now();
                      _startDate = _endDate.subtract(const Duration(days: 30));
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isExporting ? null : _export,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_isPdf ? Icons.picture_as_pdf : Icons.table_chart),
                label: Text(_isExporting ? 'Exporting...' : 'Export'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
