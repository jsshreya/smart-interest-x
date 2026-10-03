# SmartInterestX 💰

### Loan & Interest Management Mobile Application

SmartInterestX is a Flutter-based mobile application designed to help users track, calculate, and manage interest-based financial transactions between borrowers and lenders.

The application provides features for transaction management, interest calculation, payment tracking, payment proof management, due-date reminders, analytics, and CSV export.

---

## 📱 Project Overview

Managing multiple loans and interest-based transactions manually can be difficult. SmartInterestX provides a centralized mobile solution to record transactions, automatically calculate interest, track payments, monitor due dates, and analyze financial activity.

### Main Features

- 👤 Borrower & Lender Management
- 💰 Given & Taken Transactions
- 🧮 Monthly & Yearly Simple Interest Calculation
- 📅 Start Date & Due Date Tracking
- 💳 Partial & Full Payment Tracking
- 📷 Payment Proof Upload
- 🔔 Due Date Notifications
- 📊 Analytics Dashboard
- 📈 Given vs Taken Analysis
- 🔍 Month, Year & Person Filters
- 📤 CSV Export & Sharing
- 🌙 Light & Dark Theme
- 💾 Local Database Storage

---

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Mobile Application Development |
| Dart | Programming Language |
| Provider | State Management |
| SQLite / sqflite | Local Database |
| Flutter Local Notifications | Due Date Reminders |
| fl_chart | Analytics & Charts |
| image_picker | Payment Proof Images |
| csv | CSV Export |
| path_provider | Local File Storage |
| share_plus | File Sharing |

---

## 🏗️ Application Architecture

The application follows a structured Flutter architecture:

```text
lib/
│
├── app/
│   ├── app.dart
│   └── theme.dart
│
├── models/
│   ├── person.dart
│   ├── transaction.dart
│   └── payment.dart
│
├── providers/
│   ├── person_provider.dart
│   ├── transaction_provider.dart
│   ├── payment_provider.dart
│   └── theme_provider.dart
│
├── screens/
│   ├── home/
│   ├── people/
│   ├── transactions/
│   ├── analytics/
│   └── settings/
│
├── services/
│   ├── database_service.dart
│   ├── notification_service.dart
│   └── export_service.dart
│
└── utils/
    └── transaction_status.dart
