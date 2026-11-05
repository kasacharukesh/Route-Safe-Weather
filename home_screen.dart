import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/incident.dart';
import '../services/local_store.dart';
import '../services/route_safe_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = RouteSafeService();
  final _store = LocalStore();
  final _startController = TextEditingController(text: 'Guntur, Andhra Pradesh');
  final _endController = TextEditingController();
  final _incidentLocation = TextEditingController();
  final _incidentDescription = TextEditingController();
  final _mapController = MapController();

  LatLng _mapCenter = const LatLng(16.3067, 80.4365);
  LatLng? _start;
  LatLng? _end;
  RouteResult? _route;
  WeatherResult? _weather;
  List<Incident> _incidents = [];
  List<String> _savedRoutes = [];
  bool _weatherBusy = false;
  bool _routeBusy = false;
  String? _error;
  String _incidentType = 'Pothole';
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _refreshWeather();
    _loadLocalData();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _incidentLocation.dispose();
    _incidentDescription.dispose();
    super.dispose();
  }

  Future<void> _loadLocalData() async {
    final incidents = await _store.getIncidents();
    final routes = await _store.getSavedRoutes();
    if (!mounted) return;
    setState(() {
      _incidents = incidents;
      _savedRoutes = routes;
    });
  }

  Future<void> _refreshWeather() async {
    setState(() => _weatherBusy = true);
    try {
      final result = await _service.getWeather(_mapCenter);
      if (!mounted) return;
      setState(() {
        _weather = result;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _weatherBusy = false);
    }
  }

  Future<void> _useMyLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }
      final position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _mapCenter = point;
        _start = point;
        _startController.text =
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      });
      _mapController.move(point, 13);
      await _refreshWeather();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _findRoute() async {
    if (_startController.text.trim().isEmpty ||
        _endController.text.trim().isEmpty) {
      _showMessage('Enter both a starting point and a destination.');
      return;
    }
    setState(() {
      _routeBusy = true;
      _error = null;
    });
    try {
      final start = await _service.searchPlace(_startController.text.trim());
      final end = await _service.searchPlace(_endController.text.trim());
      final route = await _service.getRoute(start.point, end.point);
      if (!mounted) return;
      setState(() {
        _start = start.point;
        _end = end.point;
        _route = route;
        _mapCenter = start.point;
      });
      _mapController.move(start.point, 11);
      await _refreshWeather();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _routeBusy = false);
    }
  }

  Future<void> _saveCurrentRoute() async {
    if (_route == null) {
      _showMessage('Find a route before saving it.');
      return;
    }
    await _store.saveRoute(
      '${_startController.text} → ${_endController.text}',
      _route!.distanceKm,
    );
    await _loadLocalData();
    _showMessage('Route saved on this device.');
  }

  Future<void> _submitIncident() async {
    if (_incidentLocation.text.trim().isEmpty) {
      _showMessage('Enter a street or nearby landmark.');
      return;
    }
    final incident = Incident(
      type: _incidentType,
      location: _incidentLocation.text.trim(),
      description: _incidentDescription.text.trim(),
      createdAt: DateTime.now(),
    );
    await _store.saveIncident(incident);
    _incidentLocation.clear();
    _incidentDescription.clear();
    await _loadLocalData();
    _showMessage('Report saved locally on this device.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _sectionTitle(String title, String subtitle) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: .65))),
          ],
        ),
      );

  Widget _weatherCard() {
    final weather = _weather;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _weatherBusy && weather == null
            ? const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_outlined, color: Color(0xFF45D6C5)),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Current conditions',
                          style: TextStyle(fontWeight: FontWeight.w600))),
                      IconButton(
                        tooltip: 'Refresh weather',
                        onPressed: _refreshWeather,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  if (weather == null)
                    Text(_error ?? 'Weather data not available.')
                  else ...[
                    Text('${weather.temperature.toStringAsFixed(1)}°C',
                        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold)),
                    Text('${weather.condition} · Feels like ${weather.feelsLike.toStringAsFixed(1)}°C'),
                    const Divider(height: 24),
                    Wrap(
                      spacing: 18,
                      runSpacing: 12,
                      children: [
                        _metric('Humidity', '${weather.humidity}%'),
                        _metric('Wind', '${weather.wind.toStringAsFixed(1)} km/h'),
                        _metric('Rain', '${weather.precipitation.toStringAsFixed(1)} mm'),
                      ],
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _metric(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: .6), fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );

  Widget _routePlanner() => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _startController,
                decoration: const InputDecoration(
                  labelText: 'Starting point',
                  prefixIcon: Icon(Icons.trip_origin),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _endController,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _routeBusy ? null : _findRoute,
                      icon: _routeBusy
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.alt_route),
                      label: const Text('Find route'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Use my location',
                    onPressed: _useMyLocation,
                    icon: const Icon(Icons.my_location),
                  ),
                ],
              ),
              if (_route != null) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metric('Distance', '${_route!.distanceKm.toStringAsFixed(1)} km'),
                    _metric('Est. time', '${_route!.durationMinutes.round()} min'),
                    TextButton.icon(
                      onPressed: _saveCurrentRoute,
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('Save'),
                    ),
                  ],
                ),
                if (_route!.instructions.isNotEmpty)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('Turn-by-turn steps'),
                    children: _route!.instructions.take(12).map(
                      (step) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.turn_right, size: 18),
                        title: Text(step),
                      ),
                    ).toList(),
                  ),
              ],
            ],
          ),
        ),
      );

  Widget _mapCard() => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 330,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _mapCenter, initialZoom: 11),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.routesafe.app',
              ),
              if (_route != null)
                PolylineLayer(polylines: [
                  Polyline(points: _route!.points, strokeWidth: 5, color: const Color(0xFF21D6B9)),
                ]),
              MarkerLayer(markers: [
                if (_start != null)
                  Marker(point: _start!, width: 38, height: 38,
                    child: const Icon(Icons.trip_origin, color: Colors.green, size: 32)),
                if (_end != null)
                  Marker(point: _end!, width: 38, height: 38,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 36)),
              ]),
              const RichAttributionWidget(
                attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
              ),
            ],
          ),
        ),
      );

  Widget _incidentForm() => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _incidentType,
                decoration: const InputDecoration(labelText: 'Incident type'),
                items: const ['Pothole', 'Waterlogging', 'Road damage', 'Broken streetlight', 'Traffic hazard', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) => setState(() => _incidentType = value ?? 'Other'),
              ),
              TextField(controller: _incidentLocation,
                decoration: const InputDecoration(labelText: 'Street or nearby landmark')),
              TextField(controller: _incidentDescription,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description (optional)')),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitIncident,
                  icon: const Icon(Icons.report_outlined),
                  label: const Text('Save incident report'),
                )),
              const SizedBox(height: 6),
              Text('Reports are stored only on this device in this starter version.',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: .6))),
            ],
          ),
        ),
      );

  Widget _savedList() => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: _savedRoutes.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: Text('No saved routes yet. Plan a route and tap Save.'),
              )
            : Column(
                children: _savedRoutes.map((route) => ListTile(
                  leading: const Icon(Icons.bookmark_outline),
                  title: Text(route.split('|').first),
                  subtitle: Text(route.split('|').last),
                )).toList(),
              ),
      );

  Widget _reportsList() => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: _incidents.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: Text('No incident reports saved on this device.'),
              )
            : Column(
                children: _incidents.take(8).map((incident) => ListTile(
                  leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  title: Text('${incident.type} · ${incident.location}'),
                  subtitle: Text(incident.description.isEmpty ? incident.createdAt.toLocal().toString() : incident.description),
                )).toList(),
              ),
      );

  Widget _buildBody() {
    if (_tab == 1) {
      return ListView(children: [
        _sectionTitle('Route planner', 'Weather-aware trip planning starter'),
        _routePlanner(),
        _sectionTitle('Live map', 'Map tiles require an internet connection'),
        _mapCard(),
      ]);
    }
    if (_tab == 2) {
      return ListView(children: [
        _sectionTitle('Community safety', 'Record a road hazard'),
        _incidentForm(),
        _sectionTitle('Saved reports', '${_incidents.length} report(s) stored locally'),
        _reportsList(),
      ]);
    }
    if (_tab == 3) {
      return ListView(children: [
        _sectionTitle('Saved routes', 'Stored on this device'),
        _savedList(),
        _sectionTitle('Recent incident reports', 'Local device data'),
        _reportsList(),
      ]);
    }
    return ListView(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Row(
          children: [
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RouteSafe', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                Text('Weather-aware travel planning'),
              ],
            )),
            IconButton.filledTonal(onPressed: _refreshWeather, icon: const Icon(Icons.refresh)),
          ],
        ),
      ),
      _sectionTitle('Weather dashboard', 'Current conditions near the map centre'),
      _weatherCard(),
      _sectionTitle('Plan a safer journey', 'Search a route, view it on the map and save it'),
      _routePlanner(),
      _sectionTitle('Live map', 'OpenStreetMap'),
      _mapCard(),
      _sectionTitle('Community reports', '${_incidents.length} local report(s)'),
      _reportsList(),
      const SizedBox(height: 20),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.route_outlined), label: 'Navigate'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), label: 'Report'),
          NavigationDestination(icon: Icon(Icons.bookmarks_outlined), label: 'Saved'),
        ],
      ),
    );
  }
}
