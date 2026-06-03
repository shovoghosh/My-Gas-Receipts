import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense_category.dart';
import '../providers/receipt_provider.dart';
import '../services/image_service.dart';
import '../services/ocr_service.dart';
import '../theme/app_theme.dart';

class CaptureScreen extends StatefulWidget {
  final ImageSource source;

  const CaptureScreen({super.key, required this.source});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final _amountController = TextEditingController();
  final _stationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _previewPath;
  bool _isProcessing = false;
  bool _isScanning = false;
  String _category = 'gas';
  int? _vehicleId;

  final ImageService _imageService = ImageService();
  final OcrService _ocrService = OcrService();

  @override
  void initState() {
    super.initState();
    _vehicleId = context.read<ReceiptProvider>().defaultVehicle?.id;
    _captureImage();
  }

  Future<void> _captureImage() async {
    setState(() => _isProcessing = true);

    String? path;
    if (widget.source == ImageSource.camera) {
      path = await _imageService.captureAndSaveReceipt();
    } else {
      path = await _imageService.pickFromGallery();
    }

    if (path == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _previewPath = path;
      _isProcessing = false;
    });

    _runOcr(path);
  }

  Future<void> _runOcr(String path) async {
    setState(() => _isScanning = true);

    try {
      final result = await _ocrService.scanReceipt(path);
      if (mounted) {
        setState(() {
          if (result['total'] != null) {
            _amountController.text = result['total'];
          }
          if (result['stationName'] != null) {
            _stationController.text = result['stationName'];
          }
        });
      }
    } catch (_) {
      // OCR is optional; ignore errors
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _saveReceipt({bool addAnother = false}) async {
    if (_previewPath == null) return;

    final stationName = _stationController.text.trim();
    if (stationName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter ${CategoryManager.vendorLabel(_category).toLowerCase()} before saving',
          ),
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount before saving'),
        ),
      );
      return;
    }

    await context.read<ReceiptProvider>().saveReceiptFromPath(
      path: _previewPath!,
      amount: amount,
      stationName: stationName,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      date: _selectedDate,
      category: _category,
      vehicleId: _vehicleId,
    );

    if (mounted) {
      if (addAnother) {
        _amountController.clear();
        _stationController.clear();
        _notesController.clear();
        _selectedDate = DateTime.now();
        _captureImage();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt saved. Capture another.')),
        );
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt saved')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _stationController.dispose();
    _notesController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _buildCategoryItems(ReceiptProvider provider) {
    final builtIn = ['gas', 'maintenance', 'insurance', 'tolls', 'parking', 'other'];
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
            Text(CategoryManager.displayName(id, provider.customCategories)),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Receipt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: AppTokens.brandCyan),
                    SizedBox(width: 6),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTokens.brandCyan,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_previewPath != null)
                    GlassCard(
                      padding: EdgeInsets.zero,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.rLg),
                        child: Image.file(
                          File(_previewPath!),
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: _buildCategoryItems(provider),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 12),
                  if (provider.vehicles.isNotEmpty)
                    DropdownButtonFormField<int?>(
                      value: _vehicleId,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle',
                        prefixIcon: Icon(Icons.directions_car_outlined),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('No vehicle'),
                        ),
                        ...provider.vehicles.map((v) {
                          return DropdownMenuItem(
                            value: v.id,
                            child: Text(v.name),
                          );
                        }),
                      ],
                      onChanged: (v) => setState(() => _vehicleId = v),
                    ),
                  if (provider.vehicles.isNotEmpty) const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: r'Amount ($) *',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _stationController,
                    decoration: InputDecoration(
                      labelText: '${CategoryManager.vendorLabel(_category)} *',
                      prefixIcon: Icon(CategoryManager.vendorIcon(_category)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(AppTokens.rMd),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _saveReceipt(addAnother: true),
                          icon: const Icon(Icons.add),
                          label: const Text('Save & Add'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientFab(
                          icon: Icons.check,
                          label: 'Save',
                          onPressed: () => _saveReceipt(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
