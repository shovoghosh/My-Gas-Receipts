import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/receipt_provider.dart';
import '../theme/app_theme.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, _) {
          if (provider.vehicles.isEmpty) {
            return const EmptyState(
              icon: Icons.directions_car_outlined,
              title: 'No vehicles yet',
              subtitle:
                  'Add your first vehicle to attach receipts to it and track per-vehicle expenses.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: provider.vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final v = provider.vehicles[i];
              final scheme = Theme.of(context).colorScheme;
              final initials = v.name.isNotEmpty
                  ? v.name[0].toUpperCase()
                  : '?';
              final subtitle = [
                if (v.year != null) v.year.toString(),
                v.make,
                v.model,
              ].where((s) => s != null && s.isNotEmpty).join(' ');

              return GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                onTap: () => _showAddVehicleDialog(context, existing: v),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppTokens.brandGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (v.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: scheme.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Default',
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () => provider.setDefaultVehicle(v.id!),
                        child: const Text('Set Default'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: () => _showDeleteDialog(context, v),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: GradientFab(
        icon: Icons.add,
        label: 'Add Vehicle',
        onPressed: () => _showAddVehicleDialog(context),
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context, {Vehicle? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final makeController = TextEditingController(text: existing?.make ?? '');
    final modelController =
        TextEditingController(text: existing?.model ?? '');
    final yearController =
        TextEditingController(text: existing?.year?.toString() ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Vehicle' : 'Add Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'e.g. Work Car',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: makeController,
                decoration: const InputDecoration(
                  labelText: 'Make',
                  hintText: 'e.g. Toyota',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'e.g. Prius',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  hintText: 'e.g. 2022',
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
              if (nameController.text.trim().isEmpty) return;
              final vehicle = Vehicle(
                id: existing?.id,
                name: nameController.text.trim(),
                make: makeController.text.trim().isEmpty
                    ? null
                    : makeController.text.trim(),
                model: modelController.text.trim().isEmpty
                    ? null
                    : modelController.text.trim(),
                year: int.tryParse(yearController.text.trim()),
                isDefault: existing?.isDefault ??
                    context.read<ReceiptProvider>().vehicles.isEmpty,
              );
              if (isEdit) {
                context.read<ReceiptProvider>().updateVehicle(vehicle);
              } else {
                context.read<ReceiptProvider>().addVehicle(vehicle);
              }
              Navigator.pop(ctx);
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Vehicle?'),
        content: Text('Are you sure you want to delete "${vehicle.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ReceiptProvider>().deleteVehicle(vehicle.id!);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
