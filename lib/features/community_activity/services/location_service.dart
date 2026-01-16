import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<Position?> getCurrentLocation() async {
    print('🔍 LocationService: Starting location fetch...');
    
    // 1. Check if location services are enabled (GPS on/off)
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('📡 GPS Service enabled: $serviceEnabled');
    
    if (!serviceEnabled) {
      print('❌ GPS is turned off.');
      return null;
    }

    // 2. Check and request permission using permission_handler for better dialog reliability
    var status = await Permission.location.status;
    print('🔐 Initial permission status: $status');

    if (status.isDenied) {
      print('🔐 Requesting location permission system dialog...');
      status = await Permission.location.request();
      print('🔐 Status after request: $status');
    }

    if (status.isPermanentlyDenied) {
      print('❌ Permission PERMANENTLY denied.');
      return null;
    }

    if (!status.isGranted) {
      print('❌ Permission was denied by the user.');
      return null;
    }

    print('✅ Permission GRANTED. Proceeding to fetch position...');

    // 3. Get current position with geolocator
    try {
      print('📍 Fetching GPS position with best accuracy...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 15),
        ),
      );
      print('✅ Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }
}
