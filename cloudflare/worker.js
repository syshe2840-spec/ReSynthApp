/**
 * ReSynth VPN - Cloudflare Worker API
 * Handles server configs, updates, and notifications
 */

const SERVERS_CONFIG = {
  version: "1.0.0",
  updated_url: btoa("https://github.com/syshe2840-spec/ReSynthApp/releases"),

  // Notification system
  notification: {
    enabled: true,
    type: "success", // info, warning, success, error
    title: "Welcome to ReSynth VPN!",
    message: "Enjoy fast and secure VPN service. Stay connected!",
    show_once: true, // Show every time or just once
  },

  // Force update dialog
  force_update: {
    enabled: false,
    min_version: "1.0.0",
    title: "Update Required",
    message: "Please update to the latest version for better performance and security.",
    download_url: btoa("https://github.com/syshe2840-spec/ReSynthApp/releases"),
  },

  // Encrypted server configs (use encrypt_servers.py)
  servers: [
    {
      name: "Germany Fast",
      config: "g5s7+VyhWrBYljZw4zXL/HIk1QbHdukABC8uy4uvOEc2SJ1uWZGudKy43HkmgC1Pc7jrChXdTWLp9KPAXzqFQElfj9qqdAuu60hd7HDQjUW56cDPl2k3+/YQfw+8yqaubnstTHnuIKIvotFcXXIpWBdIqpMIK3i3hvdeMlV9heY8SSrbKipAs53j5TiklNNOuExZWEHIgnF1H6KKJ7VHjqiOxfB0MMOiq42x2SadgvoUoE5HU06WhXsyF8FDe9z73vT7pXNiiz5V3y9R6g7z8+GRPwc6V33jXPt3n1dWlRTh+4cBLaaFM+ZD6s8S3wLe2OuL5De2MklS1XnaitAV3kTQUL1Tr7nVDvMjSNq23N4="
    },
    {
      name: "Netherlands Speed",
      config: "HepGEOcwgoa+pPXwJP4idQyk5upWHUAF96NT8YVkhn0BSSiX0N7Qcmnu7Dvgs+PXQCYjLXmMWfvHXDykNtqy4DrqpyZKBUK2tuC7DdVgx08IPweslPBpnbm4o+SvGWmu9rutNppvfMUKvCjOkplmtKFMgf1t4+nxwW+6wAPUzf0tjWlf/FxbSe2AmS13ZtYbh+OkOZAy/GMGUNKrnoalsRSHbpC730PJOOd64xdrWMShxqtBB1DmNLHj7qxfgik5oHfPwj4VxCn8KiQS6zLY5Naxnwqq9ORApt7R3hwM3DIG8MVq5cfFaC0mh847szc1"
    },
    {
      name: "France Secure",
      config: "sLV4H0QcmrC3nZZ/6aozlVpdo5pUmK7YrRlGWSjY3gWjn9lC1cP+WolwxkuH8x8Iar47P0DXC4xJbbvUbcV3xmdefwbO2LgHu+0fyJkSkaCmPGK0sdOeoAVK8O+vIA0dXuosZ35qe6fVmtYwYIxZYLGlXMIRb93Z2EMsSn/wL/sqb/pjHfEKfTcCCf0ubMqThJyGX4CTQxn0ZXwW1DB83PGuf/oN5ykdcRsOoQ4FTN+wFdwJEl3uur7V3PNzHop6dFGrZl52IgnxHkV6ep7tSDqbnNwqqpe+DkhkG8XXjDx/vwT287iHmn+v52jAEoEr"
    }
  ]
};

// Simple user key generation
function generateUserKey() {
  return 'resynth_' + Date.now() + '_' + Math.random().toString(36).substring(7);
}

// User database (use KV storage in production)
const USERS_DB = new Map();

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  const url = new URL(request.url);
  const path = url.pathname;

  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'X-Content-Type-Options': 'nosniff',
  };

  if (request.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Root path - Welcome page
    if (path === '/' || path === '') {
      return new Response(JSON.stringify({
        status: true,
        message: "ReSynth VPN API v1.0.0",
        endpoints: {
          init: "/api/firebase/init/android",
          data: "/api/firebase/init/data/{user_key}"
        },
        features: {
          encryption: "AES-256",
          notification: SERVERS_CONFIG.notification.enabled,
          force_update: SERVERS_CONFIG.force_update.enabled,
          servers: SERVERS_CONFIG.servers.length
        }
      }), {
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders
        }
      });
    }

    // Initialize user and get key
    if (path === '/api/firebase/init/android') {
      const userKey = generateUserKey();
      USERS_DB.set(userKey, {
        created: Date.now(),
        requests: 0,
        lastRequest: Date.now(),
      });

      return new Response(JSON.stringify({
        key: userKey,
        status: true
      }), {
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders
        }
      });
    }

    // Get server data
    if (path.startsWith('/api/firebase/init/data/')) {
      // Note: User key validation disabled because Workers Map is stateless
      // For production, use Cloudflare KV or Durable Objects for persistent storage

      // Return config with all features
      const response = {
        status: true,
        version: SERVERS_CONFIG.version,
        updated_url: SERVERS_CONFIG.updated_url,
        servers: SERVERS_CONFIG.servers,

        // Notification (if enabled)
        notification: SERVERS_CONFIG.notification.enabled ? {
          type: SERVERS_CONFIG.notification.type,
          title: SERVERS_CONFIG.notification.title,
          message: SERVERS_CONFIG.notification.message,
          show_once: SERVERS_CONFIG.notification.show_once,
        } : null,

        // Force update (if enabled)
        force_update: SERVERS_CONFIG.force_update.enabled ? {
          required: true,
          min_version: SERVERS_CONFIG.force_update.min_version,
          title: SERVERS_CONFIG.force_update.title,
          message: SERVERS_CONFIG.force_update.message,
          download_url: SERVERS_CONFIG.force_update.download_url,
        } : null,
      };

      return new Response(JSON.stringify(response), {
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders
        }
      });
    }

    // 404
    return new Response('Not Found', {
      status: 404,
      headers: corsHeaders
    });

  } catch (error) {
    return new Response(JSON.stringify({
      status: false,
      error: error.message
    }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders
      }
    });
  }
}
