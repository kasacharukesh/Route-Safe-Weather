import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/incident.dart';

class LocalStore {
  static const _incidentsKey = 'routesafe.incidents.v1';
  static const _savedRoutesKey = 'routesafe.saved_routes.v1';

  Future<List<Incident>> getIncidents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_incidentsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => Incident.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveIncident(Incident incident) async {
    final all = await getIncidents();
    all.insert(0, incident);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _incidentsKey,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> saveRoute(String title, double distanceKm) async {
    final prefs = await SharedPreferences.getInstance();
    final routes = prefs.getStringList(_savedRoutesKey) ?? [];
    routes.insert(0, '$title|${distanceKm.toStringAsFixed(1)} km');
    await prefs.setStringList(_savedRoutesKey, routes.take(20).toList());
  }

  Future<List<String>> getSavedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedRoutesKey) ?? [];
  }
}
