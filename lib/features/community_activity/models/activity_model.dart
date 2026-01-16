import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Activity {
  final String id;
  final String activityName; // Mapped from 'title'
  final String category;
  final double latitude;     // Mapped from 'lat'
  final double longitude;    // Mapped from 'lon'
  final String address;
  final DateTime date;       // Parsed from 'date' string
  final String shortDescription; // Mapped from 'description'
  final String organizerName;    // Mapped from 'organizer'
  final String organizerContact; // Optional/Default

  Activity({
    required this.id,
    required this.activityName,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.date,
    required this.shortDescription,
    required this.organizerName,
    required this.organizerContact,
  });

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse date and time strings
    String dateStr = data['date'] ?? ''; // Format assumed: yyyy-MM-dd
    String timeStr = data['time'] ?? ''; // Format assumed: HH:mm
    DateTime parsedDate = DateTime.now();
    
    try {
      if (dateStr.isNotEmpty) {
        if (timeStr.isNotEmpty) {
           parsedDate = DateTime.parse("$dateStr $timeStr:00"); 
        } else {
           parsedDate = DateTime.parse(dateStr);
        }
      }
    } catch (e) {
      print("Error parsing date: $e");
    }

    return Activity(
      id: doc.id,
      activityName: data['activityName'] ?? data['title'] ?? '',
      category: data['category'] ?? '',
      latitude: (data['latitude'] ?? data['lat'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? data['lon'] ?? 0.0).toDouble(),
      address: data['address'] ?? '',
      date: parsedDate,
      shortDescription: data['description'] ?? '',
      organizerName: data['organizerName'] ?? data['organizer'] ?? '',
      organizerContact: data['organizerContact'] ?? 'Contact Organizer',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activityName': activityName,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'time': DateFormat('HH:mm').format(date),
      'description': shortDescription,
      'organizerName': organizerName,
      'organizerContact': organizerContact,
    };
  }
}
