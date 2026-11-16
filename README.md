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
