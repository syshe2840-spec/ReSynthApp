# 📊 Firebase User Tracking Setup

## چطوری تعداد کاربرها رو ببینی؟

### مرحله 1: فعال‌سازی Realtime Database

1. برو به Firebase Console: https://console.firebase.google.com
2. پروژه **ReSynth** رو انتخاب کن
3. از سایدبار چپ، **"Build"** > **"Realtime Database"** رو انتخاب کن
4. روی **"Create Database"** کلیک کن
5. Location رو انتخاب کن (مثلاً: `europe-west1`)
6. Security rules رو **"Start in test mode"** انتخاب کن (موقتاً)
7. **"Enable"** رو بزن

### مرحله 2: تنظیم Database Rules

1. بعد از ساخت دیتابیس، برو به تب **"Rules"**
2. قوانین زیر رو کپی کن و جایگزین کن:

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

3. روی **"Publish"** کلیک کن

### مرحله 3: دیدن آمار کاربرها

#### روش 1: مستقیم از Firebase Console

1. برو به **Realtime Database** در Firebase Console
2. توی تب **"Data"** می‌تونی ببینی:
   - `users/` - لیست همه کاربرها
   - `stats/daily/` - آمار روزانه
   - `stats/servers/` - آمار هر سرور

#### روش 2: استفاده از Dashboard سفارشی

یه فایل HTML ساختم که می‌تونی باز کنی و آمار زنده رو ببینی:
- باز کن: `firebase/dashboard.html`
- Database URL رو وارد کن
- آمار زنده رو ببین! 🎉

### مرحله 4: اضافه کردن Tracking به اپ

توی `lib/screens/home_screen.dart`، در متد `initState()`:

```dart
@override
void initState() {
  super.initState();

  // Initialize Firebase tracking
  FirebaseTracker.initUser();
  FirebaseTracker.trackAppOpen();

  // ... rest of your code
}
```

برای track کردن وقتی VPN وصل میشه:

```dart
// When connecting
await FirebaseTracker.trackConnection(
  serverName: selectedServer,
  connected: true,
);

// When disconnecting
await FirebaseTracker.trackConnection(
  serverName: selectedServer,
  connected: false,
);
```

---

## 📈 آمارهایی که Track میشن:

### در `users/{userId}/`:
- `first_seen`: اولین باری که اپ رو باز کرده
- `last_seen`: آخرین بار که اپ رو باز کرده
- `platform`: android یا ios
- `app_version`: ورژن اپ
- `is_connected`: آیا الان به VPN وصله؟
- `current_server`: به کدوم سرور وصله

### در `stats/daily/{date}/`:
- `active_users`: تعداد کاربر فعال امروز
- `connections`: تعداد اتصال امروز
- `app_opens`: تعداد باز شدن اپ امروز

### در `stats/servers/{serverName}/`:
- `connections`: تعداد کل اتصال به این سرور

---

## 🎯 مثال داده‌ها در Firebase:

```
ReSynth Database
├── users
│   ├── android_abc123
│   │   ├── first_seen: "2025-12-04T10:30:00Z"
│   │   ├── last_seen: "2025-12-04T15:45:00Z"
│   │   ├── platform: "android"
│   │   ├── is_connected: true
│   │   └── current_server: "Germany Fast"
│   └── android_xyz789
│       └── ...
└── stats
    ├── daily
    │   └── 2025-12-04
    │       ├── active_users: 157
    │       ├── connections: 423
    │       └── app_opens: 891
    └── servers
        ├── Germany Fast
        │   └── connections: 234
        └── Netherlands Speed
            └── connections: 189
```

---

## ⚡ دستورات مفید:

### نصب Dependencies (اگه نیست):
```bash
flutter pub add firebase_database
```

### تست کردن:
1. اپ رو ران کن
2. برو Firebase Console > Realtime Database
3. باید `users` و `stats` رو ببینی که داره پر میشه!

---

**نکته امنیتی:** بعداً قوانین Database رو سخت‌تر کن تا فقط اپت بتونه بنویسه!
