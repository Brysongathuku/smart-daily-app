import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milk_collection_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/milk_collection_provider.dart';
import '../../providers/farmers_provider.dart';
import '../../utils/constants.dart';

const _bg     = Color(0xFFF8FAFC);
const _white  = Color(0xFFFFFFFF);
const _green  = Color(0xFF16A34A);
const _border = Color(0xFFE2E8F0);
const _dark   = Color(0xFF0F172A);
const _mid    = Color(0xFF475569);
const _light  = Color(0xFF94A3B8);

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool               _isLoading = false;
  String?            _error;

  // Period toggle: 0=Day, 1=Week, 2=Month
  int _period = 2;

  List<MilkCollectionModel> _collections = [];
  List<UserModel>           _farmers     = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final auth    = Provider.of<AuthProvider>(context, listen: false);
      final milk    = Provider.of<MilkCollectionProvider>(context, listen: false);
      final farmers = Provider.of<FarmersProvider>(context, listen: false);
      if (auth.token == null) return;
      await milk.getAllCollections(auth.token!);
      await farmers.getAllFarmers(auth.token!);
      setState(() {
        _collections = milk.collections;
        _farmers     = farmers.farmers;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Filter collections by period ──────────────────────────────────────────
  List<MilkCollectionModel> get _filtered {
    final now = DateTime.now();
    return _collections.where((c) {
      final d = DateTime.tryParse(c.collectionDate);
      if (d == null) return false;
      switch (_period) {
        case 0: // Today
          return d.year == now.year &&
              d.month == now.month &&
              d.day == now.day;
        case 1: // This week
          final weekStart =
              now.subtract(Duration(days: now.weekday - 1));
          return d.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              d.isBefore(now.add(const Duration(days: 1)));
        case 2: // This month
          return d.year == now.year && d.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  String get _periodLabel =>
      ['Today', 'This Week', 'This Month'][_period];

  // ── Aggregate stats ────────────────────────────────────────────────────────
  double get _totalLitres =>
      _filtered.fold(0.0, (s, c) => s + c.quantityInLiters);
  double get _totalRevenue =>
      _filtered.fold(0.0, (s, c) => s + c.totalAmount);
  int    get _totalCollections => _filtered.length;
  double get _avgPerCollection =>
      _totalCollections > 0 ? _totalLitres / _totalCollections : 0;

  // ── Per-farmer breakdown ──────────────────────────────────────────────────
  List<Map<String, dynamic>> get _farmerBreakdown {
    final farmerMap = {for (var f in _farmers) f.userId: f};
    final Map<int, Map<String, dynamic>> map = {};

    for (final c in _filtered) {
      map.putIfAbsent(c.farmerID, () => {
        'farmer':      farmerMap[c.farmerID],
        'litres':      0.0,
        'revenue':     0.0,
        'collections': 0,
      });
      map[c.farmerID]!['litres']      = (map[c.farmerID]!['litres'] as double) + c.quantityInLiters;
      map[c.farmerID]!['revenue']     = (map[c.farmerID]!['revenue'] as double) + c.totalAmount;
      map[c.farmerID]!['collections'] = (map[c.farmerID]!['collections'] as int) + 1;
    }

    final list = map.values.toList();
    list.sort((a, b) =>
        (b['litres'] as double).compareTo(a['litres'] as double));
    return list;
  }

  // ── Top 5 farmers by litres ───────────────────────────────────────────────
  List<Map<String, dynamic>> get _topFarmers =>
      _farmerBreakdown.take(5).toList();

  // ── Daily trend (last 7 days of this month) ───────────────────────────────
  List<Map<String, dynamic>> get _dailyTrend {
    final now  = DateTime.now();
    final days = List.generate(7, (i) =>
        DateTime(now.year, now.month, now.day - (6 - i)));

    return days.map((day) {
      final dayStr = DateFormat('yyyy-MM-dd').format(day);
      final dayCollections = _collections.where(
          (c) => c.collectionDate == dayStr).toList();
      return {
        'date':    day,
        'label':   DateFormat('dd MMM').format(day),
        'litres':  dayCollections.fold<double>(
            0.0, (s, c) => s + c.quantityInLiters),
        'revenue': dayCollections.fold<double>(
            0.0, (s, c) => s + c.totalAmount),
        'count':   dayCollections.length,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _white,
        foregroundColor: _dark,
        title: const Text('Reports',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _dark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _green,
          unselectedLabelColor: _light,
          indicatorColor: _green,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Farmers'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _green))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildFarmersTab(),
                    _buildTrendsTab(),
                  ],
                ),
    );
  }

  // ── Period selector ───────────────────────────────────────────────────────
  Widget _buildPeriodSelector() => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(children: ['Today', 'This Week', 'This Month']
            .asMap()
            .entries
            .map((e) {
          final selected = _period == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _period = e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _green : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(e.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : _mid)),
              ),
            ),
          );
        }).toList()),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // OVERVIEW TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewTab() {
    final fmt    = NumberFormat('#,##0');
    final fmtDec = NumberFormat('#,##0.0');

    return RefreshIndicator(
      onRefresh: _load,
      color: _green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('$_periodLabel Summary',
                  style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w700,
                      color: _light)),
            ),
            const SizedBox(height: 10),

            // ── 4 stat cards ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount:   2,
                shrinkWrap:       true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing:  10,
                childAspectRatio: 1.6,
                children: [
                  _statCard(
                    icon:  Icons.water_drop_rounded,
                    color: const Color(0xFF3B82F6),
                    label: 'Total Litres',
                    value: '${fmtDec.format(_totalLitres)}L',
                    sub:   '$_totalCollections sessions',
                  ),
                  _statCard(
                    icon:  Icons.payments_rounded,
                    color: _green,
                    label: 'Total Revenue',
                    value: 'KSh ${fmt.format(_totalRevenue)}',
                    sub:   'KSh ${fmt.format(_totalRevenue ~/ (_totalCollections > 0 ? _totalCollections : 1))}/session',
                  ),
                  _statCard(
                    icon:  Icons.people_rounded,
                    color: const Color(0xFF8B5CF6),
                    label: 'Active Farmers',
                    value: '${_farmerBreakdown.length}',
                    sub:   'of ${_farmers.length} total',
                  ),
                  _statCard(
                    icon:  Icons.trending_up_rounded,
                    color: const Color(0xFFF97316),
                    label: 'Avg per Session',
                    value: '${fmtDec.format(_avgPerCollection)}L',
                    sub:   'KSh ${fmt.format(_totalCollections > 0 ? _totalRevenue / _totalCollections : 0)}/session',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Top farmers preview ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('TOP PERFORMERS',
                  style: const TextStyle(
                      fontSize: 9,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w700,
                      color: _light)),
            ),
            const SizedBox(height: 10),
            ..._topFarmers.take(3).map((f) => _buildFarmerRow(f, true)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color    color,
    required String   label,
    required String   value,
    required String   sub,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color:      Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset:     const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color:        color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _dark)),
            Text(sub,
                style: const TextStyle(
                    fontSize: 10, color: _light)),
          ],
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // FARMERS TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFarmersTab() {
    final breakdown = _farmerBreakdown;

    return RefreshIndicator(
      onRefresh: _load,
      color: _green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'PER-FARMER BREAKDOWN — $_periodLabel',
                style: const TextStyle(
                    fontSize: 9,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w700,
                    color: _light),
              ),
            ),
            const SizedBox(height: 10),

            if (breakdown.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(children: [
                    Icon(Icons.people_outline,
                        size: 48, color: _light.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text('No collections for $_periodLabel',
                        style: const TextStyle(
                            fontSize: 14, color: _light)),
                  ]),
                ),
              )
            else ...[
              // Table header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(children: [
                  const SizedBox(width: 36),
                  const Expanded(
                      flex: 3,
                      child: Text('Farmer',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _light))),
                  const Expanded(
                      flex: 2,
                      child: Text('Litres',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _light))),
                  const Expanded(
                      flex: 2,
                      child: Text('Revenue',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _light))),
                ]),
              ),
              ...breakdown.asMap().entries.map(
                  (e) => _buildFarmerRow(e.value, false, rank: e.key + 1)),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerRow(Map<String, dynamic> data, bool compact,
      {int? rank}) {
    final farmer      = data['farmer'] as UserModel?;
    final litres      = data['litres']  as double;
    final revenue     = data['revenue'] as double;
    final collections = data['collections'] as int;
    final name        = farmer != null
        ? '${farmer.firstName} ${farmer.lastName}'
        : 'Unknown';
    final initial     = farmer?.firstName.isNotEmpty == true
        ? farmer!.firstName[0].toUpperCase()
        : '?';
    final fmt         = NumberFormat('#,##0');

    // Bar width relative to top farmer
    final maxLitres   = _farmerBreakdown.isNotEmpty
        ? (_farmerBreakdown.first['litres'] as double)
        : 1.0;
    final barFraction = maxLitres > 0 ? litres / maxLitres : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(children: [
        Row(children: [
          // Rank or avatar
          rank != null && rank <= 3
              ? Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: rank == 1
                        ? const Color(0xFFFFD700)
                        : rank == 2
                            ? const Color(0xFFC0C0C0)
                            : const Color(0xFFCD7F32),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('$rank',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                )
              : CircleAvatar(
                  radius: 14,
                  backgroundColor: _green.withOpacity(0.1),
                  backgroundImage: (farmer?.imageUrl != null &&
                          farmer!.imageUrl!.isNotEmpty)
                      ? NetworkImage(
                          farmer.imageUrl!.startsWith('http')
                              ? farmer.imageUrl!
                              : '${AppConstants.baseUrl}${farmer.imageUrl!}',
                        )
                      : null,
                  child: (farmer?.imageUrl == null ||
                          farmer!.imageUrl!.isEmpty)
                      ? Text(initial,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _green))
                      : null,
                ),
          const SizedBox(width: 10),

          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _dark),
                    overflow: TextOverflow.ellipsis),
                Text('$collections collection${collections != 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 10, color: _light)),
              ],
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              '${litres.toStringAsFixed(1)}L',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B82F6)),
            ),
          ),

          Expanded(
            flex: 2,
            child: Text(
              'KSh ${fmt.format(revenue)}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _green),
            ),
          ),
        ]),

        // Progress bar
        if (!compact) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           barFraction,
              minHeight:       5,
              backgroundColor: _green.withOpacity(0.08),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
        ],
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TRENDS TAB
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTrendsTab() {
    final trend  = _dailyTrend;
    final maxL   = trend.isEmpty
        ? 1.0
        : trend.map((d) => d['litres'] as double).reduce(
            (a, b) => a > b ? a : b);
    final fmt    = NumberFormat('#,##0');
    final fmtDec = NumberFormat('#,##0.0');

    return RefreshIndicator(
      onRefresh: _load,
      color: _green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text('LAST 7 DAYS TREND',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w700,
                      color: _light)),
            ),
            const SizedBox(height: 12),

            // ── Bar chart ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bar_chart_rounded,
                          color: Color(0xFF3B82F6), size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Litres Collected',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _dark)),
                  ]),
                  const SizedBox(height: 20),

                  // Bars
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: trend.map((d) {
                      final litres   = d['litres'] as double;
                      final fraction = maxL > 0 ? litres / maxL : 0.0;
                      final isToday  = d['label'] ==
                          DateFormat('dd MMM').format(DateTime.now());

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 3),
                          child: Column(children: [
                            Text(
                              litres > 0
                                  ? '${fmtDec.format(litres)}'
                                  : '',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: isToday
                                      ? _green
                                      : const Color(0xFF3B82F6)),
                            ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 500),
                              height: 80 * fraction + 4,
                              decoration: BoxDecoration(
                                color: isToday
                                    ? _green
                                    : const Color(0xFF3B82F6)
                                        .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              (d['label'] as String)
                                  .replaceAll(' ', '\n'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 8,
                                  color:
                                      isToday ? _green : _light,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal),
                            ),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Revenue trend ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.payments_rounded,
                          color: _green, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Revenue (KSh)',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _dark)),
                  ]),
                  const SizedBox(height: 14),
                  ...trend.map((d) {
                    final revenue = d['revenue'] as double;
                    final maxRev  = trend
                        .map((x) => x['revenue'] as double)
                        .reduce((a, b) => a > b ? a : b);
                    final frac = maxRev > 0 ? revenue / maxRev : 0.0;
                    final isToday = d['label'] ==
                        DateFormat('dd MMM').format(DateTime.now());

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        SizedBox(
                          width: 48,
                          child: Text(d['label'] as String,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isToday ? _green : _mid,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value:           frac,
                              minHeight:       10,
                              backgroundColor: _green.withOpacity(0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  isToday ? _green : _green.withOpacity(0.5)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 72,
                          child: Text(
                            'KSh ${fmt.format(revenue)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isToday ? _green : _mid),
                          ),
                        ),
                      ]),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Daily summary table ────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.table_chart_rounded,
                          color: Color(0xFFF97316), size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Daily Breakdown',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _dark)),
                  ]),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _bg,
                    border: Border(
                        top:    BorderSide(color: _border),
                        bottom: BorderSide(color: _border)),
                  ),
                  child: Row(children: const [
                    Expanded(flex: 2,
                        child: Text('Date',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _light))),
                    Expanded(flex: 1,
                        child: Text('Sessions',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _light))),
                    Expanded(flex: 2,
                        child: Text('Litres',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _light))),
                    Expanded(flex: 2,
                        child: Text('Revenue',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _light))),
                  ]),
                ),
                ...trend.reversed.map((d) {
                  final isToday = d['label'] ==
                      DateFormat('dd MMM').format(DateTime.now());
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isToday
                          ? _green.withOpacity(0.04)
                          : Colors.transparent,
                      border: Border(
                          bottom: BorderSide(
                              color: _border, width: 0.5)),
                    ),
                    child: Row(children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          isToday ? 'Today' : d['label'] as String,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color:
                                  isToday ? _green : _dark),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${d['count']}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  isToday ? _green : _mid),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${fmtDec.format(d['litres'])}L',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isToday
                                  ? _green
                                  : const Color(0xFF3B82F6)),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'KSh ${fmt.format(d['revenue'])}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isToday ? _green : _mid),
                        ),
                      ),
                    ]),
                  );
                }),
              ]),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
}