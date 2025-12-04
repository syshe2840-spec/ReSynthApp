# ReSynth VPN - Cloudflare Worker Setup

## 📋 Quick Start

### Step 1: Deploy to Cloudflare Workers

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **Workers & Pages**
3. Click **Create Application** → **Create Worker**
4. Name your worker (e.g., `resynth-api`)
5. Copy the contents of `worker.js` and paste into the editor
6. Click **Save and Deploy**

### Step 2: Update Server Configurations

Edit the `SERVERS_CONFIG` object in `worker.js`:

```javascript
servers: [
  {
    name: "Germany 🇩🇪",
    config: "YOUR_ENCRYPTED_VLESS_CONFIG_HERE"
  },
  {
    name: "Netherlands 🇳🇱",
    config: "YOUR_ENCRYPTED_VMESS_CONFIG_HERE"
  }
]
```

### Step 3: Update App URLs

After deploying, update these files with your Cloudflare Worker URL:

**Files to update:**
1. `lib/screens/home_screen.dart` (line 532)
2. `lib/widgets/server_selection_modal_widget.dart` (lines 56, 68)
3. `lib/widgets/ios_server_selection_modal.dart` (lines 84, 95)

**Replace:**
```
resynth-api.lastofanarchy.workers.dev
```

**With your worker URL:**
```
YOUR-WORKER-NAME.YOUR-SUBDOMAIN.workers.dev
```

## 🔐 Encryption

For server config encryption, use the Python script in `scripts/encrypt_servers.py`:

```bash
cd scripts
python encrypt_servers.py encrypt servers.json servers_encrypted.json
```

Then copy the encrypted configs to `worker.js`.

## 📊 API Endpoints

- `GET /` - API info
- `GET /api/firebase/init/android` - Get user key
- `GET /api/firebase/init/data/{user_key}` - Get server configs

## 🎯 Features

- ✅ Server configuration delivery
- ✅ In-app notifications
- ✅ Forced update system
- ✅ Rate limiting (100 requests per user)
- ✅ CORS enabled

---

Made with ❤️ by ReSynth Team
