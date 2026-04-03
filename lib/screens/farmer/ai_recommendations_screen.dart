import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gemini_provider.dart';
import '../../models/recommendation_model.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _bg = Color(0xFFF0F4F1);
const _surface = Color(0xFFFFFFFF);
const _green = Color(0xFF16A34A);
const _greenDark = Color(0xFF15803D);
const _greenMid = Color(0xFFDCFCE7);
const _border = Color(0xFFE4E9E6);
const _ink = Color(0xFF0F1F15);
const _muted = Color(0xFF52675A);
const _hint = Color(0xFF93A89A);
const _red = Color(0xFFDC2626);
const _amber = Color(0xFFD97706);
const _blue = Color(0xFF2563EB);
const _purple = Color(0xFF7C3AED);
const _orange = Color(0xFFEA580C);

class AiRecommendationsScreen extends StatefulWidget {
  final int? farmerID;
  const AiRecommendationsScreen({Key? key, this.farmerID}) : super(key: key);

  @override
  State<AiRecommendationsScreen> createState() =>
      _AiRecommendationsScreenState();
}

class _AiRecommendationsScreenState extends State<AiRecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gemini = Provider.of<GeminiProvider>(context, listen: false);
    if (auth.token != null && auth.currentUser != null) {
      final id = widget.farmerID ?? auth.currentUser!.userId;
      await gemini.getRecommendations(id, auth.token!);
    }
  }

  Future<void> _refresh() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gemini = Provider.of<GeminiProvider>(context, listen: false);
    if (auth.token != null && auth.currentUser != null) {
      final id = widget.farmerID ?? auth.currentUser!.userId;
      await gemini.refresh(id, auth.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GeminiProvider>(
      builder: (context, gemini, _) => Scaffold(
        backgroundColor: _bg,
        appBar: _buildAppBar(gemini),
        body: gemini.isLoading
            ? _buildLoading()
            : gemini.errorMessage != null
                ? _buildError(gemini.errorMessage!, _load)
                : gemini.recommendation == null
                    ? _buildEmpty(_load)
                    : _buildContent(gemini.recommendation!),
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(GeminiProvider gemini) => AppBar(
        elevation: 0,
        backgroundColor: _surface,
        foregroundColor: _ink,
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _border),
        ),
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: _greenMid,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.eco_rounded, color: _green, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Farm Intelligence',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
        ]),
        actions: [
          if (!gemini.isLoading)
            _AppBarButton(
              icon: Icons.refresh_rounded,
              onTap: _refresh,
              tooltip: 'Refresh',
            ),
          const SizedBox(width: 8),
        ],
      );

  // ── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoading() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ScaleTransition(
            scale: _pulse,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _greenMid,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco_rounded, color: _green, size: 38),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Analysing your farm',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 6),
          Text('Milk · Feed · Weather · Finance',
              style: TextStyle(fontSize: 13, color: _hint, letterSpacing: 1)),
          const SizedBox(height: 32),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(color: _green, strokeWidth: 2.5),
          ),
        ]),
      );

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildError(String message, VoidCallback onRetry) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.signal_wifi_bad_rounded,
                  color: _red, size: 30),
            ),
            const SizedBox(height: 16),
            const Text('Analysis failed',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _hint)),
            const SizedBox(height: 24),
            _PrimaryButton(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                onTap: onRetry),
          ]),
        ),
      );

  // ── Empty ─────────────────────────────────────────────────────────────────
  Widget _buildEmpty(VoidCallback onLoad) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: _greenMid, shape: BoxShape.circle),
            child:
                const Icon(Icons.analytics_outlined, color: _green, size: 30),
          ),
          const SizedBox(height: 16),
          const Text('No analysis yet',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 24),
          _PrimaryButton(
              label: 'Generate analysis',
              icon: Icons.auto_awesome_rounded,
              onTap: onLoad),
        ]),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // MAIN CONTENT
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildContent(RecommendationModel data) {
    final rec = data.recommendations;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ─────────────────────────────────────────────────────
        _buildHeaderCard(data),
        const SizedBox(height: 12),

        // ── Score strip ────────────────────────────────────────────────
        _buildScoreStrip(rec),
        const SizedBox(height: 12),

        // ── Data pills ─────────────────────────────────────────────────
        _buildDataRow(data.dataUsed),
        const SizedBox(height: 16),

        // ── Alerts (if any) ────────────────────────────────────────────
        if (rec.smartAlerts != null && rec.smartAlerts!.hasAlerts) ...[
          _buildAlertsCard(rec.smartAlerts!),
          const SizedBox(height: 12),
        ],

        // ── Yield + Financial side by side ──────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _buildYieldMiniCard(rec)),
          const SizedBox(width: 10),
          if (rec.financialSummary != null)
            Expanded(child: _buildFinancialMiniCard(rec.financialSummary!)),
        ]),
        const SizedBox(height: 12),

        // ── Yield detail ───────────────────────────────────────────────
        _buildYieldDetail(rec),
        const SizedBox(height: 12),

        // ── Breed feeding plans ────────────────────────────────────────
        if (rec.breedRecommendations.isNotEmpty) ...[
          _sectionTitle(
              data.isMultiBreed ? 'Breed feeding plans' : 'Feeding plan'),
          const SizedBox(height: 8),
          ...rec.breedRecommendations.map((br) => _buildBreedCard(br)),
        ] else if (rec.feedingPlan != null) ...[
          _sectionTitle('Daily feeding plan'),
          const SizedBox(height: 8),
          _buildFeedingPlanCard(rec.feedingPlan!),
          const SizedBox(height: 12),
        ],

        // ── Weekly timetable ───────────────────────────────────────────
        _sectionTitle('7-day timetable'),
        const SizedBox(height: 8),
        _buildWeeklyTimetable(),
        const SizedBox(height: 12),

        // ── Category scores ────────────────────────────────────────────
        if (rec.scores != null) ...[
          _sectionTitle('Score breakdown'),
          const SizedBox(height: 8),
          _buildCategoryScores(rec.scores!),
          const SizedBox(height: 12),
        ],

        // ── Supplement ─────────────────────────────────────────────────
        if (rec.supplementRecommendation.isNotEmpty) ...[
          _buildBulletCard(
            icon: Icons.science_rounded,
            color: _purple,
            title: 'Supplement plan',
            text: rec.supplementRecommendation,
          ),
          const SizedBox(height: 10),
        ],

        // ── Weather ────────────────────────────────────────────────────
        if (rec.weatherCorrelation != null) ...[
          _buildWeatherCard(rec.weatherCorrelation!),
          const SizedBox(height: 10),
        ],

        // ── Feed efficiency ────────────────────────────────────────────
        if (rec.feedEfficiencyAnalysis.isNotEmpty) ...[
          _buildBulletCard(
            icon: Icons.speed_rounded,
            color: _orange,
            title: 'Feed efficiency',
            text: rec.feedEfficiencyAnalysis,
          ),
          const SizedBox(height: 10),
        ],

        // ── Health ─────────────────────────────────────────────────────
        if (rec.healthAlert.isNotEmpty) ...[
          _buildBulletCard(
            icon: Icons.health_and_safety_rounded,
            color: _red,
            title: 'Health advisory',
            text: rec.healthAlert,
          ),
          const SizedBox(height: 10),
        ],

        // ── Quick tips ─────────────────────────────────────────────────
        if (rec.quickTips.isNotEmpty) ...[
          _buildTipsCard(rec.quickTips),
          const SizedBox(height: 12),
        ],

        // ── Admin badge ────────────────────────────────────────────────
        if (widget.farmerID != null) ...[
          _AdminBadge(farmerName: data.farmerName),
          const SizedBox(height: 12),
        ],

        // ── Refresh ────────────────────────────────────────────────────
        _PrimaryButton(
          label: 'Refresh analysis',
          icon: Icons.auto_awesome_rounded,
          onTap: _refresh,
          fullWidth: true,
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Updated ${data.generatedAtDisplay}',
              style: TextStyle(fontSize: 11, color: _hint)),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeaderCard(RecommendationModel data) => Container(
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data.farmerName,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 2),
              Text(data.farmLocation ?? 'Kenya',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                if (data.isMultiBreed)
                  ...data.breeds.map((b) => _HeaderPill(label: b))
                else if (data.cowBreed != null)
                  _HeaderPill(label: data.cowBreed!),
                if (data.numberOfCows != null)
                  _HeaderPill(
                      label: '${data.numberOfCows} cows',
                      icon: Icons.pets_rounded),
              ]),
            ]),
          ),
        ]),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // SCORE STRIP
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScoreStrip(Recommendations rec) {
    final scoreColor = Color(rec.scoreColorValue);
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(children: [
        // Circular score
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(
              value: rec.overallScore / 100,
              strokeWidth: 5.5,
              backgroundColor: scoreColor.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${rec.overallScore}',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: scoreColor)),
            ]),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(rec.scoreEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(rec.scoreLabel,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: scoreColor)),
            ]),
            const SizedBox(height: 3),
            Text('Overall performance score',
                style: TextStyle(fontSize: 12, color: _hint)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: rec.overallScore / 100,
                minHeight: 5,
                backgroundColor: scoreColor.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DATA PILLS ROW
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDataRow(DataUsed d) => Row(children: [
        _DataPill(
            icon: Icons.water_drop_rounded,
            label: '${d.milkRecords}',
            sub: 'milk',
            color: _blue),
        const SizedBox(width: 8),
        _DataPill(
            icon: Icons.grass_rounded,
            label: '${d.feedingRecords}',
            sub: 'feed',
            color: _green),
        const SizedBox(width: 8),
        _DataPill(
            icon: Icons.cloud_rounded,
            label: '${d.weatherRecords}',
            sub: 'weather',
            color: _hint),
      ]);

  // ══════════════════════════════════════════════════════════════════════════
  // ALERTS CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAlertsCard(SmartAlerts alerts) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _red.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.warning_amber_rounded, color: _red, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                  '${alerts.activeCount} Alert${alerts.activeCount > 1 ? "s" : ""}',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: _red)),
              const Spacer(),
              if (alerts.criticalYieldDrop)
                _StatusBadge(label: 'CRITICAL', color: _red),
            ]),
          ),

          // Alert messages
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: Column(
                children: alerts.alertMessages
                    .map((msg) => _AlertRow(msg: msg))
                    .toList()),
          ),

          // Emergency protocol
          if (alerts.emergencyProtocol.isNotEmpty &&
              alerts.criticalYieldDrop) ...[
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.emergency_rounded,
                          color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('Emergency protocol',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ]),
                    const SizedBox(height: 6),
                    Text(alerts.emergencyProtocol,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white, height: 1.5)),
                  ]),
            ),
          ] else
            const SizedBox(height: 14),
        ]),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // YIELD MINI CARD + FINANCIAL MINI CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildYieldMiniCard(Recommendations rec) => _MiniCard(
        icon: Icons.bar_chart_rounded,
        color: _blue,
        title: 'Yield',
        children: rec.yieldStats == null
            ? []
            : [
                _StatRow(
                    label: 'Avg/cow', value: '${rec.yieldStats!.avgPerCow}L'),
                _StatRow(
                    label: 'Avg/session',
                    value: '${rec.yieldStats!.avgPerSession}L'),
                _StatRow(
                    label: 'Highest',
                    value: '${rec.yieldStats!.highest}L',
                    valueColor: _green),
                _StatRow(
                    label: 'Lowest',
                    value: '${rec.yieldStats!.lowest}L',
                    valueColor: _red),
              ],
      );

  Widget _buildFinancialMiniCard(FinancialSummary fin) => _MiniCard(
        icon: Icons.account_balance_wallet_rounded,
        color: _green,
        title: 'Finance',
        children: [
          _StatRow(label: 'Revenue', value: fin.totalRevenue),
          _StatRow(
              label: 'Feed cost', value: fin.totalFeedCost, valueColor: _red),
          _StatRow(
              label: 'Margin', value: fin.profitMargin, valueColor: _green),
          _StatRow(label: 'KSh/litre', value: fin.revenuePerLitre),
        ],
      );

  // ══════════════════════════════════════════════════════════════════════════
  // YIELD DETAIL (analysis text + performance badge)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildYieldDetail(Recommendations rec) {
    if (rec.yieldStats == null) {
      return _buildBulletCard(
        icon: Icons.bar_chart_rounded,
        color: _blue,
        title: 'Yield analysis',
        text: rec.yieldAnalysis,
      );
    }
    final above = rec.yieldStats!.isAboveStandard;
    final below = rec.yieldStats!.isBelowStandard;
    final badgeColor = above
        ? _green
        : below
            ? _red
            : _blue;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _IconBox(icon: Icons.bar_chart_rounded, color: _blue),
          const SizedBox(width: 10),
          const Text('Yield analysis',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
          const Spacer(),
          _StatusBadge(
            label: above
                ? 'Above standard'
                : below
                    ? 'Below standard'
                    : 'At standard',
            color: badgeColor,
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: badgeColor.withOpacity(0.15)),
          ),
          child: Text(rec.yieldStats!.performance,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: badgeColor)),
        ),
        const SizedBox(height: 10),
        _BulletText(text: rec.yieldAnalysis, color: _blue),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CATEGORY SCORES
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCategoryScores(CategoryScores scores) => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          _ScoreBar(label: 'Yield', score: scores.yield_, color: _blue),
          const SizedBox(height: 8),
          _ScoreBar(label: 'Feeding', score: scores.feeding, color: _green),
          const SizedBox(height: 8),
          _ScoreBar(label: 'Health', score: scores.health, color: _red),
          const SizedBox(height: 8),
          _ScoreBar(label: 'Weather', score: scores.weather, color: _blue),
        ]),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // BULLET CARD (generic: supplement, feed eff, health, weather impact)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBulletCard({
    required IconData icon,
    required Color color,
    required String title,
    required String text,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _IconBox(icon: icon, color: color),
            const SizedBox(width: 10),
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _ink))),
          ]),
          const SizedBox(height: 10),
          _BulletText(text: text, color: color),
        ]),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // WEATHER CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWeatherCard(WeatherCorrelation wc) => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _IconBox(icon: Icons.thermostat_rounded, color: _blue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Weather correlation',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                    Text(wc.currentCondition,
                        style: TextStyle(fontSize: 11, color: _hint)),
                  ]),
            ),
            if (wc.heatStressActive)
              _StatusBadge(label: 'HEAT STRESS', color: _red),
          ]),
          const SizedBox(height: 10),
          if (wc.yieldImpact.isNotEmpty) ...[
            _BulletText(
                text: wc.yieldImpact,
                color: wc.heatStressActive ? _red : _green),
            const SizedBox(height: 8),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _blue.withOpacity(0.12)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.lightbulb_outline_rounded, color: _blue, size: 13),
              const SizedBox(width: 7),
              Expanded(
                child: Text(wc.recommendations,
                    style: TextStyle(fontSize: 12, color: _muted, height: 1.5)),
              ),
            ]),
          ),
        ]),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // TIPS CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTipsCard(List<String> tips) => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _IconBox(icon: Icons.tips_and_updates_rounded, color: _amber),
            const SizedBox(width: 10),
            const Text('Quick action tips',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
          ]),
          const SizedBox(height: 12),
          ...tips.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(6)),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(e.value,
                            style: TextStyle(
                                fontSize: 12, color: _muted, height: 1.5)),
                      ),
                    ]),
              )),
        ]),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // BREED CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBreedCard(BreedRecommendation br) {
    final color = br.breedColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Breed header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
          ),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                  child: Text(br.breedEmoji,
                      style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(br.breed,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: color)),
                    Text(br.yieldStandard,
                        style: TextStyle(
                            fontSize: 11, color: color.withOpacity(0.65))),
                  ]),
            ),
            if (br.yieldTarget.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(br.yieldTarget,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Feeding schedule',
                style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: color.withOpacity(0.6))),
            const SizedBox(height: 8),
            _FeedSession(
                emoji: '🌅',
                time: '6:00 AM',
                content: br.feedingPlan.morning,
                color: color),
            const SizedBox(height: 6),
            _FeedSession(
                emoji: '☀️',
                time: '12:00 PM',
                content: br.feedingPlan.afternoon,
                color: color),
            const SizedBox(height: 6),
            _FeedSession(
                emoji: '🌙',
                time: '6:00 PM',
                content: br.feedingPlan.evening,
                color: color),
            if (br.feedingPlan.dailyTotalPerCow.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withOpacity(0.18)),
                ),
                child: Row(children: [
                  Icon(Icons.summarize_rounded, color: color, size: 13),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                        'Total / cow: ${br.feedingPlan.dailyTotalPerCow}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  ),
                ]),
              ),
            ],
            if (br.supplementPlan.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Supplements',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: color.withOpacity(0.6))),
              const SizedBox(height: 6),
              _BulletText(text: br.supplementPlan, color: _purple),
            ],
            if (br.specificTips.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Breed tips',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: color.withOpacity(0.6))),
              const SizedBox(height: 6),
              ...br.specificTips.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(5)),
                            child: Center(
                                child: Text('${e.key + 1}',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(e.value,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _muted,
                                      height: 1.5))),
                        ]),
                  )),
            ],
          ]),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FEEDING PLAN CARD (single-breed fallback)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildFeedingPlanCard(FeedingPlan plan) => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _IconBox(icon: Icons.schedule_rounded, color: _green),
            const SizedBox(width: 10),
            const Text('Daily feeding schedule',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _ink)),
          ]),
          const SizedBox(height: 12),
          _FeedSession(
              emoji: '🌅',
              time: '6:00 AM',
              content: plan.morning,
              color: _green),
          const SizedBox(height: 7),
          _FeedSession(
              emoji: '☀️',
              time: '12:00 PM',
              content: plan.afternoon,
              color: _amber),
          const SizedBox(height: 7),
          _FeedSession(
              emoji: '🌙',
              time: '6:00 PM',
              content: plan.evening,
              color: _purple),
          if (plan.dailyTotalPerCow.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _green.withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.summarize_rounded, color: _green, size: 13),
                const SizedBox(width: 7),
                Expanded(
                  child: Text('Total / cow: ${plan.dailyTotalPerCow}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _green)),
                ),
              ]),
            ),
          ],
        ]),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // WEEKLY TIMETABLE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildWeeklyTimetable() {
    final List<Map<String, dynamic>> week = [
      {
        'day': 'Monday',
        'emoji': '🌿',
        'highlight': 'Napier + Rhodes',
        'color': _green,
        'morning': 'Napier 18kg · Dairy Meal 3kg · Water 50L',
        'afternoon': 'Rhodes 10kg · Mineral Lick 30g · Water 30L',
        'evening': 'Napier 17kg · Dairy Meal 3kg · Dairy Cal 50g'
      },
      {
        'day': 'Tuesday',
        'emoji': '🌾',
        'highlight': 'Silage — high energy',
        'color': _amber,
        'morning': 'Maize Silage 15kg · Dairy Meal 3kg · Water 50L',
        'afternoon': 'Napier 10kg · Vitamin AD3E 2.5ml · Water 30L',
        'evening': 'Maize Silage 10kg · Dairy Meal 3kg · Mineral Lick 30g'
      },
      {
        'day': 'Wednesday',
        'emoji': '🥬',
        'highlight': 'Lucerne — high protein',
        'color': _blue,
        'morning': 'Napier 18kg · Dairy Meal 3kg · Water 50L',
        'afternoon': 'Lucerne 8kg · Wheat Bran 2kg · Water 30L',
        'evening': 'Napier 17kg · Dairy Meal 3kg · Dairy Cal 50g'
      },
      {
        'day': 'Thursday',
        'emoji': '🌱',
        'highlight': 'Brewers grain day',
        'color': _purple,
        'morning': 'Napier 15kg · Brewers Grain 5kg · Water 50L',
        'afternoon': 'Rhodes 10kg · Mineral Lick 30g · Water 30L',
        'evening': 'Napier 15kg · Dairy Meal 3kg · Cotton Seed 2kg'
      },
      {
        'day': 'Friday',
        'emoji': '🍃',
        'highlight': 'Hay + Molasses',
        'color': _red,
        'morning': 'Napier 18kg · Dairy Meal 3kg · Water 50L',
        'afternoon': 'Hay 8kg · Molasses 0.5kg · Water 30L',
        'evening': 'Napier 17kg · Dairy Meal 3kg · Mineral Lick 30g'
      },
      {
        'day': 'Saturday',
        'emoji': '🫘',
        'highlight': 'Soya protein day',
        'color': _orange,
        'morning': 'Maize Silage 15kg · Soya Meal 2kg · Water 50L',
        'afternoon': 'Napier 10kg · Vitamin AD3E 2.5ml · Water 30L',
        'evening': 'Maize Silage 10kg · Dairy Meal 3kg · Dairy Cal 50g'
      },
      {
        'day': 'Sunday',
        'emoji': '🌻',
        'highlight': 'Lucerne finish',
        'color': _greenDark,
        'morning': 'Napier 18kg · Dairy Meal 3kg · Water 50L',
        'afternoon': 'Lucerne 10kg · Mineral Lick 30g · Water 30L',
        'evening': 'Napier 17kg · Dairy Meal 3kg · Wheat Bran 2kg'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
          ),
          child: Row(children: [
            _IconBox(icon: Icons.calendar_month_rounded, color: _green),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('7-day feeding timetable',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _ink)),
                    Text('Varied feeds for optimal nutrition',
                        style: TextStyle(fontSize: 11, color: _hint)),
                  ]),
            ),
            _StatusBadge(label: 'per cow', color: _green),
          ]),
        ),

        const Divider(height: 1, thickness: 0.5, indent: 14, endIndent: 14),

        ...week.map((d) => _buildDayRow(d)),

        // Footer
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: _amber.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _amber.withOpacity(0.25)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, color: _amber, size: 13),
            const SizedBox(width: 7),
            const Expanded(
              child: Text(
                'Amounts are per cow. Multiply by herd size. '
                'Increase Dairy Meal by 1kg per 5L above baseline yield.',
                style: TextStyle(fontSize: 11, color: _muted, height: 1.45),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildDayRow(Map<String, dynamic> d) {
    final color = d['color'] as Color;
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9)),
          child: Center(
              child: Text(d['emoji'] as String,
                  style: const TextStyle(fontSize: 16))),
        ),
        title: Text(d['day'] as String,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
        subtitle: Text(d['highlight'] as String,
            style: TextStyle(fontSize: 10, color: color)),
        iconColor: color,
        collapsedIconColor: _hint,
        children: [
          _DaySession(
              emoji: '🌅',
              time: '6 AM',
              content: d['morning'] as String,
              color: color),
          const SizedBox(height: 5),
          _DaySession(
              emoji: '☀️',
              time: '12 PM',
              content: d['afternoon'] as String,
              color: color),
          const SizedBox(height: 5),
          _DaySession(
              emoji: '🌙',
              time: '6 PM',
              content: d['evening'] as String,
              color: color),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(t.toUpperCase(),
            style: TextStyle(
                fontSize: 9,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
                color: _hint)),
      );
}

// ══════════════════════════════════════════════════════════════════════════
// REUSABLE COMPONENTS
// ══════════════════════════════════════════════════════════════════════════

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBox({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: color, size: 16),
      );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5)),
      );
}

class _HeaderPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _HeaderPill({required this.label, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: Colors.white70),
            const SizedBox(width: 4)
          ],
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

class _DataPill extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color color;
  const _DataPill(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(width: 3),
            Flexible(
                child: Text(sub,
                    style: const TextStyle(fontSize: 10, color: _hint),
                    overflow: TextOverflow.ellipsis)),
          ]),
        ),
      );
}

class _AlertRow extends StatelessWidget {
  final String msg;
  const _AlertRow({required this.msg});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _red.withOpacity(0.15)),
        ),
        child: Text(msg,
            style: const TextStyle(fontSize: 12, color: _ink, height: 1.45)),
      );
}

/// Parses text into bullet points. Splits on numbered lists, bullet chars, or period+space.
class _BulletText extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletText({required this.text, required this.color});

  List<String> _parse() {
    // Try splitting on numbered patterns like "1." or "1)"
    final numbered = RegExp(r'\d+[.)]\s+');
    if (numbered.hasMatch(text)) {
      return text.split(numbered).where((s) => s.trim().isNotEmpty).toList();
    }
    // Try bullet chars
    if (text.contains('•') || text.contains('-')) {
      return text
          .split(RegExp(r'[•\-]\s*'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    // Split on sentences
    final sentences = text.split(RegExp(r'(?<=\.)\s+'));
    if (sentences.length > 1)
      return sentences.where((s) => s.trim().isNotEmpty).toList();
    return [text];
  }

  @override
  Widget build(BuildContext context) {
    final bullets = _parse();
    if (bullets.length == 1) {
      return Text(text,
          style: TextStyle(fontSize: 12, color: _muted, height: 1.55));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bullets
          .map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(b.trim(),
                              style: TextStyle(
                                  fontSize: 12, color: _muted, height: 1.5))),
                    ]),
              ))
          .toList(),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<Widget> children;
  const _MiniCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.children});
  @override
  Widget build(BuildContext context) => Container(
        height: 180,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _IconBox(icon: icon, color: color),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5, color: _border),
          const SizedBox(height: 8),
          ...children,
        ]),
      );
}

class _StatRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _StatRow({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _hint)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? _ink)),
        ]),
      );
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const _ScoreBar(
      {required this.label, required this.score, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
            width: 56,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: _muted))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 7,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text('$score',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color),
              textAlign: TextAlign.right),
        ),
      ]);
}

class _FeedSession extends StatelessWidget {
  final String emoji, time, content;
  final Color color;
  const _FeedSession(
      {required this.emoji,
      required this.time,
      required this.content,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.13)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          SizedBox(
            width: 58,
            child: Text(time,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: color)),
          ),
          Expanded(
              child: Text(content,
                  style: const TextStyle(
                      fontSize: 11, color: _muted, height: 1.4))),
        ]),
      );
}

class _DaySession extends StatelessWidget {
  final String emoji, time, content;
  final Color color;
  const _DaySession(
      {required this.emoji,
      required this.time,
      required this.content,
      required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 7),
          SizedBox(
            width: 54,
            child: Text(time,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ),
          Expanded(
              child: Text(content,
                  style: const TextStyle(
                      fontSize: 11, color: _muted, height: 1.4))),
        ]),
      );
}

class _AdminBadge extends StatelessWidget {
  final String farmerName;
  const _AdminBadge({required this.farmerName});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _purple.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _purple.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Icon(Icons.admin_panel_settings_rounded,
              size: 14, color: _purple),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Admin view — $farmerName',
                style: const TextStyle(
                    fontSize: 12, color: _purple, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool fullWidth;
  const _PrimaryButton(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.fullWidth = false});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: fullWidth ? double.infinity : null,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          label: Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      );
}

class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _AppBarButton(
      {required this.icon, required this.onTap, required this.tooltip});
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _greenMid,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _green, size: 18),
          ),
        ),
      );
}
