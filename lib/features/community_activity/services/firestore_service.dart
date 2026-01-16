import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/activity_model.dart';
import '../models/activity_feedback.dart';
import 'location_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> submitFeedback(ActivityFeedback feedback) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('feedback')
          .add(feedback.toMap());
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      print("🔐 FirestoreService: Attempting anonymous sign-in...");
      UserCredential userCredential = await _auth.signInAnonymously();
      print("✅ FirestoreService: Successfully signed in as ${userCredential.user?.uid}");
      return userCredential.user;
    } catch (e) {
      print("❌ FirestoreService: Error signing in anonymously: $e");
      // If there's an error, we should inform the user about common causes
      if (e.toString().contains('operation-not-allowed')) {
        print("💡 TIP: You MUST enable 'Anonymous' authentication in the Firebase Console (Authentication > Sign-in method).");
      }
      return null;
    }
  }

  Stream<List<Activity>> getActivities(String category) {
    // Handling case sensitivity and ensuring it matches Firestore
    return _firestore
        .collection('community_activities')
        .where('category', isEqualTo: category.toLowerCase())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList();
    });
  }

  Future<void> joinActivity(Activity activity) async {
    User? user = _auth.currentUser;
    
    // If no user, try to sign in anonymously first
    if (user == null) {
      print("👤 FirestoreService: No user found, attempting anonymous sign-in...");
      user = await signInAnonymously();
    }

    if (user != null) {
      final registrationData = {
        'activityId': activity.id,
        'activityName': activity.activityName,
        'category': activity.category,
        'date': DateFormat('yyyy-MM-dd').format(activity.date),
        'time': DateFormat('HH:mm').format(activity.date),
        'organizerName': activity.organizerName,
        'status': 'registered',
        'joinedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('joinedActivities')
          .doc(activity.id)
          .set(registrationData);
    } else {
      throw Exception("Authentication failed. Please check your internet connection.");
    }
  }

  Future<void> updateActivityStatus(String activityId, String status) async {
    User? user = _auth.currentUser;
    if (user != null) {
      print("📝 FirestoreService: Updating activity $activityId status to $status...");
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('joinedActivities')
          .doc(activityId)
          .update({'status': status});
    }
  }

  Future<void> unregisterActivity(String activityId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      print("🗑️ FirestoreService: Unregistering from activity $activityId...");
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('joinedActivities')
          .doc(activityId)
          .delete();
    }
  }

  Stream<List<Activity>> getRecommendations(String category, String excludeId) {
    return _firestore
        .collection('community_activities')
        .where('category', isEqualTo: category.toLowerCase())
        .limit(4) // Fetch a few more to filter out the current one
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Activity.fromFirestore(doc))
          .where((activity) => activity.id != excludeId)
          .take(3) // Only show top 3 recommendations
          .toList();
    });
  }
  
  Future<void> addActivity(Activity activity) async {
    await _firestore.collection('community_activities').add(activity.toMap());
  }

  Future<void> deleteActivity(String activityId) async {
    print("🗑️ FirestoreService: Deleting activity $activityId...");
    await _firestore.collection('community_activities').doc(activityId).delete();
  }

  // Helper to add dummy data (for testing purposes)
  Future<void> addDummyActivity() async {
     await _firestore.collection('community_activities').add({
      'activityName': 'Yoga for Seniors',
      'category': 'yoga',
      'latitude': 12.9716, // Bangalore
      'longitude': 77.5946,
      'address': 'Kanteerava Stadium, Bangalore',
      'date': '2025-02-10',
      'time': '08:30',
      'description': 'A gentle yoga session focused on flexibility and breathing for the elderly.',
      'organizerName': 'Healthy Living NGO',
      'organizerContact': '+91-9876543210',
    });
  }

  Future<void> refreshActivitiesWithDummyData({double? baseLat, double? baseLon}) async {
    final snapshot = await _firestore.collection('community_activities').limit(1).get();
    
    // ONLY seed if the database is completely empty. 
    // This prevents wiping out admin-added activities.
    if (snapshot.docs.isNotEmpty) {
      print("📊 FirestoreService: Data already exists, skipping automatic seed.");
      return;
    }

    print("🌱 Database is empty. Seeding initial proximity data...");

    double lat = baseLat ?? 12.9716;
    double lon = baseLon ?? 77.5946;

    // If no coordinates provided, try to fetch current location for better dummy data
    if (baseLat == null || baseLon == null) {
      try {
        final locationService = LocationService();
        final position = await locationService.getCurrentLocation();
        if (position != null) {
          lat = position.latitude;
          lon = position.longitude;
          print("📍 Seeding data near current location: ($lat, $lon)");
        }
      } catch (e) {
        print("⚠️ Failed to get current location for seeding, using default: $e");
      }
    }

    print("🌱 Seeding 5 fresh activities near ($lat, $lon)...");
    
    // Roughly 0.01 degrees is ~1.1km. 
    // For 10-12km, we use offsets around 0.08 to 0.1 degrees.
    final List<Map<String, dynamic>> dummyActivities = [
      {
        'activityName': 'Shiv Mandir Morning Prayer',
        'category': 'temple',
        'latitude': lat + 0.04, // ~4.5km away
        'longitude': lon + 0.04,
        'address': 'Shiv Temple, Nearby Area',
        'date': '2026-03-01',
        'time': '06:00',
        'description': 'Join us for the morning aarti and community breakfast.',
        'organizerName': 'Temple Trust',
        'organizerContact': '080-1234567',
      },
      {
        'activityName': 'Heritage Music Festival',
        'category': 'cultural',
        'latitude': lat - 0.05, // ~5.5km away
        'longitude': lon + 0.06,
        'address': 'Cultural Ground, Nearby Garden',
        'date': '2026-02-20',
        'time': '18:00',
        'description': 'Classical music performance by renowned artists.',
        'organizerName': 'Heritage Arts Council',
        'organizerContact': 'arts@heritage.org',
      },
      {
        'activityName': 'Free Health Checkup Camp',
        'category': 'health camps',
        'latitude': lat + 0.08, // ~9km away
        'longitude': lon - 0.03,
        'address': 'Community Hall, Sector 4',
        'date': '2026-03-15',
        'time': '09:00',
        'description': 'Comprehensive health checkup including BP, Sugar, and BMI for seniors.',
        'organizerName': 'City Hospital',
        'organizerContact': '9988776655',
      },
      {
        'activityName': 'Afternoon Seniors Meetup',
        'category': 'others',
        'latitude': lat - 0.09, // ~10km away
        'longitude': lon - 0.05,
        'address': 'Public Park, West Side',
        'date': '2026-04-05',
        'time': '16:00',
        'description': 'A casual meetup to share stories and enjoy the evening breeze.',
        'organizerName': 'Elders Joy Club',
        'organizerContact': 'info@joyclub.com',
      },
      {
        'activityName': 'Zen Yoga Session',
        'category': 'yoga',
        'latitude': lat + 0.1, // ~11km away
        'longitude': lon + 0.08,
        'address': 'Yoga Ground, Koramangala Extension',
        'date': '2026-02-25',
        'time': '07:30',
        'description': 'Relaxing outdoor yoga focused on mindfulness.',
        'organizerName': 'Yoga Bliss',
        'organizerContact': '+91-1122334455',
      },
    ];

    for (var activity in dummyActivities) {
      await _firestore.collection('community_activities').add(activity);
    }
    print("✅ Proximity activities seeded successfully!");
  }
}
