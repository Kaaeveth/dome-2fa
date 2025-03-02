import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dome_2fa/core/account/account.dart';
import 'package:dome_2fa/core/crypto_file.dart';
import 'package:dome_2fa/core/one_time_password.dart';
import 'package:logging/logging.dart';

final logger = Logger("JsonAccountDb");

class JsonAccountDb extends AccountDb {

  final List<Account> _accounts;
  CryptoFile? _cryptoFile;
  bool _closed = false;

  JsonAccountDb._internal(this._accounts, this._cryptoFile);

  static Future<JsonAccountDb> open(File dbFile, {String? password, String? key}) async {
    var crypto = await CryptoFile.createOrOpen(
      dbFile,
      password: password,
      keyBytes: key != null ? base64Decode(key) : null
    );
    var input = jsonDecode(await crypto.readAll());
    var accounts = (input as List).map((elem) {
      return Account(
        elem["key"],
        label: elem["label"],
        issuer: elem["issuer"],
        duration: elem["duration"],
        alg: HashAlgorithm.values.byName(elem["algorithm"])
      );
    }).toList();
    return JsonAccountDb._internal(accounts, crypto);
  }

  static Future<JsonAccountDb> empty(File dbFile, String password) async {
    var db = JsonAccountDb._internal(
      List<Account>.empty(growable: true),
      await CryptoFile.createOrOpen(dbFile, password: password)
    );
    await db._writeAccounts();
    return db;
  }

  static Object? accountToJsonDict(Object? obj) {
    assert (obj is Account);
    var acc = obj as Account;
    return {
      "algorithm": acc.algorithm.name,
      "key": acc.secret,
      "label": acc.label,
      "issuer": acc.issuer,
      "duration": acc.duration
    };
  } 

  Future<void> _writeAccounts() async {
    if(_cryptoFile == null) {
      throw Exception("Cannot write account db: Crypto provider is null");
    }
    await _cryptoFile!.writeAll(jsonEncode(_accounts, toEncodable: accountToJsonDict));
  }

  void _checkClosed() {
    if (_closed) {
      throw Exception("AccountDb is closed!");
    }
  }

  @override
  Iterable<Account> get accounts {
    return _accounts;
  }

  @override
  String? get key => _cryptoFile?.key.base64;

  @override
  Account operator[](int idx) {
    return _accounts[idx];
  }

  @override
  void close() {
    _cryptoFile = null;
    _accounts.clear();
    _closed = true;
    notifyListeners();
  }

  @override
  Future<void> delete(Account acc) async {
    _checkClosed();
    _accounts.remove(acc);
    await _writeAccounts();
    logger.info("Deleted Account ${acc.label}");
    notifyListeners();
  }

  @override
  Future<void> insert(Account acc) async {
    _checkClosed();
    if (_accounts.contains(acc)) {
      logger.fine("Account with label ${acc.label} already exists");
      return;
    }
    _accounts.add(acc);
    await _writeAccounts();
    notifyListeners();
  }

  @override
  bool get isClosed => _closed;

  @override
  Future<void> update(Account acc) async {
    _checkClosed();
    var idx = _accounts.indexOf(acc);
    if(idx < 0) {
      logger.fine("Account with label ${acc.label} not found!");
      return;
    }
    _accounts[idx] = acc;
    await _writeAccounts();
    notifyListeners();
  }
}