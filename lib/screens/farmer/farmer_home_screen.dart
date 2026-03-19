import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/weather_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/milk_collection_provider.dart';
import '../../providers/weather_provider.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';
import 'ai_recommendations_screen.dart';
import 'farmer_milk_collections_screen.dart';
import 'farmer_profile_screen.dart';
import 'farmer_support_screen.dart';

// ──────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ──────────────────────────────────────────────────────────────────────────
const _bg = Color(0xFFF8FAFC);
const _white = Color(0xFFFFFFFF);
const _green = Color(0xFF16A34A);
const _greenLight = Color(0xFFDCFCE7);
const _greenMid = Color(0xFFBBF7D0);
const _border = Color(0xFFE2E8F0);
const _dark = Color(0xFF0F172A);
const _mid = Color(0xFF475569);
const _light = Color(0xFF94A3B8);

class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({Key? key}) : super(key: key);

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen>
    with SingleTickerProviderStateMixin {
  double _totalEarnings = 0.0;
  double _thisMonthEarnings = 0.0;
  double _totalLiters = 0.0;
  int _totalCollections = 0;
  bool _walletLoading = true;
  bool _balanceVisible = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<AuthProvider>(context, listen: false).loadSavedUser();
      await _loadWalletData();
      await _loadWeather();
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    setState(() => _walletLoading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final milk = Provider.of<MilkCollectionProvider>(context, listen: false);
      if (auth.token != null && auth.currentUser != null) {
        await milk.getCollectionsByFarmer(
            auth.currentUser!.userId, auth.token!);
        final cols = milk.collections;
        final now = DateTime.now();
        double total = 0, month = 0, liters = 0;
        for (final c in cols) {
          total += c.totalAmount;
          liters += c.quantityInLiters;
          final d = DateTime.tryParse(c.collectionDate);
          if (d != null && d.month == now.month && d.year == now.year) {
            month += c.totalAmount;
          }
        }
        if (mounted) {
          setState(() {
            _totalEarnings = total;
            _thisMonthEarnings = month;
            _totalLiters = liters;
            _totalCollections = cols.length;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _walletLoading = false);
    }
  }

  Future<void> _loadWeather() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final weatherProvider =
          Provider.of<WeatherProvider>(context, listen: false);
      if (auth.token != null && auth.currentUser != null) {
        await weatherProvider.getCurrentWeather(
          auth.currentUser!.userId,
          auth.token!,
        );
      }
    } catch (_) {}
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
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final imageUrl = _imageUrl(user?.imageUrl);
    final fmt = NumberFormat('#,##0.00');
    final fmtShort = NumberFormat('#,##0');

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _white,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleSpacing: 20,
        title: const Text(
          'FARMER PORTAL',
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
                MaterialPageRoute(builder: (_) => FarmerProfileScreen())),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _avatar(imageUrl, user?.firstName),
            ),
          ),
          _iconBtn(Icons.logout_rounded, _logout),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadWalletData();
          await _loadWeather();
        },
        color: _green,
        backgroundColor: _white,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Greeting(
                    imageUrl: imageUrl, firstName: user?.firstName ?? 'Farmer'),

                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _WalletCard(
                    loading: _walletLoading,
                    visible: _balanceVisible,
                    onToggle: () =>
                        setState(() => _balanceVisible = !_balanceVisible),
                    totalEarnings: _totalEarnings,
                    monthEarnings: _thisMonthEarnings,
                    totalLiters: _totalLiters,
                    collections: _totalCollections,
                    fmt: fmt,
                    fmtShort: fmtShort,
                  ),
                ),

                const SizedBox(height: 14),

                if (user != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _FarmStrip(user: user),
                  ),

                // ── Weather widget ─────────────────────────────────────────
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _WeatherWidget(),
                ),

                const SizedBox(height: 24),

                _sectionLabel('QUICK ACTIONS'),
                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ActionGrid(
                    items: [
                      _ActionItem(
                        label: 'Milk Collections',
                        icon: Icons.water_drop_rounded,
                        iconBg: _greenLight,
                        iconColor: _green,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const FarmerMilkCollectionsScreen())),
                      ),
                      _ActionItem(
                        label: 'AI Assistant',
                        icon: Icons.auto_awesome_rounded,
                        iconBg: const Color(0xFFF0FDF4),
                        iconColor: const Color(0xFF16A34A),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AiRecommendationsScreen())),
                      ),
                      _ActionItem(
                        label: 'Payments',
                        icon: Icons.payments_rounded,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF3B82F6),
                        onTap: () =>
                            showSnackBar(context, 'Payments — Coming Soon!'),
                      ),
                      _ActionItem(
                        label: 'Support',
                        icon: Icons.support_agent_rounded,
                        iconBg: const Color(0xFFFFF7ED),
                        iconColor: const Color(0xFFF97316),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => FarmerSupportScreen())),
                      ),
                      _ActionItem(
                        label: 'My Profile',
                        icon: Icons.manage_accounts_rounded,
                        iconBg: const Color(0xFFFAF5FF),
                        iconColor: const Color(0xFF9333EA),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => FarmerProfileScreen())),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                _RecentCollections(context: context),

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
          width: 36,
          height: 36,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Icon(icon, color: _mid, size: 18),
        ),
      );

  Widget _avatar(String? imageUrl, String? firstName) => CircleAvatar(
        radius: 17,
        backgroundColor: _greenLight,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
        child: imageUrl == null
            ? Text(
                firstName?[0].toUpperCase() ?? '?',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: _green),
              )
            : null,
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
//  WEATHER WIDGET
// ══════════════════════════════════════════════════════════════════════════

class _WeatherWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context);
    final weather = weatherProvider.currentWeather;
    final isLoading = weatherProvider.isLoading;

    if (isLoading && weather == null) {
      return Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: _green, strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading weather...',
                style: TextStyle(fontSize: 12, color: _light)),
          ],
        ),
      );
    }

    if (weather == null) {
      return Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _greenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.cloud_off_rounded, color: _green, size: 16),
            ),
            const SizedBox(width: 12),
            const Text('Weather unavailable',
                style: TextStyle(fontSize: 12, color: _light)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.lightBlue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Text(weather.weatherEmoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(weather.conditionDisplay,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _dark)),
                    const SizedBox(height: 2),
                    Text(
                      weather.location.isNotEmpty
                          ? weather.location
                          : 'Your farm',
                      style: const TextStyle(fontSize: 11, color: _light),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(weather.tempDisplay,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _dark)),
                  Text(DateFormat('dd MMM').format(DateTime.now()),
                      style: const TextStyle(fontSize: 10, color: _light)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.blue.withOpacity(0.15), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _weatherStat(Icons.water_drop_rounded, Colors.blue,
                  weather.humidityDisplay, 'Humidity'),
              _weatherStat(Icons.grain_rounded, Colors.indigo,
                  weather.rainfallDisplay, 'Rainfall'),
              _weatherStat(
                  Icons.air_rounded, Colors.cyan, weather.windDisplay, 'Wind'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weatherStat(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _dark)),
                Text(label, style: const TextStyle(fontSize: 9, color: _light)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  SUB-WIDGETS
// ══════════════════════════════════════════════════════════════════════════

class _Greeting extends StatelessWidget {
  final String? imageUrl;
  final String firstName;
  const _Greeting({this.imageUrl, required this.firstName});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    return Container(
      color: _white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Welcome back 👋',
                  style: TextStyle(
                      fontSize: 12,
                      color: _light,
                      fontWeight: FontWeight.w400)),
              const SizedBox(height: 2),
              Text(firstName,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                      letterSpacing: -0.5)),
            ]),
            Container(
              width: 44,
              height: 44,
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
                  ? Center(
                      child: Text(firstName[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _green)))
                  : null,
            ),
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

class _WalletCard extends StatelessWidget {
  final bool loading;
  final bool visible;
  final VoidCallback onToggle;
  final double totalEarnings, monthEarnings, totalLiters;
  final int collections;
  final NumberFormat fmt, fmtShort;

  const _WalletCard({
    required this.loading,
    required this.visible,
    required this.onToggle,
    required this.totalEarnings,
    required this.monthEarnings,
    required this.totalLiters,
    required this.collections,
    required this.fmt,
    required this.fmtShort,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _green.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(children: [
        Positioned(
          top: -20,
          right: 60,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          right: -30,
          child: Container(
            width: 120,
            height: 120,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('MY WALLET',
                          style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xBBFFFFFF))),
                      GestureDetector(
                        onTap: onToggle,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            visible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Total Earnings',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0x99FFFFFF),
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 5),
                  Text(
                    visible ? 'KSh ${fmt.format(totalEarnings)}' : 'KSh ••••••',
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.0),
                  ),
                  const SizedBox(height: 4),
                  const Text('Total accumulated earnings',
                      style: TextStyle(fontSize: 11, color: Color(0x80FFFFFF))),
                  const SizedBox(height: 16),
                  Row(children: [
                    _chip(
                      label: 'This Month',
                      value: visible
                          ? 'KSh ${fmtShort.format(monthEarnings)}'
                          : 'KSh ••••',
                    ),
                    const SizedBox(width: 8),
                    _chip(
                        label: 'Litres',
                        value: '${totalLiters.toStringAsFixed(1)}L'),
                    const SizedBox(width: 8),
                    _chip(label: 'Collections', value: '$collections'),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
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

class _FarmStrip extends StatelessWidget {
  final dynamic user;
  const _FarmStrip({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Row(children: [
        _chip(Icons.location_on_rounded, user.farmLocation ?? 'No location'),
        _vDiv(),
        _chip(Icons.pets_rounded, '${user.numberOfCows ?? 0} cows'),
        _vDiv(),
        _chip(Icons.landscape_rounded, user.farmSize ?? 'No size'),
      ]),
    );
  }

  Widget _chip(IconData icon, String label) => Expanded(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
                color: _greenLight, borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 12, color: _green),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: _mid, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  Widget _vDiv() => Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: _border);
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  const _ActionItem({
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });
}

class _ActionGrid extends StatelessWidget {
  final List<_ActionItem> items;
  const _ActionGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.3,
      children: items.map((it) => _ActionCard(item: it)).toList(),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final _ActionItem item;
  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: _green.withOpacity(0.08),
        child: Ink(
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.label,
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

class _RecentCollections extends StatelessWidget {
  final BuildContext context;
  const _RecentCollections({required this.context});

  @override
  Widget build(BuildContext context) {
    final milk = Provider.of<MilkCollectionProvider>(context);
    final recent = milk.collections.take(3).toList();
    final fmt = NumberFormat('#,##0');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('RECENT COLLECTIONS',
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
              child: Text('No recent collections',
                  style: TextStyle(color: _light, fontSize: 13)),
            ),
          ),
        )
      else
        ...recent.asMap().entries.map((e) {
          final col = e.value;
          final date = DateFormat('dd MMM · hh:mm a')
              .format(DateTime.tryParse(col.collectionDate) ?? DateTime.now());

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: _greenLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.water_drop_rounded,
                      color: _green, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Text('Morning Collection',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _dark)),
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle, color: _green),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text(
                            '$date · ${col.quantityInLiters.toStringAsFixed(1)}L',
                            style:
                                const TextStyle(fontSize: 11, color: _light)),
                      ]),
                ),
                Text('KSh ${fmt.format(col.totalAmount)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _green)),
              ]),
            ),
          );
        }).toList(),
    ]);
  }
}
