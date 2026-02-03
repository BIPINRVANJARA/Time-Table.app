# Timecloud v1.0.0 Release Notes

## 🎉 Initial Release

**Release Date:** February 3, 2026

### ✨ Features

- **Weekly Timetable Management**
  - Create your college schedule for Monday-Saturday
  - Color-code subjects for easy identification
  - Set custom start and end times for each class

- **Smart Notifications**
  - Weekly repeating reminders before each class
  - Customizable reminder time (5, 10, 15, or 30 minutes before)
  - Works even when app is closed
  - Persists across device reboots

- **Today's Schedule View**
  - Automatically shows current day's classes
  - Horizontal date selector to view other days
  - Time-sorted subject display
  - Empty state messages for days without classes

- **Offline First Architecture**
  - 100% offline functionality
  - No internet required
  - Local Hive database storage
  - Fast and responsive

- **Beautiful UI**
  - Material 3 design system
  - Gradient splash screen with custom logo
  - Color-coded subject cards
  - Smooth animations and transitions

### 📥 Download

- **APK Size:** 49.4 MB
- **Minimum Android Version:** Android 5.0 (API 21)
- **Target Android Version:** Android 14 (API 34)

[Download timecloud-v1.0.0.apk](https://github.com/BIPINRVANJARA/Time-Table.app/releases/download/v1.0.0/timecloud-v1.0.0.apk)

### 🛠️ Technical Details

- **Framework:** Flutter 3.x
- **Language:** Dart
- **Database:** Hive (NoSQL)
- **Notifications:** flutter_local_notifications
- **Permissions Required:**
  - RECEIVE_BOOT_COMPLETED
  - SCHEDULE_EXACT_ALARM
  - POST_NOTIFICATIONS
  - VIBRATE

### 📝 Known Issues

- Sunday is not included in the timetable (Monday-Saturday only)
- No dark mode support yet
- No settings screen for customization

### 🔜 Planned Features

- Settings screen with preferences
- Dark mode support
- Sunday schedule support
- Export/import timetable
- Multiple timetables for different semesters
- Home screen widget

### 🐛 Bug Fixes

This is the initial release, so no bug fixes yet!

---

**Made with ❤️ for students who never want to miss a class**
