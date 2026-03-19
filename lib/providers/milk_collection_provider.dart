import 'package:flutter/material.dart';
import '../models/milk_collection_model.dart';
import '../services/milk_collection_service.dart';

class MilkCollectionProvider with ChangeNotifier {
  final MilkCollectionService _service = MilkCollectionService();

  List<MilkCollectionModel> _collections = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _lastCreatedMilkID; // ← tracks the last created milk record's ID

  List<MilkCollectionModel> get collections => _collections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get lastCreatedMilkID => _lastCreatedMilkID;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
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

      // Capture the new milk ID so feeding provider can link to it
      _lastCreatedMilkID =
          collection.milkID; // ← uses milkID from MilkCollectionModel

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
      _collections = await _service.getCollectionsByDateRange(
        startDate,
        endDate,
        token,
      );
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}