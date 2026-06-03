# My Gas Receipts

> A privacy-first, on-device expense and mileage tracker built for gig drivers, rideshare operators, and independent contractors. Capture receipts, run them through on-device OCR, organize by vehicle and category, and export tax-ready PDF or CSV reports — without ever sending your financial data to a server.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-3DDC84)](#-supported-platforms)
[![Storage](https://img.shields.io/badge/Storage-100%25%20Local-success)](#-privacy--security)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

---

## Table of Contents

- [Overview](#-overview)
- [Highlights](#-highlights)
- [Screenshots](#-screenshots)
- [Features](#-features)
  - [Capture & OCR](#-capture--ocr)
  - [Organization & Search](#-organization--search)
  - [Vehicles & Mileage](#-vehicles--mileage)
  - [Categories & Vendors](#-categories--vendors)
  - [Export & Tax Reporting](#-export--tax-reporting)
  - [Security & Privacy](#-security--privacy)
  - [Customization & UX](#-customization--ux)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Building for Release](#-building-for-release)
- [Configuration](#-configuration)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)

---

## Overview

**My Gas Receipts** is a single-purpose Flutter app that solves a real problem for self-employed drivers: keeping clean, IRS-ready records of vehicle expenses without the bookkeeping overhead or the privacy trade-offs of cloud-based tools.

Every byte of data — receipt images, parsed amounts, vendor names, mileage logs, vehicle profiles — lives on the device in a local SQLite database and the app's private documents directory. There is no account, no telemetry of your finances, and no third-party service in the data path.

The app's design language is **modern Material 3** with an indigo / cyan / violet brand palette, glassmorphic cards, gradient hero headers, and a bottom navigation bar that surfaces every primary feature in one tap.

---

## Highlights

- 📸 **One-tap capture** with on-device OCR that auto-fills vendor and amount
- 🧾 **Tax-ready exports** — PDF reports with embedded receipt images, or CSV for spreadsheets
- 🚗 **Multi-vehicle tracking** with default-vehicle selection
- 🛣️ **Mileage log** with odometer-based trip calculation
- 🎨 **3-way theme switcher** (Light / Dark / System) with persistent preference
- 🔐 **Biometric lock** to keep financial data private
- 🌓 **Fully offline** — works on a plane, no internet required after install
- 🏷️ **Custom categories** with per-category vendor labels (e.g. "Station Name" vs. "Insurance Company")

---

## Screenshots

> _Add screenshots to a `docs/screenshots/` folder and reference them here._

| Dashboard | Capture | Batch Import |
| --- | --- | --- |
| _(add screenshot)_ | _(add screenshot)_ | _(add screenshot)_ |

| Vehicles | Mileage | Settings |
| --- | --- | --- |
| _(add screenshot)_ | _(add screenshot)_ | _(add screenshot)_ |

---

## Features

### 📸 Capture & OCR

- **Camera & Gallery import** — snap a receipt with the system camera or pick from the gallery.
- **Batch import** — select multiple photos at once; each photo gets its own per-image form (vendor, amount, date, vehicle, notes) so nothing is shared by accident.
- **On-device OCR** — powered by [Google ML Kit Text Recognition](https://developers.google.com/ml-kit/vision/text-recognition). Recognized totals and station names are written straight into the form.
- **Station-name detection** — recognizes common brands including Shell, BP, Chevron, Exxon, Texaco, Costco, Mobil, 76, and others.
- **Smart image compression** — captured images are downscaled to a sensible resolution and re-encoded as JPEG to keep storage usage low.
- **Required-field validation** — both the vendor and the amount are mandatory; saving is blocked until both are valid (positive numeric amount, non-empty vendor).

### 🗂 Organization & Search

- **Receipt list** — image thumbnail, amount, date, category badge, and vehicle name for every entry.
- **Category filter chips** — quick one-tap filtering across all built-in and custom categories.
- **Date range presets** — _This Quarter_, _Last Quarter_, _Year to Date_, _All Time_.
- **Vehicle filter** — narrow the list to one vehicle's expenses.
- **Archive workflow** — mark exported receipts as archived to keep the active list focused.
- **Swipe-to-delete** and **long-press actions** for Edit / Archive / Delete.
- **Detail view** — full-size receipt image plus all metadata, with inline Edit.

### 🚗 Vehicles & Mileage

- **Vehicle profiles** — name, make, model, year, license plate, notes.
- **Default vehicle** — new receipts and mileage entries auto-attach to it; change any time.
- **Per-vehicle analytics** — filter receipts and mileage by vehicle.
- **Mileage log** — record start and end odometer readings, date, purpose, and notes.
- **Auto-calculated distance** — total miles driven for any period, per vehicle or overall.
- **Date range filter** for mileage — _This Quarter_, _Last Quarter_, _YTD_, _All Time_.

### 🏷 Categories & Vendors

- **Built-in categories** — Gas, Maintenance, Insurance, Tolls, Parking, Other.
- **Custom categories** — create, edit, and delete your own with a custom icon (40+ Material icons) and color.
- **Dynamic vendor labels** — the vendor input field adapts to the selected category:
  | Category | Vendor Field |
  | --- | --- |
  | Gas | Station Name |
  | Maintenance | Service Provider |
  | Insurance | Insurance Company |
  | Tolls | Toll Road / Bridge |
  | Parking | Parking Location |
  | Other | Vendor / Merchant |
  | Custom | Custom label per category |

### 📤 Export & Tax Reporting

- **PDF export** — branded PDF with a summary table, total expenses, and embedded receipt images, organized by date.
- **CSV export** — structured columns: _Date, Category, Vendor, Amount, Vehicle, Notes_ — drop straight into a spreadsheet.
- **Quarter-aware naming** — exports default to a tax-period label (e.g. _Q2 2026_) for easy filing.
- **Native share sheet** — export directly to email, Drive, Files, or any installed app via the OS share sheet.
- **Archive after export** — optional toggle in the export flow to keep your active list clean.

### 🔒 Security & Privacy

- **Biometric lock** — gate the app behind fingerprint or Face ID via the system biometric prompt.
- **Auto-lock on resume** — re-prompt on app foregrounding so a borrowed phone doesn't expose receipts.
- **Local-only storage** — SQLite database and image files in the app's private documents directory.
- **No analytics, no telemetry, no third-party SDKs** in the data path.

### 🎨 Customization & UX

- **3-way theme switcher** — Light, Dark, or follow System. Persisted in `SharedPreferences`.
- **Modern Material 3 design** — custom design tokens, rounded inputs, glass cards, gradient accents.
- **Bottom navigation** — Receipts, Mileage, Categories, Settings all one tap away.
- **Daily reminder notification** — opt-in daily nudge at a time you choose.
- **Splash screen** — branded gradient splash with animated logo.
- **Responsive layouts** — works on phones and tablets.

---

## 🧰 Tech Stack

| Layer | Technology | Purpose |
| --- | --- | --- |
| Framework | [Flutter](https://flutter.dev) 3.x | Cross-platform UI toolkit |
| Language | [Dart](https://dart.dev) 3.7+ | App + business logic |
| State management | [Provider](https://pub.dev/packages/provider) | Lightweight reactive state |
| Local database | [sqflite](https://pub.dev/packages/sqflite) | SQLite persistence |
| Preferences | [shared_preferences](https://pub.dev/packages/shared_preferences) | Theme & settings storage |
| Image capture | [image_picker](https://pub.dev/packages/image_picker) | Camera & gallery |
| Image compression | [flutter_image_compress](https://pub.dev/packages/flutter_image_compress) | Reduce image size |
| OCR | [google_mlkit_text_recognition](https://pub.dev/packages/google_mlkit_text_recognition) | On-device text recognition |
| PDF | [pdf](https://pub.dev/packages/pdf) | Report generation |
| CSV | [csv](https://pub.dev/packages/csv) | Structured data export |
| Share | [share_plus](https://pub.dev/packages/share_plus) | Native share sheet |
| Auth | [local_auth](https://pub.dev/packages/local_auth) | Biometric authentication |
| Notifications | [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) | Daily reminder |
| Permissions | [permission_handler](https://pub.dev/packages/permission_handler) | Runtime permission UX |
| File paths | [path_provider](https://pub.dev/packages/path_provider) + [path](https://pub.dev/packages/path) | App documents directory |
| i18n / dates | [intl](https://pub.dev/packages/intl) | Number & date formatting |

---

## 📁 Project Structure

```
my_gas_receipts/
├── android/                    # Android platform code
├── ios/                        # iOS platform code
├── lib/
│   ├── main.dart               # App entry, theme bootstrap, providers
│   ├── models/                 # Plain-Dart data models
│   │   ├── receipt.dart
│   │   ├── vehicle.dart
│   │   ├── mileage_entry.dart
│   │   └── expense_category.dart
│   ├── providers/              # ChangeNotifier state holders
│   │   ├── receipt_provider.dart
│   │   └── theme_provider.dart
│   ├── screens/                # Top-level screens / tabs
│   │   ├── home_screen.dart           # Bottom-nav shell + Receipts tab
│   │   ├── capture_screen.dart        # Single-receipt capture + OCR
│   │   ├── batch_import_screen.dart   # Multi-photo import w/ per-image forms
│   │   ├── vehicles_screen.dart       # Vehicle CRUD
│   │   ├── mileage_screen.dart        # Mileage log
│   │   ├── categories_screen.dart     # Custom category CRUD
│   │   ├── export_screen.dart         # PDF / CSV export flow
│   │   └── settings_screen.dart       # Theme, biometric, reminders
│   ├── services/               # Cross-cutting business logic
│   │   ├── database_service.dart      # SQLite schema + queries
│   │   ├── image_service.dart         # Capture, compress, store
│   │   ├── ocr_service.dart           # ML Kit text recognition
│   │   ├── pdf_service.dart           # Tax-report PDF
│   │   ├── csv_service.dart           # Spreadsheet-friendly CSV
│   │   ├── auth_service.dart          # Biometric prompt
│   │   └── notification_service.dart  # Daily reminder
│   └── theme/
│       └── app_theme.dart      # Design tokens, ThemeData, shared widgets
├── test/                       # Widget & unit tests
├── pubspec.yaml                # Dependencies
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.7.2` ([install guide](https://docs.flutter.dev/get-started/install))
- Dart `^3.7.2` (bundled with Flutter)
- Android Studio (for Android) or Xcode 15+ (for iOS)
- An Android emulator, iOS simulator, or a physical device

### Clone & Run

```bash
# 1. Clone the repository
git clone https://github.com/shovoghosh/My-Gas-Receipts.git
cd My-Gas-Receipts

# 2. Install dependencies
flutter pub get

# 3. Verify your toolchain
flutter doctor

# 4. List available devices
flutter devices

# 5. Run on a connected device / emulator
flutter run
```

> The first build can take a few minutes while Gradle and CocoaPods set up.

---

## 🏗 Building for Release

```bash
# Android APK (universal)
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS (requires a Mac with Xcode)
flutter build ios --release
```

Output artifacts land in `build/app/outputs/flutter-apk/` and `build/ios/iphoneos/`.

---

## ⚙️ Configuration

### Android permissions

The app requests the following runtime permissions on first use. Add to `android/app/src/main/AndroidManifest.xml` if customizing:

| Permission | Why |
| --- | --- |
| `CAMERA` | Capture receipt photos |
| `READ_MEDIA_IMAGES` (Android 13+) / `READ_EXTERNAL_STORAGE` (≤ 12) | Pick from gallery |
| `USE_BIOMETRIC` | Fingerprint / Face ID lock |
| `POST_NOTIFICATIONS` (Android 13+) | Daily reminder |
| `USE_FULL_SCREEN_INTENT` (optional) | Notification UX on lock screen |

### iOS permissions

Add the following keys to `ios/Runner/Info.plist` if customizing:

| Key | Why |
| --- | --- |
| `NSCameraUsageDescription` | Capture receipt photos |
| `NSPhotoLibraryUsageDescription` | Pick from gallery |
| `NSFaceIDUsageDescription` | Face ID lock |

### ML Kit model

Text recognition uses Google ML Kit's on-device Latin script model. The dependency is bundled — no extra download step on first run.

---

## 🗺 Roadmap

Planned enhancements, in no particular order:

- [ ] Cloud backup (Google Drive / iCloud) — opt-in only, end-to-end encrypted
- [ ] Spending analytics charts (monthly trends, category breakdown)
- [ ] IRS standard mileage rate auto-calculation for deductions
- [ ] Multi-currency support with per-receipt currency
- [ ] Receipt tagging and free-text search
- [ ] Tablet-optimized two-pane layouts
- [ ] Localization (Spanish, French, German)
- [ ] Home-screen widget for quick capture

---

## 🤝 Contributing

Contributions are welcome! Here's how to get started:

1. **Fork** the repository.
2. **Create a feature branch**: `git checkout -b feat/your-feature-name`
3. **Commit your changes**: `git commit -m "feat: add your feature"`
4. **Push** the branch: `git push origin feat/your-feature-name`
5. **Open a Pull Request** describing the change and any testing you performed.

Please follow the existing code style (Flutter lints are enabled via `analysis_options.yaml`) and run `flutter analyze` before submitting.

### Reporting bugs

Open an [issue](../../issues) with:

- A clear title and description
- Steps to reproduce
- Expected vs. actual behavior
- Device + OS version
- Relevant logs or screenshots

---

## 📄 License

Released under the [MIT License](LICENSE). You are free to use, modify, and distribute this app — personally or commercially — as long as the copyright notice is preserved.

---

## 🙏 Acknowledgments

- [Google ML Kit](https://developers.google.com/ml-kit) — on-device OCR
- [Flutter](https://flutter.dev) — the framework that makes this codebase a joy to write
- [Material Design 3](https://m3.material.io) — design language inspiration
- Every open-source package listed in [Tech Stack](#-tech-stack) — none of this would be possible without the Flutter community

---

<p align="center">
  <strong>Built for gig drivers who want their receipts organized without giving up their privacy.</strong>
</p>
