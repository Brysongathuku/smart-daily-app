import 'dart:ui';

class RecommendationModel {
  final int farmerID;
  final String farmerName;
  final String? farmLocation;
  final String? cowBreed;
  final int? numberOfCows;
  final List<String> breeds;
  final bool isMultiBreed;
  final DataUsed dataUsed;
  final Recommendations recommendations;
  final String generatedAt;

  RecommendationModel({
    required this.farmerID,
    required this.farmerName,
    this.farmLocation,
    this.cowBreed,
    this.numberOfCows,
    this.breeds = const [],
    this.isMultiBreed = false,
    required this.dataUsed,
    required this.recommendations,
    required this.generatedAt,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    return RecommendationModel(
      farmerID: json['farmerID'] ?? 0,
      farmerName: json['farmerName'] ?? '',
      farmLocation: json['farmLocation'],
      cowBreed: json['cowBreed'],
      numberOfCows: json['numberOfCows'],
      breeds: List<String>.from(json['breeds'] ?? []),
      isMultiBreed: json['isMultiBreed'] ?? false,
      dataUsed: DataUsed.fromJson(json['dataUsed'] ?? {}),
      recommendations: Recommendations.fromJson(json['recommendations'] ?? {}),
      generatedAt: json['generatedAt'] ?? '',
    );
  }

  String get generatedAtDisplay {
    try {
      final dt = DateTime.parse(generatedAt).toLocal();
      final h = dt.hour > 12
          ? dt.hour - 12
          : dt.hour == 0
              ? 12
              : dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '${dt.day}/${dt.month}/${dt.year} $h:$m $ap';
    } catch (_) {
      return generatedAt;
    }
  }
}

// ── Data used ─────────────────────────────────────────────────────────────
class DataUsed {
  final int milkRecords;
  final int feedingRecords;
  final int weatherRecords;

  DataUsed({
    required this.milkRecords,
    required this.feedingRecords,
    required this.weatherRecords,
  });

  factory DataUsed.fromJson(Map<String, dynamic> json) => DataUsed(
        milkRecords: json['milkRecords'] ?? 0,
        feedingRecords: json['feedingRecords'] ?? 0,
        weatherRecords: json['weatherRecords'] ?? 0,
      );
}

// ── Yield stats ───────────────────────────────────────────────────────────
class YieldStats {
  final String avgPerSession;
  final String avgPerCow;
  final String highest;
  final String lowest;
  final String breedStandard;
  final String performance;

  YieldStats({
    required this.avgPerSession,
    required this.avgPerCow,
    required this.highest,
    required this.lowest,
    required this.breedStandard,
    required this.performance,
  });

  factory YieldStats.fromJson(Map<String, dynamic> json) => YieldStats(
        avgPerSession: json['avgPerSession']?.toString() ?? '0',
        avgPerCow: json['avgPerCow']?.toString() ?? '0',
        highest: json['highest']?.toString() ?? '0',
        lowest: json['lowest']?.toString() ?? '0',
        breedStandard: json['breedStandard']?.toString() ?? '',
        performance: json['performance']?.toString() ?? '',
      );

  bool get isAboveStandard => performance.toLowerCase().contains('above');
  bool get isBelowStandard => performance.toLowerCase().contains('below');
}

// ── Smart alerts ──────────────────────────────────────────────────────────
class SmartAlerts {
  final bool criticalYieldDrop;
  final bool feedBelowStandard;
  final bool fatContentAlert;
  final bool heatStressAlert;
  final List<String> alertMessages;
  final String emergencyProtocol;

  SmartAlerts({
    required this.criticalYieldDrop,
    required this.feedBelowStandard,
    required this.fatContentAlert,
    required this.heatStressAlert,
    required this.alertMessages,
    required this.emergencyProtocol,
  });

  factory SmartAlerts.fromJson(Map<String, dynamic> json) => SmartAlerts(
        criticalYieldDrop: json['criticalYieldDrop'] ?? false,
        feedBelowStandard: json['feedBelowStandard'] ?? false,
        fatContentAlert: json['fatContentAlert'] ?? false,
        heatStressAlert: json['heatStressAlert'] ?? false,
        alertMessages: List<String>.from(json['alertMessages'] ?? []),
        emergencyProtocol: json['emergencyProtocol']?.toString() ?? '',
      );

  int get activeCount => [
        criticalYieldDrop,
        feedBelowStandard,
        fatContentAlert,
        heatStressAlert,
      ].where((a) => a).length;

  bool get hasAlerts => activeCount > 0;
}

// ── Financial summary ─────────────────────────────────────────────────────
class FinancialSummary {
  final String totalRevenue;
  final String totalFeedCost;
  final String profitMargin;
  final String revenuePerLitre;
  final String costPerLitre;
  final String feedEfficiency;
  final String improvement;

  FinancialSummary({
    required this.totalRevenue,
    required this.totalFeedCost,
    required this.profitMargin,
    required this.revenuePerLitre,
    required this.costPerLitre,
    required this.feedEfficiency,
    required this.improvement,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) =>
      FinancialSummary(
        totalRevenue: json['totalRevenue']?.toString() ?? '',
        totalFeedCost: json['totalFeedCost']?.toString() ?? '',
        profitMargin: json['profitMargin']?.toString() ?? '',
        revenuePerLitre: json['revenuePerLitre']?.toString() ?? '',
        costPerLitre: json['costPerLitre']?.toString() ?? '',
        feedEfficiency: json['feedEfficiency']?.toString() ?? '',
        improvement: json['improvement']?.toString() ?? '',
      );
}

// ── Weather correlation ───────────────────────────────────────────────────
class WeatherCorrelation {
  final String currentCondition;
  final bool heatStressActive;
  final String yieldImpact;
  final String recommendations;

  WeatherCorrelation({
    required this.currentCondition,
    required this.heatStressActive,
    required this.yieldImpact,
    required this.recommendations,
  });

  factory WeatherCorrelation.fromJson(Map<String, dynamic> json) =>
      WeatherCorrelation(
        currentCondition: json['currentCondition']?.toString() ?? '',
        heatStressActive: json['heatStressActive'] ?? false,
        yieldImpact: json['yieldImpact']?.toString() ?? '',
        recommendations: json['recommendations']?.toString() ?? '',
      );
}

// ── Feeding plan ──────────────────────────────────────────────────────────
class FeedingPlan {
  final String morning;
  final String afternoon;
  final String evening;
  final String dailyTotalPerCow;

  FeedingPlan({
    required this.morning,
    required this.afternoon,
    required this.evening,
    required this.dailyTotalPerCow,
  });

  factory FeedingPlan.fromJson(Map<String, dynamic> json) => FeedingPlan(
        morning: json['morning']?.toString() ?? '',
        afternoon: json['afternoon']?.toString() ?? '',
        evening: json['evening']?.toString() ?? '',
        dailyTotalPerCow: json['dailyTotalPerCow']?.toString() ?? '',
      );
}

// ── Per-breed recommendation ──────────────────────────────────────────────
class BreedRecommendation {
  final String breed;
  final String yieldStandard;
  final FeedingPlan feedingPlan;
  final String supplementPlan;
  final String yieldTarget;
  final List<String> specificTips;

  BreedRecommendation({
    required this.breed,
    required this.yieldStandard,
    required this.feedingPlan,
    required this.supplementPlan,
    required this.yieldTarget,
    required this.specificTips,
  });

  factory BreedRecommendation.fromJson(Map<String, dynamic> json) =>
      BreedRecommendation(
        breed: json['breed']?.toString() ?? '',
        yieldStandard: json['yieldStandard']?.toString() ?? '',
        feedingPlan: FeedingPlan.fromJson(json['feedingPlan'] ?? {}),
        supplementPlan: json['supplementPlan']?.toString() ?? '',
        yieldTarget: json['yieldTarget']?.toString() ?? '',
        specificTips: List<String>.from(json['specificTips'] ?? []),
      );

  Color get breedColor {
    switch (breed.toLowerCase()) {
      case 'friesian':
        return const Color(0xFF1D4ED8);
      case 'holstein':
        return const Color(0xFF0F766E);
      case 'ayrshire':
        return const Color(0xFFB45309);
      case 'jersey':
        return const Color(0xFF7C3AED);
      case 'sahiwal':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF16A34A);
    }
  }

  String get breedEmoji {
    switch (breed.toLowerCase()) {
      case 'friesian':
        return '🐄';
      case 'holstein':
        return '🐃';
      case 'ayrshire':
        return '🐮';
      case 'jersey':
        return '🐂';
      case 'sahiwal':
        return '🦬';
      default:
        return '🐄';
    }
  }
}

// ── Category scores ───────────────────────────────────────────────────────
class CategoryScores {
  final int yield_;
  final int feeding;
  final int health;
  final int weather;

  CategoryScores({
    required this.yield_,
    required this.feeding,
    required this.health,
    required this.weather,
  });

  factory CategoryScores.fromJson(Map<String, dynamic> json) => CategoryScores(
        yield_: json['yield'] ?? 0,
        feeding: json['feeding'] ?? 0,
        health: json['health'] ?? 0,
        weather: json['weather'] ?? 0,
      );
}

// ── Recommendations ───────────────────────────────────────────────────────
class Recommendations {
  final String yieldAnalysis;
  final YieldStats? yieldStats;
  final SmartAlerts? smartAlerts; // ✅ added
  final FinancialSummary? financialSummary; // ✅ added
  final WeatherCorrelation? weatherCorrelation; // ✅ added
  final String feedEfficiencyAnalysis; // ✅ fixed (was a broken getter)
  final List<BreedRecommendation> breedRecommendations;
  final FeedingPlan? feedingPlan;
  final String supplementRecommendation;
  final String feedingRecommendation;
  final String weatherImpact;
  final String healthAlert;
  final List<String> quickTips;
  final CategoryScores? scores;
  final int overallScore;
  final String scoreLabel;

  Recommendations({
    required this.yieldAnalysis,
    this.yieldStats,
    this.smartAlerts,
    this.financialSummary,
    this.weatherCorrelation,
    this.feedEfficiencyAnalysis = '',
    this.breedRecommendations = const [],
    this.feedingPlan,
    required this.supplementRecommendation,
    required this.feedingRecommendation,
    required this.weatherImpact,
    required this.healthAlert,
    required this.quickTips,
    this.scores,
    required this.overallScore,
    required this.scoreLabel,
  });

  factory Recommendations.fromJson(Map<String, dynamic> json) {
    final breedRecs = (json['breedRecommendations'] as List<dynamic>? ?? [])
        .map((e) => BreedRecommendation.fromJson(e as Map<String, dynamic>))
        .toList();

    return Recommendations(
      yieldAnalysis: json['yieldAnalysis'] ?? '',
      yieldStats: json['yieldStats'] != null
          ? YieldStats.fromJson(json['yieldStats'])
          : null,
      smartAlerts: json['smartAlerts'] != null
          ? SmartAlerts.fromJson(json['smartAlerts'])
          : null,
      financialSummary: json['financialSummary'] != null
          ? FinancialSummary.fromJson(json['financialSummary'])
          : null,
      weatherCorrelation: json['weatherCorrelation'] != null
          ? WeatherCorrelation.fromJson(json['weatherCorrelation'])
          : null,
      feedEfficiencyAnalysis: json['feedEfficiencyAnalysis']?.toString() ?? '',
      breedRecommendations: breedRecs,
      feedingPlan: json['feedingPlan'] != null
          ? FeedingPlan.fromJson(json['feedingPlan'])
          : null,
      supplementRecommendation: json['supplementRecommendation'] ?? '',
      feedingRecommendation: json['feedingRecommendation'] ?? '',
      weatherImpact: json['weatherImpact'] ?? '',
      healthAlert: json['healthAlert'] ?? '',
      quickTips: List<String>.from(json['quickTips'] ?? []),
      scores: json['scores'] != null
          ? CategoryScores.fromJson(json['scores'])
          : null,
      overallScore: json['overallScore'] ?? 0,
      scoreLabel: json['scoreLabel'] ?? 'Unknown',
    );
  }

  int get scoreColorValue {
    if (overallScore >= 81) return 0xFF16A34A;
    if (overallScore >= 61) return 0xFF3B82F6;
    if (overallScore >= 41) return 0xFFF97316;
    return 0xFFEF4444;
  }

  String get scoreEmoji {
    if (overallScore >= 81) return '🏆';
    if (overallScore >= 61) return '👍';
    if (overallScore >= 41) return '⚠️';
    return '🚨';
  }
}
