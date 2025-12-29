import 'dart:convert';
import 'package:http/http.dart' as http;

class NominatimService {
  final String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<Map<String, double>?> getCoordinates(String address) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?q=${Uri.encodeComponent(address)}&format=json&limit=1'),
        headers: {
          'User-Agent': 'ElderlyEase/1.0', // Required by Nominatim policy
        },
      );

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        if (data.isNotEmpty) {
          return {
            'lat': double.parse(data[0]['lat']),
            'lon': double.parse(data[0]['lon']),
          };
        }
      }
      return null;
    } catch (e) {
      print("Geocoding error: $e");
      return null;
    }
  }
}
