import 'package:flutter/material.dart';
import '../models/receipt.dart';
import '../models/vehicle.dart';
import '../models/mileage_entry.dart';
import '../services/database_service.dart';
import '../services/image_service.dart';

class ReceiptProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ImageService _imageService = ImageService();

  List<Receipt> _receipts = [];
  List<Receipt> get receipts => _receipts;

  List<Vehicle> _vehicles = [];
  List<Vehicle> get vehicles => _vehicles;

  Vehicle? _defaultVehicle;
  Vehicle? get defaultVehicle => _defaultVehicle;

  List<MileageEntry> _mileageEntries = [];
  List<MileageEntry> get mileageEntries => _mileageEntries;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  double _totalExpenses = 0.0;
  double get totalExpenses => _totalExpenses;

  double _totalMiles = 0.0;
  double get totalMiles => _totalMiles;

  DateTime? _filterStart;
  DateTime? _filterEnd;
  String? _filterCategory;
  int? _filterVehicleId;

  DateTime? _mileageFilterStart;
  DateTime? _mileageFilterEnd;

  // Receipts
  Future<void> loadReceipts() async {
    _setLoading(true);
    _receipts = await _db.getReceipts(
      startDate: _filterStart,
      endDate: _filterEnd,
      vehicleId: _filterVehicleId,
      category: _filterCategory,
    );
    _totalExpenses = await _db.getTotalExpenses(
      startDate: _filterStart,
      endDate: _filterEnd,
      vehicleId: _filterVehicleId,
      category: _filterCategory,
    );
    _setLoading(false);
  }

  Future<void> captureReceipt({
    double? amount,
    String? stationName,
    String? notes,
    DateTime? date,
    String? category,
    int? vehicleId,
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
      category: category ?? 'gas',
      vehicleId: vehicleId ?? _defaultVehicle?.id,
    );

    await _db.insertReceipt(receipt);
    await loadReceipts();
  }

  Future<void> pickReceiptFromGallery({
    double? amount,
    String? stationName,
    String? notes,
    DateTime? date,
    String? category,
    int? vehicleId,
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
      category: category ?? 'gas',
      vehicleId: vehicleId ?? _defaultVehicle?.id,
    );

    await _db.insertReceipt(receipt);
    await loadReceipts();
  }

  Future<void> saveReceiptFromPath({
    required String path,
    double? amount,
    String? stationName,
    String? notes,
    DateTime? date,
    String? category,
    int? vehicleId,
  }) async {
    final receipt = Receipt(
      imagePath: path,
      amount: amount,
      date: date ?? DateTime.now(),
      stationName: stationName,
      notes: notes,
      createdAt: DateTime.now(),
      category: category ?? 'gas',
      vehicleId: vehicleId ?? _defaultVehicle?.id,
    );

    await _db.insertReceipt(receipt);
  }

  Future<void> deleteReceipt(int id) async {
    final receipt = _receipts.firstWhere((r) => r.id == id);
    await _imageService.deleteImage(receipt.imagePath);
    await _db.deleteReceipt(id);
    await loadReceipts();
  }

  Future<void> archiveReceipts(List<int> ids) async {
    await _db.archiveReceipts(ids);
    await loadReceipts();
  }

  // Vehicles
  Future<void> loadVehicles() async {
    _vehicles = await _db.getVehicles();
    _defaultVehicle = await _db.getDefaultVehicle();
    notifyListeners();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await _db.insertVehicle(vehicle);
    await loadVehicles();
  }

  Future<void> deleteVehicle(int id) async {
    await _db.deleteVehicle(id);
    await loadVehicles();
  }

  Future<void> setDefaultVehicle(int id) async {
    await _db.setDefaultVehicle(id);
    await loadVehicles();
  }

  // Mileage
  Future<void> loadMileage() async {
    _mileageEntries = await _db.getMileageEntries(
      startDate: _mileageFilterStart,
      endDate: _mileageFilterEnd,
    );
    _totalMiles = await _db.getTotalMiles(
      startDate: _mileageFilterStart,
      endDate: _mileageFilterEnd,
    );
    notifyListeners();
  }

  Future<void> addMileageEntry(MileageEntry entry) async {
    await _db.insertMileageEntry(entry);
    await loadMileage();
  }

  Future<void> deleteMileageEntry(int id) async {
    await _db.deleteMileageEntry(id);
    await loadMileage();
  }

  void setMileageDateFilter(DateTime? start, DateTime? end) {
    _mileageFilterStart = start;
    _mileageFilterEnd = end;
    loadMileage();
  }

  void clearMileageFilter() {
    _mileageFilterStart = null;
    _mileageFilterEnd = null;
    loadMileage();
  }

  // Filters
  void setDateFilter(DateTime? start, DateTime? end) {
    _filterStart = start;
    _filterEnd = end;
    loadReceipts();
  }

  void setCategoryFilter(String? category) {
    _filterCategory = category;
    loadReceipts();
  }

  void setVehicleFilter(int? vehicleId) {
    _filterVehicleId = vehicleId;
    loadReceipts();
  }

  void clearFilter() {
    _filterStart = null;
    _filterEnd = null;
    _filterCategory = null;
    _filterVehicleId = null;
    loadReceipts();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
