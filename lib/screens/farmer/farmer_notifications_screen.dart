import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/milk_collection_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

// ── Design tokens ──────────────────────────────────────────────────────────
const _bg = Color(0xFFF8FAFC);
const _white = Color(0xFFFFFFFF);
const _green = Color(0xFF16A34A);
const _greenL = Color(0xFFDCFCE7);
const _border = Color(0xFFE2E8F0);
const _dark = Color(0xFF0F172A);
const _light = Color(0xFF94A3B8);

class FarmerNotificationsScreen extends StatefulWidget {
  const FarmerNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<FarmerNotificationsScreen> createState() =>
      _FarmerNotificationsScreenState();
}

class _FarmerNotificationsScreenState extends State<FarmerNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final notif = Provider.of<NotificationProvider>(context, listen: false);
    if (auth.currentUser == null || auth.token == null) return;

    await notif.fetchNotifications(auth.currentUser!.userId, auth.token!);
    await notif.markAsRead(auth.currentUser!.userId, auth.token!);
  }

  double _monthTotal(
      List<MilkCollectionModel> all, MilkCollectionModel current) {
    final d = DateTime.tryParse(current.collectionDate);
    if (d == null) return current.totalAmount;
    double sum = 0;
    for (final c in all) {
      final cd = DateTime.tryParse(c.collectionDate);
      if (cd != null && cd.month == d.month && cd.year == d.year) {
        sum += c.totalAmount;
      }
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _white,
        foregroundColor: _dark,
        titleSpacing: 4,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
        ),
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notif, _) {
          if (notif.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _green, strokeWidth: 2),
            );
          }

          if (notif.collections.isEmpty) {
            return _buildEmpty();
          }

          final collections = notif.collections;
          final firstName = user?.firstName ?? 'Farmer';

          return RefreshIndicator(
            onRefresh: _load,
            color: _green,
            backgroundColor: _white,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              itemCount: collections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final col = collections[index];
                final monthAmt = _monthTotal(collections, col);
                final message = NotificationProvider.buildMessage(
                  firstName: firstName,
                  collection: col,
                  monthTotal: monthAmt,
                );
                return _NotificationCard(
                  collection: col,
                  message: message,
                  isLatest: index == 0,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: _greenL,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: _green,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _dark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your milk collection notifications will appear here once the admin records your collections.',
              style: TextStyle(fontSize: 13, color: _light),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Notification Card ──────────────────────────────────────────────────────
class _NotificationCard extends StatefulWidget {
  final MilkCollectionModel collection;
  final String message;
  final bool isLatest;

  const _NotificationCard({
    required this.collection,
    required this.message,
    required this.isLatest,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _expanded = false;

  String _formatDate(String raw) {
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _formatTime(String? raw) {
    if (raw == null) return '';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(widget.collection.collectionDate);
    final time = _formatTime(widget.collection.collectionTime);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.isLatest ? _green.withOpacity(0.4) : _border,
            width: widget.isLatest ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _greenL,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: _green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Milk Collection Recorded',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _dark,
                              ),
                            ),
                            if (widget.isLatest) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _green,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$date${time.isNotEmpty ? ' · $time' : ''}',
                          style: const TextStyle(fontSize: 11, color: _light),
                        ),
                      ],
                    ),
                  ),

                  // Expand arrow
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _light,
                      size: 20,
                    ),
                  ),
                ],
              ),

              // ── Expanded message ───────────────────────────────────────
              if (_expanded) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _greenL.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _green.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.message_rounded,
                          color: _green, size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _dark,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Extra detail pills ───────────────────────────────────
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _pill(Icons.star_rounded, Colors.amber,
                        widget.collection.qualityGrade),
                    _pill(Icons.attach_money_rounded, _green,
                        'KSh ${widget.collection.pricePerLiter.toStringAsFixed(0)}/L'),
                    if (widget.collection.collectionTime != null)
                      _pill(Icons.access_time_rounded, Colors.orange,
                          widget.collection.collectionTime!),
                    if (widget.collection.fatContent != null)
                      _pill(Icons.science_rounded, Colors.purple,
                          'Fat: ${widget.collection.fatContent!.toStringAsFixed(1)}%'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, color: color)),
      ]),
    );
  }
}
