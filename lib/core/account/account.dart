import 'dart:async';

import 'package:base32/base32.dart';
import 'package:dome_2fa/core/one_time_password.dart';
import 'package:flutter/foundation.dart';
import 'package:thread/thread.dart';

class Account implements Comparable<Account> {
  final String secret; // In Base32
  final String label; // unique identifier of an account
  String issuer;
  final int duration;
  final HashAlgorithm algorithm;

  Account._internal({
    required this.secret,
    required this.label,
    required this.issuer,
    required this.duration,
    required this.algorithm,
  });

  factory Account(String key,
      {String? label, String? issuer, int? duration, HashAlgorithm? alg}) {
    duration ??= 30;
    alg ??= HashAlgorithm.sha1;
    if (key.isEmpty) {
      throw ArgumentError("Key is empty!", (#key).toString());
    }
    key = key.toUpperCase();
    if(label == null || label.isEmpty) {
      // The label is optional - Generating a unique one
      // This enables the user to have the same token inserted twice, but
      // that is fine. We assume that this is intended when entering the account
      // manually.
      label = uuid.v1();
    }
    if(duration < 1) {
      throw ArgumentError("Duration must be greater than 1!", (#duration).toString());
    }
    return Account._internal(secret: key, label: label, issuer: issuer ?? "", duration: duration, algorithm: alg);
  }

  factory Account.basic(String key, String label) {
    return Account(key, label: label);
  }

  factory Account.fromUrl(String url) {
    var otpUrl = Uri.parse(url);
    if(otpUrl.authority != "totp") {
      throw Exception("Expected TOTP URL");
    }

    var secret = otpUrl.queryParameters["secret"] ?? (throw Exception("Secret is missing from URL"));
    var alg = otpUrl.queryParameters["algorithm"];
    var label = otpUrl.pathSegments.first;
    var issuer = otpUrl.queryParameters["issuer"] ?? label.split(":")[0];
    var period = otpUrl.queryParameters["period"];

    HashAlgorithm? hashAlg;
    if(alg != null) {
      hashAlg = HashAlgorithm.values.where((e) => e.name == alg.toLowerCase()).firstOrNull
          ?? (throw Exception("Invalid algorithm $hashAlg"));
    }

    return Account(
      secret,
      label: label,
      issuer: issuer,
      duration: period != null ? int.parse(period) : null,
      alg: hashAlg
    );
  }

  String generateToken() {
    return generateOneTimePassword(
        secretAsBytes,
        DateTime.timestamp().millisecondsSinceEpoch ~/ 1000,
        duration,
        algorithm
    );
  }

  /// Returns the remaining time the current token from [generateToken]
  /// is valid
  int getRemainingTime() {
    var time = DateTime.timestamp().millisecondsSinceEpoch ~/ 1000;
    return duration - time % duration;
  }

  Uint8List get secretAsBytes {
    return base32.decode(secret);
  }
  
  @override
  int compareTo(Account other) {
    return label.compareTo(other.label);
  }

  @override
  bool operator==(Object other) {
    return other is Account && label == other.label;
  }

  @override
  int get hashCode => label.hashCode;
}

abstract class AccountDb extends ChangeNotifier {
  Future<void> insert(Account acc);
  Future<void> delete(Account acc);
  Future<void> update(Account acc);
  Future<void> save();

  Iterable<Account> get accounts;
  Account operator[](int idx);
  operator[]=(int idx, Account acc);
  int get count;

  bool exists(Account acc) {
    return accounts.any((a) => a == acc);
  }

  /// Moves the account at [idx1] to [idx2], moving other accounts in-between up or down.
  /// If either index is out of bounds, then this method does nothing.
  Future<void> changeAccountOrder(int idx1, int idx2) async {
    if(idx1 < 0 || idx1 >= count || idx2 < 0 || idx2 >= count || idx2 == idx1) return;

    var acc = this[idx1];
    if(idx1 < idx2) {
      // Up -> Down
      for(;idx1 < idx2; ++idx1) {
        this[idx1] = this[idx1+1];
      }
    } else {
      // Down -> Up
      for(;idx1 > idx2; --idx1) {
        this[idx1] = this[idx1-1];
      }
    }
    this[idx2] = acc;

    await save();
    notifyListeners();
  }

  /// Closes the DB. The object is in a disposed state
  /// and any method may fail afterwards.
  void close();
  bool get isClosed;

  /// The key used to encrypt the DB in Base64.
  /// May be empty if no encryption is used
  String? get key;
}
