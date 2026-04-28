import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/mileage_entry.dart';
import '../providers/receipt_provider.dart';

class MileageScreen extends StatelessWidget {
  const MileageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mileage Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, _) {
          if (provider.mileageEntries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.speed,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  const Text('No mileage entries yet', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Track miles for IRS standard mileage deduction',
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
                  itemCount: provider.mileageEntries.length,
                  itemBuilder: (ctx, i) {
                    final e = provider.mileageEntries[i];
                    return Dismissible(
                      key: Key(e.id?.toString() ?? e.createdAt.toIso8601String()),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => provider.deleteMileageEntry(e.id!),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(e.miles.toStringAsFixed(0)),
                        ),
                        title: Text(
                          DateFormat('MM/dd/yyyy').format(e.date),
                        ),
                        subtitle: Text(
                          '${e.startOdometer.toStringAsFixed(1)} → ${e.endOdometer.toStringAsFixed(1)} mi',
                        ),
                        trailing: Text(
                          '${e.miles.toStringAsFixed(1)} mi',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        onTap: () => _showEntryDetail(context, e),
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
        onPressed: () => _showAddEntryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Miles'),
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
                    'Total Miles',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.totalMiles.toStringAsFixed(1),
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
                  '${provider.mileageEntries.length}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  'Trips',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
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
