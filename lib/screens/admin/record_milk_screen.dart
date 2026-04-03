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
  final _feedNotesController = TextEditingController();

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

  // ── State ─────────────────────────────────────────────────────────────────
  bool _waterAvailable = true;
  final double _pricePerLiter = 50.0;
  double _calculatedTotal = 0.0;
  double _totalFeedKg = 0.0;
  int _todayCount = 0; // 0 = no collections yet, 1 = one done

  bool _showPreviousCollections = false;
  bool _loadingPrevious = false;
  List<MilkCollectionModel> _previousCollections = [];

  int get _numberOfCows => widget.farmer.numberOfCows ?? 1;
  String get _collectionLabel => _todayCount == 0 ? 'Morning' : 'Evening';

  @override
  void initState() {
    super.initState();
    _feedAmountPerCowController.addListener(_calculateFeedTotal);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTodayCount());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _fatContentController.dispose();
    _temperatureController.dispose();
    _milkNotesController.dispose();
    _feedAmountPerCowController.dispose();
    _feedNotesController.dispose();
    super.dispose();
  }

  void _checkTodayCount() {
    final milkProvider =
        Provider.of<MilkCollectionProvider>(context, listen: false);
    setState(() {
      _todayCount = milkProvider.getTodayCollectionCount(widget.farmer.userId);
    });
  }

  void _calculateTotal() {
    final qty = double.tryParse(_quantityController.text) ?? 0.0;
    setState(() => _calculatedTotal = qty * _pricePerLiter);
  }

  void _calculateFeedTotal() {
    final perCow = double.tryParse(_feedAmountPerCowController.text) ?? 0.0;
    setState(() => _totalFeedKg = perCow * _numberOfCows);
  }

  Future<void> _loadPreviousCollections() async {
    if (_loadingPrevious) return;
    setState(() => _loadingPrevious = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final milk = Provider.of<MilkCollectionProvider>(context, listen: false);
      if (auth.token != null) {
        await milk.getCollectionsByFarmer(widget.farmer.userId, auth.token!);
        setState(() {
          _previousCollections = milk.collections
              .where((c) => c.collectionDate != widget.collectionDate)
              .toList()
            ..sort((a, b) => b.collectionDate.compareTo(a.collectionDate));
        });
      }
    } catch (_) {
      if (mounted)
        showSnackBar(context, 'Failed to load history', isError: true);
    } finally {
      if (mounted) setState(() => _loadingPrevious = false);
    }
  }

  bool _validateFeeding() {
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

  // ── Main submit ───────────────────────────────────────────────────────────
  Future<void> _handleRecordMilk() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateFeeding()) return;

    // Re-check limit
    final milkProvider =
        Provider.of<MilkCollectionProvider>(context, listen: false);
    final currentCount =
        milkProvider.getTodayCollectionCount(widget.farmer.userId);
    if (currentCount >= 2) {
      showSnackBar(context,
          'Max 2 collections reached for ${widget.farmer.firstName} today.',
          isError: true);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final feeding = Provider.of<FeedingProvider>(context, listen: false);

    if (auth.token == null || auth.currentUser == null) {
      showSnackBar(context, 'Session expired. Please login again.',
          isError: true);
      return;
    }

    // ── Determine session label ────────────────────────────────────────────
    final sessionTime = currentCount == 0 ? 'Morning' : 'Evening';

    // ── Step 1: Save milk ──────────────────────────────────────────────────
    final milkRequest = CreateMilkCollectionRequest(
      farmerID: widget.farmer.userId,
      collectorID: auth.currentUser!.userId,
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
      collectionTime: sessionTime,
    );

    final milkSuccess =
        await milkProvider.createCollection(milkRequest, auth.token!);
    if (!mounted) return;

    if (!milkSuccess) {
      showSnackBar(
          context, milkProvider.errorMessage ?? 'Failed to record milk',
          isError: true);
      return;
    }

    final smsDelivered = milkProvider.lastSmsDelivered ?? false;

    // ── Step 2: Save feeding record for this session ───────────────────────
    final newMilkID = milkProvider.lastCreatedMilkID;
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

    final feedingRequest = CreateFeedingHabitRequest(
      farmerID: widget.farmer.userId,
      milkID: newMilkID,
      feedType: _selectedFeedTypes.first,
      amountKg: _totalFeedKg,
      feedingTime: sessionTime, // ← Morning or Evening
      feedingDate: widget.collectionDate,
      supplementName: supplementsStr,
      notes: combinedNotes,
      recordedBy: auth.currentUser!.userId,
    );

    final feedResult =
        await feeding.createFeedingHabit(feedingRequest, auth.token!);
    if (!mounted) return;

    final feedingSuccess = feedResult != null;
    if (!feedingSuccess) {
      showSnackBar(
        context,
        'Milk saved but feeding record failed: ${feeding.errorMessage}',
        isError: true,
      );
    }

    // ── Step 3: Fetch weather ──────────────────────────────────────────────
    if (!mounted) return;
    final weatherProvider =
        Provider.of<WeatherProvider>(context, listen: false);
    await weatherProvider.getWeatherByDate(
        widget.farmer.userId, widget.collectionDate, auth.token!);
    if (!mounted) return;

    // ── Step 4: Show success sheet ─────────────────────────────────────────
    await _showSuccessBottomSheet(
      feedingSuccess: feedingSuccess,
      weather: weatherProvider.selectedDayWeather,
      farmerName: widget.farmer.fullName,
      farmerPhone: widget.farmer.contactPhone ?? '',
      quantity: double.parse(_quantityController.text),
      totalAmount: _calculatedTotal,
      smsDelivered: smsDelivered,
      sessionTime: sessionTime,
    );
  }

  // ── Success bottom sheet ──────────────────────────────────────────────────
  Future<void> _showSuccessBottomSheet({
    required bool feedingSuccess,
    WeatherModel? weather,
    required String farmerName,
    required String farmerPhone,
    required double quantity,
    required double totalAmount,
    required bool smsDelivered,
    required String sessionTime,
  }) async {
    final hasPhone = farmerPhone.isNotEmpty;
    final smsColor = smsDelivered ? Colors.green : Colors.orange;
    final smsIcon = smsDelivered ? Icons.sms_rounded : Icons.sms_failed_rounded;
    final smsTitle = smsDelivered
        ? 'SMS Delivered to Farmer'
        : hasPhone
            ? 'SMS Failed to Send'
            : 'SMS Not Sent';
    final smsSubtitle = smsDelivered
        ? '$farmerName has been notified via SMS ✓'
        : hasPhone
            ? 'SMS could not be delivered to $farmerPhone'
            : 'No phone number on file for $farmerName';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(ctx).padding.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  feedingSuccess
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: feedingSuccess
                      ? AppConstants.primaryColor
                      : Colors.orange,
                  size: 48,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                feedingSuccess
                    ? '$sessionTime Collection Recorded!'
                    : 'Milk Saved — Check Feeding',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 4),
              Text(farmerName,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500])),

              // Session badge
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sessionTime == 'Morning'
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sessionTime == 'Morning'
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.indigo.withOpacity(0.3),
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    sessionTime == 'Morning' ? '🌅' : '🌙',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$sessionTime Session',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: sessionTime == 'Morning'
                            ? Colors.orange[700]
                            : Colors.indigo[700]),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // SMS banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: smsColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: smsColor.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: smsColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(smsIcon, color: smsColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(smsTitle,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: smsDelivered
                                    ? Colors.green[700]
                                    : Colors.orange[700])),
                        const SizedBox(height: 2),
                        Text(smsSubtitle,
                            style: TextStyle(
                                fontSize: 12,
                                color: smsDelivered
                                    ? Colors.green[600]
                                    : Colors.orange[600])),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),

              // Summary row
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.15)),
                ),
                child: Row(children: [
                  Expanded(
                      child: _summaryItem(
                    Icons.water_drop_rounded,
                    '${quantity.toStringAsFixed(1)}L',
                    'Collected',
                    Colors.blue,
                  )),
                  Container(width: 1, height: 40, color: Colors.grey[200]),
                  Expanded(
                      child: _summaryItem(
                    Icons.payments_rounded,
                    'KSh ${NumberFormat('#,##0').format(totalAmount)}',
                    'Amount',
                    Colors.green,
                  )),
                ]),
              ),
              const SizedBox(height: 16),

              // Weather card
              if (weather != null) ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.lightBlue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.withOpacity(0.15)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Row(children: [
                      Text(weather.weatherEmoji,
                          style: const TextStyle(fontSize: 28)),
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
                                  color: Color(0xFF1A1A2E)),
                            ),
                            if (weather.location != null)
                              Text(weather.location!,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[500])),
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
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      _weatherTile('🌡️', 'Temp', weather.tempDisplay),
                      _weatherTile('💧', 'Humidity', weather.humidityDisplay),
                      _weatherTile('🌧️', 'Rainfall', weather.rainfallDisplay),
                      _weatherTile('💨', 'Wind', weather.windDisplay),
                    ]),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(weather.conditionDisplay,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue)),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ] else ...[
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
                      Text('Weather data not available',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey[500])),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Done button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
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
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label, Color color) =>
      Column(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ]);

  Widget _weatherTile(String emoji, String label, String value) => Expanded(
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E))),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ]),
      );

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
      builder: (context, milkProvider, feedingProvider, _) {
        final isLoading = milkProvider.isLoading || feedingProvider.isLoading;
        return Scaffold(
          backgroundColor: const Color(0xFFF0F4F0),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            title: Text('$_collectionLabel Collection',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(36),
              child: Container(
                width: double.infinity,
                color: AppConstants.primaryColor.withOpacity(0.85),
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                child: Row(children: [
                  const Icon(Icons.calendar_today,
                      color: Colors.white70, size: 13),
                  const SizedBox(width: 6),
                  Text(displayDate,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _collectionLabel == 'Morning'
                          ? '🌅 1st Collection'
                          : '🌙 2nd Collection',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
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

                    // Session indicator
                    _buildSessionIndicator(),
                    const SizedBox(height: 16),

                    _buildMilkCard(),
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
                      text: 'Record $_collectionLabel Milk',
                      onPressed: _handleRecordMilk,
                      isLoading: isLoading,
                      backgroundColor: AppConstants.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        'This will be saved as the $_collectionLabel collection',
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

  // ── Session indicator ─────────────────────────────────────────────────────
  Widget _buildSessionIndicator() {
    final isMorning = _collectionLabel == 'Morning';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMorning
            ? Colors.orange.withOpacity(0.08)
            : Colors.indigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMorning
              ? Colors.orange.withOpacity(0.3)
              : Colors.indigo.withOpacity(0.3),
        ),
      ),
      child: Row(children: [
        Text(isMorning ? '🌅' : '🌙', style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMorning
                    ? '1st Collection — Morning'
                    : '2nd Collection — Evening',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isMorning ? Colors.orange[700] : Colors.indigo[700]),
              ),
              const SizedBox(height: 3),
              Text(
                isMorning
                    ? 'First milk session of the day'
                    : 'Final milk session of the day',
                style: TextStyle(
                    fontSize: 12,
                    color: isMorning ? Colors.orange[600] : Colors.indigo[600]),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isMorning ? Colors.orange : Colors.indigo,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isMorning ? 'Morning' : 'Evening',
            style: const TextStyle(
                fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ]),
    );
  }

  // ── Farmer card ───────────────────────────────────────────────────────────
  Widget _buildFarmerCard() => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppConstants.primaryColor,
              AppConstants.secondaryColor,
            ],
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
        child: Row(children: [
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
                Row(children: [
                  const Icon(Icons.pets, size: 12, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text('$_numberOfCows cows registered',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11)),
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
                ]),
                if (widget.farmer.cowBreedList.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.biotech_rounded,
                        size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(widget.farmer.cowBreedDisplay,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ]),
      );

  // ── Previous collections ──────────────────────────────────────────────────
  Widget _buildPreviousCollectionsCard() => Container(
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
        child: Column(children: [
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
              child: Row(children: [
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
              ]),
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
        ]),
      );

  // ── Milk card ─────────────────────────────────────────────────────────────
  Widget _buildMilkCard() => _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("$_collectionLabel Milk Collection",
                Icons.water_drop_rounded, AppConstants.primaryColor),
            const SizedBox(height: 18),
            CustomTextField(
              controller: _quantityController,
              label: 'Quantity in Liters *',
              hint: 'e.g., 25.5',
              prefixIcon: Icons.water_drop,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
            Row(children: [
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
            ]),
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

  // ── Feed types card ───────────────────────────────────────────────────────
  Widget _buildFeedTypesCard() => _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
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
            ]),
            const SizedBox(height: 6),
            Text('Select all feeds given at $_collectionLabel',
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
                                color: selected
                                    ? Colors.white
                                    : Colors.green[800])),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  // ── Feed amount card ──────────────────────────────────────────────────────
  Widget _buildFeedAmountCard() => _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
                'Feed Amount', Icons.scale_rounded, Colors.teal),
            const SizedBox(height: 6),
            Text('Enter amount per cow — total is auto-calculated',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 16),
            TextFormField(
              controller: _feedAmountPerCowController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
                gradient: LinearGradient(colors: [
                  Colors.teal.withOpacity(0.1),
                  Colors.teal.withOpacity(0.05),
                ]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.teal.withOpacity(0.2)),
              ),
              child: Row(children: [
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
                            color: Colors.teal),
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
              ]),
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

  // ── Supplements card ──────────────────────────────────────────────────────
  Widget _buildSupplementsCard() => _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
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
            ]),
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
                child: Row(children: [
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
                ]),
              ),
            ],
          ],
        ),
      );

  // ── Water card ────────────────────────────────────────────────────────────
  Widget _buildWaterCard() => _buildCard(
        child: Row(children: [
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
        ]),
      );

  // ── Payment card ──────────────────────────────────────────────────────────
  Widget _buildPaymentCard() => Container(
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
        child: Column(children: [
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
        ]),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) => Container(
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

  Widget _buildSectionHeader(String title, IconData icon, Color color) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
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
      ]);

  InputDecoration _inputDecoration(String label, IconData icon, Color color) =>
      InputDecoration(
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

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
      child: Row(children: [
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
              Row(children: [
                Icon(Icons.water_drop_rounded,
                    size: 11, color: Colors.blue[400]),
                const SizedBox(width: 3),
                Text('${c.quantityInLiters}L',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(width: 12),
                Icon(Icons.payments_rounded,
                    size: 11, color: Colors.green[400]),
                const SizedBox(width: 3),
                Text('KSh ${NumberFormat('#,##0').format(c.totalAmount)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ]),
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
      ]),
    );
  }

  Widget _buildCalcRow(String label, String value,
          {bool isBold = false, Color? valueColor, double fontSize = 15}) =>
      Row(
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
