import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:SportTracker/services/run_save_service.dart';

class RunTrackingPage extends StatefulWidget {
  const RunTrackingPage({super.key});

  @override
  State<RunTrackingPage> createState() => _RunTrackingPageState();
}

class _RunTrackingPageState extends State<RunTrackingPage> {
  bool _isRunning = false;
  bool _isSaving = false;
  DateTime? _startTime;
  StreamSubscription<Position>? _positionSub;
  Timer? _timer;
  final List<LatLng> _route = [];
  final List<DateTime> _routeTimestamps = [];
  double _currentSpeedKmh = 0;
  double _maxSpeedKmh = 0;
  double? _currentAltitudeM;
  LatLng? _initialMapCenter;
  final MapController _mapController = MapController();
  static const int _minDistanceFilterMeters = 0;
  static const LatLng _defaultMapCenter = LatLng(48.8566, 2.3522);

  String get _todaybd =>
      DateTime.now().toIso8601String().substring(0, 10);

  Duration get _elapsed =>
      _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero;

  double get _distanceKm {
    if (_route.length < 2) return 0;
    const distance = Distance();
    double meters = 0;
    for (int i = 1; i < _route.length; i++) {
      meters += distance.as(LengthUnit.Meter, _route[i - 1], _route[i]);
    }
    return meters / 1000;
  }

  /// Vitesse instantanée calculée à partir des 2 derniers points (en km/h).
  double get _computedSpeedKmh {
    if (_route.length < 2 || _routeTimestamps.length < 2) return 0;
    final i = _route.length - 1;
    final dtSec = _routeTimestamps[i].difference(_routeTimestamps[i - 1]).inMilliseconds / 1000.0;
    if (dtSec <= 0) return 0;
    const distance = Distance();
    final meters = distance.as(LengthUnit.Meter, _route[i - 1], _route[i]);
    return (meters / dtSec) * 3.6;
  }

  LatLng? get _routeCenter {
    if (_route.isEmpty) return null;
    double sumLat = 0, sumLng = 0;
    for (final p in _route) {
      sumLat += p.latitude;
      sumLng += p.longitude;
    }
    return LatLng(sumLat / _route.length, sumLng / _route.length);
  }

  double? get _avgSpeedKmh {
    final sec = _elapsed.inSeconds;
    if (sec <= 0 || _distanceKm <= 0) return null;
    return (_distanceKm / (sec / 3600));
  }

  @override
  void initState() {
    super.initState();
    _fetchInitialPosition();
  }

  Future<void> _fetchInitialPosition() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted || !mounted) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (mounted) {
        setState(() => _initialMapCenter = LatLng(pos.latitude, pos.longitude));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _initialMapCenter != null) {
            _mapController.move(_initialMapCenter!, 16);
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> _requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    }
    return false;
  }

  Future<void> _startRun() async {
    if (!await _requestLocationPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('run_tracking_location_required'))),
        );
      }
      return;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('run_tracking_enable_gps'))),
      );
      return;
    }

    setState(() {
      _isRunning = true;
      _startTime = DateTime.now();
      _route.clear();
      _routeTimestamps.clear();
      _currentSpeedKmh = 0;
      _maxSpeedKmh = 0;
      _currentAltitudeM = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRunning) setState(() {});
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: _minDistanceFilterMeters,
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition, onError: (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS: $e')),
        );
      }
    });

    final first = await Geolocator.getCurrentPosition(
      locationSettings: settings,
    );
    _onPosition(first);
  }

  void _onPosition(Position position) {
    final point = LatLng(position.latitude, position.longitude);
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      if (_route.isEmpty || _route.last != point) {
        _route.add(point);
        _routeTimestamps.add(now);
      }
      double speedKmh = 0;
      if (position.speed >= 0) {
        speedKmh = position.speed * 3.6;
      } else if (_route.length >= 2 && _routeTimestamps.length >= 2) {
        final i = _route.length - 1;
        final dtSec = _routeTimestamps[i].difference(_routeTimestamps[i - 1]).inMilliseconds / 1000.0;
        if (dtSec > 0) {
          const distance = Distance();
          final meters = distance.as(LengthUnit.Meter, _route[i - 1], _route[i]);
          speedKmh = (meters / dtSec) * 3.6;
        }
      }
      _currentSpeedKmh = speedKmh;
      _currentAltitudeM = position.altitude;
      if (speedKmh > _maxSpeedKmh) _maxSpeedKmh = speedKmh;
    });
    if (_route.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _route.isNotEmpty) {
          _mapController.move(_route.last, 16);
        }
      });
    }
  }

  Future<void> _stopRun() async {
    _positionSub?.cancel();
    _positionSub = null;
    _timer?.cancel();
    _timer = null;

    setState(() {
      _isRunning = false;
      _isSaving = true;
    });

    final durationSeconds = _elapsed.inSeconds;
    double? maxAlt = _currentAltitudeM;
    double? minAlt = _currentAltitudeM;

    final routeForSave = <Map<String, dynamic>>[];
    for (int i = 0; i < _route.length; i++) {
      final p = _route[i];
      final tSec = i < _routeTimestamps.length
          ? _routeTimestamps[i].difference(_startTime!).inSeconds
          : 0;
      routeForSave.add({
        'lat': p.latitude,
        'lng': p.longitude,
        't': tSec,
      });
    }

    String? runTitle;
    String? runDescription;
    if (mounted) {
      final result = await showDialog<_RunDetailsResult>(
        context: context,
        builder: (context) => _RunDetailsDialog(
          distanceKm: _distanceKm,
          durationSeconds: durationSeconds,
        ),
      );
      runTitle = result?.title;
      runDescription = result?.description;
    }

    if (!mounted) return;

    await RunSaveService.saveRunToTodayProgram(
      durationSeconds: durationSeconds,
      distanceKm: _distanceKm,
      avgSpeedKmh: _avgSpeedKmh,
      maxSpeedKmh: _maxSpeedKmh > 0 ? _maxSpeedKmh : null,
      maxAltitudeM: maxAlt,
      minAltitudeM: minAlt,
      route: routeForSave,
      todaybd: _todaybd,
      runTitle: runTitle,
      runDescription: runDescription,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr('run_saved_to_program'))),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('run_tracking_title')),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: _buildMap(),
          ),
          Expanded(
            flex: 1,
            child: _buildStats(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isRunning
                  ? ElevatedButton.icon(
                      icon: const Icon(Icons.stop),
                      label: Text(tr('run_tracking_stop')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _isSaving ? null : _stopRun,
                    )
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.directions_run),
                      label: Text(tr('run_tracking_start')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: _isSaving ? null : _startRun,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    LatLng center = _route.isNotEmpty
        ? (_routeCenter ?? _route.last)
        : (_initialMapCenter ?? _defaultMapCenter);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: _route.length >= 2 ? 15 : 16,
        minZoom: 3,
        maxZoom: 19,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.sport_tracker',
        ),
        if (_route.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _route,
                strokeWidth: 6,
                color: Colors.blue,
              ),
            ],
          ),
        if (_route.isNotEmpty) ...[
          MarkerLayer(
            markers: [
              if (_route.length > 1)
                Marker(
                  point: _route.first,
                  width: 28,
                  height: 28,
                  child: const Icon(Icons.trip_origin, color: Colors.green, size: 28),
                ),
              Marker(
                point: _route.last,
                width: 28,
                height: 28,
                child: const Icon(Icons.location_on, color: Colors.red, size: 28),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  label: tr('run_tracking_duration'),
                  value: _formatDuration(_elapsed),
                  icon: Icons.timer,
                ),
                _StatCard(
                  label: tr('run_tracking_distance'),
                  value: _distanceKm >= 1
                      ? '${_distanceKm.toStringAsFixed(2)} km'
                      : '${(_distanceKm * 1000).round()} m',
                  icon: Icons.straighten,
                ),
                _StatCard(
                  label: tr('run_tracking_speed'),
                  value: _currentSpeedKmh > 0
                      ? '${_currentSpeedKmh.toStringAsFixed(1)} km/h'
                      : '0.0 km/h',
                  icon: Icons.speed,
                ),
                _StatCard(
                  label: tr('run_tracking_altitude'),
                  value: _currentAltitudeM != null
                      ? '${_currentAltitudeM!.round()} m'
                      : '—',
                  icon: Icons.terrain,
                ),
              ],
            ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunDetailsResult {
  final String? title;
  final String? description;

  _RunDetailsResult({this.title, this.description});
}

class _RunDetailsDialog extends StatefulWidget {
  final double distanceKm;
  final int durationSeconds;

  const _RunDetailsDialog({
    required this.distanceKm,
    required this.durationSeconds,
  });

  @override
  State<_RunDetailsDialog> createState() => _RunDetailsDialogState();
}

class _RunDetailsDialogState extends State<_RunDetailsDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.durationSeconds ~/ 60;
    final s = widget.durationSeconds % 60;
    final durationStr = '$m:${s.toString().padLeft(2, '0')}';
    final distanceStr = widget.distanceKm >= 1
        ? '${widget.distanceKm.toStringAsFixed(2)} km'
        : '${(widget.distanceKm * 1000).round()} m';

    return AlertDialog(
      title: Text(tr('run_details_dialog_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$durationStr · $distanceStr',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: tr('run_title_optional'),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLength: 80,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: tr('run_description_optional'),
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('cancel')),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleController.text.trim();
            final desc = _descriptionController.text.trim();
            Navigator.of(context).pop(_RunDetailsResult(
              title: title.isEmpty ? null : title,
              description: desc.isEmpty ? null : desc,
            ));
          },
          child: Text(tr('run_save')),
        ),
      ],
    );
  }
}
