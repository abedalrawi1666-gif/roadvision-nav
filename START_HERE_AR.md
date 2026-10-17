# RoadVision جديد — تعليمات الهاتف (Termux)

هذه النسخة **مستقلة** عن Atlas 3D، وتحفظ المصدر القديم سليماً. يحتوي هذا المشروع على كود واجهة الخرائط والكاميرا، لكنه نموذج تطويري يحتاج Mapbox واختبارات فعلية، وليس منتج ملاحة معتمداً.

## فك الضغط في مجلد مستقل

نزّل `RoadVision_New_App_GitHub_Ready.zip` من المحادثة، ثم في Termux:

```bash
cd ~
unzip -q -o ~/storage/downloads/RoadVision_New_App_GitHub_Ready.zip -d ~
cd ~/roadvision_new
ls .github/workflows
```

## ربطه بمستودعك الموجود لكن على فرع مستقل

```bash
cd ~/roadvision_new
git init
git switch -c roadvision-new
git remote add origin "$(git -C ~/atlas_3d remote get-url origin)"
git add .
git commit -m "Add new RoadVision app"
git push -u origin roadvision-new
```

إذا لم يكن اسم Git مضبوطاً، استخدم `git config --global user.name 'YOUR NAME'` و`git config --global user.email 'YOUR EMAIL'` ببياناتك الحقيقية، ثم أعد الالتزام. للدفع قد تحتاج تسجيل GitHub المصرح به.

## البناء عبر Actions

افتح مستودع Atlas في GitHub ← Actions ← workflow Android APK (قد يظهر اسم Atlas القديم على default branch) ← Run workflow ← اختر الفرع `roadvision-new` ← تشغيل. اسم ملف workflow هو نفسه ملف Atlas القديم، لذا تستطيع اختيار الفرع الجديد. بعد النجاح ← Artifacts ← RoadVision-Android-APK ← فك الضغط وتثبيت APK.

## مفاتيح Mapbox

لفتح الخريطة، أضف في GitHub: Settings → Secrets and variables → Actions → New repository secret → `MAPBOX_PUBLIC_TOKEN` وضع قيمة public تبدأ بـ `pk.`. وإذا تطلب Gradle وصول SDK الخاص، أنشئ secret آخر باسم `MAPBOX_DOWNLOADS_TOKEN` لقيمة `sk.` بامتياز `DOWNLOADS:READ` وفق متطلبات Mapbox. لا ترسل مفاتيح `sk.` في المحادثة أو تضعها داخل ملفات المشروع.

## حدود النسخة

- وضع كاميرا الهاتف متاح في الكود، وخيار بث HTTPS MJPEG متوافق؛ وصول كاميرا السيارة الأصلية ليس عاماً ويتطلب واجهة تدعمها الشركة.
- وضع الكاميرا ليس AR مثبتاً على الطريق، ولا يجوز استخدامه كمرشد موثوق أثناء القيادة.
- هذا الملف لا يضمن بناء APK بنجاح؛ يعتمد ذلك على تنزيل المكتبات وإعدادات SDK ومنصة CI. افحص سجلات GitHub Actions إذا فشل البناء.
