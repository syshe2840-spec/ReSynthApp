# 🔥 راهنمای کامل Firebase - ReSynth VPN

## ✅ ویژگی‌های فعال شده

### 1️⃣ Firebase Realtime Database
**وضعیت:** ✅ فعال و کار می‌کنه

**قابلیت‌ها:**
- ✅ ثبت کاربران جدید
- ✅ ردیابی آمار روزانه (app opens, connections)
- ✅ ذخیره اطلاعات کاربران
- ✅ آمار سرورها

**دیتابیس:**
```
users/
  {device_id}/
    - first_seen
    - last_seen
    - platform (android/ios)
    - app_version
    - status
    - current_server
    - is_connected

stats/
  daily/
    {date}/
      - active_users
      - app_opens
      - connections
  servers/
    {server_name}/
      - connections
```

---

### 2️⃣ Firebase Cloud Messaging (FCM) - نوتیفیکیشن
**وضعیت:** ✅ فعال و آماده استفاده

**قابلیت‌ها:**
- ✅ ارسال نوتیفیکیشن به همه کاربران
- ✅ ارسال نوتیفیکیشن به کاربر خاص
- ✅ ارسال نوتیفیکیشن با عکس
- ✅ نوتیفیکیشن در Background
- ✅ نوتیفیکیشن در Foreground
- ✅ Subscribe/Unsubscribe به Topics

**نحوه ارسال نوتیفیکیشن:**

#### روش 1: از Firebase Console
1. برو به: https://console.firebase.google.com/project/resynth-b44bb/messaging
2. کلیک روی **"Create your first campaign"** یا **"New notification"**
3. مشخصات نوتیفیکیشن:
   - **Notification title:** عنوان نوتیفیکیشن (مثلاً "سرور جدید!")
   - **Notification text:** متن نوتیفیکیشن (مثلاً "سرور آلمان اضافه شد")
   - **Notification image (optional):** لینک عکس
4. **Target:**
   - **User segment:** همه کاربران
   - **Topic:** ارسال به topic خاص
   - **Single device:** ارسال به یک دستگاه (با FCM Token)
5. کلیک روی **Review** و بعد **Publish**

#### روش 2: از کد (Programmatic)
```dart
// Subscribe to topic
await FirebaseMessagingService.subscribeToTopic('announcements');

// Unsubscribe from topic
await FirebaseMessagingService.unsubscribeFromTopic('announcements');

// Get FCM Token
String? token = FirebaseMessagingService.fcmToken;
```

#### روش 3: با API (Postman/cURL)
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
-H "Authorization: key=YOUR_SERVER_KEY" \
-H "Content-Type: application/json" \
-d '{
  "to": "/topics/all_users",
  "notification": {
    "title": "سرور جدید!",
    "body": "سرور آلمان اضافه شد",
    "image": "https://example.com/image.png"
  },
  "data": {
    "server_name": "Germany",
    "action": "open_server_list"
  }
}'
```

**یافتن Server Key:**
1. Firebase Console → Project Settings
2. Cloud Messaging tab
3. کپی کردن "Server key"

---

### 3️⃣ Firebase Remote Config - تنظیمات از راه دور
**وضعیت:** ✅ فعال و آماده استفاده

**قابلیت‌ها:**
- ✅ تغییر تنظیمات بدون آپدیت
- ✅ فعال/غیرفعال کردن ویژگی‌ها
- ✅ تغییر متن‌ها و پیام‌ها
- ✅ لینک سرورهای جدید
- ✅ Maintenance Mode
- ✅ Force Update

**پارامترهای پیش‌فرض:**

| Key | Type | Default | توضیح |
|-----|------|---------|-------|
| `app_maintenance_mode` | bool | false | وضعیت تعمیرات |
| `app_force_update` | bool | false | آپدیت اجباری |
| `app_latest_version` | string | 1.0.0 | آخرین ورژن |
| `app_update_url` | string | - | لینک دانلود |
| `vpn_auto_connect` | bool | false | اتصال خودکار |
| `vpn_default_protocol` | string | vmess | پروتکل پیش‌فرض |
| `vpn_connection_timeout` | int | 30 | تایم‌اوت (ثانیه) |
| `servers_update_interval` | int | 3600 | بروزرسانی سرورها |
| `servers_config_url` | string | - | لینک کانفیگ سرورها |
| `feature_dark_mode` | bool | true | دارک مود |
| `feature_auto_reconnect` | bool | true | اتصال مجدد خودکار |
| `feature_split_tunneling` | bool | false | تونل منتخب |
| `message_welcome` | string | - | پیام خوش‌آمدگویی |
| `message_maintenance` | string | - | پیام تعمیرات |
| `analytics_enabled` | bool | true | آنالیتیکس |

**نحوه استفاده از Remote Config:**

#### تنظیم پارامترها در Firebase Console:
1. برو به: https://console.firebase.google.com/project/resynth-b44bb/config
2. کلیک روی **"Add parameter"**
3. نام پارامتر رو وارد کن (مثلاً `app_maintenance_mode`)
4. مقدار رو تنظیم کن (مثلاً `true`)
5. کلیک روی **"Publish changes"**

#### استفاده در کد:
```dart
// Check maintenance mode
if (FirebaseRemoteConfigService.isMaintenanceMode) {
  // Show maintenance screen
}

// Check force update
if (FirebaseRemoteConfigService.isForceUpdate) {
  // Show update dialog
}

// Get custom values
String serverUrl = FirebaseRemoteConfigService.getString('servers_config_url');
bool autoConnect = FirebaseRemoteConfigService.getBool('vpn_auto_connect');
int timeout = FirebaseRemoteConfigService.getInt('vpn_connection_timeout');

// Refresh config manually
await FirebaseRemoteConfigService.fetch();
```

---

## 🎯 سناریوهای کاربردی

### سناریو 1: اضافه کردن سرور جدید بدون آپدیت
1. لیست سرورها رو به یه JSON فایل آنلاین منتقل کن
2. لینک فایل رو در Remote Config ذخیره کن (`servers_config_url`)
3. اپ هر ساعت لیست سرورها رو از لینک دانلود می‌کنه
4. سرور جدید اضافه می‌شه بدون نیاز به آپدیت!

### سناریو 2: ارسال اطلاعیه به همه کاربران
1. برو Firebase Console → Cloud Messaging
2. یه نوتیفیکیشن جدید بساز:
   - عنوان: "🎉 سرور جدید اضافه شد!"
   - متن: "سرور آلمان با سرعت بالا الان در دسترسه"
3. Target: All users
4. ارسال!

### سناریو 3: فعال/غیرفعال کردن ویژگی
1. برو Remote Config
2. پارامتر `feature_dark_mode` رو `false` کن
3. Publish کن
4. همه اپ‌ها تو 1 ساعت دارک مود رو غیرفعال می‌کنن!

### سناریو 4: آپدیت اجباری
1. ورژن جدید اپ رو منتشر کن
2. Remote Config رو باز کن
3. `app_force_update` = `true`
4. `app_latest_version` = `1.1.0`
5. `app_update_url` = لینک دانلود
6. Publish کن
7. همه کاربران ورژن قدیمی مجبور به آپدیت می‌شن!

### سناریو 5: Maintenance Mode
1. برو Remote Config
2. `app_maintenance_mode` = `true`
3. `message_maintenance` = "اپ در حال بروزرسانی است. لطفاً 2 ساعت دیگر امتحان کنید."
4. Publish کن
5. همه کاربران پیام تعمیرات رو می‌بینن!

---

## 📊 مشاهده آمار

### آمار Realtime Database:
https://console.firebase.google.com/project/resynth-b44bb/database/resynth-b44bb-default-rtdb/data

**می‌تونی ببینی:**
- تعداد کاربران فعال
- تعداد app opens روزانه
- تعداد اتصالات VPN
- محبوب‌ترین سرورها

### آمار Cloud Messaging:
https://console.firebase.google.com/project/resynth-b44bb/messaging

**می‌تونی ببینی:**
- تعداد نوتیفیکیشن‌های ارسال شده
- نرخ باز شدن (Open Rate)
- دستگاه‌های فعال

### آمار Remote Config:
https://console.firebase.google.com/project/resynth-b44bb/config

**می‌تونی ببینی:**
- کدوم پارامترها بیشتر استفاده می‌شن
- تاریخچه تغییرات

---

## 🔐 امنیت Firebase

### Rules فعلی (Public - فقط برای تست):
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

⚠️ **هشدار:** این rules امن نیست! برای production باید تغییر بده.

### Rules امن (Production):
```json
{
  "rules": {
    "users": {
      "$userId": {
        ".read": "auth != null || $userId === data.child('device_id').val()",
        ".write": "auth != null || $userId === data.child('device_id').val()"
      }
    },
    "stats": {
      ".read": true,
      ".write": "auth != null"
    },
    "device_tokens": {
      "$deviceId": {
        ".read": false,
        ".write": true
      }
    }
  }
}
```

---

## 🚀 چیزی که الان می‌تونی بکنی:

1. ✅ **بیلد بگیر** - همه چیز آماده‌س
2. ✅ **نوتیفیکیشن بفرست** - از Firebase Console
3. ✅ **Remote Config تست کن** - پارامتر جدید اضافه کن
4. ✅ **آمار ببین** - Realtime Database رو چک کن

---

## 📞 لینک‌های مهم:

- **Firebase Console:** https://console.firebase.google.com/project/resynth-b44bb
- **Realtime Database:** https://console.firebase.google.com/project/resynth-b44bb/database/resynth-b44bb-default-rtdb/data
- **Cloud Messaging:** https://console.firebase.google.com/project/resynth-b44bb/messaging
- **Remote Config:** https://console.firebase.google.com/project/resynth-b44bb/config
- **Project Settings:** https://console.firebase.google.com/project/resynth-b44bb/settings/general

---

## ✨ همه چیز آماده!

همه ویژگی‌های Firebase فعال شدن:
- ✅ Realtime Database
- ✅ Cloud Messaging (FCM)
- ✅ Remote Config

**الان می‌تونی:**
1. بیلد بگیری و تست کنی
2. نوتیفیکیشن بفرستی
3. تنظیمات رو از راه دور تغییر بدی
4. آمار کاربران رو ببینی

🎉 **موفق باشی!**
