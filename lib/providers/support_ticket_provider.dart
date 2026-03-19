import 'package:flutter/material.dart';
import '../models/support_ticket_model.dart';
import '../services/support_ticket_service.dart';

class SupportTicketProvider with ChangeNotifier {
  final SupportTicketService _service = SupportTicketService();

  List<SupportTicket> _tickets        = [];
  List<SupportTicket> _filteredTickets = [];
  bool   _isLoading    = false;
  String? _errorMessage;
  String  _activeFilter = 'All'; // All, Open, In Progress, Resolved, Closed

  // ── Getters ───────────────────────────────────────────────────────────────
  List<SupportTicket> get tickets         => _tickets;
  List<SupportTicket> get filteredTickets => _filteredTickets;
  bool                get isLoading       => _isLoading;
  String?             get errorMessage    => _errorMessage;
  String              get activeFilter    => _activeFilter;

  // Quick stats
  int get openCount       => _tickets.where((t) => t.isOpen).length;
  int get inProgressCount => _tickets.where((t) => t.isInProgress).length;
  int get resolvedCount   => _tickets.where((t) => t.isResolved).length;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? m) { _errorMessage = m; notifyListeners(); }
  void clearError() { _errorMessage = null; notifyListeners(); }

  // ── Apply local filter ────────────────────────────────────────────────────
  void setFilter(String filter) {
    _activeFilter = filter;
    if (filter == 'All') {
      _filteredTickets = List.from(_tickets);
    } else {
      _filteredTickets = _tickets.where((t) => t.status == filter).toList();
    }
    notifyListeners();
  }

  // ── Farmer: Create ticket ─────────────────────────────────────────────────
  Future<bool> createTicket({
    required int farmerID,
    required String token,
    required String subject,
    required String description,
    String priority = 'Medium',
    String? category,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _service.createTicket(
        farmerID:    farmerID,
        token:       token,
        subject:     subject,
        description: description,
        priority:    priority,
        category:    category,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // ── Admin: Load all tickets ───────────────────────────────────────────────
  Future<void> loadAllTickets(String token) async {
    _setLoading(true);
    _setError(null);
    try {
      _tickets         = await _service.getAllTickets(token);
      _filteredTickets = List.from(_tickets);
      setFilter(_activeFilter); // re-apply active filter
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  // ── Farmer: Load own tickets ──────────────────────────────────────────────
  Future<void> loadFarmerTickets(int farmerID, String token) async {
    _setLoading(true);
    _setError(null);
    try {
      _tickets         = await _service.getTicketsByFarmer(farmerID, token);
      _filteredTickets = List.from(_tickets);
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  // ── Admin: Reply to ticket ────────────────────────────────────────────────
  Future<bool> replyToTicket({
    required int ticketID,
    required String token,
    required String response,
    required int adminID,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _service.replyToTicket(
        ticketID: ticketID,
        token:    token,
        response: response,
        adminID:  adminID,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  // ── Admin: Resolve ticket ─────────────────────────────────────────────────
  Future<bool> resolveTicket({
    required int ticketID,
    required String token,
    required String resolution,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _service.resolveTicket(
        ticketID:   ticketID,
        token:      token,
        resolution: resolution,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}