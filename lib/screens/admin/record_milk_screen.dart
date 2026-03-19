import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/feeding_habit_model.dart';
import '../../models/milk_collection_model.dart';
import '../../models/user_model.dart';
import '../../models/weather_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/feeding_provider.dart';
import '../../providers/milk_collection_provider.dart';
import '../../providers/weather_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

class RecordMilkScreen extends StatefulWidget {
  final UserModel farmer;
  final String collectionDate;

  const RecordMilkScreen({
    Key? key,
    required this.farmer,
    required this.collectionDate,
  }) : super(key: key);

  @override
  State<RecordMilkScreen> createState() => _RecordMilkScreenState();
}

class _RecordMilkScreenState extends State<RecordMilkScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Milk controllers ──────────────────────────────────────────────────────
  final _quantityController = TextEditingController();
  final _fatContentController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _milkNotesController = TextEditingController();

  // ── Feeding controllers ───────────────────────────────────────────────────
  final _feedAmountPerCowController = TextEditingController();
  final _supplementNotesController = TextEditingController();
  final _feedNotesController = TextEditingController();

  // ── Feeding times ─────────────────────────────────────────────────────────
  final Set<String> _selectedFeedingTimes = {'Morning', 'Evening'};
  static const List<String> _allFeedingTimes = [
    'Morning',
    'Afternoon',
    'Evening',
    'Night',
  ];

  // ── Feed types ────────────────────────────────────────────────────────────
  final Set<String> _selectedFeedTypes = {'Napier Grass'};
  static const List<String> _allFeedTypes = [
    'Napier Grass',
    'Maize Silage',
    'Dairy Meal',
    'Rhodes Grass',
    'Lucerne',
    'Wheat Bran',
    'Cotton Seed Cake',
    'Soya Bean Meal',
    'Hay',
    'Brewers Grain',
    'Molasses',
    'Maize Stalks',
    'Other',
  ];

  // ── Supplements ───────────────────────────────────────────────────────────
  final Set<String> _selectedSupplements = {};
  static const List<String> _allSupplements = [
    'Mineral Supplement',
    'Vitamin Boost',
    'Salt Lick',
    'Calcium Powder',
    'Protein Concentrate',
    'Urea Treated Straw',
  ];

  // ── Water availability ────────────────────────────────────────────────────
  bool _waterAvailable = true;

  // ── Milk state ────────────────────────────────────────────────────────────
  final double _pricePerLiter = 50.0;
  double _calculatedTotal = 0.0;
  double _totalFeedKg = 0.0;

  bool _showPreviousCollections = false;
  bool _loadingPrevious = false;
  List<MilkCollectionModel> _previousCollections = [];

  int get _numberOfCows => widget.farmer.numberOfCows ?? 1;

  @override
  void initState() {
    super.initState();
    _feedAmountPerCowController.addListener(_calculateFeedTotal);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _fatContentController.dispose();
    _temperatureController.dispose();
    _milkNotesController.dispose();
    _feedAmountPerCowController.dispose();
    _supplementNotesController.dispose();
    _feedNotesController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    setState(() => _calculatedTotal = quantity * _pricePerLiter);
  }

  void _calculateFeedTotal() {
    final perCow = double.tryParse(_feedAmountPerCowController.text) ?? 0.0;
    setState(() => _totalFeedKg = perCow * _numberOfCows);
  }

  Future<void> _loadPreviousCollections() async {
    if (_loadingPrevious) return;
    setState(() => _loadingPrevious = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final milkProvider =
          Provider.of<MilkCollectionProvider>(context, listen: false);
      if (authProvider.token != null) {
        await milkProvider.getCollectionsByFarmer(
            widget.farmer.userId, authProvider.token!);
        setState(() {
          _previousCollections = milkProvider.collections
              .where((c) => c.collectionDate != widget.collectionDate)
              .toList()
            ..sort((a, b) => b.collectionDate.compareTo(a.collectionDate));
        });
      }
    } catch (e) {
      if (mounted)
        showSnackBar(context, 'Failed to load history', isError: true);
    } finally {
      if (mounted) setState(() => _loadingPrevious = false);
    }
  }

  bool _validateFeeding() {
    if (_selectedFeedingTimes.length < 2) {
      showSnackBar(context, 'Please select at least 2 feeding times',
          isError: true);
      return false;
    }
    if (_selectedFeedTypes.isEmpty) {
      showSnackBar(context, 'Please select at least one feed type',
          isError: true);
      return false;
    }
    if (_feedAmountPerCowController.text.trim().isEmpty) {
      showSnackBar(context, 'Please enter feed amount per cow', isError: true);
      return false;
    }
    final perCow = double.tryParse(_feedAmountPerCowController.text.trim());
    if (perCow == null || perCow <= 0) {
      showSnackBar(context, 'Feed amount per cow must be a positive number',
          isError: true);
      return false;
    }
    return true;
  }

  Future<void> _handleRecordMilk() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateFeeding()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final milkProvider =
        Provider.of<MilkCollectionProvider>(context, listen: false);
    final feedingProvider =
        Provider.of<FeedingProvider>(context, listen: false);

    if (authProvider.token == null || authProvider.currentUser == null) {
      showSnackBar(context, 'Session expired. Please login again.',
          isError: true);
      return;
    }

    // ── Step 1: Save milk ─────────────────────────────────────────────────
    final milkRequest = CreateMilkCollectionRequest(
      farmerID: widget.farmer.userId,
      collectorID: authProvider.currentUser!.userId,
      quantityInLiters: double.parse(_quantityController.text),
      fatContent: _fatContentController.text.isNotEmpty
          ? double.parse(_fatContentController.text)
          : null,
      temperature: _temperatureController.text.isNotEmpty
          ? double.parse(_temperatureController.text)
          : null,
      notes: _milkNotesController.text.trim().isNotEmpty
          ? _milkNotesController.text.trim()
          : null,
      collectionDate: widget.collectionDate,
    );

    final milkSuccess =
        await milkProvider.createCollection(milkRequest, authProvider.token!);
    if (!mounted) return;

    if (!milkSuccess) {
      showSnackBar(
          context, milkProvider.errorMessage ?? 'Failed to record milk',
          isError: true);
      return;
    }

    // ── Step 2: Save feeding records per selected time ────────────────────
    final newMilkID = milkProvider.lastCreatedMilkID;
    final feedTypesStr = _selectedFeedTypes.join(', ');
    final supplementsStr = _selectedSupplements.isNotEmpty
        ? _selectedSupplements.join(', ')
        : null;

    final combinedNotes = [
      if (_feedNotesController.text.trim().isNotEmpty)
        _feedNotesController.text.trim(),
      if (supplementsStr != null) 'Supplements: $supplementsStr',
      'Water available: ${_waterAvailable ? 'Yes' : 'No'}',
      'Cows: $_numberOfCows | Per cow: ${_feedAmountPerCowController.text} KG | Total: ${_totalFeedKg.toStringAsFixed(2)} KG',
      if (widget.farmer.cowBreedList.isNotEmpty)
        'Breed: ${widget.farmer.cowBreedDisplay}',
    ].join(' | ');

    bool allFeedingSuccess = true;

    for (final time in _selectedFeedingTimes) {
      final feedingRequest = CreateFeedingHabitRequest(
        farmerID: widget.farmer.userId,
        milkID: newMilkID,
        feedType: _selectedFeedTypes.first,
        amountKg: _totalFeedKg / _selectedFeedingTimes.length,
        feedingTime: time,
        feedingDate: widget.collectionDate,
        supplementName: supplementsStr,
        notes: combinedNotes,
        recordedBy: authProvider.currentUser!.userId,
      );

      final result = await feedingProvider.createFeedingHabit(
          feedingRequest, authProvider.token!);
      if (result == null) allFeedingSuccess = false;
      if (!mounted) return;
    }

    if (!allFeedingSuccess) {
      showSnackBar(
        context,
        'Milk saved but some feeding records failed: ${feedingProvider.errorMessage}',
        isError: true,
      );
    }

    // ── Step 3: Fetch weather then show success bottom sheet ──────────────
    if (!mounted) return;
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);
    await weatherProvider.getWeatherByDate(
      widget.farmer.userId,
      widget.collectionDate,
      authProvider.token!,
    );
    if (!mounted) return;

    await _showSuccessBottomSheet(
      allFeedingSuccess: allFeedingSuccess,
      weather: weatherProvider.selectedDayWeather,
    );
  }

  // ── Success + Weather bottom sheet ────────────────────────────────────────
  Future<void> _showSuccessBottomSheet({
    required bool allFeedingSuccess,
    WeatherModel? weather,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle bar ────────────────────────────────────────────────
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // ── Success icon ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                allFeedingSuccess
                    ? Icons.check_circle_rounded
                    : Icons.warning_amber_rounded,
                color: allFeedingSuccess
                    ? AppConstants.primaryColor
                    : Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 14),

            Text(
              allFeedingSuccess
                  ? 'Recorded Successfully!'
                  : 'Milk Saved — Check Feeding',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.farmer.fullName,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),

            // ── Weather card ──────────────────────────────────────────────
            if (weather != null) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade50,
                      Colors.lightBlue.shade50,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.withOpacity(0.15)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Text(
                          weather.weatherEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weather on ${DateFormat('dd MMM yyyy').format(DateTime.parse(widget.collectionDate))}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              if (weather.location != null)
                                Text(
                                  weather.location!,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[500]),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            weather.dataSource?.toUpperCase() ?? 'AUTO',
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Weather grid
                    Row(
                      children: [
                        _buildWeatherTile('🌡️', 'Temp', weather.tempDisplay),
                        _buildWeatherTile(
                            '💧', 'Humidity', weather.humidityDisplay),
                        _buildWeatherTile(
                            '🌧️', 'Rainfall', weather.rainfallDisplay),
                        _buildWeatherTile('💨', 'Wind', weather.windDisplay),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Condition pill
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          weather.conditionDisplay,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // No weather available
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_rounded,
                        color: Colors.grey[400], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Weather data not available',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Done button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close bottom sheet
                  Navigator.pop(context, true); // go back
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Done',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Weather tile helper ───────────────────────────────────────────────────
  Widget _buildWeatherTile(String emoji, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  String _getInitials() {
    final f = widget.farmer.firstName.isNotEmpty
        ? widget.farmer.firstName[0].toUpperCase()
        : '';
    final l = widget.farmer.lastName.isNotEmpty
        ? widget.farmer.lastName[0].toUpperCase()
        : '';
    return (f + l).isNotEmpty ? f + l : '?';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Verified':
        return const Color(0xFF22C55E);
      case 'Disputed':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Verified':
        return Icons.verified_rounded;
      case 'Disputed':
        return Icons.warning_amber_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = DateFormat('EEEE, dd MMMM yyyy')
        .format(DateTime.parse(widget.collectionDate));

    return Consumer2<MilkCollectionProvider, FeedingProvider>(
      builder: (context, milkProvider, feedingProvider, child) {
        final isLoading = milkProvider.isLoading || feedingProvider.isLoading;
        return Scaffold(
          backgroundColor: const Color(0xFFF0F4F0),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            title: const Text('Record Collection',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(36),
              child: Container(
                width: double.infinity,
                color: AppConstants.primaryColor.withOpacity(0.85),
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white70, size: 13),
                    const SizedBox(width: 6),
                    Text(displayDate,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          body: LoadingOverlay(
            isLoading: isLoading,
            message: milkProvider.isLoading
                ? 'Recording milk...'
                : 'Saving feeding data...',
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFarmerCard(),
                    const SizedBox(height: 16),
                    _buildPreviousCollectionsCard(),
                    const SizedBox(height: 16),
                    _buildMilkCard(),
                    const SizedBox(height: 16),
                    _buildFeedingTimesCard(),
                    const SizedBox(height: 16),
                    _buildFeedTypesCard(),
                    const SizedBox(height: 16),
                    _buildFeedAmountCard(),
                    const SizedBox(height: 16),
                    _buildSupplementsCard(),
                    const SizedBox(height: 16),
                    _buildWaterCard(),
                    const SizedBox(height: 16),
                    _buildPaymentCard(),
                    const SizedBox(height: 28),
                    CustomButton(
                      text: 'Record Milk & Feeding',
                      onPressed: _handleRecordMilk,
                      isLoading: isLoading,
                      backgroundColor: AppConstants.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Milk and feeding data will be saved together',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Farmer card ───────────────────────────────────────────────────────────
  Widget _buildFarmerCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppConstants.primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 5)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5)),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              backgroundImage: (widget.farmer.imageUrl != null &&
                      widget.farmer.imageUrl!.isNotEmpty)
                  ? NetworkImage(
                      widget.farmer.imageUrl!.startsWith('http')
                          ? widget.farmer.imageUrl!
                          : '${AppConstants.baseUrl}${widget.farmer.imageUrl!}',
                    )
                  : null,
              child: (widget.farmer.imageUrl == null ||
                      widget.farmer.imageUrl!.isEmpty)
                  ? Text(_getInitials(),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor))
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recording for',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 3),
                Text(widget.farmer.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text(widget.farmer.email,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.pets, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text('$_numberOfCows cows registered',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11)),
                    if (widget.farmer.farmLocation != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_rounded,
                          size: 12, color: Colors.white70),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(widget.farmer.farmLocation!,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ],
                ),
                if (widget.farmer.cowBreedList.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.biotech_rounded,
                          size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.farmer.cowBreedDisplay,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Previous collections ──────────────────────────────────────────────────
  Widget _buildPreviousCollectionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () async {
              final opening = !_showPreviousCollections;
              setState(() => _showPreviousCollections = opening);
              if (opening && _previousCollections.isEmpty) {
                await _loadPreviousCollections();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.history_rounded,
                        color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Previous Collections',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1A1A2E))),
                        Text('View past milk records for this farmer',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showPreviousCollections ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _loadingPrevious
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: AppConstants.primaryColor, strokeWidth: 2)),
                  )
                : _previousCollections.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded,
                                  color: Colors.grey[400], size: 20),
                              const SizedBox(width: 8),
                              Text('No previous collections found',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 13)),
                            ],
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: _previousCollections
                              .take(10)
                              .map((c) => _buildHistoryItem(c))
                              .toList(),
                        ),
                      ),
            crossFadeState: _showPreviousCollections
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ── Milk card ─────────────────────────────────────────────────────────────
  Widget _buildMilkCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Today's Milk Collection",
              Icons.water_drop_rounded, AppConstants.primaryColor),
          const SizedBox(height: 18),
          CustomTextField(
            controller: _quantityController,
            label: 'Quantity in Liters *',
            hint: 'e.g., 25.5',
            prefixIcon: Icons.water_drop,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (v) {
              if (v == null || v.isEmpty) return 'Quantity is required';
              if ((double.tryParse(v) ?? 0) <= 0)
                return 'Enter a valid quantity';
              return null;
            },
            onChanged: (_) => _calculateTotal(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _fatContentController,
                  label: 'Fat Content %',
                  hint: 'e.g., 3.5',
                  prefixIcon: Icons.science,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final fat = double.tryParse(v);
                      if (fat == null || fat < 0 || fat > 100)
                        return 'Enter 0–100';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: _temperatureController,
                  label: 'Temp °C',
                  hint: 'e.g., 4.0',
                  prefixIcon: Icons.thermostat,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^-?\d+\.?\d{0,2}')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _milkNotesController,
            label: 'Notes (Optional)',
            hint: 'Any notes about quality, etc.',
            prefixIcon: Icons.note_alt_rounded,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ── Feeding times card ────────────────────────────────────────────────────
  Widget _buildFeedingTimesCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionHeader(
                  'Feeding Times', Icons.access_time_rounded, Colors.orange),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _selectedFeedingTimes.length < 2
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedFeedingTimes.length < 2
                      ? 'Min 2 required'
                      : '${_selectedFeedingTimes.length} selected ✓',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _selectedFeedingTimes.length < 2
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Select all times the farmer feeds their cows today',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allFeedingTimes.map((time) {
              final selected = _selectedFeedingTimes.contains(time);
              final icon = _feedingTimeIcon(time);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      if (_selectedFeedingTimes.length > 1) {
                        _selectedFeedingTimes.remove(time);
                      } else {
                        showSnackBar(
                            context, 'At least 1 feeding time required',
                            isError: true);
                      }
                    } else {
                      _selectedFeedingTimes.add(time);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.orange
                        : Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? Colors.orange
                          : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 16,
                          color: selected ? Colors.white : Colors.orange),
                      const SizedBox(width: 6),
                      Text(time,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : Colors.orange[800])),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Feed types card ───────────────────────────────────────────────────────
  Widget _buildFeedTypesCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionHeader(
                  'Feed Types', Icons.grass_rounded, Colors.green),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedFeedTypes.length} selected',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Select all feeds given today (can choose multiple)',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allFeedTypes.map((feed) {
              final selected = _selectedFeedTypes.contains(feed);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    if (_selectedFeedTypes.length > 1) {
                      _selectedFeedTypes.remove(feed);
                    } else {
                      showSnackBar(context, 'At least 1 feed type required',
                          isError: true);
                    }
                  } else {
                    _selectedFeedTypes.add(feed);
                  }
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.green
                        : Colors.green.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.green
                          : Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.check_circle,
                              size: 13, color: Colors.white),
                        ),
                      Text(feed,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color:
                                  selected ? Colors.white : Colors.green[800])),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Feed amount card ──────────────────────────────────────────────────────
  Widget _buildFeedAmountCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Feed Amount', Icons.scale_rounded, Colors.teal),
          const SizedBox(height: 6),
          Text('Enter amount per cow — total is auto-calculated',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 16),
          TextFormField(
            controller: _feedAmountPerCowController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: _inputDecoration(
                'Feed per Cow (KG) *', Icons.set_meal_rounded, Colors.teal),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if ((double.tryParse(v) ?? 0) <= 0) return 'Must be > 0';
              return null;
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.teal.withOpacity(0.1),
                  Colors.teal.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.teal.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calculate_rounded,
                      color: Colors.teal, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_feedAmountPerCowController.text.isEmpty ? '0' : _feedAmountPerCowController.text} KG × $_numberOfCows cows',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ${_totalFeedKg.toStringAsFixed(2)} KG',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$_numberOfCows cows',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[500])),
                    Text(
                      widget.farmer.cowBreedList.isNotEmpty
                          ? widget.farmer.cowBreedDisplay
                          : 'from profile',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _feedNotesController,
            label: 'Feeding Notes (Optional)',
            hint: 'Any observations about feeding today...',
            prefixIcon: Icons.note_alt_outlined,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ── Supplements card ──────────────────────────────────────────────────────
  Widget _buildSupplementsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildSectionHeader(
                  'Supplements', Icons.medication_rounded, Colors.purple),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Optional',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Select any supplements given today',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allSupplements.map((sup) {
              final selected = _selectedSupplements.contains(sup);
              return GestureDetector(
                onTap: () => setState(() => selected
                    ? _selectedSupplements.remove(sup)
                    : _selectedSupplements.add(sup)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.purple
                        : Colors.purple.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? Colors.purple
                          : Colors.purple.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.check_circle,
                              size: 13, color: Colors.white),
                        ),
                      Text(sup,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : Colors.purple[800])),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedSupplements.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.purple, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedSupplements.join(' · '),
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.purple,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Water card ────────────────────────────────────────────────────────────
  Widget _buildWaterCard() {
    return _buildCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.water_drop_outlined,
                color: Colors.blue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Water Available Today',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                Text(
                  _waterAvailable
                      ? 'Cows have access to clean water ✓'
                      : 'No water access today — will affect milk yield',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _waterAvailable ? Colors.green[600] : Colors.red[400],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _waterAvailable,
            onChanged: (v) => setState(() => _waterAvailable = v),
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  // ── Payment card ──────────────────────────────────────────────────────────
  Widget _buildPaymentCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor.withOpacity(0.08),
            AppConstants.secondaryColor.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _buildSectionHeader('Payment Calculation', Icons.calculate_rounded,
              AppConstants.primaryColor),
          const SizedBox(height: 16),
          _buildCalcRow(
              'Price per Liter', 'KSh ${_pricePerLiter.toStringAsFixed(2)}'),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1)),
          _buildCalcRow(
            'Total Amount',
            'KSh ${_calculatedTotal.toStringAsFixed(2)}',
            isBold: true,
            valueColor: AppConstants.primaryColor,
            fontSize: 20,
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E))),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, Color color) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color, size: 20),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2)),
      labelStyle: TextStyle(color: color),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  IconData _feedingTimeIcon(String time) {
    switch (time) {
      case 'Morning':
        return Icons.wb_sunny_rounded;
      case 'Afternoon':
        return Icons.wb_cloudy_rounded;
      case 'Evening':
        return Icons.nights_stay_rounded;
      case 'Night':
        return Icons.dark_mode_rounded;
      default:
        return Icons.access_time;
    }
  }

  Widget _buildHistoryItem(MilkCollectionModel c) {
    final color = _statusColor(c.collectionStatus);
    final icon = _statusIcon(c.collectionStatus);
    final date = DateFormat('dd MMM yyyy')
        .format(DateTime.tryParse(c.collectionDate) ?? DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.water_drop_rounded,
                        size: 11, color: Colors.blue[400]),
                    const SizedBox(width: 3),
                    Text('${c.quantityInLiters}L',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 12),
                    Icon(Icons.payments_rounded,
                        size: 11, color: Colors.green[400]),
                    const SizedBox(width: 3),
                    Text('KSh ${NumberFormat('#,##0').format(c.totalAmount)}',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(c.collectionStatus,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(String label, String value,
      {bool isBold = false, Color? valueColor, double fontSize = 15}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: const Color(0xFF1A1A2E))),
        Text(value,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1A2E))),
      ],
    );
  }
}
