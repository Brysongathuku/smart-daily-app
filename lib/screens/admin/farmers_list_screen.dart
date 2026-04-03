import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farmers_provider.dart';
import '../../providers/milk_collection_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_overlay.dart';
import '../farmer/ai_recommendations_screen.dart';
import 'record_milk_screen.dart';

class FarmersListScreen extends StatefulWidget {
  final String collectionDate;

  const FarmersListScreen({
    Key? key,
    required this.collectionDate,
  }) : super(key: key);

  @override
  State<FarmersListScreen> createState() => _FarmersListScreenState();
}

class _FarmersListScreenState extends State<FarmersListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final farmers = Provider.of<FarmersProvider>(context, listen: false);
    final milk = Provider.of<MilkCollectionProvider>(context, listen: false);

    if (auth.token == null) {
      if (mounted) showSnackBar(context, 'Session expired.', isError: true);
      return;
    }

    await farmers.getAllFarmers(auth.token!);

    // Load today's collections so we can check per-farmer count
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await milk.getCollectionsByDateRange(today, today, auth.token!);

    if (farmers.errorMessage != null && mounted) {
      showSnackBar(context, farmers.errorMessage!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmersProvider = Provider.of<FarmersProvider>(context);
    final milkProvider = Provider.of<MilkCollectionProvider>(context);
    final displayDate = DateFormat('EEEE, dd MMMM yyyy')
        .format(DateTime.parse(widget.collectionDate));

    final filteredFarmers = farmersProvider.farmers.where((f) {
      final q = _searchQuery.toLowerCase();
      return f.firstName.toLowerCase().contains(q) ||
          f.lastName.toLowerCase().contains(q) ||
          f.email.toLowerCase().contains(q) ||
          (f.farmLocation ?? '').toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Record Collection',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            width: double.infinity,
            color: AppConstants.primaryColor.withOpacity(0.85),
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: Row(children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 13),
              const SizedBox(width: 6),
              Text(displayDate,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
        ),
      ),
      body: LoadingOverlay(
        isLoading: farmersProvider.isLoading,
        message: 'Loading farmers...',
        child: Column(children: [
          // ── Search bar ──────────────────────────────────────────────────
          Container(
            color: AppConstants.primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search farmers...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: AppConstants.primaryColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''))
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ── Farmer count ────────────────────────────────────────────────
          if (!farmersProvider.isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF0F4F0),
              child: Text(
                '${filteredFarmers.length} farmer${filteredFarmers.length != 1 ? 's' : ''} found',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
            ),

          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppConstants.primaryColor,
              child: filteredFarmers.isEmpty && !farmersProvider.isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filteredFarmers.length,
                      itemBuilder: (context, index) {
                        final farmer = filteredFarmers[index];
                        final todayCount =
                            milkProvider.getTodayCollectionCount(farmer.userId);
                        final isMaxReached = todayCount >= 2;
                        return _buildFarmerCard(
                            context, farmer, todayCount, isMaxReached);
                      },
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFarmerCard(
    BuildContext context,
    dynamic farmer,
    int todayCount,
    bool isMaxReached,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: [
        // ── Tap area ────────────────────────────────────────────────────
        InkWell(
          onTap: isMaxReached
              ? () => _showMaxReachedDialog(context, farmer.fullName)
              : () => _navigateToRecord(context, farmer),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isMaxReached
                          ? Colors.grey.withOpacity(0.3)
                          : AppConstants.primaryColor.withOpacity(0.3),
                      width: 2),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: isMaxReached
                      ? Colors.grey.withOpacity(0.08)
                      : AppConstants.primaryColor.withOpacity(0.08),
                  backgroundImage:
                      (farmer.imageUrl != null && farmer.imageUrl!.isNotEmpty)
                          ? NetworkImage(
                              farmer.imageUrl!.startsWith('http')
                                  ? farmer.imageUrl!
                                  : '${AppConstants.baseUrl}${farmer.imageUrl!}',
                            )
                          : null,
                  child: (farmer.imageUrl == null || farmer.imageUrl!.isEmpty)
                      ? Text(
                          farmer.firstName.isNotEmpty
                              ? farmer.firstName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isMaxReached
                                  ? Colors.grey
                                  : AppConstants.primaryColor),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          farmer.fullName,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isMaxReached
                                  ? Colors.grey
                                  : const Color(0xFF1A1A2E)),
                        ),
                      ),
                      // Collection count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isMaxReached
                              ? Colors.grey.withOpacity(0.12)
                              : AppConstants.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$todayCount/2 today',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isMaxReached
                                  ? Colors.grey
                                  : AppConstants.primaryColor),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 3),
                    Text(farmer.email,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(children: [
                      if (farmer.farmLocation != null)
                        _chip(Icons.location_on_rounded, farmer.farmLocation!,
                            Colors.teal),
                      const SizedBox(width: 6),
                      _chip(
                          Icons.pets_rounded,
                          '${farmer.numberOfCows ?? 0} cows',
                          AppConstants.primaryColor),
                    ]),

                    // Max reached banner
                    if (isMaxReached) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.block_rounded,
                              size: 12, color: Colors.orange),
                          const SizedBox(width: 6),
                          const Text(
                            'Max 2 collections reached for today',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500),
                          ),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isMaxReached
                      ? Colors.grey.withOpacity(0.1)
                      : AppConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMaxReached
                      ? Icons.block_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isMaxReached ? Colors.grey : AppConstants.primaryColor,
                ),
              ),
            ]),
          ),
        ),

        // ── Divider ──────────────────────────────────────────────────────
        Divider(height: 1, color: Colors.grey[100], indent: 14, endIndent: 14),

        // ── Action buttons ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Expanded(
              child: _actionBtn(
                icon: isMaxReached
                    ? Icons.check_circle_rounded
                    : Icons.water_drop_rounded,
                label: isMaxReached ? 'Collected ✓' : 'Record Milk',
                color: isMaxReached ? Colors.grey : AppConstants.primaryColor,
                disabled: isMaxReached,
                onTap: isMaxReached
                    ? () => _showMaxReachedDialog(context, farmer.fullName)
                    : () => _navigateToRecord(context, farmer),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                icon: Icons.auto_awesome_rounded,
                label: 'AI Report',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AiRecommendationsScreen(farmerID: farmer.userId),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _navigateToRecord(BuildContext context, dynamic farmer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecordMilkScreen(
          farmer: farmer,
          collectionDate: widget.collectionDate,
        ),
      ),
    ).then((_) => _loadData()); // refresh counts after returning
  }

  void _showMaxReachedDialog(BuildContext context, String farmerName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.block_rounded, color: Colors.orange, size: 22),
          SizedBox(width: 10),
          Text('Limit Reached',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: Text(
          '$farmerName has already been collected twice today '
          '(Morning & Evening). No more collections allowed for today.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.withOpacity(0.06)
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: disabled
                  ? Colors.grey.withOpacity(0.2)
                  : color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: disabled ? Colors.grey : color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: disabled ? Colors.grey : color)),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _buildEmptyState() => ListView(children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.people_outline,
                      size: 64,
                      color: AppConstants.primaryColor.withOpacity(0.5)),
                ),
                const SizedBox(height: 20),
                const Text('No farmers found',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Try a different search term'
                      : 'Farmers who register will appear here',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]);
}
