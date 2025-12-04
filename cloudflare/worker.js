// ReSynth VPN - Cloudflare Worker
// Encrypted Server Configuration System

const SERVERS_CONFIG = {
  version: "1.0.0",
  updated_url: "https://github.com/syshe2840-spec/ReSynthApp/releases",

  // Server Notification System
  notification: {
    enabled: true,
    type: "info", // info, success, warning, error, notification
    title: "Welcome to ReSynth VPN!",
    message: "Enjoy fast and secure browsing with our free VPN service.",
    show_once: false
  },

  // Forced Update System
  force_update: {
    enabled: false,
    min_version: "1.0.0",
    title: "Update Required",
    message: "Please update to the latest version to continue using ReSynth VPN.",
    download_url: btoa("https://github.com/syshe2840-spec/ReSynthApp/releases")
  },

  // Encrypted Server Configurations
  servers: [
    {
      name: "Germany 🇩🇪",
      config: "vless://your-config-here"
    },
    {
      name: "Netherlands 🇳🇱",
      config: "vmess://your-config-here"
    },
    {
      name: "United States 🇺🇸",
      config: "trojan://your-config-here"
    }
  ]
};

// User Key Generation
function generateUserKey() {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 15);
  return 'resynth_' + timestamp + '_' + random;
}

// In-Memory User Storage (for demo purposes)
const userStore = new Map();

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // CORS Headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Content-Type': 'application/json'
    };

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // API Routes
    if (url.pathname === '/') {
      return new Response(JSON.stringify({
        status: true,
        message: "ReSynth VPN API v1.0.0",
        endpoints: {
          init: "/api/firebase/init/android",
          data: "/api/firebase/init/data/{user_key}"
        }
      }), { headers: corsHeaders });
    }

    // Initialize User - Get User Key
    if (url.pathname === '/api/firebase/init/android') {
      const userKey = generateUserKey();
      userStore.set(userKey, {
        created: Date.now(),
        requests: 0
      });

      return new Response(JSON.stringify({
        status: true,
        key: userKey
      }), { headers: corsHeaders });
    }

    // Get Server Data
    if (url.pathname.startsWith('/api/firebase/init/data/')) {
      const userKey = url.pathname.split('/').pop();

      // Validate user key
      if (!userStore.has(userKey)) {
        return new Response(JSON.stringify({
          status: false,
          error: "Invalid user key"
        }), {
          status: 401,
          headers: corsHeaders
        });
      }

      // Rate limiting
      const userData = userStore.get(userKey);
      userData.requests++;

      if (userData.requests > 100) {
        return new Response(JSON.stringify({
          status: false,
          error: "Rate limit exceeded"
        }), {
          status: 429,
          headers: corsHeaders
        });
      }

      // Return server configuration
      return new Response(JSON.stringify({
        status: true,
        version: SERVERS_CONFIG.version,
        updated_url: btoa(SERVERS_CONFIG.updated_url),
        servers: SERVERS_CONFIG.servers,
        notification: SERVERS_CONFIG.notification,
        force_update: SERVERS_CONFIG.force_update
      }), { headers: corsHeaders });
    }

    // 404 Not Found
    return new Response(JSON.stringify({
      status: false,
      error: "Endpoint not found"
    }), {
      status: 404,
      headers: corsHeaders
    });
  }
};
