# TaskFlow

A Flutter productivity app for creating and managing personal tasks, backed by Firebase.

## Features

- Email/password authentication
- Task creation, editing, and deletion
- Dashboard with task statistics and search
- Offline support with local cache
- User profile and settings

---

## Prerequisites

| Tool | Minimum version |
|------|----------------|
| Flutter SDK | 3.11.5 |
| Dart SDK | 3.11.5 (included with Flutter) |
| Firebase CLI | latest — `npm install -g firebase-tools` |
| FlutterFire CLI | latest — `dart pub global activate flutterfire_cli` |
| Xcode | 15 (iOS only) |
| Android Studio / SDK | API 21+ (Android only) |

Check your environment:

```bash
flutter doctor
```

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/barcodepandora/MyTaskFlowFlutter.git
cd MyTaskFlowFlutter/taskflow
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Firebase configuration

The app requires a Firebase project with **Email/Password Authentication** and **Cloud Firestore** enabled.

**Create a Firebase project:**

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a project.
2. Enable **Authentication → Sign-in method → Email/Password**.
3. Enable **Firestore Database** (production mode).

**Connect the app:**

```bash
firebase login
flutterfire configure
```

`flutterfire configure` generates `lib/firebase_options.dart` and places the platform config files (`google-services.json`, `GoogleService-Info.plist`) in the correct directories automatically.

**Deploy Firestore security rules:**

```bash
firebase deploy --only firestore:rules
```

### 4. Run code generation

The project uses Riverpod code generation. Run once after setup (and again after modifying annotated providers):

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Running the app

```bash
# User
test@taskflow.com Test1234!

# List available devices
flutter devices

# Run on a specific device
flutter run -d <device-id>
```

Common targets: `ios`, `android`, `chrome`.

<img width="379" height="790" alt="Screenshot 2026-06-12 at 2 39 19 PM" src="https://github.com/user-attachments/assets/080f492d-bc7f-4368-b7a8-beece92bc153" />
<img width="379" height="776" alt="Screenshot 2026-06-12 at 2 40 33 PM" src="https://github.com/user-attachments/assets/29286c5f-ad69-41b5-a924-107ba1ae08a4" />
<img width="385" height="797" alt="Screenshot 2026-06-12 at 2 41 07 PM" src="https://github.com/user-attachments/assets/17f29c85-1b38-4f5a-b43e-0c217e592478" />
<img width="391" height="794" alt="Screenshot 2026-06-12 at 2 42 11 PM" src="https://github.com/user-attachments/assets/32e3440f-c058-42ee-971b-26f59cbc11f8" />
<img width="385" height="789" alt="Screenshot 2026-06-12 at 2 42 32 PM" src="https://github.com/user-attachments/assets/1a2273ae-4176-49bd-9fdb-fabfacef36f0" />
<img width="385" height="789" alt="Screenshot 2026-06-12 at 2 42 45 PM" src="https://github.com/user-attachments/assets/47b49905-90e7-44f9-a2e6-47b4ff9ee8ad" />
<img width="388" height="782" alt="Screenshot 2026-06-12 at 2 43 46 PM" src="https://github.com/user-attachments/assets/8b7539d6-9d24-471c-a391-b33c8f9a6291" />
<img width="386" height="786" alt="Screenshot 2026-06-12 at 2 48 37 PM" src="https://github.com/user-attachments/assets/84f31444-5f28-4687-999c-310adac7e472" />

---

## Running tests

```bash
flutter test
```
