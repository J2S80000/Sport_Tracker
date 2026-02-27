import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:SportTracker/views/run_speed_by_segment_page.dart';

/// Affiche le tracé d'une course avec stats. La vitesse par segment est dans une sous-page.
class RunRouteViewerPage extends StatefulWidget {
  final Map<String, dynamic> exercise;

  const RunRouteViewerPage({super.key, required this.exercise});

  @override
  State<RunRouteViewerPage> createState() => _RunRouteViewerPageState();
}

class _RunRouteViewerPageState extends State<RunRouteViewerPage> {
  static List<LatLng> _routeToPoints(List<dynamic> route) {
    final points = <LatLng>[];
    for (final p in route) {
      if (p is Map) {
        final lat = p['lat'];
        final lng = p['lng'];
        if (lat != null && lng != null) {
          points.add(LatLng((lat as num).toDouble(), (lng as num).toDouble()));
        }
      }
    }
    return points;
  }

  double _parseDistanceKm(String? s) {
    if (s == null || s.isEmpty) return 0;
    final kmMatch = RegExp(r'([\d.,]+)\s*km').firstMatch(s);
    if (kmMatch != null) {
      return double.tryParse(kmMatch.group(1)!.replaceAll(',', '.')) ?? 0;
    }
    final mMatch = RegExp(r'(\d+)\s*m').firstMatch(s);
    if (mMatch != null) {
      return (int.tryParse(mMatch.group(1)!) ?? 0) / 1000.0;
    }
    return double.tryParse(s.replaceAll(',', '.')) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.exercise['route'] as List<dynamic>? ?? [];
    final points = _routeToPoints(route);

    final durationSec =
        (widget.exercise['durationSeconds'] as num?)?.toInt() ??
            (int.tryParse(widget.exercise['duration']?.toString() ?? '0') ??
                    0) *
                60;
    final distanceKm =
        (widget.exercise['distanceKm'] as num?)?.toDouble() ??
            _parseDistanceKm(widget.exercise['distance']?.toString());
    final avgSpeedKmh = (widget.exercise['avgSpeedKmh'] as num?)?.toDouble();
    final maxSpeedKmh = (widget.exercise['maxSpeedKmh'] as num?)?.toDouble();
    final caloriesRun = (widget.exercise['caloriesRun'] as num?)?.toInt();

    final avgPace = avgSpeedKmh != null && avgSpeedKmh > 0
        ? 60 / avgSpeedKmh
        : (durationSec > 0 && distanceKm > 0
            ? (durationSec / 60) / distanceKm
            : null);

    if (points.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('run_tracking_route'))),
        body: Center(child: Text(tr('run_tracking_no_route'))),
      );
    }

    LatLng center = points.first;
    if (points.length > 1) {
      double sumLat = 0, sumLng = 0;
      for (final p in points) {
        sumLat += p.latitude;
        sumLng += p.longitude;
      }
      center = LatLng(sumLat / points.length, sumLng / points.length);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final runTitle = widget.exercise['runTitle']?.toString();
    final runDescription = widget.exercise['runDescription']?.toString();
    final hasTitleOrDescription =
        (runTitle != null && runTitle.isNotEmpty) ||
        (runDescription != null && runDescription.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          runTitle?.isNotEmpty == true ? runTitle! : tr('run_tracking_route'),
        ),
        centerTitle: true,
        scrolledUnderElevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.speed),
            tooltip: tr('run_viewer_speed_by_segment'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RunSpeedBySegmentPage(
                    exercise: widget.exercise,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasTitleOrDescription)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: colorScheme.surfaceContainerLowest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (runDescription != null && runDescription.isNotEmpty) ...[
                    Text(
                      tr('run_viewer_description_label'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      runDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                minZoom: 3,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.sport_tracker',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      strokeWidth: 5,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildStatsSection(
            context: context,
            durationSec: durationSec,
            distanceKm: distanceKm,
            avgSpeedKmh: avgSpeedKmh,
            maxSpeedKmh: maxSpeedKmh,
            avgPaceMinPerKm: avgPace,
            calories: caloriesRun,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RunSpeedBySegmentPage(
                    exercise: widget.exercise,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart_rounded),
            label: Text(tr('run_viewer_speed_by_segment')),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection({
    required BuildContext context,
    required int durationSec,
    required double distanceKm,
    required double? avgSpeedKmh,
    required double? maxSpeedKmh,
    required double? avgPaceMinPerKm,
    required int? calories,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final min = durationSec ~/ 60;
    final sec = durationSec % 60;
    final durationStr = '$min:${sec.toString().padLeft(2, '0')}';

    final distanceStr = distanceKm >= 1
        ? '${distanceKm.toStringAsFixed(2)} km'
        : '${(distanceKm * 1000).round()} m';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.timer_outlined,
                  label: tr('run_viewer_duration'),
                  value: durationStr,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.straighten,
                  label: tr('run_tracking_distance'),
                  value: distanceStr,
                ),
                if (avgSpeedKmh != null) ...[
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.speed,
                    label: tr('run_viewer_avg_speed'),
                    value: '${avgSpeedKmh.toStringAsFixed(1)} km/h',
                  ),
                ],
                if (maxSpeedKmh != null) ...[
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.speed,
                    label: tr('run_viewer_max_speed'),
                    value: '${maxSpeedKmh.toStringAsFixed(1)} km/h',
                  ),
                ],
                if (avgPaceMinPerKm != null) ...[
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.timer,
                    label: tr('run_viewer_pace'),
                    value: '${avgPaceMinPerKm.toStringAsFixed(1)} min/km',
                  ),
                ],
                if (calories != null) ...[
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.local_fire_department_outlined,
                    label: tr('run_viewer_calories'),
                    value: '$calories kcal',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
