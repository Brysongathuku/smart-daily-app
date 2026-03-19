import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/support_ticket_provider.dart';
import '../../models/support_ticket_model.dart';

// ── Design tokens (Clean Light — matches your existing theme) ──────────────
const _bg       = Color(0xFFF8FAFC);
const _white    = Color(0xFFFFFFFF);
const _green    = Color(0xFF16A34A);
const _greenLight = Color(0xFFDCFCE7);
const _border   = Color(0xFFE2E8F0);
const _dark     = Color(0xFF0F172A);
const _mid      = Color(0xFF475569);
const _light    = Color(0xFF94A3B8);

class FarmerSupportScreen extends StatefulWidget {
  const FarmerSupportScreen({Key? key}) : super(key: key);

  @override
  State<FarmerSupportScreen> createState() => _FarmerSupportScreenState();
}

class _FarmerSupportScreenState extends State<FarmerSupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth    = Provider.of<AuthProvider>(context, listen: false);
    final support = Provider.of<SupportTicketProvider>(context, listen: false);
    if (auth.token != null && auth.currentUser != null) {
      await support.loadFarmerTickets(auth.currentUser!.userId, auth.token!);
    }
  }

  void _openCreateTicketSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateTicketSheet(),
    ).then((_) => _load()); // reload after creating
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _white,
        foregroundColor: _dark,
        title: const Text('Support',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _openCreateTicketSheet,
              icon: const Icon(Icons.add_rounded, size: 16, color: _green),
              label: const Text('New Ticket',
                  style: TextStyle(
                      color: _green, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: Consumer<SupportTicketProvider>(
        builder: (context, support, _) {
          if (support.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _green));
          }

          if (support.tickets.isEmpty) {
            return _EmptyState(onTap: _openCreateTicketSheet);
          }

          return RefreshIndicator(
            onRefresh: _load,
            color: _green,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: support.tickets.length,
              itemBuilder: (_, i) =>
                  _FarmerTicketCard(ticket: support.tickets[i]),
            ),
          );
        },
      ),
    );
  }
}

// ── Create Ticket Bottom Sheet ─────────────────────────────────────────────
class _CreateTicketSheet extends StatefulWidget {
  const _CreateTicketSheet();

  @override
  State<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends State<_CreateTicketSheet> {
  final _formKey     = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descCtrl    = TextEditingController();
  String _priority   = 'Medium';
  String? _category;

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];
  final List<String> _categories = [
    'Payment Query', 'Collection Issue', 'Quality Dispute', 'General'
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth    = Provider.of<AuthProvider>(context, listen: false);
    final support = Provider.of<SupportTicketProvider>(context, listen: false);

    final ok = await support.createTicket(
      farmerID:    auth.currentUser!.userId,
      token:       auth.token!,
      subject:     _subjectCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      priority:    _priority,
      category:    _category,
    );

    if (ok && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket submitted successfully!'),
          backgroundColor: _green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(support.errorMessage ?? 'Failed to submit ticket'),
          backgroundColor: Colors.redAccent,
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
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),

            const Text('New Support Ticket',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
            const SizedBox(height: 4),
            const Text('Describe your issue and we will get back to you.',
                style: TextStyle(fontSize: 12, color: _light)),

            const SizedBox(height: 20),

            // Subject
            _label('Subject'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _subjectCtrl,
              decoration: _inputDec('e.g. Payment not received'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
            ),

            const SizedBox(height: 14),

            // Description
            _label('Description'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: _inputDec('Explain your issue in detail...'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Description is required' : null,
            ),

            const SizedBox(height: 14),

            // Priority + Category row
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Priority'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: _inputDec(''),
                    items: _priorities
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => _priority = v ?? 'Medium'),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Category'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _category,
                    hint: const Text('Optional',
                        style: TextStyle(fontSize: 13, color: _light)),
                    decoration: _inputDec(''),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ]),
              ),
            ]),

            const SizedBox(height: 24),

            // Submit button
            Consumer<SupportTicketProvider>(
              builder: (_, support, __) => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: support.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
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
                      : const Text('Submit Ticket',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: _mid));

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

// ── Farmer Ticket Card ─────────────────────────────────────────────────────
class _FarmerTicketCard extends StatelessWidget {
  final SupportTicket ticket;
  const _FarmerTicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final date = ticket.createdAt != null
        ? DateFormat('dd MMM yyyy').format(
            DateTime.tryParse(ticket.createdAt!) ?? DateTime.now())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(ticket.subject,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
            ),
            _StatusBadge(status: ticket.status),
          ]),

          const SizedBox(height: 6),
          Text(ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _mid)),

          const SizedBox(height: 10),

          // Admin reply (if any)
          if (ticket.hasResponse) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _greenLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _green.withOpacity(0.2)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.support_agent_rounded,
                    size: 14, color: _green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ticket.response!,
                      style: const TextStyle(fontSize: 12, color: _dark)),
                ),
              ]),
            ),
            const SizedBox(height: 10),
          ],

          Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 11, color: _light),
            const SizedBox(width: 4),
            Text(date, style: const TextStyle(fontSize: 11, color: _light)),
            const SizedBox(width: 12),
            _PriorityBadge(priority: ticket.priority),
            if (ticket.category != null) ...[
              const SizedBox(width: 8),
              Text('· ${ticket.category}',
                  style: const TextStyle(fontSize: 11, color: _light)),
            ],
          ]),
        ]),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: const BoxDecoration(
              color: _greenLight, shape: BoxShape.circle),
          child: const Icon(Icons.support_agent_rounded,
              size: 36, color: _green),
        ),
        const SizedBox(height: 16),
        const Text('No tickets yet',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
        const SizedBox(height: 6),
        const Text('Submit a ticket if you have an issue.',
            style: TextStyle(fontSize: 13, color: _light)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Create Ticket'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    );
  }
}

// ── Shared badge widgets ───────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (status) {
      case 'Open':
        bg = const Color(0xFFEFF6FF); fg = const Color(0xFF3B82F6); break;
      case 'In Progress':
        bg = const Color(0xFFFFF7ED); fg = const Color(0xFFF97316); break;
      case 'Resolved':
        bg = _greenLight; fg = _green; break;
      case 'Closed':
        bg = const Color(0xFFF1F5F9); fg = _light; break;
      default:
        bg = const Color(0xFFF1F5F9); fg = _mid;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
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
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}