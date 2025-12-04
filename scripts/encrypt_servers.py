#!/usr/bin/env python3
"""
Server Config Encryption Script for ReSynth VPN
Encrypts V2Ray server configurations using AES-256-CBC
"""

import base64
import json
from Crypto.Cipher import AES
from Crypto.Util.Padding import pad, unpad

# AES Configuration - MUST match Flutter app
AES_KEY = b'ReSynthVPN2024Key' + b'0' * 15  # Pad to 32 bytes for AES-256
AES_IV = b'ReSynthIV16Char!'  # Exactly 16 bytes

def encrypt_server(config_string):
    """
    Encrypt a server configuration string

    Args:
        config_string (str): V2Ray config URL (vless://... or vmess://...)

    Returns:
        str: Base64 encoded encrypted string
    """
    cipher = AES.new(AES_KEY, AES.MODE_CBC, AES_IV)
    padded_data = pad(config_string.encode('utf-8'), AES.block_size)
    encrypted = cipher.encrypt(padded_data)
    return base64.b64encode(encrypted).decode('utf-8')

def decrypt_server(encrypted_string):
    """
    Decrypt a server configuration string (for testing)

    Args:
        encrypted_string (str): Base64 encoded encrypted string

    Returns:
        str: Decrypted V2Ray config URL
    """
    cipher = AES.new(AES_KEY, AES.MODE_CBC, AES_IV)
    encrypted_data = base64.b64decode(encrypted_string)
    decrypted = cipher.decrypt(encrypted_data)
    return unpad(decrypted, AES.block_size).decode('utf-8')

def encrypt_server_list(servers_file='servers.json', output_file='servers_encrypted.json'):
    """
    Encrypt all servers in a JSON file

    Args:
        servers_file (str): Input JSON file with plain servers
        output_file (str): Output JSON file with encrypted servers
    """
    try:
        with open(servers_file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        encrypted_servers = []
        for server in data.get('servers', []):
            encrypted_config = encrypt_server(server['config'])
            encrypted_servers.append({
                'name': server['name'],
                'config': encrypted_config
            })

        output_data = {
            'version': data.get('version', '1.0.0'),
            'updated_url': data.get('updated_url', ''),
            'notification': data.get('notification', {}),
            'status': True,
            'servers': encrypted_servers
        }

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)

        print(f"✅ Successfully encrypted {len(encrypted_servers)} servers")
        print(f"📁 Output saved to: {output_file}")

        # Print encrypted configs for easy copy-paste to worker.js
        print("\n📋 Copy these to cloudflare/worker.js:")
        print("=" * 80)
        for server in encrypted_servers:
            print(f"\n  {{\n    name: \"{server['name']}\",")
            print(f"    config: \"{server['config']}\"")
            print(f"  }},")
        print("=" * 80)

    except FileNotFoundError:
        print(f"❌ Error: File '{servers_file}' not found")
    except json.JSONDecodeError:
        print(f"❌ Error: Invalid JSON in '{servers_file}'")
    except Exception as e:
        print(f"❌ Error: {str(e)}")

if __name__ == '__main__':
    import sys

    if len(sys.argv) > 1:
        if sys.argv[1] == 'encrypt':
            if len(sys.argv) == 4:
                encrypt_server_list(sys.argv[2], sys.argv[3])
            else:
                print("Usage: python encrypt_servers.py encrypt <input.json> <output.json>")

        elif sys.argv[1] == 'test':
            # Test encryption/decryption with 3 real servers
            test_servers = [
                {
                    "name": "Germany Fast",
                    "config": "vless://2f075d0d-4a20-4a78-a5d0-3c01de4d313c@multi.ger.cloudnsas.ir:443?encryption=none&flow=xtls-rprx-vision&security=reality&pbk=61YEDKlaF6jpnBtgKdGghQDPhKMoV4lJVyJaI3Qhj2g&sid=acda9f2a&sni=www.speedtest.net&fp=firefox&spx=%2F&type=tcp&headerType=none#Germany-Fast"
                },
                {
                    "name": "Netherlands Speed",
                    "config": "vless://399e8f0f-76c2-4517-b180-9b5f54e22ee0@ns1.go2cloudio.ir:2083?encryption=none&security=tls&sni=37ea2a40546445ff72f1f4c5715a660f.go2cloudio.ir&alpn=h2,http/1.1&fp=chrome&type=ws&host=ns1.go2cloudio.ir&path=%2Fnews#US-CDN"
                },
                {
                    "name": "France Secure",
                    "config": "vless://08b6328c-4fdc-4262-b908-f0ad389e9911@ns.cloudnsmkh.ir:443?encryption=none&security=tls&sni=a3947276170e793e157956e4df953f01.ezcloudnet.ir&alpn=h2,http/1.1&fp=chrome&type=ws&host=ns1.ezcloudnet.ir&path=%2Fnews#Netherlands"
                }
            ]

            print("=" * 80)
            print("🔐 Testing Encryption/Decryption with ReSynth Keys")
            print("=" * 80)

            all_passed = True
            for i, server in enumerate(test_servers, 1):
                print(f"\n📡 Server {i}: {server['name']}")
                print("-" * 80)

                original = server['config']
                print(f"Original ({len(original)} chars):")
                print(f"  {original[:60]}...")

                encrypted = encrypt_server(original)
                print(f"\n🔒 Encrypted ({len(encrypted)} chars):")
                print(f"  {encrypted[:60]}...")

                decrypted = decrypt_server(encrypted)
                print(f"\n🔓 Decrypted ({len(decrypted)} chars):")
                print(f"  {decrypted[:60]}...")

                if original == decrypted:
                    print(f"\n✅ Server {i} - Encryption/Decryption PASSED")
                else:
                    print(f"\n❌ Server {i} - Encryption/Decryption FAILED")
                    all_passed = False

            print("\n" + "=" * 80)
            if all_passed:
                print("✅ All 3 servers encrypted/decrypted successfully with ReSynth keys!")
            else:
                print("❌ Some servers failed encryption/decryption test")
            print("=" * 80)
    else:
        print("ReSynth VPN Server Encryption Tool")
        print("=" * 50)
        print("\nUsage:")
        print("  python encrypt_servers.py encrypt <input.json> <output.json>")
        print("  python encrypt_servers.py test")
        print("\nExample:")
        print("  python encrypt_servers.py encrypt servers.json servers_encrypted.json")
