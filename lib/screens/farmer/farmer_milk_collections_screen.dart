import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milk_collection_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/milk_collection_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_overlay.dart';

class FarmerMilkCollectionsScreen extends StatefulWidget {
  const FarmerMilkCollectionsScreen({Key? key}) : super(key: key);

  @override
  State<FarmerMilkCollectionsScreen> createState() =>
      _FarmerMilkCollectionsScreenState();
}

class _FarmerMilkCollectionsScreenState
    extends State<FarmerMilkCollectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCollections());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final milkProvider =
        Provider.of<MilkCollectionProvider>(context, listen: false);
    if (authProvider.token != null && authProvider.currentUser != null) {
      await milkProvider.getCollectionsByFarmer(
        authProvider.currentUser!.userId,
        authProvider.token!,
      );
    }
  }

  List<MilkCollectionModel> _getLast7Days(
      List<MilkCollectionModel> collections) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 6));
    final cutoffDate = DateTime(cutoff.year, cutoff.month, cutoff.day);
    return collections.where((c) {
      final d = DateTime.tryParse(c.collectionDate);
      if (d == null) return false;
      final day = DateTime(d.year, d.month, d.day);
      return !day.isBefore(cutoffDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final milkProvider = Provider.of<MilkCollectionProvider>(context);
    final last7 = _getLast7Days(milkProvider.collections);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: LoadingOverlay(
        isLoading: milkProvider.isLoading,
        message: 'Loading collections...',
        child: RefreshIndicator(
          onRefresh: _loadCollections,
          color: AppConstants.primaryColor,
          child: milkProvider.collections.isEmpty && !milkProvider.isLoading
              ? _buildEmptyState()
              : NestedScrollView(
                  headerSliverBuilder: (context, _) => [
                    SliverToBoxAdapter(
                      child: _buildSummaryCard(milkProvider),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: AppConstants.primaryColor,
                          unselectedLabelColor: Colors.grey[500],
                          indicatorColor: AppConstants.primaryColor,
                          indicatorWeight: 3,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          tabs: [
                            Tab(
                              text:
                                  'All Collections (${milkProvider.collections.length})',
                            ),
                            Tab(text: 'Last 7 Days (${last7.length})'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCollectionsList(milkProvider.collections),
                      _buildLast7DaysView(last7),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'My Milk Collections',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadCollections,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildSummaryCard(MilkCollectionProvider provider) {
    final totalLiters = provider.collections
        .fold<double>(0.0, (s, i) => s + i.quantityInLiters);
    final totalAmount =
        provider.collections.fold<double>(0.0, (s, i) => s + i.totalAmount);
    final last7 = _getLast7Days(provider.collections);
    final last7Liters =
        last7.fold<double>(0.0, (s, i) => s + i.quantityInLiters);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppConstants.primaryColor.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Overall Summary',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSumStat('${provider.collections.length}', 'Collections',
                  Icons.list_alt),
              _buildDivider(),
              _buildSumStat('${totalLiters.toStringAsFixed(1)}L', 'Total Milk',
                  Icons.opacity),
              _buildDivider(),
              _buildSumStat('KSh ${_shortAmount(totalAmount)}', 'Earnings',
                  Icons.payments),
            ],
          ),
          const Divider(color: Colors.white24, height: 28),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white60, size: 14),
              const SizedBox(width: 6),
              Text(
                'Last 7 days: ${last7Liters.toStringAsFixed(1)} L from ${last7.length} collections',
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSumStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }

  Widget _buildDivider() => Container(
        height: 48,
        width: 1,
        color: Colors.white24,
      );

  String _shortAmount(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  // ─── All Collections List ─────────────────────────────────────────────────

  Widget _buildCollectionsList(List<MilkCollectionModel> collections) {
    if (collections.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: collections.length,
      itemBuilder: (_, i) => _buildCollectionCard(collections[i]),
    );
  }

  // ─── Last 7 Days View ─────────────────────────────────────────────────────

  Widget _buildLast7DaysView(List<MilkCollectionModel> last7) {
    if (last7.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No collections in the last 7 days',
                style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          ],
        ),
      );
    }

    // Build per-day buckets for last 7 days
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final Map<String, double> dailyLiters = {};
    for (final day in days) {
      dailyLiters[DateFormat('yyyy-MM-dd').format(day)] = 0.0;
    }
    for (final c in last7) {
      final d = DateTime.tryParse(c.collectionDate);
      if (d == null) continue;
      final key = DateFormat('yyyy-MM-dd').format(d);
      if (dailyLiters.containsKey(key)) {
        dailyLiters[key] = dailyLiters[key]! + c.quantityInLiters;
      }
    }

    final maxLiters =
        dailyLiters.values.fold<double>(0.0, (m, v) => v > m ? v : m);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bar chart card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.bar_chart_rounded,
                          color: AppConstants.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Daily Milk (Litres)',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 160,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: dailyLiters.entries.map((e) {
                      final date = DateTime.tryParse(e.key) ?? DateTime.now();
                      final ratio = maxLiters > 0 ? e.value / maxLiters : 0.0;
                      final isToday =
                          DateFormat('yyyy-MM-dd').format(DateTime.now()) ==
                              e.key;
                      return Expanded(
                        child: _buildBar(
                          label: DateFormat('E').format(date),
                          value: e.value,
                          ratio: ratio,
                          isToday: isToday,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 7-day stats row
          _build7DayStats(last7),

          const SizedBox(height: 20),

          // Collections list for 7 days
          const Text(
            'Collections This Week',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 12),
          ...last7.map((c) => _buildCollectionCard(c)).toList(),
        ],
      ),
    );
  }

  Widget _buildBar(
      {required String label,
      required double value,
      required double ratio,
      required bool isToday}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (value > 0)
            Text(
              '${value.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isToday ? AppConstants.primaryColor : Colors.grey[600],
              ),
            ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            height: ratio * 110 + (value > 0 ? 8 : 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isToday
                    ? [AppConstants.primaryColor, AppConstants.secondaryColor]
                    : [
                        AppConstants.primaryColor.withOpacity(0.4),
                        AppConstants.primaryColor.withOpacity(0.65),
                      ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: isToday ? AppConstants.primaryColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build7DayStats(List<MilkCollectionModel> last7) {
    final totalLiters =
        last7.fold<double>(0.0, (s, i) => s + i.quantityInLiters);
    final totalAmount = last7.fold<double>(0.0, (s, i) => s + i.totalAmount);
    final avgPerDay = last7.isEmpty ? 0.0 : totalLiters / 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMiniStat('${totalLiters.toStringAsFixed(1)} L', '7-Day Total',
              AppConstants.primaryColor),
          _buildVertDivider(),
          _buildMiniStat(
              '${avgPerDay.toStringAsFixed(1)} L', 'Avg / Day', Colors.orange),
          _buildVertDivider(),
          _buildMiniStat(
              'KSh ${_shortAmount(totalAmount)}', 'Earned', Colors.green),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16, color: color)),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildVertDivider() => Container(
        height: 36,
        width: 1,
        color: Colors.grey[200],
      );

  // ─── Collection Card ──────────────────────────────────────────────────────

  Widget _buildCollectionCard(MilkCollectionModel collection) {
    final date = DateTime.tryParse(collection.collectionDate) ?? DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy').format(date);
    final dayStr = DateFormat('EEE').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dayStr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                _buildStatusChip(collection.collectionStatus),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                          'Quantity',
                          '${collection.quantityInLiters} L',
                          Icons.water_drop_rounded),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                          'Price / L',
                          'KSh ${collection.pricePerLiter.toStringAsFixed(2)}',
                          Icons.sell_rounded),
                    ),
                    Expanded(
                      child: _buildInfoItem('Grade', collection.qualityGrade,
                          Icons.grade_rounded),
                    ),
                  ],
                ),
                if (collection.fatContent != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem('Fat %',
                            '${collection.fatContent}%', Icons.science_rounded),
                      ),
                      if (collection.temperature != null)
                        Expanded(
                          child: _buildInfoItem(
                              'Temp',
                              '${collection.temperature}°C',
                              Icons.thermostat_rounded),
                        ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Amount',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600])),
                    Text(
                      'KSh ${collection.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                if (collection.notes != null &&
                    collection.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note_rounded,
                            size: 15, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            collection.notes!,
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppConstants.primaryColor),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    final colors = {
      'recorded': Colors.blue,
      'verified': Colors.green,
      'disputed': Colors.red,
    };
    final color = colors[status.toLowerCase()] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        status,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.water_drop_outlined,
                size: 56, color: Colors.grey[350]),
          ),
          const SizedBox(height: 20),
          const Text('No milk collections yet',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333))),
          const SizedBox(height: 8),
          Text(
            'Collections recorded by admin will appear here',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadCollections,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pinned TabBar delegate ──────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          tabBar,
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
