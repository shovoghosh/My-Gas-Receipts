# My Gas Receipts

A complete expense tracker and tax receipt manager built for gig drivers, rideshare operators, and independent contractors. Capture receipt photos, auto-extract totals with OCR, organize expenses by vehicle and category, and export tax-ready reports — all stored locally on your device.

---

## Features

### Capture & OCR
- **Camera & Gallery Import** — Snap a receipt with your camera or import from gallery.
- **Batch Import** — Select multiple photos at once to import receipts in bulk.
- **ML Kit OCR** — Automatically extracts the total amount and detects popular gas station names (Shell, BP, Chevron, Exxon, Texaco, Costco, Mobil, 76, and more).

### Organization
- **Receipt List** — View all receipts with image thumbnails, amount, date, category badge, and vehicle name.
- **Smart Filters** — Filter receipts by date range, category, or vehicle.
- **Archive** — Mark exported receipts as archived to keep your main list clean.
- **Search & Sort** — Receipts are sorted by date (newest first).

### Vehicles
- **Vehicle Profiles** — Add multiple vehicles (name, make, model, year).
- **Default Vehicle** — Set a default so new receipts automatically attach to it.
- **Per-Vehicle Tracking** — View expenses and mileage per vehicle.

### Categories
- **Built-in Categories** — Gas, Maintenance, Insurance, Tolls, Parking, Other.
- **Custom Categories** — Create your own categories with custom icons and colors.
- **Dynamic Vendor Labels** — The vendor field adapts to the selected category:
  - Gas → "Station Name"
  - Maintenance → "Service Provider"
  - Insurance → "Insurance Company"
  - Tolls → "Toll Road / Bridge"
  - Parking → "Parking Location"
  - Other → "Vendor / Merchant"

### Mileage Tracker
- **Log Trips** — Record start and end odometer readings, date, purpose, and notes.
- **Total Miles** — Automatically calculates total miles driven for any period.
- **Vehicle-Linked** — Mileage entries can be linked to specific vehicles.

### Export & Reporting
- **PDF Export** — Generate tax-ready PDF reports with a summary table and receipt images.
- **CSV Export** — Export structured data for your accountant:
  - Date, Category, Station, Amount, Vehicle, Notes
- **Date Range Presets** — Quick filters for This Quarter, Last Quarter, YTD, and Last 30 Days.
- **Archive After Export** — Optionally mark exported receipts as archived automatically.

### Security & Customization
- **Biometric Lock** — Enable fingerprint or Face ID to protect your financial data.
- **Dark Mode** — Toggle between light and dark themes in settings.
- **Daily Reminders** — Schedule a daily notification to log receipts.

### Receipt Management
- **View Detail** — Tap any receipt to see full details including the image.
- **Edit Receipts** — Update amount, vendor, date, category, vehicle, or notes.
- **Long-Press Actions** — Edit, archive, or delete directly from the list.
- **Swipe to Delete** — Quick swipe-to-delete on the receipt list.

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.x |
| State Management | Provider |
| Local Database | SQLite (sqflite) |
| Image Compression | flutter_image_compress |
| OCR | Google ML Kit Text Recognition |
| PDF Generation | pdf + share_plus |
| CSV Export | csv + share_plus |
| Biometric Auth | local_auth |
| Notifications | flutter_local_notifications |
| Preferences | shared_preferences |

---

## Supported Platforms

- **Android** (API 21+)
- **iOS** (iOS 12+)

---

## Installation

```bash
# Clone the repo
git clone https://github.com/shovoghosh/My-Gas-Receipts.git
cd My-Gas-Receipts

# Get dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

---

## Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, theme, providers
├── models/                    # Data models (Receipt, Vehicle, Mileage, Category)
├── providers/                 # State management (ReceiptProvider, ThemeProvider)
├── screens/                   # UI screens
│   ├── home_screen.dart       # Dashboard, receipt list, filters
│   ├── capture_screen.dart    # Camera/gallery capture + OCR
│   ├── batch_import_screen.dart
│   ├── categories_screen.dart # Custom category CRUD
│   ├── export_screen.dart     # PDF/CSV export
│   ├── mileage_screen.dart    # Mileage log
│   ├── vehicles_screen.dart   # Vehicle profiles
│   └── settings_screen.dart   # Theme, biometric, notifications
├── services/                  # Business logic
│   ├── database_service.dart  # SQLite CRUD
│   ├── image_service.dart     # Image capture & compression
│   ├── ocr_service.dart       # Text recognition
│   ├── pdf_service.dart       # PDF generation
│   ├── csv_service.dart       # CSV export
│   ├── auth_service.dart      # Biometric authentication
│   └── notification_service.dart
└── widgets/                   # Reusable widgets (if any)
```

---

## Privacy

- **100% Local Storage** — All data and images are stored on your device only.
- **No Cloud Uploads** — Nothing is uploaded to external servers.
- **Your Data, Your Control** — Delete or export everything at any time.

---

## Upcoming Features

- Cloud backup to Google Drive / iCloud
- Monthly spending analytics charts
- IRS standard mileage rate auto-calculation
- Multi-currency support

---

## License

MIT License — free for personal and commercial use.

---

> Built for gig drivers who need their tax receipts organized without the headache.
