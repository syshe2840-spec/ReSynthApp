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

  // Encrypted server configs (use encrypt_servers.py with ReSynth keys)
  servers: [
    {
      name: "Germany Fast",
      config: "yCFMcYZB1DC9q8aa6m/5bO4ZeSfkgfRAqdqTLYxwartlaVFahy81ZpRF+kYt8XAcPYD6wvgtd5VaTDmAKkFqtM9cWfBENFtLBKJoh3yGtm30U66zNqmx6G+6wvhgpG5uN1C65EDPC6vYW8lLCPhutPFaXnNnxdlW9ERxlrWy3MuDtZoo30AI7WoSDNnWLxuC8ZqaWEnW+NxL30rj0JpEezl4ydSpPMd4N6lj7Ws6cAkkD/0c9MOQNkXNAW8EDpTrJ2MIy/ifwga1z+GndqlvzJEx1qayUg4ZQwS96WtXBDttJHGXsIjvD07DsAo89DxLBxnrB1KrmQA9+JocgLCzpbe3yZhQYXPXum4Pq/E4GvI="
    },
    {
      name: "Netherlands Speed",
      config: "8Y8FLf/YP58Qrcftc+YmcIn5YwuZwDhTZkpVV3nVX9oyUqgzWV+b9F2WuSlinrDQjd6ibnV/P8uwBnjE2FtdRCvK/jT0EU+ylZSC0xAC5um9/yJOBcmtCcHq907e7midFNv5mjyr6viFnOt285p0p2xODDzPIekgh/Fojrh/f44tNqVddI222KljyAh0j+ky7mnc9UCKB+SoxAPGQlkuVKD6UEgKebl6z2DOPkYg/7dVjLzkYyu4H721/v068Gm80FifmptQpQxvSLuHqn/Uem/qxMFkDcKwRxhCZSpiNgEzLhgDxgqWpOQ2bpK4Ijac"
    },
    {
      name: "France Secure",
      config: "J8vW7ESpmOwjNfSoocAKDdDTQrQes7CUJ3Oruv+14AkPI5fJMYeAArVfjhMjFZUJ9NGJQ5AylXiUGaB3YJGtT3+/KPsL+wndskU7Av1RrcoYrCcCfZqT8QjA2ZFWQiR6HkNWTwa/lGGV84GdhnzpWrwN9mhraA6Edumh3+3gI1OU8ipV1G9NRyulwuyFr2eSefPKGQjjW6a9QD7GwsCNHYD9ZDl3923kOtVLts1AErvkdtcoNdiM/xsQghP9UeR2qbceLdNW6V5gDIIWvLsM/1VHSFZPpkCRhe3WnFe8E70Zp3Zdov/fyKOVfx0df3yh"
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
