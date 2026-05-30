import 'dart:async' show StreamSubscription, TimeoutException;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

/// Result from a geofence check.
enum GeofenceResult {
  inside,
  outside,
  permissionDenied,
  serviceDisabled,
  timeout,
  error,
}

class GeofencingService {
  // Default radius in metres if user hasn't customised it.
  static const defaultRadiusM = 150.0;

  /// Returns the user's current position or null on failure.
  static Future<Position?> getCurrentPosition() async {
    if (kIsWeb) return null;
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Requests foreground location permission. Returns true if granted.
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// Requests background ("always") location permission.
  /// Must be called after [requestPermission] grants whileInUse first.
  /// Returns true when LocationPermission.always is granted.
  static Future<bool> requestBackgroundPermission() async {
    if (kIsWeb) return false;
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.whileInUse) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always;
  }

  /// Checks if the user is within [radiusM] metres of [officeLat]/[officeLng].
  static Future<GeofenceResult> checkInOffice({
    required double officeLat,
    required double officeLng,
    double radiusM = defaultRadiusM,
  }) async {
    if (kIsWeb) return GeofenceResult.error;
    if (!await Geolocator.isLocationServiceEnabled()) {
      return GeofenceResult.serviceDisabled;
    }
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return GeofenceResult.permissionDenied;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final dist = _haversineM(
        pos.latitude,
        pos.longitude,
        officeLat,
        officeLng,
      );
      return dist <= radiusM ? GeofenceResult.inside : GeofenceResult.outside;
    } on TimeoutException {
      return GeofenceResult.timeout;
    } catch (_) {
      return GeofenceResult.error;
    }
  }

  /// Starts a background geofence exit monitor using a continuous position
  /// stream. Calls [onExit] once when the device moves beyond [radiusM] metres
  /// from the office coordinates, then stops.
  ///
  /// Requires LocationPermission.always on iOS/Android (request via
  /// [requestBackgroundPermission] first). On web or when permission is
  /// insufficient, returns null immediately.
  ///
  /// The caller owns the returned [StreamSubscription] and must cancel it
  /// when the shift ends or the app is disposed.
  static StreamSubscription<Position>? startExitMonitor({
    required double officeLat,
    required double officeLng,
    double radiusM = defaultRadiusM,
    required void Function() onExit,
  }) {
    if (kIsWeb) return null;

    // Use a lower accuracy + 30 s interval to preserve battery.
    const settings = LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 50, // only emit when moved ≥50 m
    );

    bool fired = false;
    StreamSubscription<Position>? sub;
    sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        if (fired) return;
        final dist = _haversineM(
          pos.latitude,
          pos.longitude,
          officeLat,
          officeLng,
        );
        if (dist > radiusM) {
          fired = true;
          onExit();
          sub?.cancel();
        }
      },
      onError: (_) => sub?.cancel(),
      cancelOnError: false,
    );
    return sub;
  }

  // Haversine formula — distance in metres between two lat/lng points.
  static double _haversineM(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0; // Earth radius in metres
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
