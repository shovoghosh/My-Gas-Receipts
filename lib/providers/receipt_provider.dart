import 'package:flutter/material.dart';
import '../models/receipt.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';

class ReceiptProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ImageService _imageService = ImageService();

  List<Receipt> _receipts = [];
  List<Receipt> get receipts => _receipts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _totalExpenses = 0.0;
  double get totalExpenses => _totalExpenses;

  DateTime? _filterStart;
  DateTime? _filterEnd;

  Future<void> loadReceipts() async {
    _setLoading(true);
    _receipts = await _db.getReceipts(
      startDate: _filterStart,
      endDate: _filterEnd,
    );
    _totalExpenses = await _db.getTotalExpenses(
      startDate: _filterStart,
      endDate: _filterEnd,
    );
    _setLoading(false);
  }

  Future<void> captureReceipt({
    double? amount,
    String? stationName,
    String? notes,
    DateTime? date,
  }) async {
    final path = await _imageService.captureAndSaveReceipt();
    if (path == null) return;

    final receipt = Receipt(
      imagePath: path,
      amount: amount,
      date: date ?? DateTime.now(),
      stationName: stationName,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _db.insertReceipt(receipt);
    await loadReceipts();
  }

  Future<void> pickReceiptFromGallery({
    double? amount,
    String? stationName,
    String? notes,
    DateTime? date,
  }) async {
    final path = await _imageService.pickFromGallery();
    if (path == null) return;

    final receipt = Receipt(
      imagePath: path,
      amount: amount,
      date: date ?? DateTime.now(),
      stationName: stationName,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _db.insertReceipt(receipt);
    await loadReceipts();
  }

  Future<void> deleteReceipt(int id) async {
    final receipt = _receipts.firstWhere((r) => r.id == id);
    await _imageService.deleteImage(receipt.imagePath);
    await _db.deleteReceipt(id);
    await loadReceipts();
  }

  void setDateFilter(DateTime? start, DateTime? end) {
    _filterStart = start;
    _filterEnd = end;
    loadReceipts();
  }

  void clearFilter() {
    _filterStart = null;
    _filterEnd = null;
    loadReceipts();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
