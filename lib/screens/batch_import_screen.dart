import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_category.dart';
import '../providers/receipt_provider.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';

class BatchImportScreen extends StatefulWidget {
  const BatchImportScreen({super.key});

  @override
  State<BatchImportScreen> createState() => _BatchImportScreenState();
}

class _BatchImportScreenState extends State<BatchImportScreen> {
  final ImageService _imageService = ImageService();
  final List<_ReceiptDraft> _drafts = [];
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pickImages();
  }

  Future<void> _pickImages() async {
    setState(() => _isLoading = true);
    final paths = await _imageService.pickMultipleImages();
    setState(() {
      _drafts.addAll(paths.map((p) => _ReceiptDraft(imagePath: p)));
      _isLoading = false;
    });

    if (paths.isEmpty && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _pickMoreImages() async {
    final paths = await _imageService.pickMultipleImages();
    if (paths.isEmpty) return;
    setState(() {
      _drafts.addAll(paths.map((p) => _ReceiptDraft(imagePath: p)));
    });
  }

  Future<void> _saveAll() async {
    final missingStation = <int>[];
    final missingAmount = <int>[];
    for (var i = 0; i < _drafts.length; i++) {
      final d = _drafts[i];
      if (d.stationName.text.trim().isEmpty) missingStation.add(i);
      final amt = double.tryParse(d.amountController.text.replaceAll(',', ''));
      if (amt == null || amt <= 0) missingAmount.add(i);
    }
    if (missingStation.isNotEmpty || missingAmount.isNotEmpty) {
      final parts = <String>[];
      if (missingStation.isNotEmpty) {
        parts.add('station/vendor name for #${missingStation.map((i) => i + 1).join(', #')}');
      }
      if (missingAmount.isNotEmpty) {
        parts.add('amount for #${missingAmount.map((i) => i + 1).join(', #')}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter ${parts.join(' and ')}')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<ReceiptProvider>();
    int saved = 0;

    for (final d in _drafts) {
      final amount = double.tryParse(d.amountController.text.replaceAll(',', ''));
      await provider.saveReceiptFromPath(
        path: d.imagePath,
        amount: amount,
        stationName: d.stationName.text.trim(),
        notes: d.notesController.text.trim().isEmpty
            ? null
            : d.notesController.text.trim(),
        date: d.date,
        category: d.category,
        vehicleId: d.vehicleId,
      );
      saved++;
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$saved receipts saved')),
      );
    }
  }

  void _removeDraft(int index) {
    setState(() => _drafts.removeAt(index));
    if (_drafts.isEmpty && mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Batch Import (${_drafts.length})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Add more photos',
            onPressed: _pickMoreImages,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: _drafts.length,
                    itemBuilder: (ctx, i) => _DraftCard(
                      key: ValueKey(_drafts[i].imagePath),
                      index: i,
                      draft: _drafts[i],
                      onRemove: () => _removeDraft(i),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveAll,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          _isSaving
                              ? 'Saving...'
                              : 'Save ${_drafts.length} Receipt${_drafts.length == 1 ? '' : 's'}',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ReceiptDraft {
  final String imagePath;
  final TextEditingController stationName = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String category;
  DateTime date;
  int? vehicleId;

  _ReceiptDraft({
    required this.imagePath,
  })  : date = DateTime.now(),
        category = 'gas';

  void dispose() {
    stationName.dispose();
    amountController.dispose();
    notesController.dispose();
  }
}

class _DraftCard extends StatefulWidget {
  final int index;
  final _ReceiptDraft draft;
  final VoidCallback onRemove;

  const _DraftCard({
    super.key,
    required this.index,
    required this.draft,
    required this.onRemove,
  });

  @override
  State<_DraftCard> createState() => _DraftCardState();
}

class _DraftCardState extends State<_DraftCard> {
  late String _category;
  late int? _vehicleId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _category = widget.draft.category;
    _vehicleId = widget.draft.vehicleId;
    _date = widget.draft.date;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        widget.draft.date = picked;
      });
    }
  }

  List<DropdownMenuItem<String>> _buildCategoryItems(ReceiptProvider provider) {
    const builtIn = ['gas', 'maintenance', 'insurance', 'tolls', 'parking', 'other'];
    final allIds = [
      ...builtIn,
      ...provider.customCategories.map((c) => c.id),
    ];

    return allIds.map((id) {
      return DropdownMenuItem(
        value: id,
        child: Row(
          children: [
            Icon(
              CategoryManager.icon(id, provider.customCategories),
              color: CategoryManager.color(id, provider.customCategories),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                CategoryManager.displayName(id, provider.customCategories),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();
    final scheme = Theme.of(context).colorScheme;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.rMd),
                child: Image.file(
                  File(widget.draft.imagePath),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Receipt #${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Remove',
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _buildCategoryItems(provider),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _category = v;
                widget.draft.category = v;
              });
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.draft.stationName,
            decoration: InputDecoration(
              labelText: '${CategoryManager.vendorLabel(_category)} *',
              prefixIcon: Icon(CategoryManager.vendorIcon(_category)),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.draft.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: r'Amount ($) *',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    child: Text(
                      DateFormat('MM/dd/yyyy').format(_date),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              if (provider.vehicles.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _vehicleId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None'),
                      ),
                      ...provider.vehicles.map((v) {
                        return DropdownMenuItem(
                          value: v.id,
                          child: Text(
                            v.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _vehicleId = v;
                        widget.draft.vehicleId = v;
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: widget.draft.notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              prefixIcon: Icon(Icons.notes),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
