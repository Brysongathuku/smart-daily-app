class FeedingHabitModel {
  final int feedingID;
  final int farmerID;
  final int? milkID;
  final String feedType;
  final double amountKg;
  final String feedingTime;
  final String feedingDate;
  final String? supplementName;
  final double? costPerKg;
  final String? notes;

  FeedingHabitModel({
    required this.feedingID,
    required this.farmerID,
    this.milkID,
    required this.feedType,
    required this.amountKg,
    required this.feedingTime,
    required this.feedingDate,
    this.supplementName,
    this.costPerKg,
    this.notes,
  });

  factory FeedingHabitModel.fromJson(Map<String, dynamic> json) {
    return FeedingHabitModel(
      feedingID: json['feeding_id'] ?? json['feedingID'] ?? 0,
      farmerID: json['farmer_id'] ?? json['farmerID'] ?? 0,
      milkID: json['milk_id'] ?? json['milkID'],
      feedType: json['feed_type'] ?? json['feedType'] ?? '',
      amountKg: double.tryParse(json['amount_kg']?.toString() ?? '0') ?? 0.0,
      feedingTime: json['feeding_time'] ?? json['feedingTime'] ?? '',
      feedingDate: json['feeding_date'] ?? json['feedingDate'] ?? '',
      supplementName: json['supplement_name'] ?? json['supplementName'],
      costPerKg: json['cost_per_kg'] != null
          ? double.tryParse(json['cost_per_kg'].toString())
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'farmerID': farmerID,
        if (milkID != null) 'milkID': milkID,
        'feedType': feedType,
        'amountKg': amountKg,
        'feedingTime': feedingTime,
        'feedingDate': feedingDate,
        if (supplementName != null) 'supplementName': supplementName,
        if (costPerKg != null) 'costPerKg': costPerKg,
        if (notes != null) 'notes': notes,
      };
}

class CreateFeedingHabitRequest {
  final int farmerID;
  final int? milkID;
  final String feedType;
  final double amountKg;
  final String feedingTime;
  final String feedingDate;
  final String? supplementName;
  final String? notes;
  final int recordedBy;

  CreateFeedingHabitRequest({
    required this.farmerID,
    this.milkID,
    required this.feedType,
    required this.amountKg,
    required this.feedingTime,
    required this.feedingDate,
    this.supplementName,
    this.notes,
    required this.recordedBy,
  });

  Map<String, dynamic> toJson() => {
        'farmerID': farmerID,
        if (milkID != null) 'milkID': milkID,
        'feedType': feedType,
        'amountKg': amountKg,
        'feedingTime': feedingTime,
        'feedingDate': feedingDate,
        if (supplementName != null && supplementName!.isNotEmpty)
          'supplementName': supplementName,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'recordedBy': recordedBy,
      };
}
