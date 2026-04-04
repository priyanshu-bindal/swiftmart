import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LocationNotifier extends Notifier<String> {
  static const _storage = FlutterSecureStorage();

  @override
  String build() {
    _loadSaved();
    return 'Set location';
  }

  Future<void> _loadSaved() async {
    final saved = await _storage.read(key: 'user_location');
    if (saved != null) {
      state = saved;
    }
  }

  /// Returns null on success, or an error message string on failure.
  Future<String?> requestAndUpdate() async {
    try {
      // 1. Check if location services are enabled on the device
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Location services are disabled. Please enable GPS.';
      }

      // 2. Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Location permission permanently denied. Enable it in app settings.';
      }
      if (permission == LocationPermission.denied) {
        return 'Location permission denied.';
      }

      // 3. Get coordinates with a 15-second timeout
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // 4. Reverse-geocode to a human-readable area name
      String locationStr =
          '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'; // fallback

      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if (p.subLocality != null && p.subLocality!.isNotEmpty)
              p.subLocality!,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          ];
          if (parts.isNotEmpty) {
            locationStr = parts.join(', ');
          } else if (p.administrativeArea != null &&
              p.administrativeArea!.isNotEmpty) {
            locationStr = p.administrativeArea!;
          }
        }
      } catch (_) {
        // geocoding failed → keep the coordinate fallback
      }

      state = locationStr;
      await _storage.write(key: 'user_location', value: locationStr);
      return null; // success
    } on LocationServiceDisabledException {
      return 'Location services are disabled. Please enable GPS.';
    } catch (e) {
      return 'Could not fetch location: ${e.toString()}';
    }
  }

  void updateLocation(String location) {
    state = location;
    _storage.write(key: 'user_location', value: location);
  }
}

final locationProvider = NotifierProvider<LocationNotifier, String>(
  LocationNotifier.new,
);
