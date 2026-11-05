import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class PlaceResult {
  const PlaceResult(this.name, this.point);
  final String name;
  final LatLng point;
}

class WeatherResult {
  const WeatherResult({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.wind,
    required this.precipitation,
    required this.code,
  });

  final double temperature;
  final double feelsLike;
  final int humidity;
  final double wind;
  final double precipitation;
  final int code;

  String get condition {
    if (code == 0) return 'Clear sky';
    if ([1, 2, 3].contains(code)) return 'Partly cloudy';
    if ([45, 48].contains(code)) return 'Fog';
    if ([51, 53, 55, 61, 63, 65, 80, 81, 82].contains(code)) return 'Rain';
    if ([71, 73, 75, 77, 85, 86].contains(code)) return 'Snow';
    if ([95, 96, 99].contains(code)) return 'Thunderstorm';
    return 'Weather conditions';
  }
}

class RouteResult {
  const RouteResult({
    required this.distanceKm,
    required this.durationMinutes,
    required this.points,
    required this.instructions,
  });

  final double distanceKm;
  final double durationMinutes;
  final List<LatLng> points;
  final List<String> instructions;
}

class RouteSafeService {
  static const _headers = {'User-Agent': 'RouteSafeFlutter/1.0 (educational app)'};

  Future<PlaceResult> searchPlace(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '1',
    });
    final response = await http.get(uri, headers: _headers).timeout(
          const Duration(seconds: 15),
        );
    if (response.statusCode != 200) {
      throw Exception('Place search failed (${response.statusCode}).');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    if (data.isEmpty) throw Exception('Place not found. Try a fuller address.');
    final item = data.first as Map<String, dynamic>;
    final lat = double.parse(item['lat'] as String);
    final lon = double.parse(item['lon'] as String);
    return PlaceResult(
      item['display_name'] as String? ?? query,
      LatLng(lat, lon),
    );
  }

  Future<WeatherResult> getWeather(LatLng point) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': point.latitude.toString(),
      'longitude': point.longitude.toString(),
      'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
      'timezone': 'auto',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Weather service unavailable (${response.statusCode}).');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;
    return WeatherResult(
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).round(),
      wind: (current['wind_speed_10m'] as num).toDouble(),
      precipitation: (current['precipitation'] as num).toDouble(),
      code: (current['weather_code'] as num).round(),
    );
  }

  Future<RouteResult> getRoute(LatLng start, LatLng end) async {
    final coords = '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}';
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coords'
      '?overview=full&geometries=geojson&steps=true',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Routing service unavailable (${response.statusCode}).');
    }
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = root['routes'] as List<dynamic>;
    if (routes.isEmpty) throw Exception('No drivable route was found.');
    final route = routes.first as Map<String, dynamic>;
    final geometry = route['geometry'] as Map<String, dynamic>;
    final coordinates = geometry['coordinates'] as List<dynamic>;
    final points = coordinates.map((value) {
      final pair = value as List<dynamic>;
      return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
    }).toList();

    final instructions = <String>[];
    final legs = route['legs'] as List<dynamic>;
    for (final legValue in legs) {
      final leg = legValue as Map<String, dynamic>;
      for (final stepValue in leg['steps'] as List<dynamic>) {
        final step = stepValue as Map<String, dynamic>;
        final maneuver = step['maneuver'] as Map<String, dynamic>;
        final type = maneuver['type'] as String? ?? 'Continue';
        final modifier = maneuver['modifier'] as String? ?? '';
        final name = step['name'] as String? ?? '';
        instructions.add('$type ${modifier.isEmpty ? '' : modifier} '
            '${name.isEmpty ? 'on unnamed road' : 'onto $name'}'.trim());
      }
    }
    return RouteResult(
      distanceKm: (route['distance'] as num).toDouble() / 1000,
      durationMinutes: (route['duration'] as num).toDouble() / 60,
      points: points,
      instructions: instructions,
    );
  }
}
