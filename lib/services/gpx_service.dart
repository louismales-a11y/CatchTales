import 'dart:math';
import 'dart:io';
import 'package:xml/xml.dart';

/// A GPS track point with timestamp.
class GpxTrackPoint {
  final double latitude;
  final double longitude;
  final double? elevation;
  final DateTime? time;

  GpxTrackPoint({
    required this.latitude,
    required this.longitude,
    this.elevation,
    this.time,
  });
}

/// A parsed GPX track.
class GpxTrack {
  final String name;
  final List<GpxTrackPoint> points;

  GpxTrack({required this.name, required this.points});
}

/// Parses GPX (GPS Exchange Format) files.
///
/// GPX files contain GPS tracks recorded by phones or GPS devices.
/// This service extracts track points for display on the map.
class GpxService {
  static final GpxService instance = GpxService._();
  GpxService._();

  /// Parse a GPX file and return all tracks found.
  Future<List<GpxTrack>> parseFile(File file) async {
    final content = await file.readAsString();
    return parseString(content);
  }

  /// Parse GPX XML string content.
  List<GpxTrack> parseString(String xmlContent) {
    final tracks = <GpxTrack>[];

    try {
      final document = XmlDocument.parse(xmlContent);
      final gpx = document.findElements('gpx').firstOrNull;
      if (gpx == null) return tracks;

      // Parse <trk> elements
      for (final trk in gpx.findElements('trk')) {
        final name = trk.findElements('name').firstOrNull?.innerText ?? 'Unnamed Track';
        final points = <GpxTrackPoint>[];

        for (final trkseg in trk.findElements('trkseg')) {
          for (final trkpt in trkseg.findElements('trkpt')) {
            final lat = double.tryParse(trkpt.getAttribute('lat') ?? '');
            final lon = double.tryParse(trkpt.getAttribute('lon') ?? '');
            if (lat == null || lon == null) continue;

            double? ele;
            DateTime? time;

            final eleElem = trkpt.findElements('ele').firstOrNull;
            if (eleElem != null) {
              ele = double.tryParse(eleElem.innerText);
            }

            final timeElem = trkpt.findElements('time').firstOrNull;
            if (timeElem != null) {
              time = DateTime.tryParse(timeElem.innerText);
            }

            points.add(GpxTrackPoint(
              latitude: lat,
              longitude: lon,
              elevation: ele,
              time: time,
            ));
          }
        }

        if (points.length >= 2) {
          tracks.add(GpxTrack(name: name, points: points));
        }
      }

      // Also parse <wpt> waypoints
      // (not implementing for now — focus on tracks)
    } catch (_) {
      // Invalid XML — return empty
    }

    return tracks;
  }

  /// Get total distance of a track in kilometers.
  static double trackDistanceKm(List<GpxTrackPoint> points) {
    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += _haversine(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }
    return total;
  }

  /// Haversine distance in km.
  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * asin(sqrt(a));
    return r * c;
  }

  static double _toRad(double deg) => deg * 3.141592653589793 / 180;
}
