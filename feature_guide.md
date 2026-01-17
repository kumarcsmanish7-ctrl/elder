# Feature Guide: Community Activities

This guide explains how to run the application and explore the **Community Activities** feature.

## Prerequisites

- **Flutter SDK**: Ensure Flutter is installed and configured on your machine.
- **Android Emulator / Physical Device**: A device should be connected or an emulator should be running.
- **Firebase**: The app uses Firebase. Ensure `google-services.json` (for Android) and `firebase_options.dart` are present.

## How to Run the App

1.  **Open a Terminal**: Navigate to the project root directory: `c:\Users\Monika KN\elderly_app`.
2.  **Check Connected Devices**:
    ```powershell
    flutter devices
    ```
3.  **Run the App**:
    - To run on the default device (usually the emulator if only one is running):
      ```powershell
      flutter run
      ```
    - To run on a specific device (e.g., the emulator):
      ```powershell
      flutter run -d emulator-5554
      ```
    - To run on Windows desktop:
      ```powershell
      flutter run -d windows
      ```

## Exploring the Feature

Once the app is running on your device:

1.  **Home Screen**: You will see the "Welcome to Elderly Ease" screen.
2.  **Access Community Activities**: Click the **"Community Activities"** button (teal color).
3.  **Community Activities Hub**: This is the main center where you can choose between Elder and Admin sections.

### Elder Section
- **Browse Activities**: Search and view upcoming events near you.
- **Track Your Participation**: View activities you've joined and mark your attendance.

### Admin / Caretaker Section
- **Add New Activity**: Create a new event with a name, date, and location.
- **Track Participation**: See which elders have registered or attended specific activities.
- **Manage Activities (Delete)**: Clean up or remove old/incorrect activities.

## Troubleshooting

- **Firebase Error**: If you see "Firebase initialization failed", double-check that your `firebase_options.dart` is correctly configured for your project.
- **Location Error**: The app needs location permissions to show nearby activities. Ensure location services are enabled on your device/emulator.
