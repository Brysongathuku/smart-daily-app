import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/farmers_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFarmers());
  }

  Future<void> _loadFarmers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final farmersProvider =
        Provider.of<FarmersProvider>(context, listen: false);

    if (authProvider.token != null) {
      await farmersProvider.getAllFarmers(authProvider.token!);
      if (farmersProvider.errorMessage != null && mounted) {
        showSnackBar(context, farmersProvider.errorMessage!, isError: true);
      }
    } else {
      if (mounted) {
        showSnackBar(context, 'Session expired. Please login again.',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmersProvider = Provider.of<FarmersProvider>(context);
    final displayDate = DateFormat('EEEE, dd MMMM yyyy')
        .format(DateTime.parse(widget.collectionDate));

    final filteredFarmers = farmersProvider.farmers.where((f) {
      final query = _searchQuery.toLowerCase();
      return f.firstName.toLowerCase().contains(query) ||
          f.lastName.toLowerCase().contains(query) ||
          f.email.toLowerCase().contains(query) ||
          (f.farmLocation ?? '').toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Record Collection',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                color: AppConstants.primaryColor.withOpacity(0.85),
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 6),
                    Text(
                      displayDate,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: LoadingOverlay(
        isLoading: farmersProvider.isLoading,
        message: 'Loading farmers...',
        child: Column(
          children: [
            // ── Search Bar ─────────────────────────────────────────────
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
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search farmers...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: AppConstants.primaryColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // ── Farmer Count Badge ─────────────────────────────────────
            if (!farmersProvider.isLoading)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFF0F4F0),
                child: Text(
                  '${filteredFarmers.length} farmer${filteredFarmers.length != 1 ? 's' : ''} found',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // ── List ───────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadFarmers,
                color: AppConstants.primaryColor,
                child: filteredFarmers.isEmpty && !farmersProvider.isLoading
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredFarmers.length,
                        itemBuilder: (context, index) {
                          final farmer = filteredFarmers[index];
                          return _buildFarmerCard(context, farmer);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerCard(BuildContext context, dynamic farmer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          // ── Main tap area ────────────────────────────────────────────
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecordMilkScreen(
                  farmer: farmer,
                  collectionDate: widget.collectionDate,
                ),
              ),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppConstants.primaryColor.withOpacity(0.3),
                          width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          AppConstants.primaryColor.withOpacity(0.08),
                      backgroundImage: (farmer.imageUrl != null &&
                              farmer.imageUrl!.isNotEmpty)
                          ? NetworkImage(
                              farmer.imageUrl!.startsWith('http')
                                  ? farmer.imageUrl!
                                  : '${AppConstants.baseUrl}${farmer.imageUrl!}',
                            )
                          : null,
                      child:
                          (farmer.imageUrl == null || farmer.imageUrl!.isEmpty)
                              ? Text(
                                  farmer.firstName.isNotEmpty
                                      ? farmer.firstName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryColor,
                                  ),
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
                        Text(
                          farmer.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          farmer.email,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (farmer.farmLocation != null)
                              _buildChip(Icons.location_on_rounded,
                                  farmer.farmLocation!, Colors.teal),
                            const SizedBox(width: 6),
                            _buildChip(
                                Icons.pets_rounded,
                                '${farmer.numberOfCows ?? 0} cows',
                                AppConstants.primaryColor),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppConstants.primaryColor),
                  ),
                ],
              ),
            ),
          ),

          // ── Divider ──────────────────────────────────────────────────
          Divider(
              height: 1, color: Colors.grey[100], indent: 14, endIndent: 14),

          // ── Action buttons row ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Record Milk button
                Expanded(
                  child: _actionBtn(
                    icon: Icons.water_drop_rounded,
                    label: 'Record Milk',
                    color: AppConstants.primaryColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordMilkScreen(
                          farmer: farmer,
                          collectionDate: widget.collectionDate,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // AI Report button
                Expanded(
                  child: _actionBtn(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Report',
                    color: const Color(0xFF7C3AED),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiRecommendationsScreen(
                          farmerID: farmer.userId,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
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
                const Text(
                  'No farmers found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
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
                  onPressed: _loadFarmers,
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
      ],
    );
  }
}
