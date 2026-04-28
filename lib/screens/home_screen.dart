import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_category.dart';
import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../services/csv_service.dart';
import '../services/pdf_service.dart';
import 'capture_screen.dart';
import 'categories_screen.dart';
import 'export_screen.dart';
import 'mileage_screen.dart';
import 'settings_screen.dart';
import 'batch_import_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gas Receipts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () => _showExportOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildSummaryCard(context, provider),
              _buildCategoryChips(context, provider),
              if (provider.receipts.isEmpty)
                Expanded(
                  child: _buildEmptyState(context, provider),
                )
              else
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
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r.stationName ??
                                      CategoryManager.vendorLabel(r.category),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  CategoryManager.displayName(
                                    r.category, provider.customCategories),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                backgroundColor: CategoryManager.color(
                                  r.category, provider.customCategories)
                                    .withAlpha(40),
                                side: BorderSide(
                                  color: CategoryManager.color(
                                    r.category, provider.customCategories),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '${DateFormat('MM/dd/yyyy').format(r.date)} • ${r.amount != null ? '\$${r.amount!.toStringAsFixed(2)}' : '--'}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showReceiptDetail(context, r),
                          onLongPress: () => _showReceiptActions(context, r),
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.local_gas_station, size: 48, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'My Gas Receipts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Expense Tracker',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Receipts'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Mileage Tracker'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MileageScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Categories'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('Export'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ReceiptProvider provider) {
    final hasActiveFilter = provider.totalExpenses > 0 ||
        (provider.receipts.isEmpty &&
            (provider.filterCategory != null ||
                provider.filterVehicleId != null ||
                provider.filterStart != null));

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
          Text(
            hasActiveFilter ? 'No receipts match filters' : 'No receipts yet',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          if (hasActiveFilter)
            TextButton.icon(
              onPressed: () => provider.clearFilter(),
              icon: const Icon(Icons.clear),
              label: const Text('Clear All Filters'),
            )
          else
            const Text(
              'Tap the + button to add your first receipt',
              style: TextStyle(color: Colors.grey),
            ),
        ],
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

  Widget _buildCategoryChips(BuildContext context, ReceiptProvider provider) {
    final builtIn = [
      'gas', 'maintenance', 'insurance', 'tolls', 'parking', 'other',
    ];
    final allIds = [
      ...builtIn,
      ...provider.customCategories.map((c) => c.id),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.all_inclusive, size: 16),
            label: const Text('All'),
            onPressed: () => provider.setCategoryFilter(null),
          ),
          const SizedBox(width: 8),
          ...allIds.map((id) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: Icon(
                  CategoryManager.icon(id, provider.customCategories),
                  size: 16,
                ),
                label: Text(
                  CategoryManager.displayName(id, provider.customCategories),
                ),
                onPressed: () => provider.setCategoryFilter(id),
              ),
            );
          }),
        ],
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
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Batch Import'),
              subtitle: const Text('Import multiple photos at once'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BatchImportScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(ctx);
                _exportPdf(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(ctx);
                _exportCsv(context);
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

  void _exportCsv(BuildContext context) async {
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
            Text('Generating CSV...'),
          ],
        ),
      ),
    );

    try {
      await CsvService.exportReceipts(
        provider.receipts,
        taxPeriodLabel: taxPeriodLabel,
        vehicles: provider.vehicles,
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

  void _showReceiptDetail(BuildContext context, Receipt receipt) {
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
                    receipt.stationName ??
                        CategoryManager.vendorLabel(receipt.category),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${DateFormat('MM/dd/yyyy').format(receipt.date)}',
                  ),
                  Text(
                    'Category: ${CategoryManager.displayName(receipt.category, context.read<ReceiptProvider>().customCategories)}',
                  ),
                  if (receipt.amount != null)
                    Text('Amount: \$${receipt.amount!.toStringAsFixed(2)}'),
                  if (receipt.notes != null && receipt.notes!.isNotEmpty)
                    Text('Notes: ${receipt.notes}'),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showEditReceiptDialog(context, receipt);
                  },
                  child: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptActions(BuildContext context, Receipt receipt) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Receipt'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditReceiptDialog(context, receipt);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive Receipt'),
              onTap: () {
                context.read<ReceiptProvider>().archiveReceipts([receipt.id!]);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt archived')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Receipt', style: TextStyle(color: Colors.red)),
              onTap: () {
                context.read<ReceiptProvider>().deleteReceipt(receipt.id!);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditReceiptDialog(BuildContext context, Receipt receipt) {
    final amountController = TextEditingController(
      text: receipt.amount?.toStringAsFixed(2) ?? '',
    );
    final stationController = TextEditingController(
      text: receipt.stationName ?? '',
    );
    final notesController = TextEditingController(
      text: receipt.notes ?? '',
    );
    var selectedDate = receipt.date;
    var selectedCategory = receipt.category;
    var selectedVehicleId = receipt.vehicleId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Receipt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'gas', 'maintenance', 'insurance', 'tolls', 'parking', 'other',
                    ...context.read<ReceiptProvider>().customCategories.map((c) => c.id),
                  ].map((id) {
                    return DropdownMenuItem(
                      value: id,
                      child: Text(
                        CategoryManager.displayName(
                          id, context.read<ReceiptProvider>().customCategories),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: r'Amount ($)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stationController,
                  decoration: InputDecoration(
                    labelText: CategoryManager.vendorLabel(selectedCategory),
                    prefixIcon: Icon(CategoryManager.vendorIcon(selectedCategory)),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('MM/dd/yyyy').format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                if (context.read<ReceiptProvider>().vehicles.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    value: selectedVehicleId,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No vehicle'),
                      ),
                      ...context.read<ReceiptProvider>().vehicles.map((v) {
                        return DropdownMenuItem(
                          value: v.id,
                          child: Text(v.name),
                        );
                      }),
                    ],
                    onChanged: (v) => setState(() => selectedVehicleId = v),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final updated = receipt.copyWith(
                  amount: double.tryParse(
                    amountController.text.replaceAll(',', ''),
                  ),
                  stationName: stationController.text.isEmpty
                      ? null
                      : stationController.text,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                  date: selectedDate,
                  category: selectedCategory,
                  vehicleId: selectedVehicleId,
                );
                context.read<ReceiptProvider>().updateReceipt(updated);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Receipt updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
