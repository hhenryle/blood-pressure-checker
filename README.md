# BP Tracker

Flutter app to log blood pressure and heart rate, with daily reminders. Data is stored locally (SQLite), no account needed.

## Project tree

```
blood-pressure-records/
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── scripts/
│   └── setup.sh                  # generates android/ios, patches manifest
├── lib/
│   ├── main.dart                 # app entry, theme (light/dark), providers
│   ├── models/
│   │   └── reading.dart          # Reading model + SQLite map conversion
│   ├── data/
│   │   └── database.dart         # sqflite CRUD
│   ├── state/
│   │   └── app_state.dart        # readings, reminders, streak (ChangeNotifier)
│   ├── services/
│   │   ├── notification_service.dart  # local reminders, skip-if-logged
│   │   └── export_service.dart        # CSV + PDF export and share
│   ├── utils/
│   │   ├── bp_category.dart      # AHA classification + colors
│   │   └── stats.dart            # averages, date windows, streak
│   ├── screens/
│   │   ├── home_shell.dart       # bottom navigation
│   │   ├── home_screen.dart      # today status, latest reading, streak
│   │   ├── add_reading_screen.dart   # add/edit form
│   │   ├── history_screen.dart   # grouped by day, swipe delete, tap edit
│   │   ├── trends_screen.dart    # charts + averages
│   │   └── settings_screen.dart  # reminders, export
│   └── widgets/
│       └── reading_tile.dart     # list row + category badge
└── test/
    └── logic_test.dart           # classification, stats, CSV, model
```

## Features

| Feature | Where |
|---|---|
| Add reading: systolic, diastolic, pulse, date/time | add_reading_screen |
| Optional arm, position, tags, note | add_reading_screen |
| Validation (ranges, systolic > diastolic) | add_reading_screen |
| Crisis warning (>180 or >120) after saving | add_reading_screen |
| Edit and delete (swipe, with confirm) | history_screen |
| History grouped by day, color-coded by category | history_screen, reading_tile |
| Daily reminders (up to 4 times), skipped for today once logged | settings_screen, notification_service |
| Reminders survive reboot, rebuilt on every app open | notification_service |
| 7/30/90-day chart with 120/80 guide lines | trends_screen |
| Average, morning vs evening average | trends_screen |
| Streak and "done today" status | home_screen |
| PDF and CSV export, shared via the share sheet | settings_screen, export_service |
| Offline, local-only storage | database |
| Light and dark mode | main |

## Run

```bash
./scripts/setup.sh     # once, after installing Flutter
flutter test
flutter run
```

On iOS, open `ios/Runner.xcworkspace` once to set a signing team. Android needs the desugaring step printed by the setup script.

## Reminder design

A repeating daily alarm cannot be cancelled for a single day, so the app schedules one-shot notifications for the next 14 days and rebuilds them on app start and after any reading or reminder change. If you log a reading today, today's remaining reminders are dropped. If you do not open the app for 14 days, reminders stop until you do.

## Not in MVP (v2)

Medication log, Health Connect / HealthKit sync, camera OCR, app lock, cloud backup, widgets, multiple profiles, localization.
