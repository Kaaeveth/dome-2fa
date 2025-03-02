import 'dart:io';

import 'package:dome_2fa/core/account/account.dart';
import 'package:dome_2fa/core/account/json_account_db.dart';
import 'package:dome_2fa/core/preferences.dart';
import 'package:flutter/foundation.dart';
import "package:path/path.dart" as p;

class AccountsService extends ChangeNotifier {

  final Preferences preferences;
  AccountDb? _accountDb;
  final ValueNotifier<bool> dbPasswordSaved;

  static const String DB_NAME = "accounts.db";
  static const String DB_PWD = "dbKey";

  AccountsService._internal(this.preferences, this.dbPasswordSaved);

  factory AccountsService(Preferences prefs) {
    var dbKeyExists = ((prefs[DB_PWD] ?? "") as String).isNotEmpty;

    return AccountsService._internal(prefs, ValueNotifier(dbKeyExists));
  }

  AccountDb? get accountDb => _accountDb;

  @override
  void dispose() {
    closeDb();
    super.dispose();
  }

  void closeDb() {
    _accountDb?.close();
    _accountDb = null;
    notifyListeners();
  }

  void _checkDbOpen() {
    if(_accountDb == null) {
      throw Exception("Account DB is closed!");
    }
  }

  /// Saves the encryption key inside [preferences] for password-less login.
  /// Throws [Exception] if the [accountDb] is null / not open.
  void rememberDbPassword() {
    _checkDbOpen();
    var key = _accountDb!.key;
    if(key == null) {
      if(kDebugMode) {
        print("Cannot save Db Key: Key is null");
      }
      return;
    }

    preferences[DB_PWD] = key;
    dbPasswordSaved.value = true;
  }

  String? get savedDbPassword => preferences.get<String>(DB_PWD);

  /// Forgets the password saved by [rememberDbPassword].
  /// Has no effect if no password was set to begin with.
  void forgetDbPassword() {
    preferences[DB_PWD] = null;
    dbPasswordSaved.value = false;
  }

  Future<void> createOrOpenDatabase(String password) async {
    var dbFilePath = File(dbPath);
    if(dbExists) {
      _accountDb = await JsonAccountDb.open(dbFilePath, password: password);
    } else {
      _accountDb = await JsonAccountDb.empty(dbFilePath, password);
    }

    notifyListeners();
  }

  /// Tries to open the account database [accountDb] using the previously saved password.
  /// Returns false if their is no saved password, if the db file does not exist
  /// or if the password is incorrect.
  Future<bool> tryOpenWithSavedPassword() async {
    if(!dbExists || !dbPasswordSaved.value) {
      return false;
    }

    var key = savedDbPassword;
    if(key == null) {
      return false;
    }

    try {
      _accountDb = await JsonAccountDb.open(File(dbPath), key: key);
    } catch (e) {
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<void> createOrOpenDatabaseWithSecureAuth() async {
    // TODO: Use platform specific auth mechanism for password/pin-less db
    throw UnimplementedError();
  }

  /// Exports all accounts in [accountDb].
  /// Throws Exception if the [accountDb] is null.
  Future<void> exportDatabase(String path) async {
    _checkDbOpen();
    await File(dbPath).copy(path);
  }

  /// Imports a collection of [Account] from cleartext json.
  /// Accounts with duplicate [Account.label] will be overriden.
  /// Throws Exception if [accountDb] is null.
  Future<void> importDatabase(String path, String password) async {
    _checkDbOpen();

    var importedDb = await JsonAccountDb.open(File(path), password: password);
    for(var acc in importedDb.accounts) {
      if(accountDb!.exists(acc)) {
        await accountDb!.update(acc);
      } else {
        await accountDb!.insert(acc);
      }
    }
    importedDb.close();
  }

  String get dbPath => p.normalize(p.join(preferences.preferencesDirectory, DB_NAME));
  bool get dbExists => File(dbPath).existsSync();
}