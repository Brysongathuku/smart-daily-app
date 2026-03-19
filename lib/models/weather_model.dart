class WeatherModel {
  final int weatherID;
  final int farmerID;
  final String recordDate;
  final String? temperatureCelsius;
  final String? rainfallMm;
  final String? humidity;
  final String? weatherCondition;
  final String? windSpeedKph;
  final String? location;
  final String? dataSource;
  final String? createdAt;

  WeatherModel({
    required this.weatherID,
    required this.farmerID,
    required this.recordDate,
    this.temperatureCelsius,
    this.rainfallMm,
    this.humidity,
    this.weatherCondition,
    this.windSpeedKph,
    this.location,
    this.dataSource,
    this.createdAt,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      weatherID: json['weather_id'] ?? json['weatherID'] ?? 0,
      farmerID: json['farmer_id'] ?? json['farmerID'] ?? 0,
      recordDate: json['record_date'] ?? json['recordDate'] ?? '',
      temperatureCelsius: json['temperature_celsius']?.toString() ??
          json['temperatureCelsius']?.toString(),
      rainfallMm:
          json['rainfall_mm']?.toString() ?? json['rainfallMm']?.toString(),
      humidity: json['humidity']?.toString(),
      weatherCondition: json['weather_condition'] ?? json['weatherCondition'],
      windSpeedKph: json['wind_speed_kph']?.toString() ??
          json['windSpeedKph']?.toString(),
      location: json['location'],
      dataSource: json['data_source'] ?? json['dataSource'],
      createdAt: json['created_at'] ?? json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weather_id': weatherID,
      'farmer_id': farmerID,
      'record_date': recordDate,
      'temperature_celsius': temperatureCelsius,
      'rainfall_mm': rainfallMm,
      'humidity': humidity,
      'weather_condition': weatherCondition,
      'wind_speed_kph': windSpeedKph,
      'location': location,
      'data_source': dataSource,
      'created_at': createdAt,
    };
  }

  // ── Display helpers ───────────────────────────────────────────────────────
  String get tempDisplay => temperatureCelsius != null
      ? '${double.tryParse(temperatureCelsius!)?.toStringAsFixed(1) ?? temperatureCelsius}°C'
      : '--';

  String get humidityDisplay => humidity != null
      ? '${double.tryParse(humidity!)?.toStringAsFixed(0) ?? humidity}%'
      : '--';

  String get rainfallDisplay => rainfallMm != null
      ? '${double.tryParse(rainfallMm!)?.toStringAsFixed(1) ?? rainfallMm} mm'
      : '--';

  String get windDisplay => windSpeedKph != null
      ? '${double.tryParse(windSpeedKph!)?.toStringAsFixed(1) ?? windSpeedKph} km/h'
      : '--';

  String get conditionDisplay => weatherCondition ?? 'Unknown';

  // ── Weather condition → emoji mapping ────────────────────────────────────
  String get weatherEmoji {
    final condition = weatherCondition?.toLowerCase() ?? '';
    if (condition.contains('rain')) return '🌧️';
    if (condition.contains('cloud')) return '☁️';
    if (condition.contains('sun') || condition.contains('clear')) return '☀️';
    if (condition.contains('hot')) return '🌡️';
    if (condition.contains('wind')) return '💨';
    if (condition.contains('storm')) return '⛈️';
    if (condition.contains('fog') || condition.contains('mist')) return '🌫️';
    return '🌤️';
  }
}

// ── Live weather response (from /weather/current — not saved to DB) ────────
class LiveWeatherModel {
  final String temperatureCelsius;
  final String humidity;
  final String rainfallMm;
  final String weatherCondition;
  final String windSpeedKph;
  final String location;

  LiveWeatherModel({
    required this.temperatureCelsius,
    required this.humidity,
    required this.rainfallMm,
    required this.weatherCondition,
    required this.windSpeedKph,
    required this.location,
  });

  factory LiveWeatherModel.fromJson(Map<String, dynamic> json) {
    return LiveWeatherModel(
      temperatureCelsius: json['temperatureCelsius']?.toString() ?? '--',
      humidity: json['humidity']?.toString() ?? '--',
      rainfallMm: json['rainfallMm']?.toString() ?? '0.0',
      weatherCondition: json['weatherCondition'] ?? 'Unknown',
      windSpeedKph: json['windSpeedKph']?.toString() ?? '--',
      location: json['location'] ?? '',
    );
  }

  String get tempDisplay =>
      '${double.tryParse(temperatureCelsius)?.toStringAsFixed(1) ?? temperatureCelsius}°C';

  String get humidityDisplay =>
      '${double.tryParse(humidity)?.toStringAsFixed(0) ?? humidity}%';

  String get rainfallDisplay =>
      '${double.tryParse(rainfallMm)?.toStringAsFixed(1) ?? rainfallMm} mm';

  String get windDisplay =>
      '${double.tryParse(windSpeedKph)?.toStringAsFixed(1) ?? windSpeedKph} km/h';

  String get conditionDisplay => weatherCondition; // ← ADDED

  // ── Weather condition → emoji mapping ────────────────────────────────────
  String get weatherEmoji {
    final condition = weatherCondition.toLowerCase();
    if (condition.contains('rain')) return '🌧️';
    if (condition.contains('cloud')) return '☁️';
    if (condition.contains('sun') || condition.contains('clear')) return '☀️';
    if (condition.contains('hot')) return '🌡️';
    if (condition.contains('wind')) return '💨';
    if (condition.contains('storm')) return '⛈️';
    if (condition.contains('fog') || condition.contains('mist')) return '🌫️';
    return '🌤️';
  }
}
