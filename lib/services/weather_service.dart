import 'dart:async';
import 'dart:convert';

import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../data/local/local_storage_service.dart';
import '../features/weather/domain/weather.dart';

/// Fetches current weather from Open-Meteo (free, keyless). Location via
/// geolocator with graceful permission handling; a manual city is the
/// fallback when location is unavailable. Last result is cached for offline.
class WeatherService {
  WeatherService(this._storage);

  final LocalStorageService _storage;

  static const String _forecastBase = 'https://api.open-meteo.com/v1/forecast';
  static const String _geocodeBase = 'https://geocoding-api.open-meteo.com/v1/search';

  Future<Weather?> cached() async {
    final Map<String, dynamic>? m = await _storage.getWeatherCache();
    return m == null ? null : Weather.fromMap(m);
  }

  /// Fetch by device location. Falls back to a saved manual city if location
  /// is denied/off, else returns the corresponding [WeatherError].
  Future<WeatherResult> fetchByLocation() async {
    final bool serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      return _cityFallback(WeatherError.locationOff);
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return _cityFallback(WeatherError.locationDenied);
    }

    try {
      Position? pos;
      try {
        // A hard GPS lock can take a long time (or never resolve) indoors;
        // bail out to the last-known fix rather than leaving the UI stuck.
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } on TimeoutException {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) {
        return _cityFallback(WeatherError.network);
      }
      final String place = await _reverseGeocode(pos.latitude, pos.longitude);
      final Weather? w = await _fetchForecast(pos.latitude, pos.longitude, place);
      return w == null
          ? const WeatherResult(error: WeatherError.network)
          : WeatherResult(weather: w);
    } catch (_) {
      return _cityFallback(WeatherError.network);
    }
  }

  /// Fetch by a named city (Open-Meteo geocoding). Persists it as the manual city.
  Future<WeatherResult> fetchByCity(String city) async {
    try {
      final Uri uri = Uri.parse('$_geocodeBase?name=${Uri.encodeComponent(city)}&count=1');
      final http.Response res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const WeatherResult(error: WeatherError.network);
      final Map<String, dynamic> body = jsonDecode(res.body) as Map<String, dynamic>;
      final List<dynamic>? results = body['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return const WeatherResult(error: WeatherError.network);
      }
      final Map<String, dynamic> r = (results.first as Map).cast<String, dynamic>();
      final double lat = (r['latitude'] as num).toDouble();
      final double lon = (r['longitude'] as num).toDouble();
      final String name = <String?>[
        r['name'] as String?,
        r['admin1'] as String?,
      ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
      final Weather? w = await _fetchForecast(lat, lon, name.isEmpty ? city : name);
      if (w == null) return const WeatherResult(error: WeatherError.network);
      await _storage.setManualCity(city);
      return WeatherResult(weather: w);
    } catch (_) {
      return const WeatherResult(error: WeatherError.network);
    }
  }

  Future<WeatherResult> _cityFallback(WeatherError reason) async {
    final String? city = await _storage.getManualCity();
    if (city != null && city.isNotEmpty) {
      final WeatherResult r = await fetchByCity(city);
      if (r.weather != null) return r;
    }
    return WeatherResult(error: reason);
  }

  Future<Weather?> _fetchForecast(double lat, double lon, String place) async {
    final Uri uri = Uri.parse(
      '$_forecastBase?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,is_day,weather_code,wind_speed_10m'
      '&wind_speed_unit=kmh&timezone=auto',
    );
    final http.Response res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final Map<String, dynamic> body = jsonDecode(res.body) as Map<String, dynamic>;
    final Map<String, dynamic>? cur = (body['current'] as Map?)?.cast<String, dynamic>();
    if (cur == null) return null;

    final Weather weather = Weather(
      temperatureC: (cur['temperature_2m'] as num?)?.toDouble() ?? 0,
      weatherCode: (cur['weather_code'] as num?)?.toInt() ?? 0,
      windKph: (cur['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      humidity: (cur['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      isDay: ((cur['is_day'] as num?)?.toInt() ?? 1) == 1,
      place: place,
      fetchedAt: DateTime.now(),
    );
    await _storage.setWeatherCache(weather.toMap());
    return weather;
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final List<geo.Placemark> marks = await geo.placemarkFromCoordinates(lat, lon);
      if (marks.isNotEmpty) {
        final geo.Placemark p = marks.first;
        final String city = <String?>[
          p.locality,
          p.subAdministrativeArea,
          p.administrativeArea,
        ].whereType<String>().firstWhere((s) => s.isNotEmpty, orElse: () => '');
        if (city.isNotEmpty) return city;
      }
    } catch (_) {
      // reverse geocoding is best-effort
    }
    return 'Current location';
  }
}
