import 'dart:async';
import 'package:flutter/material.dart';
import '../services/support_ticket_service.dart';

/// Polls the open-ticket count for the admin bell badge.
/// Does NOT touch NotificationProvider (farmer-only).
class AdminNotificationProvider with ChangeNotifier {
  final SupportTicketService _service = SupportTicketService();

  int _openTicketCount = 0;
  Timer? _timer;

  int get openTicketCount => _openTicketCount;
  bool get hasUnread => _openTicketCount > 0;

  // ── Start polling every 30 seconds ──────────────────────────────────────
  void startPolling(String token) {
    _fetch(token);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetch(token));
  }

  // ── Stop on logout ───────────────────────────────────────────────────────
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _openTicketCount = 0;
    notifyListeners();
  }

  Future<void> _fetch(String token) async {
    try {
      final tickets = await _service.getTicketsByStatus(token, 'Open');
      final count = tickets.length;
      if (count != _openTicketCount) {
        _openTicketCount = count;
        notifyListeners();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
