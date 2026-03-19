class RecommendationModel {
  final int farmerID;
  final String farmerName;
  final String? farmLocation;
  final String? cowBreed;
  final int? numberOfCows;
  final DataUsed dataUsed;
  final Recommendations recommendations;
  final String generatedAt;

  RecommendationModel({
    required this.farmerID,
    required this.farmerName,
    this.farmLocation,
    this.cowBreed,
    this.numberOfCows,
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
      dataUsed: DataUsed.fromJson(json['dataUsed'] ?? {}),
      recommendations: Recommendations.fromJson(json['recommendations'] ?? {}),
      generatedAt: json['generatedAt'] ?? '',
    );
  }

  // ── Formatted generated time ──────────────────────────────────────────────
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

// ── Data used summary ─────────────────────────────────────────────────────
class DataUsed {
  final int milkRecords;
  final int feedingRecords;
  final int weatherRecords;

  DataUsed({
    required this.milkRecords,
    required this.feedingRecords,
    required this.weatherRecords,
  });

  factory DataUsed.fromJson(Map<String, dynamic> json) {
    return DataUsed(
      milkRecords: json['milkRecords'] ?? 0,
      feedingRecords: json['feedingRecords'] ?? 0,
      weatherRecords: json['weatherRecords'] ?? 0,
    );
  }
}

// ── Recommendations ───────────────────────────────────────────────────────
class Recommendations {
  final String yieldAnalysis;
  final String feedingRecommendation;
  final String weatherImpact;
  final String healthAlert;
  final List<String> quickTips;
  final int overallScore;
  final String scoreLabel;

  Recommendations({
    required this.yieldAnalysis,
    required this.feedingRecommendation,
    required this.weatherImpact,
    required this.healthAlert,
    required this.quickTips,
    required this.overallScore,
    required this.scoreLabel,
  });

  factory Recommendations.fromJson(Map<String, dynamic> json) {
    return Recommendations(
      yieldAnalysis: json['yieldAnalysis'] ?? '',
      feedingRecommendation: json['feedingRecommendation'] ?? '',
      weatherImpact: json['weatherImpact'] ?? '',
      healthAlert: json['healthAlert'] ?? '',
      quickTips: List<String>.from(json['quickTips'] ?? []),
      overallScore: json['overallScore'] ?? 0,
      scoreLabel: json['scoreLabel'] ?? 'Unknown',
    );
  }

  // ── Score color ───────────────────────────────────────────────────────────
  // Returns a hex-style int for use in Color()
  int get scoreColorValue {
    if (overallScore >= 81) return 0xFF16A34A; // green  — Excellent
    if (overallScore >= 61) return 0xFF3B82F6; // blue   — Good
    if (overallScore >= 41) return 0xFFF97316; // orange — Fair
    return 0xFFEF4444; // red    — Poor
  }

  // ── Score icon emoji ──────────────────────────────────────────────────────
  String get scoreEmoji {
    if (overallScore >= 81) return '🏆';
    if (overallScore >= 61) return '👍';
    if (overallScore >= 41) return '⚠️';
    return '🚨';
  }
}
