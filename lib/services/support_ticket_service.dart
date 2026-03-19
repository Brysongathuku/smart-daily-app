import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/support_ticket_model.dart';
import '../utils/constants.dart';

class SupportTicketService {
  final String _baseUrl = AppConstants.baseUrl;

  // ── Farmer: Create a support ticket ──────────────────────────────────────
  Future<String> createTicket({
    required int farmerID,
    required String token,
    required String subject,
    required String description,
    String priority = 'Medium',
    String? category,
  }) async {
    final uri = Uri.parse('$_baseUrl/support/ticket');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'farmerID':    farmerID,
        'subject':     subject,
        'description': description,
        'priority':    priority,
        if (category != null) 'category': category,
      }),
    );

    final json = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return json['message'] ?? 'Ticket created successfully';
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Failed to create ticket');
    }
  }

  // ── Admin: Get all tickets ────────────────────────────────────────────────
  Future<List<SupportTicket>> getAllTickets(String token) async {
    final uri = Uri.parse('$_baseUrl/support/tickets');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((e) => SupportTicket.fromJson(e)).toList();
    } else if (response.statusCode == 404) {
      return []; // No tickets yet
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Failed to fetch tickets');
    }
  }

  // ── Admin: Get tickets filtered by status ─────────────────────────────────
  Future<List<SupportTicket>> getTicketsByStatus(String token, String status) async {
    final uri = Uri.parse('$_baseUrl/support/tickets/status?status=${Uri.encodeComponent(status)}');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((e) => SupportTicket.fromJson(e)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Failed to fetch tickets');
    }
  }

  // ── Farmer: Get own tickets ───────────────────────────────────────────────
  Future<List<SupportTicket>> getTicketsByFarmer(int farmerID, String token) async {
    final uri = Uri.parse('$_baseUrl/support/farmer/$farmerID');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((e) => SupportTicket.fromJson(e)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      final json = jsonDecode(response.body);
      throw Exception(json['error'] ?? 'Failed to fetch tickets');
    }
  }

  // ── Admin: Reply to a ticket (sets status → In Progress) ─────────────────
  Future<String> replyToTicket({
    required int ticketID,
    required String token,
    required String response,
    required int adminID,
  }) async {
    final uri = Uri.parse('$_baseUrl/support/ticket/$ticketID/response');

    final res = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'response': response,
        'adminID':  adminID,
      }),
    );

    final json = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return json['message'] ?? 'Response sent';
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Failed to send response');
    }
  }

  // ── Admin: Resolve a ticket ───────────────────────────────────────────────
  Future<String> resolveTicket({
    required int ticketID,
    required String token,
    required String resolution,
  }) async {
    final uri = Uri.parse('$_baseUrl/support/ticket/$ticketID/resolve');

    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'resolution': resolution}),
    );

    final json = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return json['message'] ?? 'Ticket resolved';
    } else {
      throw Exception(json['error'] ?? json['message'] ?? 'Failed to resolve ticket');
    }
  }
}