class MilkCollectionModel {
  final int? milkID;
  final int farmerID;
  final int collectorID;
  final double quantityInLiters;
  final double pricePerLiter;
  final double totalAmount;
  final String collectionDate;
  final String? collectionTime;
  final String collectionStatus;
  final String qualityGrade;
  final double? fatContent;
  final double? temperature;
  final String? notes;
  final bool isDisputed;
  final String? disputeReason;
  final String? createdAt;
  final String? updatedAt;

  MilkCollectionModel({
    this.milkID,
    required this.farmerID,
    required this.collectorID,
    required this.quantityInLiters,
    required this.pricePerLiter,
    required this.totalAmount,
    required this.collectionDate,
    this.collectionTime,
    this.collectionStatus = 'Recorded',
    this.qualityGrade = 'Grade A',
    this.fatContent,
    this.temperature,
    this.notes,
    this.isDisputed = false,
    this.disputeReason,
    this.createdAt,
    this.updatedAt,
  });

  factory MilkCollectionModel.fromJson(Map<String, dynamic> json) {
    return MilkCollectionModel(
      milkID: json['milk_id'] ?? json['milkID'],
      farmerID: json['farmer_id'] ?? json['farmerID'] ?? 0,
      collectorID: json['collector_id'] ?? json['collectorID'] ?? 0,
      quantityInLiters:
          _parseDouble(json['quantity_in_liters'] ?? json['quantityInLiters']),
      pricePerLiter:
          _parseDouble(json['price_per_liter'] ?? json['pricePerLiter']),
      totalAmount: _parseDouble(json['total_amount'] ?? json['totalAmount']),
      collectionDate: json['collection_date'] ?? json['collectionDate'] ?? '',
      collectionTime: json['collection_time'] ?? json['collectionTime'],
      collectionStatus:
          json['collection_status'] ?? json['collectionStatus'] ?? 'Recorded',
      qualityGrade: json['quality_grade'] ?? json['qualityGrade'] ?? 'Grade A',
      fatContent: json['fat_content'] != null || json['fatContent'] != null
          ? _parseDouble(json['fat_content'] ?? json['fatContent'])
          : null,
      temperature: json['temperature'] != null
          ? _parseDouble(json['temperature'])
          : null,
      notes: json['notes'],
      isDisputed: json['is_disputed'] ?? json['isDisputed'] ?? false,
      disputeReason: json['dispute_reason'] ?? json['disputeReason'],
      createdAt: json['created_at'] ?? json['createdAt'],
      updatedAt: json['updated_at'] ?? json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (milkID != null) 'milk_id': milkID,
      'farmer_id': farmerID,
      'collector_id': collectorID,
      'quantity_in_liters': quantityInLiters,
      'price_per_liter': pricePerLiter,
      'total_amount': totalAmount,
      'collection_date': collectionDate,
      if (collectionTime != null) 'collection_time': collectionTime,
      'collection_status': collectionStatus,
      'quality_grade': qualityGrade,
      if (fatContent != null) 'fat_content': fatContent,
      if (temperature != null) 'temperature': temperature,
      if (notes != null) 'notes': notes,
      'is_disputed': isDisputed,
      if (disputeReason != null) 'dispute_reason': disputeReason,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class CreateMilkCollectionRequest {
  final int farmerID;
  final int collectorID;
  final double quantityInLiters;
  final double? fatContent;
  final double? temperature;
  final String? notes;
  final String collectionDate; // ── Added ──

  CreateMilkCollectionRequest({
    required this.farmerID,
    required this.collectorID,
    required this.quantityInLiters,
    this.fatContent,
    this.temperature,
    this.notes,
    required this.collectionDate, // ── Added ──
  });

  Map<String, dynamic> toJson() {
    return {
      'farmerID': farmerID,
      'collectorID': collectorID,
      'quantityInLiters': quantityInLiters,
      if (fatContent != null) 'fatContent': fatContent,
      if (temperature != null) 'temperature': temperature,
      if (notes != null) 'notes': notes,
      'collectionDate': collectionDate, // ── Added ──
    };
  }
}
