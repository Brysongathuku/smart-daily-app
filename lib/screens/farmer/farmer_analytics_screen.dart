import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/milk_collection_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/milk_collection_provider.dart';

const _bg = Color(0xFFF8FAFC);
const _white = Color(0xFFFFFFFF);
const _green = Color(0xFF16A34A);
const _border = Color(0xFFE2E8F0);
const _dark = Color(0xFF0F172A);
const _mid = Color(0xFF475569);
const _light = Color(0xFF94A3B8);

class FarmerAnalyticsScreen extends StatefulWidget {
  const FarmerAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<FarmerAnalyticsScreen> createState() => _FarmerAnalyticsScreenState();
}

class _FarmerAnalyticsScreenState extends State<FarmerAnalyticsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final milk = Provider.of<MilkCollectionProvider>(context, listen: false);
    if (auth.token != null && auth.currentUser != null) {
      await milk.getCollectionsByFarmer(auth.currentUser!.userId, auth.token!);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final milk = Provider.of<MilkCollectionProvider>(context);

    // ── Strongly typed list ────────────────────────────────────────────
    final List<MilkCollectionModel> collections =
        milk.collections.map((e) => e).toList();

    // ── Compute stats ──────────────────────────────────────────────────
    double totalLiters = 0;
    double totalEarnings = 0;
    double highestMilk = 0;
    double lowestMilk = double.infinity;

    for (final c in collections) {
      totalLiters += c.quantityInLiters;
      totalEarnings += c.totalAmount;
      if (c.quantityInLiters > highestMilk) highestMilk = c.quantityInLiters;
      if (c.quantityInLiters < lowestMilk) lowestMilk = c.quantityInLiters;
    }
    if (collections.isEmpty) lowestMilk = 0;
    final avgMilk =
        collections.isEmpty ? 0.0 : totalLiters / collections.length;

    // ── Last 7 for charts ──────────────────────────────────────────────
    final List<MilkCollectionModel> last7 =
        collections.take(7).toList().reversed.toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _white,
        foregroundColor: _dark,
        title: const Text(
          'Analytics',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w800, color: _dark),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : collections.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _green,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Summary cards ──────────────────────────────
                        _buildSummaryRow(
                          totalLiters: totalLiters,
                          totalEarnings: totalEarnings,
                          avgMilk: avgMilk,
                          total: collections.length,
                        ),
                        const SizedBox(height: 20),

                        // ── Milk yield line chart ──────────────────────
                        _sectionLabel('MILK YIELD OVER TIME'),
                        const SizedBox(height: 10),
                        _buildMilkLineChart(last7),
                        const SizedBox(height: 20),

                        // ── Daily earnings bar chart ───────────────────
                        _sectionLabel('DAILY EARNINGS TREND'),
                        const SizedBox(height: 10),
                        _buildEarningsBarChart(last7),
                        const SizedBox(height: 20),

                        // ── Quality breakdown ──────────────────────────
                        _sectionLabel('QUALITY BREAKDOWN'),
                        const SizedBox(height: 10),
                        _buildQualityBreakdown(collections),
                        const SizedBox(height: 20),

                        // ── Performance highlights ─────────────────────
                        _sectionLabel('PERFORMANCE HIGHLIGHTS'),
                        const SizedBox(height: 10),
                        _buildHighlights(
                            highestMilk, lowestMilk, avgMilk, collections),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 9,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
                color: _light)),
      );

  // ── Summary cards ─────────────────────────────────────────────────────────
  Widget _buildSummaryRow({
    required double totalLiters,
    required double totalEarnings,
    required double avgMilk,
    required int total,
  }) {
    final fmt = NumberFormat('#,##0');
    return Column(children: [
      Row(children: [
        _statCard('Total Litres', '${totalLiters.toStringAsFixed(1)}L',
            Icons.water_drop_rounded, const Color(0xFF3B82F6)),
        const SizedBox(width: 10),
        _statCard('Total Earnings', 'KSh ${fmt.format(totalEarnings)}',
            Icons.payments_rounded, _green),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        _statCard('Avg Per Session', '${avgMilk.toStringAsFixed(1)}L',
            Icons.trending_up_rounded, const Color(0xFF8B5CF6)),
        const SizedBox(width: 10),
        _statCard('Collections', '$total total', Icons.list_alt_rounded,
            const Color(0xFFF97316)),
      ]),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _dark),
                        overflow: TextOverflow.ellipsis),
                    Text(label,
                        style: const TextStyle(fontSize: 10, color: _light)),
                  ]),
            ),
          ]),
        ),
      );

  // ── Milk yield line chart ─────────────────────────────────────────────────
  Widget _buildMilkLineChart(List<MilkCollectionModel> data) {
    if (data.isEmpty) return _emptyChart('No milk data yet');

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.quantityInLiters))
        .toList();

    final maxY =
        data.map((c) => c.quantityInLiters).reduce((a, b) => a > b ? a : b) + 5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Litres collected per session',
            style: TextStyle(fontSize: 12, color: _mid)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: LineChart(LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: _border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}L',
                      style: const TextStyle(fontSize: 9, color: _light)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= data.length) return const SizedBox();
                    final date = DateTime.tryParse(data[i].collectionDate);
                    return Text(
                      date != null ? DateFormat('dd/MM').format(date) : '',
                      style: const TextStyle(fontSize: 9, color: _light),
                    );
                  },
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: _green,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 4,
                    color: _white,
                    strokeWidth: 2,
                    strokeColor: _green,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: _green.withOpacity(0.08),
                ),
              ),
            ],
          )),
        ),
      ]),
    );
  }

  // ── Earnings bar chart ────────────────────────────────────────────────────
  Widget _buildEarningsBarChart(List<MilkCollectionModel> data) {
    if (data.isEmpty) return _emptyChart('No earnings data yet');

    final maxY =
        data.map((c) => c.totalAmount).reduce((a, b) => a > b ? a : b) + 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Earnings per collection (KSh)',
            style: TextStyle(fontSize: 12, color: _mid)),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: BarChart(BarChartData(
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  FlLine(color: _border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (v, _) => Text(
                    NumberFormat('#,##0').format(v.toInt()),
                    style: const TextStyle(fontSize: 9, color: _light),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= data.length) return const SizedBox();
                    final date = DateTime.tryParse(data[i].collectionDate);
                    return Text(
                      date != null ? DateFormat('dd/MM').format(date) : '',
                      style: const TextStyle(fontSize: 9, color: _light),
                    );
                  },
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: data.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.totalAmount,
                    color: const Color(0xFF3B82F6),
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              );
            }).toList(),
          )),
        ),
      ]),
    );
  }

  // ── Quality breakdown ─────────────────────────────────────────────────────
  Widget _buildQualityBreakdown(List<MilkCollectionModel> collections) {
    final Map<String, int> qualityMap = {};
    for (final c in collections) {
      qualityMap[c.qualityGrade] = (qualityMap[c.qualityGrade] ?? 0) + 1;
    }

    final colors = [
      _green,
      const Color(0xFF3B82F6),
      const Color(0xFFF97316),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: qualityMap.entries.toList().asMap().entries.map((e) {
          final index = e.key;
          final grade = e.value.key;
          final count = e.value.value;
          final percent = (count / collections.length * 100).toStringAsFixed(1);
          final color = colors[index % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(grade,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _dark)),
                    ]),
                    Text('$count ($percent%)',
                        style: const TextStyle(fontSize: 11, color: _light)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: count / collections.length,
                    minHeight: 6,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Performance highlights ────────────────────────────────────────────────
  Widget _buildHighlights(
    double highest,
    double lowest,
    double avg,
    List<MilkCollectionModel> collections,
  ) {
    final MilkCollectionModel highestCol = collections.reduce(
        (MilkCollectionModel a, MilkCollectionModel b) =>
            a.quantityInLiters > b.quantityInLiters ? a : b);

    final MilkCollectionModel lowestCol = collections.reduce(
        (MilkCollectionModel a, MilkCollectionModel b) =>
            a.quantityInLiters < b.quantityInLiters ? a : b);

    return Column(children: [
      _highlightCard(
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFF59E0B),
        title: 'Best Collection',
        value: '${highest.toStringAsFixed(1)}L',
        sub: DateFormat('dd MMM yyyy').format(
            DateTime.tryParse(highestCol.collectionDate) ?? DateTime.now()),
      ),
      const SizedBox(height: 10),
      _highlightCard(
        icon: Icons.trending_down_rounded,
        color: const Color(0xFFEF4444),
        title: 'Lowest Collection',
        value: '${lowest.toStringAsFixed(1)}L',
        sub: DateFormat('dd MMM yyyy').format(
            DateTime.tryParse(lowestCol.collectionDate) ?? DateTime.now()),
      ),
      const SizedBox(height: 10),
      _highlightCard(
        icon: Icons.show_chart_rounded,
        color: _green,
        title: 'Average Collection',
        value: '${avg.toStringAsFixed(1)}L',
        sub: 'Across all ${collections.length} collections',
      ),
    ]);
  }

  Widget _highlightCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String sub,
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 12, color: _light)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
              Text(sub, style: const TextStyle(fontSize: 11, color: _light)),
            ]),
          ),
        ]),
      );

  // ── Empty states ──────────────────────────────────────────────────────────
  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('No data yet',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _dark)),
            const SizedBox(height: 8),
            const Text(
              'Record some milk collections\nto see your analytics',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _light),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );

  Widget _emptyChart(String msg) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Center(
          child: Text(msg, style: const TextStyle(fontSize: 13, color: _light)),
        ),
      );
}
