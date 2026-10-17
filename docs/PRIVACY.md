# Privacy notes / مسودة خصوصية المنتج

This describes **the included prototype code**, not claims about a future production app or the data practices of third-party vendors.

- **Location:** requested only when user presses the location/route control; GPS updates are received while app is active and its location stream remains subscribed. There is no implemented background location mode.
- **Camera:** frames are shown as a local preview; the application source does not upload, record, or share video. Camera permission is requested when that view starts.
- **External network:** destination search queries and proximity may be sent to Mapbox Search/Geocoding; origin/destination are sent to Mapbox Directions. Map data may be fetched by Mapbox SDK. Consult Mapbox terms/privacy for their practices.
- **No user accounts:** no login, analytics SDK, ads SDK, database or cloud recording are included.
- **Audio:** flutter_tts uses the device TTS engine, whose voice/language availability and data handling depend on the device/OS/voice provider.
- **Data retention:** no application-managed history storage is implemented.
- **Before release:** prepare an actual legal privacy policy, verify third-party SDK collection/retention, consent mechanisms, data safety declarations, geographic regulations, and support contact.


## مصادر الكاميرا الاختيارية

يُحفظ اختيار مصدر الكاميرا ورابط البث الشبكي الاختياري محلياً على الجهاز عبر `shared_preferences`. لا تُخزَّن كلمات مرور الكاميرا ولا يُسجَّل الفيديو داخل التطبيق. عند اختيار رابط بث HTTPS MJPEG يتصل الهاتف مباشرة بعنوان الطرف الثالث الذي أدخله المستخدم؛ قد يطّلع ذلك الخادم على عنوان IP الخاص بالهاتف. لا تستخدم رابطاً يتضمن اسم مستخدم/كلمة مرور.
