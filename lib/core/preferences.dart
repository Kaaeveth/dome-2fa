import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

abstract interface class Preferences {
  Object? operator [](String i);
  void operator[]=(String idx, Object? value);

  T? get<T>(String i);
  void set<T>(String idx, T? value);

  String get preferencesFilePath;
  String get preferencesDirectory;
}

class UserPreferences implements Preferences {

  static const String PREF_FILE = "preferences.json";
  static const String PREF_DIRE = ".dome_2fa/";
  final File _userPrefFile;
  Map<String, Object> _preferences;

  @override
  final String preferencesDirectory;

  UserPreferences._internal(this._preferences, this._userPrefFile, this.preferencesDirectory);

  static Future<UserPreferences> create({String? prefFileName}) async{
    var homeDire = p.normalize(p.join(await getHomeDirectory(), PREF_DIRE));
    var prefDire = Directory(homeDire)..createSync();
    var prefFile = File(p.join(prefDire.path, prefFileName ?? PREF_FILE));

    var prefs = prefFile.existsSync() ? await _loadUserPreferences(prefFile) : <String, Object>{};
    return UserPreferences._internal(
      prefs,
      prefFile,
      homeDire
    );
  }

  @override
  String get preferencesFilePath => _userPrefFile.path;

  static Future<Map<String, Object>> _loadUserPreferences(File file) async {
    return Map.castFrom(jsonDecode(await file.readAsString()));
  }

  void writeUserPreferences() {
    _userPrefFile.writeAsStringSync(jsonEncode(_preferences));
  }

  void reload() async {
    _preferences = await _loadUserPreferences(_userPrefFile);
  }

  static Future<String> getHomeDirectory() async {
    var homeDire = switch(Platform.operatingSystem) {
      "windows" => Platform.environment["UserProfile"],
      "linux" || "macos" => Platform.environment["HOME"],
      "android" => (await getApplicationDocumentsDirectory()).path,
      _ => null
    };
    if(homeDire == null) {
      throw Exception("Could not get home directory");
    }
    return homeDire;
  }

  @override
  Object? operator [](String i) {
    return _preferences[i];
  }

  @override
  void operator[]=(String idx, Object? value) {
    if(value == null) {
      _preferences.remove(idx);
    } else {
      _preferences[idx] = value;
    }
    writeUserPreferences();
  }

  @override
  T? get<T>(String i) {
    return this[i] as T;
  }

  @override
  void set<T>(String idx, T? value) {
    this[idx] = value;
  }
}