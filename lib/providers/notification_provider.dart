import 'dart:async';
import 'package:flutter/material.dart';
import '../models/milk_collection_model.dart';
import '../services/notification_service.dart';
import '../services/milk_collection_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();
  final MilkCollectionService _milkService = MilkCollectionService();

  int _unreadCount = 0;
  Timer? _timer;
  List<MilkCollectionModel> _collections = [];
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;
  bool get isLoading => _isLoading;
  List<MilkCollectionModel> get collections => _collections;

  // ── Start polling every 30 seconds ────────────────────────────────────
  void startPolling(int farmerID, String token) {
    _fetchCount(farmerID, token);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchCount(farmerID, token);
    });
  }

  // ── Stop polling on logout ─────────────────────────────────────────────
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _unreadCount = 0;
    _collections = [];
    notifyListeners();
  }

  Future<void> _fetchCount(int farmerID, String token) async {
    try {
      final count = await _service.getUnreadCount(farmerID, token);
      if (count != _unreadCount) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Fetch collections to build notification messages ───────────────────
  Future<void> fetchNotifications(int farmerID, String token) async {
    _isLoading = true;
    notifyListeners();
    try {
      _collections = await _milkService.getCollectionsByFarmer(farmerID, token);
      _collections.sort((a, b) => b.collectionDate.compareTo(a.collectionDate));
    } catch (_) {
      _collections = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Call when farmer taps notification bell ────────────────────────────
  Future<void> markAsRead(int farmerID, String token) async {
    try {
      await _service.resetUnreadCount(farmerID, token);
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  // ── Build notification message from a collection ───────────────────────
  static String buildMessage({
    required String firstName,
    required MilkCollectionModel collection,
    required double monthTotal,
  }) {
    final fmt = _fmt();
    final date = _formatDate(collection.collectionDate);
    final litres = collection.quantityInLiters.toStringAsFixed(1);
    final amount = fmt.format(collection.totalAmount);
    final monthly = fmt.format(monthTotal);

    return 'Dear $firstName, your milk collection of ${litres}L '
        'recorded on $date has been successfully saved. '
        'Amount earned: KSh $amount. '
        'Your total cumulative earnings this month stands at KSh $monthly. '
        'Thank you for your continued partnership — Smart Dairy 🐄';
  }

  static _fmt() {
    // inline to avoid import issues
    return _NumberFmt();
  }

  static String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Simple number formatter to avoid intl import issues in provider
class _NumberFmt {
  String format(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '$buffer.$decPart';
  }
}
