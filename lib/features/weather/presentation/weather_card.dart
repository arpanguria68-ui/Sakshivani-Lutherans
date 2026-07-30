import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../domain/weather.dart';

/// Home weather widget: shows cached weather immediately, then refreshes from
/// the device location; offers a manual-city fallback when location is off.
class WeatherCard extends ConsumerStatefulWidget {
  const WeatherCard({super.key});

  @override
  ConsumerState<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends ConsumerState<WeatherCard> {
  Weather? _weather;
  WeatherError _error = WeatherError.none;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final service = ref.read(weatherServiceProvider);
    final Weather? cached = await service.cached();
    if (mounted && cached != null) {
      setState(() {
        _weather = cached;
        _loading = false;
      });
    }
    await _refresh();
  }

  Future<void> _refresh() async {
    if (mounted) setState(() => _loading = true);
    final WeatherResult r = await ref.read(weatherServiceProvider).fetchByLocation();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.weather != null) {
        _weather = r.weather;
        _error = WeatherError.none;
      } else {
        _error = r.error;
      }
    });
  }

  Future<void> _promptCity() async {
    final TextEditingController controller = TextEditingController();
    final String? city = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Set your city'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Ranchi'),
          onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (city == null || city.isEmpty) return;
    setState(() => _loading = true);
    final WeatherResult r = await ref.read(weatherServiceProvider).fetchByCity(city);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.weather != null) {
        _weather = r.weather;
        _error = WeatherError.none;
      } else {
        _error = r.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (_weather == null && _loading) {
      return const GlassCard(
        child: SizedBox(height: 64, child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_weather == null) {
      // No data and a location problem — offer manual city.
      return GlassCard(
        onTap: _promptCity,
        child: Row(
          children: <Widget>[
            const Icon(Icons.location_off),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Weather unavailable', style: text.titleMedium),
                  Text(
                    _error == WeatherError.locationDenied
                        ? 'Location denied — tap to set a city'
                        : _error == WeatherError.locationOff
                            ? 'Location is off — tap to set a city'
                            : 'Tap to set a city',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_location_alt),
          ],
        ),
      );
    }

    final Weather w = _weather!;
    return GlassCard(
      onTap: _refresh,
      child: Row(
        children: <Widget>[
          Icon(w.icon, size: 40, color: colors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text('${w.temperatureC.round()}°C', style: text.headlineSmall),
                    const SizedBox(width: 8),
                    Text(w.description, style: text.bodyMedium),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${w.place}  ·  💧 ${w.humidity}%  ·  🌬 ${w.windKph.round()} km/h',
                  style: text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Change city',
            icon: const Icon(Icons.edit_location_alt_outlined),
            onPressed: _promptCity,
          ),
          if (_loading)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          else
            const Icon(Icons.refresh, size: 18),
        ],
      ),
    );
  }
}
