import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/milk_collection_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/milk_collection_provider.dart';
import '../../providers/farmers_provider.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';

class AllCollectionsScreen extends StatefulWidget {
  final String collectionDate;

  const AllCollectionsScreen({
    super.key,
    required this.collectionDate,
  });

  @override
  State<AllCollectionsScreen> createState() => _AllCollectionsScreenState();
}

class _AllCollectionsScreenState extends State<AllCollectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MilkCollectionModel> _allCollections = [];
  List<UserModel> _uncollectedFarmers = [];
  Map<int, UserModel> _farmerMap = {};
  bool _isLoading = false;
  String? _errorMessage;
  late String _selectedDate;

  // Last 7 days for the date selector
  late List<DateTime> _last7Days;

  static const List<String> _statusOrder = ['Recorded', 'Verified', 'Disputed'];
  static const Map<String, Color> _statusColors = {
    'Recorded': Color(0xFF3B82F6),
    'Verified': Color(0xFF22C55E),
    'Disputed': Color(0xFFEF4444),
  };
  static const Map<String, IconData> _statusIcons = {
    'Recorded': Icons.edit_note_rounded,
    'Verified': Icons.verified_rounded,
    'Disputed': Icons.warning_amber_rounded,
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.collectionDate;
    _tabController = TabController(length: 2, vsync: this);

    // Build last 7 days list
    final today = DateTime.now();
    _last7Days = List.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day - i),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final farmers = Provider.of<FarmersProvider>(context, listen: false);
      final milk = Provider.of<MilkCollectionProvider>(context, listen: false);

      if (auth.token == null) {
        setState(() => _errorMessage = 'Session expired. Please login again.');
        return;
      }

      await farmers.getAllFarmers(auth.token!);
      await milk.getCollectionsByDateRange(
          _selectedDate, _selectedDate, auth.token!);

      final collections = milk.collections;
      final allFarmers = farmers.farmers;
      final farmerMap = {for (var f in allFarmers) f.userId: f};
      final collectedIds = collections.map((c) => c.farmerID).toSet();
      final uncollected =
          allFarmers.where((f) => !collectedIds.contains(f.userId)).toList();

      final sorted = [...collections]..sort((a, b) => _statusOrder
          .indexOf(a.collectionStatus)
          .compareTo(_statusOrder.indexOf(b.collectionStatus)));

      setState(() {
        _allCollections = sorted;
        _uncollectedFarmers = uncollected;
        _farmerMap = farmerMap;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String get _displayDate =>
      DateFormat('EEEE, dd MMMM yyyy').format(DateTime.parse(_selectedDate));

  bool get _isToday =>
      _selectedDate == DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('All Collections',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(children: [
            // ── Date display ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: AppConstants.primaryColor.withOpacity(0.85),
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
              child: Row(children: [
                const Icon(Icons.calendar_today,
                    color: Colors.white70, size: 13),
                const SizedBox(width: 6),
                Text(_displayDate,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                if (!_isToday)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Past',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ]),
            ),

            // ── Last 7 days selector ──────────────────────────────────────
            Container(
              height: 48,
              color: AppConstants.primaryColor.withOpacity(0.85),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _last7Days.length,
                itemBuilder: (context, index) {
                  final day = _last7Days[index];
                  final dateStr = DateFormat('yyyy-MM-dd').format(day);
                  final isSelected = _selectedDate == dateStr;
                  final isToday = index == 0;

                  return GestureDetector(
                    onTap: () {
                      if (!isSelected) {
                        setState(() => _selectedDate = dateStr);
                        _loadData();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isToday
                                ? 'Today'
                                : DateFormat('EEE dd').format(day),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppConstants.primaryColor
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Tabs ──────────────────────────────────────────────────────
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.water_drop_rounded, size: 15),
                      const SizedBox(width: 6),
                      Text('Collected (${_allCollections.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_off_rounded, size: 15),
                      const SizedBox(width: 6),
                      Text('Pending (${_uncollectedFarmers.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ]),
        ),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: AppConstants.primaryColor))
          : _errorMessage != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCollectionsTab(),
                    _buildUncollectedTab(),
                  ],
                ),
    );
  }

  // ── Summary bar ───────────────────────────────────────────────────────────
  Widget _buildSummaryBar() {
    final recorded =
        _allCollections.where((c) => c.collectionStatus == 'Recorded').length;
    final verified =
        _allCollections.where((c) => c.collectionStatus == 'Verified').length;
    final disputed =
        _allCollections.where((c) => c.collectionStatus == 'Disputed').length;
    final totalLiters =
        _allCollections.fold<double>(0, (s, c) => s + c.quantityInLiters);
    final totalAmount =
        _allCollections.fold<double>(0, (s, c) => s + c.totalAmount);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(
            _isToday ? "Today's Summary" : _displayDate,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B)),
          ),
          if (!_isToday) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Past Day',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _summaryChip('${totalLiters.toStringAsFixed(1)}L', 'Total Litres',
              Icons.water_drop_rounded, AppConstants.primaryColor),
          const SizedBox(width: 8),
          _summaryChip('KSh ${NumberFormat('#,##0').format(totalAmount)}',
              'Total Value', Icons.payments_rounded, Colors.green),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _statusCount('Recorded', recorded, _statusColors['Recorded']!),
          const SizedBox(width: 8),
          _statusCount('Verified', verified, _statusColors['Verified']!),
          const SizedBox(width: 8),
          _statusCount('Disputed', disputed, _statusColors['Disputed']!),
        ]),
      ]),
    );
  }

  Widget _summaryChip(String value, String label, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: color)),
                  Text(label,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
          ]),
        ),
      );

  Widget _statusCount(String label, int count, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(children: [
            Text('$count',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ]),
        ),
      );

  // ── Collections tab ───────────────────────────────────────────────────────
  Widget _buildCollectionsTab() {
    if (_allCollections.isEmpty) {
      return _buildEmptyState(
        icon: Icons.water_drop_outlined,
        title: 'No collections',
        subtitle: _isToday
            ? 'No milk has been recorded for today'
            : 'No collections on ${DateFormat('dd MMM yyyy').format(DateTime.parse(_selectedDate))}',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppConstants.primaryColor,
      child: ListView(children: [
        _buildSummaryBar(),
        ..._statusOrder.map((status) {
          final group = _allCollections
              .where((c) => c.collectionStatus == status)
              .toList();
          if (group.isEmpty) return const SizedBox.shrink();
          return _buildStatusGroup(status, group);
        }),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildStatusGroup(String status, List<MilkCollectionModel> items) {
    final color = _statusColors[status]!;
    final icon = _statusIcons[status]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text('$status (${items.length})',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ]),
          ),
        ),
        ...items.map((c) => _buildCollectionCard(c)),
      ],
    );
  }

  Widget _buildCollectionCard(MilkCollectionModel c) {
    final color =
        _statusColors[c.collectionStatus] ?? AppConstants.primaryColor;
    final icon = _statusIcons[c.collectionStatus] ?? Icons.water_drop_rounded;
    final farmer = _farmerMap[c.farmerID];
    final name = farmer != null
        ? '${farmer.firstName} ${farmer.lastName}'
        : 'Farmer #${c.farmerID}';
    final initial = farmer?.firstName.isNotEmpty == true
        ? farmer!.firstName[0].toUpperCase()
        : '#';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Status strip
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppConstants.primaryColor.withOpacity(0.08),
            backgroundImage:
                (farmer?.imageUrl != null && farmer!.imageUrl!.isNotEmpty)
                    ? NetworkImage(
                        farmer.imageUrl!.startsWith('http')
                            ? farmer.imageUrl!
                            : '${AppConstants.baseUrl}${farmer.imageUrl!}',
                      )
                    : null,
            child: (farmer?.imageUrl == null || farmer!.imageUrl!.isEmpty)
                ? Text(initial,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                        fontSize: 16))
                : null,
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1E293B)),
                        overflow: TextOverflow.ellipsis),
                  ),
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 11, color: color),
                      const SizedBox(width: 4),
                      Text(c.collectionStatus,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  _miniStat(Icons.water_drop_rounded, '${c.quantityInLiters}L',
                      Colors.blue),
                  const SizedBox(width: 12),
                  _miniStat(
                      Icons.payments_rounded,
                      'KSh ${NumberFormat('#,##0').format(c.totalAmount)}',
                      Colors.green),
                  if (c.collectionTime != null) ...[
                    const SizedBox(width: 12),
                    _miniStat(Icons.access_time_rounded, c.collectionTime!,
                        Colors.orange),
                  ],
                ]),
                if (c.notes != null && c.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(c.notes!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500)),
        ],
      );

  // ── Uncollected tab ───────────────────────────────────────────────────────
  Widget _buildUncollectedTab() {
    if (_uncollectedFarmers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'All farmers collected!',
        subtitle: 'Every farmer has been collected 🎉',
        color: Colors.green,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppConstants.primaryColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_uncollectedFarmers.length} farmer${_uncollectedFarmers.length > 1 ? 's have' : ' has'} not been collected',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          ),
          ..._uncollectedFarmers.map((f) => _buildUncollectedCard(f)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUncollectedCard(UserModel farmer) {
    final initials = ((farmer.firstName.isNotEmpty ? farmer.firstName[0] : '') +
            (farmer.lastName.isNotEmpty ? farmer.lastName[0] : ''))
        .toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.orange.withOpacity(0.1),
          backgroundImage:
              (farmer.imageUrl != null && farmer.imageUrl!.isNotEmpty)
                  ? NetworkImage(
                      farmer.imageUrl!.startsWith('http')
                          ? farmer.imageUrl!
                          : '${AppConstants.baseUrl}${farmer.imageUrl!}',
                    )
                  : null,
          child: (farmer.imageUrl == null || farmer.imageUrl!.isEmpty)
              ? Text(initials.isEmpty ? '?' : initials,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontSize: 15))
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${farmer.firstName} ${farmer.lastName}'.trim(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 3),
              Text(farmer.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis),
              if (farmer.farmLocation != null) ...[
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.location_on_rounded,
                      size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 3),
                  Text(farmer.farmLocation!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ]),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: const Text('Pending',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange)),
        ),
      ]),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color color = AppConstants.primaryColor,
  }) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 56, color: color.withOpacity(0.5)),
              ),
              const SizedBox(height: 20),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Widget _buildErrorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
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
