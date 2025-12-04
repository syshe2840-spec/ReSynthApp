import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  // AES Key - Keep this secret!
  static const String _aesKey = 'ReSynthVPN2024Key'; // 16 chars for AES-128
  static const String _aesIV = 'ReSynthIV16Chars!'; // 16 chars IV

  static final encrypt.Key _key = encrypt.Key.fromUtf8(_aesKey.padRight(32, '0'));
  static final encrypt.IV _iv = encrypt.IV.fromUtf8(_aesIV);

  /// Decrypt AES encrypted server config
  static String decryptServer(String encryptedConfig) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
      final decrypted = encrypter.decrypt64(encryptedConfig, iv: _iv);
      return decrypted;
    } catch (e) {
      return encryptedConfig; // Return as-is if not encrypted
    }
  }

  /// Encrypt server config (for testing)
  static String encryptServer(String config) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key, mode: encrypt.AESMode.cbc));
      final encrypted = encrypter.encrypt(config, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      return config;
    }
  }
}
