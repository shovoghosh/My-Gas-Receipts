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
import '../theme/app_theme.dart';
import 'batch_import_screen.dart';
import 'capture_screen.dart';
import 'categories_screen.dart';
import 'mileage_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  void _switchTab(int i) {
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          _ReceiptsTab(),
          _MileageTab(),
          _CategoriesTab(),
          _SettingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _switchTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Receipts',
          ),
          NavigationDestination(
            icon: Icon(Icons.speed_outlined),
            selectedIcon: Icon(Icons.speed),
            label: 'Mileage',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab: Receipts (this is the original home content, no bottom nav, no AppBar)
// ---------------------------------------------------------------------------

class _ReceiptsTab extends StatelessWidget {
  const _ReceiptsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: GradientHeader(
                  title: 'My Gas Receipts',
                  subtitle: _greeting(provider),
                  trailing: Row(
                    children: [
                      _headerIcon(
                        Icons.file_upload_outlined,
                        () => _showExportOptions(context),
                      ),
                      const SizedBox(width: 8),
                      _headerIcon(
                        Icons.tune,
                        () => _showFilterDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _buildSummaryCard(context, provider),
                ),
              ),
              SliverToBoxAdapter(child: _buildCategoryChips(context, provider)),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              if (provider.receipts.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox.shrink(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 100),
                  sliver: SliverList.builder(
                    itemCount: provider.receipts.length,
                    itemBuilder: (ctx, i) {
                      final r = provider.receipts[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        child: Dismissible(
                          key: Key(r.id?.toString() ?? r.imagePath),
                          background: Container(
                            decoration: BoxDecoration(
                              color: AppTokens.danger,
                              borderRadius:
                                  BorderRadius.circular(AppTokens.rMd),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => provider.deleteReceipt(r.id!),
                          child: ReceiptRow(
                            icon: CategoryManager.icon(
                                r.category, provider.customCategories),
                            iconColor: CategoryManager.color(
                                r.category, provider.customCategories),
                            title: r.stationName ??
                                CategoryManager.vendorLabel(r.category),
                            subtitle:
                                '${DateFormat('MMM d, yyyy').format(r.date)} · ${CategoryManager.displayName(r.category, provider.customCategories)}',
                            trailingText: r.amount != null
                                ? '\$${r.amount!.toStringAsFixed(2)}'
                                : null,
                            onTap: () => _showReceiptDetail(context, r),
                            onLongPress: () =>
                                _showReceiptActions(context, r),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (provider.receipts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context, provider),
                ),
            ],
          );
        },
      ),
      floatingActionButton: GradientFab(
        icon: Icons.add,
        label: 'Add Receipt',
        onPressed: () => _showAddOptions(context),
      ),
    );
  }

  // The remaining helpers are top-level functions (declared below) so the
  // widget tree above stays readable.
}

// ---------------------------------------------------------------------------
// Tab wrappers — each is a Scaffold with no bottom nav, so the global one
// remains the single source of truth.
// ---------------------------------------------------------------------------

class _MileageTab extends StatelessWidget {
  const _MileageTab();
  @override
  Widget build(BuildContext context) {
    return const MileageScreen();
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();
  @override
  Widget build(BuildContext context) {
    return const CategoriesScreen();
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();
  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}

// ---------------------------------------------------------------------------
// Helpers (top-level so they can be reused across tabs / tested).
// ---------------------------------------------------------------------------

String _greeting(ReceiptProvider provider) {
  final hour = DateTime.now().hour;
  final greet = hour < 12
      ? 'Good morning'
      : hour < 18
          ? 'Good afternoon'
          : 'Good evening';
  final total = provider.totalExpenses;
  if (total <= 0) return greet;
  return '$greet · \$${total.toStringAsFixed(2)} tracked';
}

Widget _headerIcon(IconData icon, VoidCallback onTap) {
  return Material(
    color: Colors.white.withAlpha(40),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    ),
  );
}

Widget _buildEmptyState(BuildContext context, ReceiptProvider provider) {
  final hasActiveFilter = provider.totalExpenses > 0 ||
      (provider.receipts.isEmpty &&
          (provider.filterCategory != null ||
              provider.filterVehicleId != null ||
              provider.filterStart != null));

  return EmptyState(
    icon: Icons.receipt_long,
    title: hasActiveFilter ? 'No receipts match filters' : 'No receipts yet',
    subtitle: hasActiveFilter
        ? 'Try clearing the active filters to see more.'
        : 'Tap the + button to add your first receipt and start tracking expenses.',
    action: hasActiveFilter
        ? FilledButton.icon(
            onPressed: () => provider.clearFilter(),
            icon: const Icon(Icons.clear),
            label: const Text('Clear All Filters'),
          )
        : null,
  );
}

Widget _buildSummaryCard(BuildContext context, ReceiptProvider provider) {
  final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());
  return StatCard(
    label: 'TOTAL EXPENSES · $monthLabel'.toUpperCase(),
    value: '\$${provider.totalExpenses.toStringAsFixed(2)}',
    icon: Icons.payments_outlined,
    secondary: '${provider.receipts.length} receipts tracked',
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

  return SizedBox(
    height: 44,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        PillChip(
          label: 'All',
          icon: Icons.all_inclusive,
          selected: provider.filterCategory == null,
          onTap: () => provider.setCategoryFilter(null),
        ),
        const SizedBox(width: 8),
        ...allIds.map((id) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PillChip(
              label: CategoryManager.displayName(
                  id, provider.customCategories),
              icon: CategoryManager.icon(id, provider.customCategories),
              color: CategoryManager.color(id, provider.customCategories),
              selected: provider.filterCategory == id,
              onTap: () => provider.setCategoryFilter(id),
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: Image.file(
                    File(receipt.imagePath),
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Icon(Icons.broken_image, size: 64),
                    ),
                  ),
                ),
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
            title: const Text('Delete Receipt',
                style: TextStyle(color: Colors.red)),
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
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  'gas', 'maintenance', 'insurance', 'tolls', 'parking', 'other',
                  ...context
                      .read<ReceiptProvider>()
                      .customCategories
                      .map((c) => c.id),
                ].map((id) {
                  return DropdownMenuItem(
                    value: id,
                    child: Text(
                      CategoryManager.displayName(
                        id,
                        context.read<ReceiptProvider>().customCategories,
                      ),
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
                  labelText: r'Amount ($) *',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stationController,
                decoration: InputDecoration(
                  labelText: '${CategoryManager.vendorLabel(selectedCategory)} *',
                  prefixIcon:
                      Icon(CategoryManager.vendorIcon(selectedCategory)),
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
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(DateFormat('EEE, MMM d, yyyy').format(selectedDate)),
                ),
              ),
              const SizedBox(height: 12),
              if (context.read<ReceiptProvider>().vehicles.isNotEmpty)
                DropdownButtonFormField<int?>(
                  value: selectedVehicleId,
                  decoration: const InputDecoration(labelText: 'Vehicle'),
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
              final amount = double.tryParse(
                amountController.text.replaceAll(',', ''),
              );
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
                return;
              }
              if (stationController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter ${CategoryManager.vendorLabel(selectedCategory).toLowerCase()}',
                    ),
                  ),
                );
                return;
              }
              final updated = receipt.copyWith(
                amount: amount,
                stationName: stationController.text.trim(),
                notes: notesController.text.isEmpty
                    ? null
                    : notesController.text,
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
