import 'dart:io';

import 'package:dome_2fa/core/preferences.dart';
import 'package:test/test.dart';

void main() {
  test("write and read primitive setting", () async {
    var fileName = "test1.json";
    var prefs = await UserPreferences.create(prefFileName: fileName);
    addTearDown(() {
      File(prefs.preferencesFilePath).deleteSync();
    });

    prefs["test1"] =  true;
    prefs = await UserPreferences.create(prefFileName: fileName);
    expect(prefs["test1"], true);
  });

  test("write and read object setting", () async {
    var fileName = "test2.json";
    var prefs = await UserPreferences.create(prefFileName: fileName);
    addTearDown(() {
      File(prefs.preferencesFilePath).deleteSync();
    });
    prefs["test1"] = {"first": true, "second": 42};

    prefs = await UserPreferences.create(prefFileName: fileName);
    var setting = prefs["test1"] as Map<String, dynamic>;
    expect(setting["first"], true);
    expect(setting["second"], 42);
  });

  test("get non existing setting", () async {
    var fileName = "test3.json";
    var prefs = await UserPreferences.create(prefFileName: fileName);

    expect(prefs["non"], null);
  });

  test("return json array as iterable", () async {
    var fileName = "test4.json";
    var prefs = await UserPreferences.create(prefFileName: fileName);
    addTearDown(() {
      File(prefs.preferencesFilePath).deleteSync();
    });

    var actualList = List.from([1,2,3]);
    prefs["iter"] = actualList;
    var list = prefs["iter"] as List<dynamic>;
    for(var (i, n) in list.cast<int>().indexed) {
      expect(n, actualList[i]);
    }
  });
}