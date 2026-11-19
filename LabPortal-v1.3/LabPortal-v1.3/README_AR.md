# LabPortal v1.3 — شبكة مختبر مستقلة مع إعلان Captive Portal تجريبي

## تغييرات v1.3 عن v1.2
- احتفظنا بالسيرفر والصفحة وInput **أكواد اختبار TEST-0000 إلى TEST-9999** وسجلات JSONL.
- أضفنا مسار `GET /api/captive` كاستجابة `application/captive+json` وفق RFC 8908.
- أضفنا **إعلان DHCP option 114** وفق RFC 8910 عبر `/etc/NetworkManager/dnsmasq-shared.d/99-labportal-v1.3.conf` عندما تكون `ENABLE_CAPTIVE_HINT=1`.
- لا يوجد DNS spoofing ولا اعتراض HTTP(S) ولا استنساخ شبكة أخرى ولا جمع كلمات مرور.

## التشغيل
أوقف Airgeddon أولاً. افتح طرفية داخل المجلد:

```bash
bash start.sh
```

افتح طرفية ثانية:

```bash
bash start-ap.sh
```

اتصل من جهازك بشبكة `Lab-WiFi-Demo` المفتوحة، وجرّب ظهور إشعار صفحة الترحيب. **إذا لم يظهر، افتح الرابط يدوياً:**

`http://10.42.0.1:18765`

جرب `TEST-1234` فقط. السجلات في `demo-events.jsonl`. للتشخيص `bash check.sh`، ولإيقاف الشبكة وإزالة إعداد DHCP التجريبي `bash stop-ap.sh`.

## حدود مهمة
- الشهادة المحلية ذاتية التوقيع؛ المعيار RFC 8908 يتطلب شهادة **HTTPS موثوقة**، ولذلك أغلب الهواتف قد تتجاهل الإعلان، وليس هناك ضمان لفتح الصفحة تلقائياً. ليس هذا إعادة توجيه قسرية.
- DHCP option 114 الإضافي في مجلد NetworkManager قد يؤثر على **أي اتصال shared** آخر حتى تحذفه عبر `bash stop-ap.sh`.
- يتطلب USB Wi-Fi داخل VMware بوضع `AP`؛ تحقّق بواسطة `iw list`.
- SSID وIP والمنافذ قابلة للتعديل في `config.env`. لا تُدخل بيانات حساسة في الـInput.
- NetworkManager shared قد يشارك الإنترنت من eth0؛ إذا أردت عزلاً تاماً افصل وصلة الإنترنت الصاعدة أو استعمل مختبراً معزولاً.
