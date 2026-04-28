import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/receipt_provider.dart';
import '../services/image_service.dart';
import '../services/ocr_service.dart';

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

  final ImageService _imageService = ImageService();
  final OcrService _ocrService = OcrService();

  @override
  void initState() {
    super.initState();
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
      if (result['total'] != null && mounted) {
        setState(() {
          _amountController.text = result['total'];
        });
      }
    } catch (_) {
      // OCR is optional; ignore errors
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _saveReceipt() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));

    await context.read<ReceiptProvider>().captureReceipt(
      amount: amount,
      stationName: _stationController.text.isEmpty ? null : _stationController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      date: _selectedDate,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt saved')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Receipt'),
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_previewPath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
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
                    controller: _stationController,
                    decoration: const InputDecoration(
                      labelText: 'Station Name',
                      prefixIcon: Icon(Icons.local_gas_station),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('MM/dd/yyyy').format(_selectedDate),
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
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveReceipt,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Receipt'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
