# 🔥 راهنمای کامل راه‌اندازی Firebase

## ⚠️ چرا الان آمار صفره؟

**دلایل اصلی:**
1. هنوز کسی اپ رو نصب نکرده (اپ آماده نیست!)
2. Realtime Database فعال نیست
3. کد tracking هنوز کامل نشده

---

## 📋 مراحل کامل (از صفر تا صد)

### مرحله 1: فعال‌سازی Realtime Database در Firebase

1. برو به: https://console.firebase.google.com/project/resynth-b44bb
2. از منوی چپ: **Build** → **Realtime Database**
3. کلیک کن روی **Create Database**
4. Location رو انتخاب کن: **United States (us-central1)** یا **Europe (europe-west1)**
5. Security rules رو **Start in test mode** انتخاب کن
6. کلیک کن روی **Enable**

### مرحله 2: تنظیم Database Rules

بعد از ساخت database:

1. برو به تب **Rules**
2. کدهای زیر رو کپی کن:

```json
{
  "rules": {
    "users": {
      "$userId": {
        ".read": true,
        ".write": true
      }
    },
    "stats": {
      ".read": true,
      ".write": true
    }
  }
}
```

3. کلیک کن روی **Publish**

### مرحله 3: ساخت و تست اپ

#### گام 1: نصب Dependencies

```bash
cd C:\Users\R3ZA\ReSynthApp-temp
flutter pub get
```

#### گام 2: Build کردن اپ برای تست

```bash
# برای اندروید
flutter build apk --release

# فایل APK اینجا ساخته میشه:
# build/app/outputs/flutter-apk/app-release.apk
```

#### گام 3: نصب روی گوشی

1. فایل APK رو از مسیر بالا کپی کن
2. روی گوشی اندرویدت نصب کن
3. اپ رو باز کن

#### گام 4: چک کردن آمار

**روش 1: از Firebase Console**
1. برو به: https://console.firebase.google.com/project/resynth-b44bb/database/resynth-b44bb-default-rtdb/data
2. باید ببینی که `users` و `stats` ساخته شدن
3. توی `users` باید یه کاربر جدید باشه

**روش 2: از Dashboard HTML**
1. باز کن: `C:\Users\R3ZA\ReSynthApp-temp\firebase\dashboard.html`
2. باید آمارها رو ببینی!

---

## 🎯 چیزهایی که الان Track میشن:

### ✅ اضافه شده:
- 📱 باز شدن اپ
- 👤 کاربر جدید (اولین بار)
- 🕒 آخرین باری که کاربر اپ رو باز کرده

### ⏳ نیاز به اضافه کردن:
- 🔌 وصل شدن به VPN (باید کد اضافه کنی)
- 🔻 قطع شدن از VPN (باید کد اضافه کنی)

---

## 📝 کدهای اضافی برای Track کردن اتصال VPN

### کد برای Home Screen

باز کن: `lib/screens/home_screen.dart`

**جایی که VPN وصل میشه، این کد رو اضافه کن:**

```dart
import 'package:resynth/common/firebase_tracker.dart';

// بعد از اینکه VPN با موفقیت وصل شد:
await FirebaseTracker.trackConnection(
  serverName: selectedServer,
  connected: true,
);
```

**جایی که VPN قطع میشه، این کد رو اضافه کن:**

```dart
// بعد از اینکه VPN قطع شد:
await FirebaseTracker.trackConnection(
  serverName: selectedServer,
  connected: false,
);
```

---

## 🐛 مشکلات رایج و راه‌حل:

### مشکل 1: آمار هنوز صفره
**راه‌حل:**
1. مطمئن شو Realtime Database فعال شده
2. اپ رو Build کن و روی گوشی نصب کن
3. اپ رو باز کن
4. صبر کن 10 ثانیه
5. Firebase Console رو Refresh کن

### مشکل 2: خطا هنگام Build
**راه‌حل:**
```bash
flutter clean
flutter pub get
flutter build apk
```

### مشکل 3: "Permission Denied" در Firebase
**راه‌حل:**
- Database Rules رو درست تنظیم کن (مرحله 2)

### مشکل 4: آمار توی Dashboard نمیاد
**راه‌حل:**
1. مطمئن شو که اپ روی گوشی نصب شده و باز شده
2. چک کن Firebase Console → Realtime Database → Data
3. اگه اونجا داده هست ولی Dashboard نمیاره، browser cache رو پاک کن

---

## 📊 مثال آمارهایی که می‌بینی:

### بعد از نصب اولین کاربر:

**Firebase Console:**
```
ReSynth Database
├── users
│   └── android_abc123def456
│       ├── first_seen: "2025-12-04T12:00:00Z"
│       ├── last_seen: "2025-12-04T12:00:00Z"
│       ├── platform: "android"
│       ├── app_version: "1.0.0"
│       └── status: "active"
└── stats
    └── daily
        └── 2025-12-04
            ├── active_users: 1
            └── app_opens: 1
```

**Dashboard:**
- Total Users: **1**
- Active Today: **1**
- Currently Connected: **0** (چون هنوز کد track اتصال اضافه نشده)

---

## 🚀 مراحل بعدی:

### 1. ساخت APK برای انتشار
```bash
flutter build apk --release
```

### 2. تست کامل
- [ ] نصب روی گوشی
- [ ] باز کردن اپ
- [ ] چک کردن آمار در Firebase
- [ ] چک کردن Dashboard

### 3. اضافه کردن Track اتصال VPN
- [ ] پیدا کردن جای وصل شدن VPN
- [ ] اضافه کردن FirebaseTracker.trackConnection
- [ ] تست کردن

### 4. Deploy کردن Cloudflare Worker
- [ ] برو به https://dash.cloudflare.com
- [ ] Worker جدید بساز
- [ ] کد از `cloudflare/worker.js` رو کپی کن
- [ ] Deploy کن
- [ ] URL Worker رو توی اپ بذار

---

## 📞 راه‌های ارتباطی:

- **Firebase Console:** https://console.firebase.google.com/project/resynth-b44bb
- **Analytics Dashboard:** https://console.firebase.google.com/project/resynth-b44bb/analytics
- **Realtime Database:** https://console.firebase.google.com/project/resynth-b44bb/database
- **GitHub Repo:** https://github.com/syshe2840-spec/ReSynthApp

---

## ✅ Checklist برای تست:

- [ ] Realtime Database فعال شده؟
- [ ] Database Rules تنظیم شده؟
- [ ] `flutter pub get` اجرا شده؟
- [ ] APK ساخته شده؟
- [ ] APK روی گوشی نصب شده؟
- [ ] اپ باز شده و کار میکنه؟
- [ ] Firebase Console → Data چک شده؟
- [ ] Dashboard HTML چک شده؟

**وقتی همه اینا ✅ شدن، آمارها باید بیان!** 🎉

---

Made with ❤️ by ReSynth Team
