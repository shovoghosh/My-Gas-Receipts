import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/receipt_provider.dart';
import '../services/pdf_service.dart';
import 'capture_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gas Receipts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.receipts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No receipts yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the + button to add your first receipt',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildSummaryCard(context, provider),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.receipts.length,
                  itemBuilder: (ctx, i) {
                    final r = provider.receipts[i];
                    return Dismissible(
                      key: Key(r.id?.toString() ?? r.imagePath),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => provider.deleteReceipt(r.id!),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(r.imagePath),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                        title: Text(
                          r.stationName ?? 'Gas Station',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${DateFormat('MM/dd/yyyy').format(r.date)} • ${r.amount != null ? '\$${r.amount!.toStringAsFixed(2)}' : '--'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showReceiptDetail(context, r),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Receipt'),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ReceiptProvider provider) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Expenses',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${provider.totalExpenses.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${provider.receipts.length}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Receipts',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CaptureScreen(
                      source: ImageSource.camera,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CaptureScreen(
                      source: ImageSource.gallery,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportPdf(BuildContext context) async {
    final provider = context.read<ReceiptProvider>();
    if (provider.receipts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No receipts to export')),
      );
      return;
    }

    final now = DateTime.now();
    final quarter = ((now.month - 1) ~/ 3) + 1;
    final taxPeriodLabel = 'Q$quarter ${now.year}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Generating PDF...'),
          ],
        ),
      ),
    );

    try {
      await PdfService.exportReceipts(
        provider.receipts,
        taxPeriodLabel: taxPeriodLabel,
      );
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter Receipts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('This Quarter'),
              onTap: () {
                final now = DateTime.now();
                final q = ((now.month - 1) ~/ 3);
                final start = DateTime(now.year, q * 3 + 1, 1);
                final end = DateTime(now.year, (q + 1) * 3 + 1, 1)
                    .subtract(const Duration(days: 1));
                context.read<ReceiptProvider>().setDateFilter(start, end);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Last Quarter'),
              onTap: () {
                final now = DateTime.now();
                final q = ((now.month - 1) ~/ 3) - 1;
                final year = now.year + (q < 0 ? -1 : 0);
                final adjustedQ = q < 0 ? 3 : q;
                final start = DateTime(year, adjustedQ * 3 + 1, 1);
                final end = DateTime(year, (adjustedQ + 1) * 3 + 1, 1)
                    .subtract(const Duration(days: 1));
                context.read<ReceiptProvider>().setDateFilter(start, end);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Year to Date'),
              onTap: () {
                final now = DateTime.now();
                context.read<ReceiptProvider>().setDateFilter(
                  DateTime(now.year, 1, 1),
                  now,
                );
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('All Time'),
              onTap: () {
                context.read<ReceiptProvider>().clearFilter();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptDetail(BuildContext context, receipt) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(
              File(receipt.imagePath),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.stationName ?? 'Gas Station',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${DateFormat('MM/dd/yyyy').format(receipt.date)}',
                  ),
                  if (receipt.amount != null)
                    Text('Amount: \$${receipt.amount!.toStringAsFixed(2)}'),
                  if (receipt.notes != null && receipt.notes!.isNotEmpty)
                    Text('Notes: ${receipt.notes}'),
                ],
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
