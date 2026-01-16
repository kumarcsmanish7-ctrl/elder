import 'dart:convert';
import 'package:http/http.dart' as http;

class NominatimService {
  final String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<Map<String, dynamic>?> getCoordinates(String address, {double? userLat, double? userLon, Function(String)? onStatusUpdate}) async {
    final cleanAddress = address.trim();
    if (cleanAddress.isEmpty) return null;

    final strategies = <String>[];
    strategies.add(cleanAddress);
    
    List<String> parts = cleanAddress.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.length > 2) strategies.add("${parts.first}, ${parts.last}");
    if (parts.length > 1) strategies.add(parts.first);

    // Variation for common typos in Bangalore
    if (cleanAddress.toLowerCase().contains("banglore")) {
      strategies.add(cleanAddress.toLowerCase().replaceAll("banglore", "bangalore"));
    }

    for (var query in strategies) {
      onStatusUpdate?.call("Searching nearby: $query...");
      var results = await _fetchFromNominatim(query, lat: userLat, lon: userLon, strict: true, radius: 0.1);
      if (results != null) return results;

      onStatusUpdate?.call("Searching city-wide: $query...");
      results = await _fetchFromNominatim(query, lat: userLat, lon: userLon, strict: false, radius: 0.5);
      if (results != null) return results;
      
      onStatusUpdate?.call("Searching globally: $query...");
      results = await _fetchFromNominatim(query, strict: false);
      if (results != null) return results;
    }

    return null;
  }

  Future<Map<String, dynamic>?> _fetchFromNominatim(String query, {double? lat, double? lon, bool strict = false, double radius = 0.2}) async {
    try {
      String url = '$_baseUrl?q=${Uri.encodeComponent(query)}&format=json&limit=1&addressdetails=1';
      
      if (lat != null && lon != null) {
        url += '&viewbox=${lon - radius},${lat + radius},${lon + radius},${lat - radius}';
        if (strict) url += '&bounded=1';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'ElderlyEase/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        if (data.isNotEmpty) {
          return {
            'lat': double.parse(data[0]['lat']),
            'lon': double.parse(data[0]['lon']),
            'displayName': data[0]['display_name'],
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
