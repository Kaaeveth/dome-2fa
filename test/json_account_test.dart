import 'dart:io';

import 'package:dome_2fa/core/account/account.dart';
import 'package:dome_2fa/core/account/json_account_db.dart';
import 'package:test/test.dart';

void main() {
  test("Create empty, add account and read account again", () async {
    final dbPath = File("./accounts1.db");
    addTearDown(() => dbPath.deleteSync());

    var acc = Account.basic("I65VU7K5ZQL7WB4E", "01");
    var db = await JsonAccountDb.empty(dbPath, "leckeier");
    await db.insert(acc);
    expect(db.accounts.first.label, "01");
    db.close();

    var db2 = await JsonAccountDb.open(dbPath, password: "leckeier");
    expect(db2.accounts.first, acc);
    db2.close();
  });

  test("Create account after close", () async {
    final dbPath = File("./accounts2.db");
    addTearDown(() => dbPath.deleteSync());

    var db = await JsonAccountDb.empty(dbPath, "leck");
    db.close();
    expect(
      () async => await db.insert(Account.basic("I65VU7K5ZQL7WB4E", "02")),
      throwsA(isA<Exception>())
    );
  });
}