#!/usr/bin/env python3
"""Apply user-facing camera, internet and foreground location configuration.

Run from project root after: flutter create --platforms=android,ios .
The script is idempotent and does NOT enable background tracking.
"""
from pathlib import Path
import re

android_manifest = Path('android/app/src/main/AndroidManifest.xml')
if android_manifest.exists():
    text = android_manifest.read_text(encoding='utf-8')
    additions = [
        ('android.permission.INTERNET', '<uses-permission android:name="android.permission.INTERNET" />'),
        ('android.permission.CAMERA', '<uses-permission android:name="android.permission.CAMERA" />'),
        ('android.permission.ACCESS_FINE_LOCATION', '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />'),
        ('android.permission.ACCESS_COARSE_LOCATION', '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />'),
    ]
    new = '\n'.join('    ' + tag for key, tag in additions if key not in text)
    if new:
        text = text.replace('<application', new + '\n    <application', 1)
    if 'android.hardware.camera' not in text:
        text = text.replace('<application',
            '<uses-feature android:name="android.hardware.camera" android:required="false" />\n    <application', 1)
    android_manifest.write_text(text, encoding='utf-8')
    print('Android manifest: camera, location, internet configured.')
else:
    print('Android manifest missing: run flutter create first.')

for build in (Path('android/app/build.gradle.kts'), Path('android/app/build.gradle')):
    if build.exists():
        text = build.read_text(encoding='utf-8')
        text = re.sub(r'minSdk\s*=\s*flutter.minSdkVersion', 'minSdk = 23', text)
        text = re.sub(r'minSdkVersion\s+flutter.minSdkVersion', 'minSdkVersion 23', text)
        build.write_text(text, encoding='utf-8')
        print('Android minSdk checked (23 for Mapbox compatibility).')

ios_plist = Path('ios/Runner/Info.plist')
if ios_plist.exists():
    text = ios_plist.read_text(encoding='utf-8')
    additions = {
        'NSCameraUsageDescription': 'نستخدم الكاميرا لعرض الطريق مع معلومات الملاحة.',
        'NSLocationWhenInUseUsageDescription': 'نستخدم الموقع أثناء تشغيل التطبيق لتحديد مكانك وحساب الطريق.',
    }
    content = ''.join('    <key>%s</key>\n    <string>%s</string>\n' % (key, message)
                      for key, message in additions.items() if '<key>%s</key>' % key not in text)
    if content:
        text = text.replace('</dict>', content + '</dict>', 1)
    ios_plist.write_text(text, encoding='utf-8')
    print('iOS camera/location usage explanations configured.')
else:
    print('iOS Info.plist missing: run flutter create first.')

podfile = Path('ios/Podfile')
if podfile.exists():
    text = podfile.read_text(encoding='utf-8')
    text = re.sub(r"^#?\s*platform :ios, ['\"]\d+\.\d+['\"]", "platform :ios, '14.0'", text, count=1, flags=re.M)
    if 'platform :ios' not in text:
        text = "platform :ios, '14.0'\n" + text
    podfile.write_text(text, encoding='utf-8')
    print('iOS minimum deployment target set to 14.0 (review plugin release notes).')

print('Only foreground location requested. No external car camera support configured.')

# ROADVISION_KOTLIN_FIX
for gradle in (
    Path("android/settings.gradle"),
    Path("android/settings.gradle.kts"),
):
    if gradle.exists():
        data = gradle.read_text()
        pattern = r'(id\s*(?:\(\s*)?["\']org\.jetbrains\.kotlin\.android["\'](?:\s*\))?\s+version\s*["\'])[^"\']+'
        data, count = re.subn(
            pattern,
            r'\g<1>2.2.20',
            data,
        )
        if count == 0:
            raise RuntimeError("Kotlin version not found")
        gradle.write_text(data)
        print("Kotlin updated to 2.2.20")
