import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_category.dart';
import '../providers/receipt_provider.dart';
import '../theme/app_theme.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, _) {
          final builtIn = [
            'gas', 'maintenance', 'insurance', 'tolls', 'parking', 'other',
          ];
          final scheme = Theme.of(context).colorScheme;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _SectionHeader(title: 'BUILT-IN'),
              GlassCard(
                margin: const EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < builtIn.length; i++) ...[
                      _CategoryRow(
                        icon: CategoryManager.icon(
                            builtIn[i], provider.customCategories),
                        color: CategoryManager.color(
                            builtIn[i], provider.customCategories),
                        name: CategoryManager.displayName(
                            builtIn[i], provider.customCategories),
                        locked: true,
                      ),
                      if (i < builtIn.length - 1)
                        const Divider(height: 1, indent: 56),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  const _SectionHeader(title: 'CUSTOM', inline: true),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showAddCategoryDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (provider.customCategories.isEmpty)
                GlassCard(
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          color: scheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No custom categories yet. Tap Add to create one for things like car washes or tolls.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                )
              else
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0;
                          i < provider.customCategories.length;
                          i++) ...[
                        _CategoryRow(
                          icon: provider.customCategories[i].icon,
                          color: provider.customCategories[i].color,
                          name: provider.customCategories[i].name,
                          onEdit: () => _showEditCategoryDialog(
                              context, provider.customCategories[i]),
                          onDelete: () => _confirmDelete(
                              context, provider.customCategories[i]),
                        ),
                        if (i < provider.customCategories.length - 1)
                          const Divider(height: 1, indent: 56),
                      ],
                    ],
                  ),
                ),
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
                  colorValue: selectedColor.toARGB32(),
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
                  colorValue: selectedColor.toARGB32(),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool inline;

  const _SectionHeader({required this.title, this.inline = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(4, inline ? 0 : 8, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String name;
  final bool locked;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _CategoryRow({
    required this.icon,
    required this.color,
    required this.name,
    this.locked = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (locked)
            Icon(Icons.lock_outline, size: 16, color: scheme.onSurfaceVariant)
          else ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: scheme.error),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}
