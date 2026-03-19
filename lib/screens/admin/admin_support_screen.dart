import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_ticket_provider.dart';
import '../../models/support_ticket_model.dart';

// ── Design tokens (Clean Light) ────────────────────────────────────────────
const _bg        = Color(0xFFF8FAFC);
const _white     = Color(0xFFFFFFFF);
const _green     = Color(0xFF16A34A);
const _greenLight= Color(0xFFDCFCE7);
const _border    = Color(0xFFE2E8F0);
const _dark      = Color(0xFF0F172A);
const _mid       = Color(0xFF475569);
const _light     = Color(0xFF94A3B8);

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({Key? key}) : super(key: key);

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final List<String> _filters = ['All', 'Open', 'In Progress', 'Resolved', 'Closed'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth    = Provider.of<AuthProvider>(context, listen: false);
    final support = Provider.of<SupportTicketProvider>(context, listen: false);
    if (auth.token != null) {
      await support.loadAllTickets(auth.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _white,
        foregroundColor: _dark,
        title: const Text('Support Tickets',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
      ),
      body: Consumer<SupportTicketProvider>(
        builder: (context, support, _) {
          return Column(children: [
            // ── Stats row ──────────────────────────────────────────────
            Container(
              color: _white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(children: [
                _StatChip(label: 'Open',        count: support.openCount,       color: const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _StatChip(label: 'In Progress', count: support.inProgressCount, color: const Color(0xFFF97316)),
                const SizedBox(width: 8),
                _StatChip(label: 'Resolved',    count: support.resolvedCount,   color: _green),
              ]),
            ),

            // ── Filter tabs ────────────────────────────────────────────
            Container(
              color: _white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: _filters.map((f) {
                    final active = support.activeFilter == f;
                    return GestureDetector(
                      onTap: () => support.setFilter(f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? _green : _bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: active ? _green : _border),
                        ),
                        child: Text(f,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active ? Colors.white : _mid)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Ticket list ────────────────────────────────────────────
            Expanded(
              child: support.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _green))
                  : support.filteredTickets.isEmpty
                      ? const _EmptyFiltered()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: _green,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: support.filteredTickets.length,
                            itemBuilder: (_, i) => _AdminTicketCard(
                              ticket: support.filteredTickets[i],
                              onRefresh: _load,
                            ),
                          ),
                        ),
            ),
          ]);
        },
      ),
    );
  }
}

// ── Admin Ticket Card ──────────────────────────────────────────────────────
class _AdminTicketCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback  onRefresh;
  const _AdminTicketCard({required this.ticket, required this.onRefresh});

  void _openReplySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReplySheet(ticket: ticket),
    ).then((_) => onRefresh());
  }

  @override
  Widget build(BuildContext context) {
    final date = ticket.createdAt != null
        ? DateFormat('dd MMM yyyy').format(
            DateTime.tryParse(ticket.createdAt!) ?? DateTime.now())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            Expanded(
              child: Text(ticket.subject,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
            ),
            _StatusBadge(status: ticket.status),
          ]),

          const SizedBox(height: 4),

          // Farmer name
          Row(children: [
            const Icon(Icons.person_outline_rounded, size: 12, color: _light),
            const SizedBox(width: 4),
            Text(ticket.farmerName,
                style: const TextStyle(fontSize: 11, color: _mid, fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            const Icon(Icons.calendar_today_rounded, size: 11, color: _light),
            const SizedBox(width: 4),
            Text(date, style: const TextStyle(fontSize: 11, color: _light)),
          ]),

          const SizedBox(height: 8),

          // Description
          Text(ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _mid)),

          // Existing response
          if (ticket.hasResponse) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _greenLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _green.withOpacity(0.2)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Your Response',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _green,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(ticket.response!,
                    style: const TextStyle(fontSize: 12, color: _dark)),
              ]),
            ),
          ],

          const SizedBox(height: 10),

          // Priority + action button
          Row(children: [
            _PriorityBadge(priority: ticket.priority),
            if (ticket.category != null) ...[
              const SizedBox(width: 8),
              Text('· ${ticket.category}',
                  style: const TextStyle(fontSize: 11, color: _light)),
            ],
            const Spacer(),
            // Only show reply button if not resolved/closed
            if (!ticket.isResolved && !ticket.isClosed)
              GestureDetector(
                onTap: () => _openReplySheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ticket.hasResponse ? 'Update Reply' : 'Reply',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
              ),
          ]),
        ]),
      ),
    );
  }
}

// ── Reply & Resolve Bottom Sheet ───────────────────────────────────────────
class _ReplySheet extends StatefulWidget {
  final SupportTicket ticket;
  const _ReplySheet({required this.ticket});

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  final _responseCtrl   = TextEditingController();
  final _resolutionCtrl = TextEditingController();
  bool _markResolved    = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if already replied
    if (widget.ticket.hasResponse) {
      _responseCtrl.text = widget.ticket.response!;
    }
  }

  @override
  void dispose() {
    _responseCtrl.dispose();
    _resolutionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_responseCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response cannot be empty'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_markResolved && _resolutionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a resolution note'),
            backgroundColor: Colors.redAccent),
      );
      return;
    }

    final auth    = Provider.of<AuthProvider>(context, listen: false);
    final support = Provider.of<SupportTicketProvider>(context, listen: false);

    // 1. Send reply
    final replied = await support.replyToTicket(
      ticketID: widget.ticket.ticketID,
      token:    auth.token!,
      response: _responseCtrl.text.trim(),
      adminID:  auth.currentUser!.userId,
    );

    if (!replied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(support.errorMessage ?? 'Failed to send reply'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // 2. Resolve if checked
    if (_markResolved) {
      await support.resolveTicket(
        ticketID:   widget.ticket.ticketID,
        token:      auth.token!,
        resolution: _resolutionCtrl.text.trim(),
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_markResolved
              ? 'Reply sent & ticket resolved!'
              : 'Reply sent successfully!'),
          backgroundColor: _green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: _border, borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 16),

          const Text('Reply to Ticket',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
          const SizedBox(height: 4),
          Text(widget.ticket.subject,
              style: const TextStyle(fontSize: 13, color: _mid)),

          const SizedBox(height: 6),

          // Original message
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Text(widget.ticket.description,
                style: const TextStyle(fontSize: 12, color: _mid)),
          ),

          const SizedBox(height: 16),

          // Response field
          const Text('Your Response',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _mid)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _responseCtrl,
            maxLines: 4,
            decoration: _inputDec('Type your response here...'),
          ),

          const SizedBox(height: 14),

          // Mark resolved toggle
          GestureDetector(
            onTap: () => setState(() => _markResolved = !_markResolved),
            child: Row(children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: _markResolved ? _green : _white,
                  border: Border.all(
                      color: _markResolved ? _green : _border, width: 1.5),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: _markResolved
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 10),
              const Text('Mark ticket as Resolved',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _dark)),
            ]),
          ),

          // Resolution note (shown if mark resolved is checked)
          if (_markResolved) ...[
            const SizedBox(height: 12),
            const Text('Resolution Note',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _mid)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _resolutionCtrl,
              maxLines: 2,
              decoration: _inputDec('Summarise how this was resolved...'),
            ),
          ],

          const SizedBox(height: 24),

          Consumer<SupportTicketProvider>(
            builder: (_, support, __) => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: support.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _markResolved
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: support.isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        _markResolved
                            ? 'Send Reply & Resolve'
                            : 'Send Reply',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _light),
        filled: true,
        fillColor: _bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _green, width: 1.5)),
      );
}

// ── Stat chip ──────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final int    count;
  final Color  color;
  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.8))),
        ]),
      ),
    );
  }
}

class _EmptyFiltered extends StatelessWidget {
  const _EmptyFiltered();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_rounded, size: 48, color: _light),
        SizedBox(height: 12),
        Text('No tickets in this category',
            style: TextStyle(fontSize: 14, color: _light)),
      ]),
    );
  }
}

// ── Shared badges ──────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case 'Open':        bg = const Color(0xFFEFF6FF); fg = const Color(0xFF3B82F6); break;
      case 'In Progress': bg = const Color(0xFFFFF7ED); fg = const Color(0xFFF97316); break;
      case 'Resolved':    bg = _greenLight;              fg = _green;                  break;
      case 'Closed':      bg = const Color(0xFFF1F5F9); fg = _light;                  break;
      default:            bg = const Color(0xFFF1F5F9); fg = _mid;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case 'Urgent': color = const Color(0xFFDC2626); break;
      case 'High':   color = const Color(0xFFF97316); break;
      case 'Medium': color = const Color(0xFFEAB308); break;
      default:       color = _light;
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(priority,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}