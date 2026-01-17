# Elder Section - Team Lead Handoff

## 🎯 Overview

This is the **Elder section** of the Elderly Ease app. It allows elderly users to browse and join community activities.

## 🚀 How to Run

```bash
flutter run -t lib/main_elder.dart
```

Or set as default by copying `lib/main_elder.dart` content to `lib/main.dart`.

## ✅ What's Working

### Features Implemented:
- ✅ **Browse Activities** by category (Temple, Yoga, Health Camps, Cultural, Others)
- ✅ **View Activity Details** with map location
- ✅ **Join Activities** 
- ✅ **Track Joined Activities** (see what they've registered for)
- ✅ **Mark Attendance** via checkbox after attending
- ✅ **Activity Reminders** (1 day before + 1 hour before)
- ✅ **Distance Calculation** (shows how far activities are from user)
- ✅ **Anonymous Authentication** (persists across app restarts)

### Elder Section Structure:

**Entry Point:**
- `lib/main_elder.dart` - Starts the Elder app

**Screens:**
- `elder_hub_screen.dart` - Main hub (2 buttons: Browse, Track Participation)
- `category_screen.dart` - Choose activity category
- `activity_list_screen.dart` - List of activities in category
- `activity_details_screen.dart` - Full details, map, join button
- `joined_activities_screen.dart` - See joined activities, mark attendance

**Services (Shared with Volunteer section):**
- `firestore_service.dart` - All database operations
- `location_service.dart` - GPS/location handling
- `nominatim_service.dart` - Address ↔ coordinates conversion
- `reminder_service.dart` - Local notifications

**Models:**
- `activity_model.dart` - Activity data structure
- `activity_feedback.dart` - Feedback data structure

## 🔨 What You Need to Add

### Elder Login Screen

Currently, the app uses **anonymous authentication** for testing. You need to create:

1. **Create Elder Login Screen** (`lib/features/community_activity/screens/elder_login_screen.dart`)
   - Could be phone number + OTP
   - Or email/password
   - Or any authentication method you prefer

2. **Update `lib/main_elder.dart` line 64:**
   ```dart
   // Change from:
   home: const ElderHubScreen(),
   
   // To:
   home: const ElderLoginScreen(),  // Your login screen
   ```

3. **After successful login**, navigate to:
   ```dart
   Navigator.pushReplacement(
     context,
     MaterialPageRoute(builder: (context) => const ElderHubScreen()),
   );
   ```

## 📊 Data Flow

### How Activities Work:
1. **Volunteers** add activities via Volunteer section
2. Activities stored in Firestore: `community_activities` collection
3. **Elders** browse and join activities
4. Joined activities stored in: `users/{userId}/joinedActivities`
5. Reminders scheduled automatically when joining

### Current User System:
- Uses **Firebase Anonymous Auth** (temporary for testing)
- User persists across app restarts
- You should replace with proper Elder authentication

## 🧪 Testing Instructions

1. **Run the app:**
   ```bash
   flutter run -t lib/main_elder.dart -d emulator-5554
   ```

2. **Test Browse Flow:**
   - Click "Browse Activities"
   - Choose a category (e.g., Yoga)
   - See list of activities
   - Click an activity to see details
   - Click "Join Activity"

3. **Test Participation Tracking:**
   - Click "Track Your Participation"
   - See joined activities
   - Check boxes to mark attendance
   - Delete button to cancel registration

4. **Test Persistence:**
   - Join some activities
   - Restart the app
   - Joined activities should still appear

## 🔑 Firebase Setup

The app uses these Firebase services:
- **Firebase Auth** (anonymous currently, you'll change this)
- **Cloud Firestore** (database)
- **Firebase options** configured in `lib/firebase_options.dart`

All Firebase config is already set up and working.

## 🎨 UI/UX Notes

- **Color scheme**: Teal/Green (`Color(0xFF4D9689)`)
- **Large buttons** for accessibility
- **Icons** for visual clarity
- **Distance displayed** in km for each activity
- **Maps** show activity location

## 📞 Integration with Volunteer Section

The Elder and Volunteer sections share:
- ✅ Same Firestore database
- ✅ Same services (firestore, location, etc.)
- ✅ Same models (Activity, Feedback)

**Activities added by volunteers automatically appear in Elder browse.**

## 💡 Suggestions for Elder Login

Consider these elder-friendly authentication options:

1. **Phone + OTP** (Recommended)
   - Easy for elders
   - No passwords to remember
   - Firebase Phone Auth available

2. **Simple PIN**
   - 4-digit PIN
   - Very accessible

3. **Family Member Setup**
   - Caretaker creates account for elder
   - Pre-configured login

## 🐛 Known Issues

None! Everything is working smoothly.

## 📁 File Structure

```
lib/
├── main_elder.dart              # Elder entry point
├── firebase_options.dart        # Firebase config
├── features/
│   └── community_activity/
│       ├── screens/
│       │   ├── elder_hub_screen.dart
│       │   ├── category_screen.dart
│       │   ├── activity_list_screen.dart
│       │   ├── activity_details_screen.dart
│       │   └── joined_activities_screen.dart
│       ├── services/
│       │   ├── firestore_service.dart
│       │   ├── location_service.dart
│       │   ├── nominatim_service.dart
│       │   └── reminder_service.dart
│       └── models/
│           ├── activity_model.dart
│           └── activity_feedback.dart
```

## ✉️ Questions?

Contact: Monika (monikakn1@gmail.com)

---

**Last Updated:** January 17, 2026  
**Status:** ✅ Ready for Elder Login Implementation
