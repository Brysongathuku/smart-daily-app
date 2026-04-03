import 'package:flutter/material.dart';
import '../models/milk_collection_model.dart';
import '../services/milk_collection_service.dart';

class MilkCollectionProvider with ChangeNotifier {
  final MilkCollectionService _service = MilkCollectionService();

  List<MilkCollectionModel> _collections = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _lastCreatedMilkID;
  bool? _lastSmsDelivered;

  List<MilkCollectionModel> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get lastCreatedMilkID => _lastCreatedMilkID;
  bool? get lastSmsDelivered => _lastSmsDelivered;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? m) {
    _errorMessage = m;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── How many collections does this farmer have TODAY ──────────────────────
  int getTodayCollectionCount(int farmerID) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return _collections
        .where((c) => c.farmerID == farmerID && c.collectionDate == todayStr)
        .length;
  }

  // ── Create milk collection ────────────────────────────────────────────────
  Future<bool> createCollection(
    CreateMilkCollectionRequest request,
    String token,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      final collection = await _service.createMilkCollection(request, token);
      _lastCreatedMilkID = collection.milkID;
      _lastSmsDelivered = collection.smsDelivered;
      _collections.insert(0, collection);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // ── Get all collections ───────────────────────────────────────────────────
  Future<void> getAllCollections(String token) async {
    _setLoading(true);
    _setError(null);
    try {
      _collections = await _service.getAllCollections(token);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Get collections by farmer ─────────────────────────────────────────────
  Future<void> getCollectionsByFarmer(int farmerID, String token) async {
    _setLoading(true);
    _setError(null);
    try {
      _collections = await _service.getCollectionsByFarmer(farmerID, token);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Get collections by collector ──────────────────────────────────────────
  Future<void> getCollectionsByCollector(int collectorID, String token) async {
    _setLoading(true);
    _setError(null);
    try {
      _collections =
          await _service.getCollectionsByCollector(collectorID, token);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Get collections by date range ─────────────────────────────────────────
  Future<void> getCollectionsByDateRange(
    String startDate,
    String endDate,
    String token,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      _collections =
          await _service.getCollectionsByDateRange(startDate, endDate, token);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
