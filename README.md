# EasyLoad Shop Manager — Android starter project

This is a new Flutter Android project based on the supplied `MOBILE LOAD (2).zip` source. The desktop source is Python/Tkinter, so it cannot be converted to APK by changing a GitHub workflow alone; the Android UI and database need Flutter implementation.

## Included in this first Android build
- EasyLoad Shop Manager name throughout (no E Zero label).
- Fresh local SQLite database created automatically on first launch.
- Dashboard totals for Sales, Received, Purchases and Expenses.
- Basic add/list screens for Items/Stock, Purchase, Sales, Customers, Payments, Expenses, JazzCash, EasyPaisa and Reports.
- Separate EasyLoad Hisab ledger with Jazz, Zong, Telenor, Ufone, Udhaar App, One Load and Cash.
- EasyLoad calculations from the supplied desktop README:
  - Total Balance = Opening Balance + 2 Day Load
  - Remaining = Total Balance - Sale
  - Remaining Ledger = RSO Total Remaining - Today Transfer - RSO Katta

## Build APK on GitHub
1. Create a new GitHub repository.
2. Upload the contents of this folder (not the outer ZIP folder) to the repository root.
3. Open **Actions** and run **Build EasyLoad Android APK**, or push to `main` / `master`.
4. Download `EasyLoad-Shop-Manager-APK` from the workflow run's **Artifacts** section.

## Important scope note
This is a working starter implementation, not yet a complete one-to-one port of every desktop feature. Advanced purchase/sale stock posting, full reports/PDF, camera/USB barcode scanning, login/roles, backup/restore, date editing/deleting, and data migration still need implementation and testing before business use. The supplied ZIP did not contain a populated records database, and this app starts with a new empty database.


## Android build fixes in this package

- Creates a real `assets/provider_logos/` directory containing the provider logo PNG files referenced by `pubspec.yaml`.
- The GitHub Actions workflow generates the Android platform and then pins Android Gradle Plugin 8.6.1, Kotlin 2.0.20, Gradle 8.7, and compileSdk 35.
- The app includes the EasyLoad dashboard, EasyLoad Hisab ledger, and camera barcode/QR scanner pages in `lib/main.dart`.

Run the `Build EasyLoad Android APK` workflow from GitHub Actions. The workflow has not been executed in this local environment; verify the release build in GitHub Actions.
