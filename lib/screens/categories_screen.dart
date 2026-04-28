import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_category.dart';
import '../providers/receipt_provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, _) {
          final builtIn = ['gas', 'maintenance', 'insurance', 'tolls', 'parking', 'other'];

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                'Built-in',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...builtIn.map((id) {
                return ListTile(
                  leading: Icon(
                    CategoryManager.icon(id, provider.customCategories),
                    color: CategoryManager.color(id, provider.customCategories),
                  ),
                  title: Text(
                    CategoryManager.displayName(id, provider.customCategories),
                  ),
                  trailing: const Icon(Icons.lock, size: 16, color: Colors.grey),
                );
              }),
              const Divider(height: 32),
              Row(
                children: [
                  Text(
                    'Custom',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAddCategoryDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (provider.customCategories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No custom categories yet. Tap Add to create one.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...provider.customCategories.map((c) {
                  return ListTile(
                    leading: Icon(c.icon, color: c.color),
                    title: Text(c.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showEditCategoryDialog(context, c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _confirmDelete(context, c),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.receipt;
    Color selectedColor = CategoryManager.availableColors.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Car Wash',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Icon',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoryManager.availableIcons.map((icon) {
                    final isSelected = icon == selectedIcon;
                    return InkWell(
                      onTap: () => setState(() => selectedIcon = icon),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(ctx).colorScheme.primaryContainer
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(ctx).colorScheme.primary)
                              : null,
                        ),
                        child: Icon(icon),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Color',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoryManager.availableColors.map((color) {
                    final isSelected = color == selectedColor;
                    return InkWell(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: color, blurRadius: 8)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
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

                final iconName = _iconToName(selectedIcon);
                final category = CustomCategory(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  iconName: iconName,
                  colorValue: selectedColor.value,
                );

                context.read<ReceiptProvider>().addCustomCategory(category);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, CustomCategory category) {
    final nameController = TextEditingController(text: category.name);
    IconData selectedIcon = category.icon;
    Color selectedColor = category.color;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Icon',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoryManager.availableIcons.map((icon) {
                    final isSelected = icon == selectedIcon;
                    return InkWell(
                      onTap: () => setState(() => selectedIcon = icon),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(ctx).colorScheme.primaryContainer
                              : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(ctx).colorScheme.primary)
                              : null,
                        ),
                        child: Icon(icon),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Color',
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoryManager.availableColors.map((color) {
                    final isSelected = color == selectedColor;
                    return InkWell(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: color, blurRadius: 8)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
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

                final updated = CustomCategory(
                  id: category.id,
                  name: nameController.text.trim(),
                  iconName: _iconToName(selectedIcon),
                  colorValue: selectedColor.value,
                );

                context.read<ReceiptProvider>().updateCustomCategory(updated);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CustomCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          'Delete "${category.name}"? Receipts with this category will keep the category name but it won\'t appear in filters.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ReceiptProvider>().deleteCustomCategory(category.id);
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

  String _iconToName(IconData icon) {
    if (icon == Icons.local_gas_station) return 'local_gas_station';
    if (icon == Icons.build) return 'build';
    if (icon == Icons.shield) return 'shield';
    if (icon == Icons.toll) return 'toll';
    if (icon == Icons.local_parking) return 'local_parking';
    if (icon == Icons.receipt) return 'receipt';
    if (icon == Icons.car_repair) return 'car_repair';
    if (icon == Icons.local_car_wash) return 'local_car_wash';
    if (icon == Icons.ev_station) return 'ev_station';
    if (icon == Icons.card_membership) return 'card_membership';
    if (icon == Icons.wifi_tethering) return 'wifi_tethering';
    if (icon == Icons.directions_car) return 'directions_car';
    if (icon == Icons.home_repair_service) return 'home_repair_service';
    if (icon == Icons.medical_services) return 'medical_services';
    if (icon == Icons.restaurant) return 'restaurant';
    if (icon == Icons.store) return 'store';
    if (icon == Icons.hotel) return 'hotel';
    if (icon == Icons.flight) return 'flight';
    if (icon == Icons.local_shipping) return 'local_shipping';
    if (icon == Icons.attach_money) return 'attach_money';
    return 'receipt';
  }
}
