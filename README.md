
# Visitor Management App

A Flutter-based mobile application for registering visitors, managing visitor records, tracking check-in/check-out activity, and identifying visitors using QR codes.

## Features

- Dashboard with visitor statistics
- Register new visitors
- View visitor records and details
- Edit and delete visitor records
- Search visitors
- Generate a QR code for each visitor
- Scan QR codes to identify visitors
- Check-in and check-out workflow
- REST API integration for persistent visitor records

## Technology Stack

- **Framework:** Flutter
- **Language:** Dart
- **State Management:** Provider
- **Networking:** Dio
- **Backend:** MockAPI REST API
- **QR Code Generation:** qr_flutter
- **QR Code Scanning:** mobile_scanner
- **Date Formatting:** intl

## Requirements

- Flutter SDK
- Dart SDK (included with Flutter)
- Android Studio or VS Code
- Android SDK and an Android device or emulator
- Internet connection for API operations

## Flutter and Dart Versions

Run the following commands to check your installed versions:

```bash
flutter --version
dart --version
```

Record the versions used to develop and test this application here.

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/visitor-management-app.git
cd visitor-management-app
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the application

Connect an Android device or start an emulator, then run:

```bash
flutter run
```

### 4. Build the Android APK

```bash
flutter build apk --release
```

The APK is generated at:

`build/app/outputs/flutter-apk/app-release.apk`

## API Details

The application uses MockAPI as its REST backend.

**Base endpoint:**

`https://6ae18f6fbe3bc8fead98bcdf.mockapi.io/visitors`

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/visitors` | Retrieve all visitors |
| GET | `/visitors/{id}` | Retrieve one visitor |
| POST | `/visitors` | Register a visitor |
| PUT | `/visitors/{id}` | Update visitor details |
| DELETE | `/visitors/{id}` | Delete a visitor |

The API stores visitor information such as name, mobile number, email, visitor type, project, purpose, status, creation time, check-in time, and check-out time.

Each visitor receives an ID from MockAPI. The QR code uses this visitor ID to retrieve the corresponding record.

## Third-Party Packages

- `provider` — state management
- `dio` — HTTP requests and REST API communication
- `qr_flutter` — QR code generation
- `mobile_scanner` — QR code scanning
- `intl` — date and time formatting

See `pubspec.yaml` for the dependency versions.

## Test Login Credentials

No login credentials are required if the application opens directly to the dashboard without authentication.

## Screenshots

Application screenshots are available in the `screenshots/` directory.

- Dashboard
- Visitor registration
- Visitor list
- Visitor details and QR code
- QR scanner
- Check-in/check-out status

## Known Limitations

- The application requires an internet connection for MockAPI operations.
- The backend is a mock REST API and is intended for demonstration and assignment testing.
- QR scanning requires camera permission and a compatible device.
- Visitor records are stored in the configured MockAPI resource; the service may have usage or availability limitations.
- Authentication and role-based access control are not implemented unless added separately.

## Author

Aswin Saji
