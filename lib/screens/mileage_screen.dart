import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/mileage_entry.dart';
import '../providers/receipt_provider.dart';
import '../theme/app_theme.dart';

class MileageScreen extends StatelessWidget {
  const MileageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mileage Tracker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, _) {
          if (provider.mileageEntries.isEmpty) {
            return const EmptyState(
              icon: Icons.speed,
              title: 'No mileage entries yet',
              subtitle:
                  'Track miles for IRS standard mileage deduction. Tap + to log your first trip.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _buildSummaryCard(context, provider),
              const SizedBox(height: 16),
              ...provider.mileageEntries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Dismissible(
                    key:
                        Key(e.id?.toString() ?? e.createdAt.toIso8601String()),
                    background: Container(
                      decoration: BoxDecoration(
                        color: AppTokens.danger,
                        borderRadius:
                            BorderRadius.circular(AppTokens.rLg),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child:
                          const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => provider.deleteMileageEntry(e.id!),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      onTap: () => _showEntryDetail(context, e),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTokens.brandCyan.withAlpha(35),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.route_outlined,
                              color: AppTokens.brandCyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('MMM d, yyyy').format(e.date),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${e.startOdometer.toStringAsFixed(1)} → ${e.endOdometer.toStringAsFixed(1)} mi'
                                  '${e.purpose != null ? ' · ${e.purpose}' : ''}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 12.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${e.miles.toStringAsFixed(1)} mi',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
      floatingActionButton: GradientFab(
        icon: Icons.add_road,
        label: 'Log Miles',
        onPressed: () => _showAddEntryDialog(context),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ReceiptProvider provider) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      gradient: AppTokens.brandGradient,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL MILES',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  provider.totalMiles.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${provider.mileageEntries.length} trips logged',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.timeline, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    final startController = TextEditingController();
    final endController = TextEditingController();
    final purposeController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Log Mileage'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(DateFormat('MM/dd/yyyy').format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Start Odometer (mi)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'End Odometer (mi)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purposeController,
                  decoration: const InputDecoration(
                    labelText: 'Purpose',
                    hintText: 'e.g. Uber rides',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
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
                final start = double.tryParse(startController.text);
                final end = double.tryParse(endController.text);
                if (start == null || end == null || end <= start) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter valid odometer readings'),
                    ),
                  );
                  return;
                }

                final entry = MileageEntry(
                  date: selectedDate,
                  startOdometer: start,
                  endOdometer: end,
                  purpose: purposeController.text.isEmpty
                      ? null
                      : purposeController.text,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                  createdAt: DateTime.now(),
                );

                context.read<ReceiptProvider>().addMileageEntry(entry);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryDetail(BuildContext context, MileageEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trip Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${DateFormat('MM/dd/yyyy').format(entry.date)}'),
            Text('Start: ${entry.startOdometer.toStringAsFixed(1)} mi'),
            Text('End: ${entry.endOdometer.toStringAsFixed(1)} mi'),
            Text(
              'Distance: ${entry.miles.toStringAsFixed(1)} mi',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (entry.purpose != null) Text('Purpose: ${entry.purpose}'),
            if (entry.notes != null) Text('Notes: ${entry.notes}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter Trips'),
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
                context.read<ReceiptProvider>().setMileageDateFilter(start, end);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Year to Date'),
              onTap: () {
                final now = DateTime.now();
                context.read<ReceiptProvider>().setMileageDateFilter(
                  DateTime(now.year, 1, 1),
                  now,
                );
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('All Time'),
              onTap: () {
                context.read<ReceiptProvider>().clearMileageFilter();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
