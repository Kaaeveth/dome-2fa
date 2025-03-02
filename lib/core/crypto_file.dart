import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:argon2/argon2.dart';
import 'package:flutter/foundation.dart' as f;
import 'package:thread/thread.dart';

/// An AES-CTR encrypted file
/// 
/// The first byte is the file version followed by [CryptoFile.SALT_SIZE] bytes
/// for the salt of KDF algorithm.
/// The next [CryptoFile.IV_SIZE] bytes are the initialization vector and
/// the next [CryptoFile.SALT_SIZE] bytes is the encrypted salt (nonce).
/// The remaining file is the cipher text.
class CryptoFile {
  final Encrypter encrypter;
  final Key key;
  final IV _iv;
  final Uint8List _salt;
  final File _file;
  static const int IV_SIZE = 16;
  static const int SALT_SIZE = 16;
  static const int VERSION = 1;
  
  CryptoFile._internal(this.encrypter, this.key, this._iv, this._file, this._salt);

  static Future<CryptoFile> createOrOpen(File file, {String? password, Uint8List? keyBytes}) async {
    IV iv;
    Uint8List salt;
    Uint8List? nonce;
    if(!await file.exists()) {
      iv = IV.fromSecureRandom(IV_SIZE);
      salt = IV.fromSecureRandom(SALT_SIZE).bytes;
    } else {
      var fd = await file.open();
      var _ = await fd.read(1); // Check version in the future
      salt = await fd.read(SALT_SIZE);
      var ivBuffer = await fd.read(IV_SIZE);
      nonce = await fd.read(2*SALT_SIZE);
      await fd.close();
      iv = IV(ivBuffer);
    }

    Key key;
    if(password != null) {
      key = Key(await Thread.ComputeWith(
          (password, salt), (params) => keyFromPassword(params.$1, params.$2)));
    } else if(keyBytes != null) {
      key = Key(keyBytes);
    } else {
      throw Exception("Either password or keyBytes must not be null");
    }

    var encrypter = Encrypter(AES(key, mode: AESMode.ctr));
    var cryptoFile =  CryptoFile._internal(encrypter, key, iv, file, salt);

    // Check password of file if it exists
    if(nonce != null) {
      Uint8List challenge;
      try {
        challenge = cryptoFile.decryptBytes(nonce);
      } catch (e) {
        throw Exception("Invalid Password");
      }
      if (!f.listEquals(challenge, salt)) {
        throw Exception("Invalid Password");
      }
    }

    return cryptoFile;
  }

  static Future<Uint8List> keyFromPassword(String password, Uint8List salt) async {
    var parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_i,
      salt,
      version: Argon2Parameters.ARGON2_VERSION_10,
      iterations: 1,
      memoryPowerOf2: 8,
    );
    var argon2 = Argon2BytesGenerator();
    var result = Uint8List(32);
    argon2.init(parameters);

    var passwordBytes = parameters.converter.convert(password);
    argon2.generateBytes(passwordBytes, result, 0, result.length);
    return result;
  }

  Uint8List encrypt(String clear) {
    var res = encrypter.encrypt(clear, iv: _iv);
    return res.bytes;
  }

  Uint8List encryptBytes(Uint8List clear) {
    var res = encrypter.encryptBytes(clear, iv: _iv);
    return res.bytes;
  }

  String decrypt(Uint8List crypt) {
    return encrypter.decrypt(Encrypted(crypt), iv: _iv);
  }

  Uint8List decryptBytes(Uint8List crypt) {
    return encrypter.decryptBytes(Encrypted(crypt), iv: _iv).toUint8List();
  }

  Future<void> writeAll(String content) async {
    var fd = await _file.open(mode: FileMode.writeOnly);
    await fd.writeByte(VERSION);
    await fd.writeFrom(_salt);
    await fd.writeFrom(_iv.bytes);
    await fd.writeFrom(encryptBytes(_salt));
    await fd.writeFrom(encrypt(content));
    await fd.close();
  }

  String _decryptRead(Uint8List buffer) {
    // +1 for version; The salt is writen in cleartext and encrypted (twice the size)
    const headerSize = IV_SIZE+2*SALT_SIZE+SALT_SIZE+1;
    if (buffer.length < headerSize) {
      throw Exception("Invalid or corrupted file");
    }
    return decrypt(Uint8List.sublistView(buffer, headerSize));
  }

  Future<String> readAll() async {
    var buffer = await _file.readAsBytes();
    return _decryptRead(buffer);
  }

  String readAllSync() {
    var buffer = _file.readAsBytesSync();
    return _decryptRead(buffer);
  }
}
