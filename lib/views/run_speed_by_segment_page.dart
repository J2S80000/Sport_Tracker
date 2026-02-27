import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Données d'un segment pour l'affichage.
class SegmentStat {
  final String label;
  final double speedKmh;
  final String paceMinPerKm;

  SegmentStat({required this.label, required this.speedKmh})
      : paceMinPerKm =
            speedKmh > 0 ? '${(60 / speedKmh).toStringAsFixed(1)}' : '—';
}

/// Sous-page Material You : vitesses par segment (par durée ou par distance).
class RunSpeedBySegmentPage extends StatefulWidget {
  final Map<String, dynamic> exercise;

  const RunSpeedBySegmentPage({super.key, required this.exercise});

  @override
  State<RunSpeedBySegmentPage> createState() => _RunSpeedBySegmentPageState();
}

class _RunSpeedBySegmentPageState extends State<RunSpeedBySegmentPage> {
  bool _byDuration = true;
  int _segmentSize = 1;

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

  static List<int> _routeToTimes(List<dynamic> route) {
    final times = <int>[];
    for (final p in route) {
      if (p is Map && p['t'] != null) {
        times.add((p['t'] as num).toInt());
      } else {
        times.add(0);
      }
    }
    final pts = _routeToPoints(route);
    while (times.length < pts.length) {
      times.add(times.isEmpty ? 0 : times.last);
    }
    return times;
  }

  static double _parseDistanceKm(String? s) {
    if (s == null || s.isEmpty) return 0;
    final kmMatch = RegExp(r'([\d.,]+)\s*km').firstMatch(s);
    if (kmMatch != null) {
      return double.tryParse(kmMatch.group(1)!.replaceAll(',', '.')) ?? 0;
    }
    final mMatch = RegExp(r'(\d+)\s*m').firstMatch(s);
    if (mMatch != null) return (int.tryParse(mMatch.group(1)!) ?? 0) / 1000.0;
    return double.tryParse(s.replaceAll(',', '.')) ?? 0;
  }

  static List<SegmentStat> _computeSegmentStats({
    required List<LatLng> points,
    required List<int> times,
    required int durationSec,
    required double distanceKm,
    required bool byDuration,
    required int segmentSize,
  }) {
    final result = <SegmentStat>[];
    const distance = Distance();
    if (points.length < 2 || times.length < 2) return result;

    if (byDuration) {
      final segmentSec = segmentSize * 60;
      int tStart = 0;
      while (tStart < durationSec) {
        final tEnd = (tStart + segmentSec).clamp(0, durationSec);
        int i = 0;
        while (i < times.length && times[i] < tStart) i++;
        int j = i;
        while (j + 1 < times.length && times[j + 1] <= tEnd) j++;
        double segDistM = 0;
        for (int k = i; k < j && k + 1 < points.length; k++) {
          segDistM += distance.as(LengthUnit.Meter, points[k], points[k + 1]);
        }
        final segDistKm = segDistM / 1000;
        final segDurationH = segmentSec / 3600.0;
        final speedKmh = segDurationH > 0 ? segDistKm / segDurationH : 0.0;
        result.add(SegmentStat(
          label: '${tStart ~/ 60}-${tEnd ~/ 60} min',
          speedKmh: speedKmh,
        ));
        tStart = tEnd;
        if (tEnd >= durationSec) break;
      }
    } else {
      final segmentM = segmentSize * 1000.0;
      double cumulM = 0;
      int startIdx = 0;
      int tStart = times.isNotEmpty ? times[0] : 0;
      double nextBoundaryM = segmentM;
      while (startIdx < points.length && nextBoundaryM <= distanceKm * 1000) {
        int endIdx = startIdx;
        while (endIdx + 1 < points.length) {
          final d =
              distance.as(LengthUnit.Meter, points[endIdx], points[endIdx + 1]);
          cumulM += d;
          endIdx++;
          if (cumulM >= nextBoundaryM) break;
        }
        final tEnd = endIdx < times.length ? times[endIdx] : durationSec;
        final segTimeSec = (tEnd - tStart).clamp(1, durationSec);
        final segDistKm = segmentSize.toDouble();
        final speedKmh =
            segTimeSec > 0 ? segDistKm / (segTimeSec / 3600) : 0.0;
        result.add(SegmentStat(
          label:
              '${((nextBoundaryM - segmentM) / 1000).toStringAsFixed(1)}-${(nextBoundaryM / 1000).toStringAsFixed(1)} km',
          speedKmh: speedKmh,
        ));
        startIdx = endIdx;
        tStart = tEnd;
        nextBoundaryM += segmentM;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.exercise['route'] as List<dynamic>? ?? [];
    final points = _routeToPoints(route);
    final times = _routeToTimes(route);
    final durationSec =
        (widget.exercise['durationSeconds'] as num?)?.toInt() ??
            (int.tryParse(widget.exercise['duration']?.toString() ?? '0') ??
                    0) *
                60;
    final distanceKm =
        (widget.exercise['distanceKm'] as num?)?.toDouble() ??
            _parseDistanceKm(widget.exercise['distance']?.toString());

    final segmentStats = _computeSegmentStats(
      points: points,
      times: times,
      durationSec: durationSec,
      distanceKm: distanceKm,
      byDuration: _byDuration,
      segmentSize: _segmentSize,
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('run_viewer_speed_by_segment')),
        centerTitle: true,
        scrolledUnderElevation: 4,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: colorScheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('run_viewer_group_by'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: true,
                              label: Text(tr('run_viewer_by_duration')),
                              icon: const Icon(Icons.timer_outlined),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text(tr('run_viewer_by_distance')),
                              icon: const Icon(Icons.straighten_outlined),
                            ),
                          ],
                          selected: {_byDuration},
                          onSelectionChanged: (Set<bool> s) {
                            setState(() => _byDuration = s.first);
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _byDuration
                              ? tr('run_viewer_segment_duration')
                              : tr('run_viewer_segment_distance'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<int>(
                          segments: (_byDuration
                                  ? const [1, 2, 5, 10]
                                  : const [1, 2, 5, 10])
                              .map((size) => ButtonSegment<int>(
                                    value: size,
                                    label: Text(
                                        _byDuration ? '$size min' : '$size km'),
                                  ))
                              .toList(),
                          selected: {_segmentSize},
                          onSelectionChanged: (Set<int> s) {
                            setState(() => _segmentSize = s.first);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.speed, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      tr('run_viewer_segments_list'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (segmentStats.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_run_outlined,
                        size: 64,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tr('run_viewer_no_segments'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final s = segmentStats[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: colorScheme.surfaceContainerHighest,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                '${index + 1}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            title: Text(
                              s.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${s.speedKmh.toStringAsFixed(1)} km/h  ·  ${s.paceMinPerKm} min/km',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: segmentStats.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
