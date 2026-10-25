#!/usr/bin/env bash
# One-time setup. Run after installing Flutter (https://docs.flutter.dev/get-started/install).
# Generates android/ and ios/, installs packages, and patches AndroidManifest.xml for reminders.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v flutter >/dev/null || { echo "flutter not found on PATH"; exit 1; }

# Keeps existing lib/, test/ and pubspec.yaml; only adds the platform folders.
flutter create --project-name bp_tracker --org com.example --platforms android,ios .
flutter pub get

MANIFEST=android/app/src/main/AndroidManifest.xml
if ! grep -q POST_NOTIFICATIONS "$MANIFEST"; then
  python3 - "$MANIFEST" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
perms = '''    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
'''
receivers = '''        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
            </intent-filter>
        </receiver>
'''
s = s.replace('<application', perms + '    <application', 1)
s = s.replace('</application>', receivers + '    </application>', 1)
open(p, 'w').write(s)
PY
  echo "Patched $MANIFEST"
fi

cat <<'MSG'

Manual step (Android): flutter_local_notifications needs core library desugaring.
In android/app/build.gradle(.kts):
  android { compileOptions { isCoreLibraryDesugaringEnabled = true } }   // Groovy: coreLibraryDesugaringEnabled true
  dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }

Then:  flutter test && flutter run
MSG
