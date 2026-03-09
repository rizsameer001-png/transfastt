# TransFast Flutter App

Cross-platform mobile application for the TransFast International Remittance Platform.

## Tech Stack

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `dio` | HTTP client |
| `flutter_secure_storage` | JWT token storage |
| `shared_preferences` | User data cache |
| `fl_chart` | Charts |
| `intl` | Date/number formatting |

---

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── core/
│   ├── api/
│   │   ├── dio_client.dart          # Dio setup + interceptors
│   │   └── api_services.dart        # All API service classes
│   ├── constants/
│   │   └── api_constants.dart       # Base URL + all endpoints
│   ├── theme/
│   │   └── app_theme.dart           # Colors, typography, theme
│   ├── storage/
│   │   └── secure_storage.dart      # Token + user persistence
│   └── utils/
│       └── app_router.dart          # go_router config
├── features/
│   ├── auth/                        # Login, register, forgot password
│   ├── dashboard/                   # Home + bottom nav shell
│   ├── transfer/                    # 4-step send money wizard
│   ├── transactions/                # History + detail + tracking
│   ├── beneficiaries/               # Manage recipients
│   ├── kyc/                         # Identity verification
│   ├── rates/                       # Live exchange rates
│   ├── profile/                     # Account settings
│   └── admin/                       # Admin panel (users, txns, KYC)
└── shared/
    └── widgets/
        └── app_widgets.dart         # Reusable UI components
```

---

## Quick Start

### 1. Prerequisites

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- TransFast Server running

Install Flutter: https://flutter.dev/docs/get-started/install

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure API URL

Edit `lib/core/constants/api_constants.dart`:

```dart
// For Android emulator (connects to localhost on host machine)
static const String baseUrl = 'http://10.0.2.2:5000/api';

// For iOS simulator
static const String baseUrl = 'http://localhost:5000/api';

// For physical device (use your machine's local IP)
static const String baseUrl = 'http://192.168.1.100:5000/api';

// For production
static const String baseUrl = 'https://your-domain.com/api';
```

### 4. Run the App

```bash
# List available devices
flutter devices

# Run on Android emulator
flutter run

# Run on specific device
flutter run -d <device_id>

# Build release APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

---

## App Screens

### User Flow

| Screen | Description |
|--------|-------------|
| Splash | Auto-login check |
| Login | Email/password auth with demo credentials |
| Register | Account creation |
| Dashboard | Overview, quick actions, recent transfers |
| Send Money | 4-step wizard: amount → recipient → payment → review |
| Transactions | Full history with status filters |
| Transaction Detail | Status tracker, full details, cancel option |
| Beneficiaries | Add/manage recipients |
| KYC | Identity verification form |
| Rates | Live FX rates with calculator |
| Profile | Edit profile, change password, logout |

### Admin Flow (admin/compliance role)

| Screen | Description |
|--------|-------------|
| Admin Dashboard | Stats: users, volume, KYC pending, flags |
| Users | Search, suspend/activate accounts |
| Transactions | Monitor all TXNs, mark delivered/reject |
| KYC Review | Approve or reject KYC submissions |

---

## State Management

Uses **Riverpod** with the following pattern:

```dart
// Provider definition
final myProvider = FutureProvider.autoDispose<List<Item>>((ref) async {
  return ApiService().getItems();
});

// Usage in widget
final itemsAsync = ref.watch(myProvider);
return itemsAsync.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
  data: (items) => ListView(...),
);
```

---

## Authentication

JWT token stored in `flutter_secure_storage`:

1. On login/register → token saved securely
2. Dio interceptor → attaches `Authorization: Bearer <token>` to every request
3. On 401 → token cleared → user redirected to login
4. On app start → token checked → user auto-logged in

---

## Adding Fonts (Optional)

Download DM Sans from Google Fonts and place in `assets/fonts/`:
- `DMSans-Regular.ttf`
- `DMSans-Medium.ttf`
- `DMSans-Bold.ttf`

Or remove the `fonts` section from `pubspec.yaml` to use system fonts.

---

## Demo Credentials

Run `npm run seed` in the server directory first, then:

| Role | Email | Password |
|------|-------|----------|
| User | john@example.com | User@12345 |
| Admin | admin@transfast.com | Admin@123456 |

---

## Production Checklist

- [ ] Update `baseUrl` to production server
- [ ] Remove demo credentials from login screen
- [ ] Configure push notifications (FCM)
- [ ] Add proper error reporting (Sentry/Firebase Crashlytics)
- [ ] Enable obfuscation: `flutter build apk --obfuscate --split-debug-info=debug-info/`
- [ ] Set proper app icons: `flutter_launcher_icons`
- [ ] Configure deep linking for payment callbacks
