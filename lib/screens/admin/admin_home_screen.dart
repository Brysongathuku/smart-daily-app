import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/milk_collection_provider.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'farmers_list_screen.dart';
import 'all_collections_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_support_screen.dart'; // ✅ ADDED

// ──────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS  (Clean Light)
// ──────────────────────────────────────────────────────────────────────────
const _bg        = Color(0xFFF8FAFC);
const _white     = Color(0xFFFFFFFF);
const _green     = Color(0xFF16A34A);
const _greenLight= Color(0xFFDCFCE7);
const _greenMid  = Color(0xFFBBF7D0);
const _border    = Color(0xFFE2E8F0);
const _dark      = Color(0xFF0F172A);
const _mid       = Color(0xFF475569);
const _light     = Color(0xFF94A3B8);

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  int    _totalFarmers     = 0;
  int    _todayCollections = 0;
  double _todayLiters      = 0.0;
  double _todayRevenue     = 0.0;
  bool   _statsLoading     = true;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<AuthProvider>(context, listen: false).loadSavedUser();
      await _loadStats();
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final milk = Provider.of<MilkCollectionProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.token != null) {
        await milk.getAllCollections(auth.token!);
        final today     = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final todayCols = milk.collections
            .where((c) => c.collectionDate.startsWith(today))
            .toList();
        final farmerIds = milk.collections.map((c) => c.farmerID).toSet();

        if (mounted) setState(() {
          _totalFarmers     = farmerIds.length;
          _todayCollections = todayCols.length;
          _todayLiters      = todayCols.fold(0.0, (s, c) => s + c.quantityInLiters);
          _todayRevenue     = todayCols.fold(0.0, (s, c) => s + c.totalAmount);
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  String? _imageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return raw.startsWith('http') ? raw : '${AppConstants.baseUrl}$raw';
  }

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _border)),
        title: const Text('Logout',
            style: TextStyle(color: _dark, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: _mid, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: _mid))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Logout')),
        ],
      ),
    );
    if (ok == true) {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth           = Provider.of<AuthProvider>(context);
    final user           = auth.currentUser;
    final imageUrl       = _imageUrl(user?.imageUrl);
    final collectionDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor:          Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness:     Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleSpacing: 20,
        title: const Text(
          'ADMIN PORTAL',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w700,
            color: _light,
          ),
        ),
        actions: [
          _iconBtn(Icons.notifications_none_rounded, () {}),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminProfileScreen())),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: _greenLight,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null
                    ? Text(user?.firstName[0].toUpperCase() ?? '?',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _green))
                    : null,
              ),
            ),
          ),
          _iconBtn(Icons.logout_rounded, _logout),
          const SizedBox(width: 8),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: _green,
        backgroundColor: _white,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdminGreeting(
                    imageUrl: imageUrl, name: user?.firstName ?? 'Admin'),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _StatsCard(
                    loading:      _statsLoading,
                    totalFarmers: _totalFarmers,
                    todayColls:   _todayCollections,
                    todayLiters:  _todayLiters,
                    todayRevenue: _todayRevenue,
                  ),
                ),

                const SizedBox(height: 24),

                _sectionLabel('QUICK ACTIONS'),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount:   2,
                    shrinkWrap:       true,
                    physics:          const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing:  10,
                    childAspectRatio: 2.5,
                    children: [
                      _DarkCard(
                        label:     'Record Collection',
                        icon:      Icons.water_drop_rounded,
                        iconBg:    _greenLight,
                        iconColor: _green,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => FarmersListScreen(
                                    collectionDate: collectionDate))),
                      ),
                      _DarkCard(
                        label:     'All Collections',
                        icon:      Icons.list_alt_rounded,
                        iconBg:    const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF3B82F6),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => AllCollectionsScreen(
                                    collectionDate: collectionDate))),
                      ),
                      _DarkCard(
                        label:     'Process Payments',
                        icon:      Icons.payments_rounded,
                        iconBg:    const Color(0xFFFFF7ED),
                        iconColor: const Color(0xFFF97316),
                        onTap: () => showSnackBar(context, 'Coming Soon!'),
                      ),
                      _DarkCard(
                        label:     'Support Tickets',
                        icon:      Icons.support_agent_rounded,
                        iconBg:    const Color(0xFFFDF4FF),
                        iconColor: const Color(0xFFA855F7),
                        // ✅ CONNECTED — was showSnackBar, now navigates
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => AdminSupportScreen())),
                      ),
                      _DarkCard(
                        label:     'My Profile',
                        icon:      Icons.manage_accounts_rounded,
                        iconBg:    const Color(0xFFF0FDF4),
                        iconColor: _green,
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const AdminProfileScreen())),
                      ),
                      _DarkCard(
                        label:     'Reports',
                        icon:      Icons.bar_chart_rounded,
                        iconBg:    const Color(0xFFFFF1F2),
                        iconColor: const Color(0xFFE11D48),
                        onTap: () => showSnackBar(context, 'Coming Soon!'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const _AdminRecentActivity(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:        _white,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: _border),
          ),
          child: Icon(icon, color: _mid, size: 18),
        ),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(text,
            style: const TextStyle(
                fontSize: 9,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
                color: _light)),
      );
}

// ══════════════════════════════════════════════════════════════════════════
//  SUB-WIDGETS
// ══════════════════════════════════════════════════════════════════════════

class _AdminGreeting extends StatelessWidget {
  final String? imageUrl;
  final String  name;
  const _AdminGreeting({this.imageUrl, required this.name});

  @override
  Widget build(BuildContext context) {
    final hour  = DateTime.now().hour;
    final greet = hour < 12 ? 'Good morning 👋' : hour < 17 ? 'Good afternoon 👋' : 'Good evening 👋';
    final date  = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    return Container(
      color: _white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(greet,
                  style: const TextStyle(
                      fontSize: 12, color: _light, fontWeight: FontWeight.w400)),
              const SizedBox(height: 2),
              Text(name,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                      letterSpacing: -0.5)),
            ]),
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: _greenLight,
                  border: Border.all(color: _greenMid, width: 2),
                  image: imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: imageUrl == null
                    ? const Center(
                        child: Icon(Icons.admin_panel_settings,
                            color: _green, size: 22))
                    : null,
              ),
              Positioned(
                bottom: -3, right: -3,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                    border: Border.all(color: _white, width: 2),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 8),
                ),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _bg,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_today_rounded, size: 12, color: _mid),
            const SizedBox(width: 6),
            Text(date,
                style: const TextStyle(
                    fontSize: 12, color: _mid, fontWeight: FontWeight.w500)),
          ]),
        ),
      ]),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final bool   loading;
  final int    totalFarmers;
  final int    todayColls;
  final double todayLiters;
  final double todayRevenue;

  const _StatsCard({
    required this.loading,
    required this.totalFarmers,
    required this.todayColls,
    required this.todayLiters,
    required this.todayRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');

    return Container(
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:      _green.withOpacity(0.25),
            blurRadius: 24,
            offset:     const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(children: [
        Positioned(
          top: -20, right: 60,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -30, right: -30,
          child: Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("TODAY'S OVERVIEW",
                      style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xBBFFFFFF))),
                  const SizedBox(height: 16),
                  const Text("Today's Revenue",
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0x99FFFFFF),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5),
                  Text('KSh ${fmt.format(todayRevenue)}',
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1.0)),
                  const SizedBox(height: 16),
                  Row(children: [
                    _chip(label: 'Farmers',     value: '$totalFarmers'),
                    const SizedBox(width: 8),
                    _chip(label: 'Collections', value: '$todayColls'),
                    const SizedBox(width: 8),
                    _chip(label: 'Litres',
                        value: '${todayLiters.toStringAsFixed(1)}L'),
                  ]),
                ]),
        ),
      ]),
    );
  }

  Widget _chip({required String label, required String value}) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 2),
            Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 9,
                    color: Color(0x99FFFFFF),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _DarkCard extends StatelessWidget {
  final String    label;
  final IconData  icon;
  final Color     iconBg;
  final Color     iconColor;
  final VoidCallback onTap;

  const _DarkCard({
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor:  _green.withOpacity(0.08),
        child: Ink(
          decoration: BoxDecoration(
            color:        _white,
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: _border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color:        iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _dark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _AdminRecentActivity extends StatelessWidget {
  const _AdminRecentActivity();

  @override
  Widget build(BuildContext context) {
    final milk   = Provider.of<MilkCollectionProvider>(context);
    final recent = milk.collections.take(4).toList();
    final fmt    = NumberFormat('#,##0');

    final dotColors = [
      _green,
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFFEC4899),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('RECENT ACTIVITY',
                style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w700,
                    color: _light)),
            const Text('View all',
                style: TextStyle(
                    fontSize: 11, color: _green, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (recent.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: const Center(
              child: Text('No recent activity',
                  style: TextStyle(color: _light, fontSize: 13)),
            ),
          ),
        )
      else
        ...recent.asMap().entries.map((e) {
          final idx      = e.key;
          final col      = e.value;
          final dotColor = dotColors[idx % dotColors.length];
          final date     = DateFormat('dd MMM').format(
              DateTime.tryParse(col.collectionDate) ?? DateTime.now());

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:        _white,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: _border),
              ),
              child: Row(children: [
                Container(
                  width: 3, height: 38,
                  decoration: BoxDecoration(
                      color:        dotColor,
                      borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Farmer #${col.farmerID}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _dark)),
                        const SizedBox(height: 2),
                        Text('$date · ${col.quantityInLiters.toStringAsFixed(1)}L',
                            style: const TextStyle(
                                fontSize: 10, color: _light)),
                      ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('KSh ${fmt.format(col.totalAmount)}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _green)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:        dotColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                      border:       Border.all(color: dotColor.withOpacity(0.25)),
                    ),
                    child: Text(col.collectionStatus ?? 'Recorded',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: dotColor)),
                  ),
                ]),
              ]),
            ),
          );
        }).toList(),
    ]);
  }
}