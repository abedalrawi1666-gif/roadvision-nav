# RoadVision Nav | رؤية الطريق — مشروع Flutter 3D + Camera

**المنصات:** Android وiOS — واجهة عربية RTL.  
**الإصدار:** 0.4.0 — اختيار مصادر الكاميرا من داخل التطبيق.
**الحالة:** MVP هندسي غير مُختبر على أجهزة حقيقية؛ ليس نظام ملاحة معتمداً للاستخدام أثناء القيادة.

## ما الذي أُنجز في الكود؟

- واجهة تطبيق عربية ذات وضعين والتبديل الفوري بينهما.
- **خرائط 3D:** Mapbox Standard بمنظور كاميرا مائل، مع رسم مسار فعلي محسوب من Directions API (بعد توفير المفتاح).
- **كاميرا الطريق:** اختيار كاميرا الهاتف أو بث كاميرا سيارة متوافقة عبر HTTPS MJPEG من إعدادات التطبيق، مع خيار الكاميرا الأصلية موضحاً حدود الوصول إليها. تعليمات الانعطاف في شريط منفصل. **لا يوجد إسقاط AR مثبت على الطريق حالياً.**
- **GPS:** إذن الموقع الأمامي، التقاط الموقع، وتحديث حي كل 5 أمتار تقريباً عند توافر قياسات النظام؛ عرض الخريطة يتبع الموقع.
- **البحث:** واجهة بحث عربية تستدعي Mapbox Geocoding API عند إدخال اسم شارع/مكان.
- **المسارات:** Mapbox Directions (driving-traffic) يعيد الوقت والمسافة والخط والخطوات، مع زر تحديث يدوي.
- **التوجيه المبدئي:** عرض الخطوة التالية وتقدير مسافة مستقيمة إليها؛ انتقال تقريبي بين المنعطفات بحسب قرب GPS، وليس map matching.
- **الصوت:** دعم اختياري عبر TTS باللغة العربية إذا كانت متوفرة على الجهاز.
- **الاختبارات:** اختبارات Haversine وParsing للبحث والمسار.
- أذونات الكاميرا وGPS للمنصتين؛ دون تسجيل فيديو أو طلب أذونات موقع الخلفية.

## 1. المتطلبات

- Flutter مع Dart SDK (Dart 3.5+)، Android Studio وAndroid SDK.
- لبناء iOS يجب استخدام **Mac مع Xcode، CocoaPods، وحساب Apple Developer للنشر**.
- هاتف حقيقي بكاميرا، وموقع GPS واتصال إنترنت للاختبار.
- حساب Mapbox لتوفير **Public access token** (`pk...`). راجع شروط الاستخدام والفوترة وتغطية ثلاثي الأبعاد.
- ربما يلزم **Secret downloads token** لعمليات تنزيل Mapbox SDK الأصلية (`sk...`) حسب إعدادات SDK والمنصة؛ لا تضفه للشيفرة ولا ترسله للمستخدم النهائي.

## 2. الإعداد في الطرفية

افتح الطرفية من مجلد المشروع الذي يحتوي `pubspec.yaml`:

```bash
bash scripts/setup.sh
```

إذا أردت تشغيل الخطوات يدوياً:

```bash
flutter create --platforms=android,ios --project-name roadvision_nav .
python3 scripts/configure_platforms.py
flutter pub get
flutter analyze
flutter test
```

`flutter create` يُنتج ملفات Android/iOS الخاصة بنسخة Flutter المثبتة، لذا لا تحتاج نسخ ملفات منصة قديمة/غير متوافقة.

## 3. التشغيل

```bash
flutter devices
flutter run --dart-define=MAPBOX_PUBLIC_TOKEN=pk.YOUR_PUBLIC_TOKEN
```

المفتاح `pk.` عام لكنه قد يُستهلك حسب فوترة Mapbox. قيّد استخدامه قدر ما تدعمه لوحة Mapbox. لا تستخدم رمز `sk.` كـ `dart-define`.

**تنبيه مهم:** إذا تعطّل تنزيل Mapbox SDK أثناء Gradle أو CocoaPods، اتبع وثائق Mapbox الخاصة بإعداد **downloads token** بأمان على آلة البناء، وليس داخل الكود. لا تخلط بينه وبين public token للتشغيل.

قد يتطلب iOS تحديد إعداد `BYPASS_PERMISSION_LOCATION_ALWAYS=1` لمكتبة `geolocator_apple` ضمن Podfile/إعدادات البناء لمنع طلب إذن الخلفية؛ انظر وثائق geolocator بحسب إصدار الإضافة المختار. ملف `configure_platforms.py` يضيف إذن الموقع الأمامي فقط.

## 4. الاستخدام

1. اضغط علامة **موقعي** واسمح باستخدام GPS.
2. اضغط حقل **إلى أين تريد الذهاب؟** واكتب الوجهة واختر نتيجة.
3. ينتظر التطبيق استجابة خدمة Mapbox؛ إن وجِد طريق يظهر باللون الأزرق على الخريطة مع المسافة والمدة.
4. اضغط **بدء التوجيه** لتحديث شريط المنعطفات بحسب موقعك. يمكنك تشغيل الصوت من أيقونة الصوت.
5. بدّل إلى **كاميرا الطريق** لرؤية معاينة فيديو الكاميرا مع شريط تعليمات غير مثبت على الطريق.
6. افتح **إعدادات الكاميرا**، واختر هاتفاً أو بث سيارة `https://...` أو الكاميرا الأصلية، واحفظ اختيارك. يمكنك تشغيل الرجوع للهاتف عند التعذر.
7. اضغط **تحديث الطريق** عند الحاجة؛ إعادة التوجيه تلقائياً غير منفذة.

### القيود في هذه النسخة

- عرض 3D يعتمد على تغطية Mapbox ولا يعني نموذجاً فوتوغرافياً لكافة الأبنية.
- تعليمات الحركة ليست دقيقة بما يكفي للاعتماد عليها على الطرق؛ لا توجد مطابقة طرق map matching ولا حساب تقدم المسار الحقيقي ولا إعادة تخطيط تلقائي.
- AR ليس إلا Camera Guidance الآن. لا تظهر الأسهم الأرضية الثابتة؛ تنفيذها يحتاج كاميرا معايرة، ARKit/ARCore/Visual-Inertial Odometry، ربط مع شبكة الطرق واختبار ثقة الإسقاط.
- **اختيار المصدر:** الهاتف فعّال؛ بث سيارة HTTPS MJPEG أُضيف كآلية تجريبية تعتمد على توفر رابط صالح، دون تأكيد تشغيله على جهاز محدد؛ الكاميرا الأصلية غير متصلة دون دعم المصنع. ارجع إلى `docs/CAMERA_SOURCES.md`.
- لم تُجرَ اختبارات تشغيل فعلية للبناء على Android/iOS في هذه البيئة لعدم توفر Flutter SDK أو مفاتيح Mapbox/التوقيع.

## 5. إخراج Android APK أو iOS IPA

```bash
export MAPBOX_PUBLIC_TOKEN='pk.YOUR_PUBLIC_TOKEN'
bash scripts/build_android.sh
# على Mac فقط:
bash scripts/build_ios.sh
```

**النشر في Google Play:** App Bundle مع توقيع الإصدار، اسم الحزمة النهائي، وسياسة الخصوصية والاختبارات.
**النشر في Apple App Store:** Xcode signing/Provisioning Profiles، Bundle ID، حساب مطور، App Store Connect، سياسة خصوصية ومراجعة استخدام الموقع والكاميرا. راجع `docs/RELEASE_CHECKLIST.md
docs/CAMERA_SOURCES.md`.

## 6. أين تجد الملفات؟

```text
lib/main.dart
lib/src/app.dart
lib/src/config/app_config.dart
lib/src/domain/geo_coordinate.dart
lib/src/domain/navigation_route.dart
lib/src/services/location_service.dart
lib/src/services/mapbox_api.dart
lib/src/services/navigation_controller.dart
lib/src/services/voice_service.dart
lib/src/features/shell/navigation_shell.dart
lib/src/features/search/destination_search_sheet.dart
lib/src/features/map3d/map_3d_screen.dart
lib/src/features/ar/ar_camera_screen.dart
lib/src/features/settings/camera_preferences.dart
lib/src/features/settings/camera_settings_sheet.dart
lib/src/services/video/mjpeg_camera_view.dart
lib/src/services/video/jpeg_frame_extractor.dart
scripts/configure_platforms.py
scripts/setup.sh
scripts/build_android.sh
scripts/build_ios.sh
test/geo_coordinate_test.dart
test/mapbox_api_test.dart
docs/ARCHITECTURE.md
docs/AR_PIPELINE.md
docs/PRIVACY.md
docs/RELEASE_CHECKLIST.md
docs/CAMERA_SOURCES.md
```

## 7. السلامة والخصوصية

لا تُثبت الهاتف بحيث يحجب رؤية السائق. يجب أن يتم إعداد الوجهة أثناء التوقف، وأي استخدام حقيقي يتطلب بحث سلامة مرورية واختبارات ميدانية. هذا المنتج في مرحلته الحالية للتطوير/العرض فقط.

تُرسل بيانات إحداثيات البحث والمسار إلى Mapbox عند استخدام تلك الميزات. لا تُرفع معاينة الكاميرا في هذا الكود، ولا توجد تحليلات أو حسابات مستخدم. اقرأ `docs/PRIVACY.md`.

## مكتبة هندسة AR للمطورين

توجد أداة حسابية قابلة للاختبار في `lib/src/features/ar/geometry/route_projector.dart` لتحويل المسار من إحداثيات WGS84 إلى نظام ENU وإسقاط نقاط 3D على صورة كاميرا معايرة. **غير مفعّلة في واجهة الكاميرا** إلى أن يتوفر تتبع كاميرا صحيح ومستقر.
