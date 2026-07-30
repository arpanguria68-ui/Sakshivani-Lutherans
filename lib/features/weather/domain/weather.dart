import 'package:flutter/material.dart';

/// Current weather snapshot rendered on Home.
class Weather {
  const Weather({
    required this.temperatureC,
    required this.weatherCode,
    required this.windKph,
    required this.humidity,
    required this.place,
    required this.fetchedAt,
    this.isDay = true,
  });

  final double temperatureC;
  final int weatherCode;
  final double windKph;
  final int humidity;
  final String place;
  final DateTime fetchedAt;
  final bool isDay;

  String get description => _wmo(weatherCode).$1;
  IconData get icon => _wmo(weatherCode).$2;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'temperatureC': temperatureC,
        'weatherCode': weatherCode,
        'windKph': windKph,
        'humidity': humidity,
        'place': place,
        'fetchedAt': fetchedAt.toIso8601String(),
        'isDay': isDay,
      };

  factory Weather.fromMap(Map<String, dynamic> m) => Weather(
        temperatureC: (m['temperatureC'] as num?)?.toDouble() ?? 0,
        weatherCode: (m['weatherCode'] as num?)?.toInt() ?? 0,
        windKph: (m['windKph'] as num?)?.toDouble() ?? 0,
        humidity: (m['humidity'] as num?)?.toInt() ?? 0,
        place: m['place'] as String? ?? '',
        fetchedAt: DateTime.tryParse(m['fetchedAt'] as String? ?? '') ?? DateTime.now(),
        isDay: m['isDay'] as bool? ?? true,
      );

  /// WMO weather-code -> (label, icon). Codes per Open-Meteo docs.
  static (String, IconData) _wmo(int code) {
    switch (code) {
      case 0:
        return ('Clear sky', Icons.wb_sunny);
      case 1:
        return ('Mainly clear', Icons.wb_sunny_outlined);
      case 2:
        return ('Partly cloudy', Icons.wb_cloudy);
      case 3:
        return ('Overcast', Icons.cloud);
      case 45:
      case 48:
        return ('Fog', Icons.foggy);
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return ('Drizzle', Icons.grain);
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return ('Rain', Icons.water_drop);
      case 71:
      case 73:
      case 75:
      case 77:
        return ('Snow', Icons.ac_unit);
      case 80:
      case 81:
      case 82:
        return ('Rain showers', Icons.grain);
      case 85:
      case 86:
        return ('Snow showers', Icons.ac_unit);
      case 95:
        return ('Thunderstorm', Icons.thunderstorm);
      case 96:
      case 99:
        return ('Thunderstorm, hail', Icons.thunderstorm);
      default:
        return ('Weather', Icons.cloud_outlined);
    }
  }
}

/// Reason a weather fetch could not complete (drives the Home card UI).
enum WeatherError { locationDenied, locationOff, network, none }

class WeatherResult {
  const WeatherResult({this.weather, this.error = WeatherError.none});
  final Weather? weather;
  final WeatherError error;
}
