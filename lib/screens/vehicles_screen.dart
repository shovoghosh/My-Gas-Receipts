import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/receipt_provider.dart';

class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicles')),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, _) {
          if (provider.vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  const Text('No vehicles yet', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your first vehicle to attach receipts to it',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.vehicles.length,
            itemBuilder: (ctx, i) {
              final v = provider.vehicles[i];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(v.name[0].toUpperCase()),
                ),
                title: Text(v.name),
                subtitle: Text(
                  [
                    if (v.year != null) v.year.toString(),
                    v.make,
                    v.model,
                  ].where((s) => s != null && s.isNotEmpty).join(' '),
                ),
                trailing: v.isDefault
                    ? Chip(
                        label: const Text('Default'),
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                      )
                    : TextButton(
                        onPressed: () => provider.setDefaultVehicle(v.id!),
                        child: const Text('Set Default'),
                      ),
                onLongPress: () => _showDeleteDialog(context, v),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVehicleDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    final nameController = TextEditingController();
    final makeController = TextEditingController();
    final modelController = TextEditingController();
    final yearController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Vehicle'),
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
              const SizedBox(height: 8),
              TextField(
                controller: makeController,
                decoration: const InputDecoration(
                  labelText: 'Make',
                  hintText: 'e.g. Toyota',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: 'Model',
                  hintText: 'e.g. Prius',
                ),
              ),
              const SizedBox(height: 8),
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
                name: nameController.text.trim(),
                make: makeController.text.trim().isEmpty
                    ? null
                    : makeController.text.trim(),
                model: modelController.text.trim().isEmpty
                    ? null
                    : modelController.text.trim(),
                year: int.tryParse(yearController.text.trim()),
                isDefault: context.read<ReceiptProvider>().vehicles.isEmpty,
              );
              context.read<ReceiptProvider>().addVehicle(vehicle);
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
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
