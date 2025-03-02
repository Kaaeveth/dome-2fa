import 'package:dome_2fa/core/account/account.dart';
import 'package:dome_2fa/core/one_time_password.dart';
import 'package:test/test.dart';

void main() {
  test("Create Account from minimal Key URI format", () {
    var uri = "otpauth://totp/totp@authenticationtest.com?secret=I65VU7K5ZQL7WB4E";
    var acc = Account.fromUrl(uri);
    expect(acc.label, "totp@authenticationtest.com");
    expect(acc.secret, "I65VU7K5ZQL7WB4E");
    expect(acc.issuer, "totp@authenticationtest.com");
    expect(acc.duration, 30);
    expect(acc.algorithm, HashAlgorithm.sha1);
  });

  test("Create Account from complete Key URI format", () {
    var uri = "otpauth://totp/AWS:geil?secret=wcwqjifokprmuwrubrztvjwaodkvgj6go3u4e6dmvefopzs4wbg5wo2p&algorithm=SHA256&digits=6&period=60&lock=false";
    var acc = Account.fromUrl(uri);
    expect(acc.label, "AWS:geil");
    expect(acc.secret, "wcwqjifokprmuwrubrztvjwaodkvgj6go3u4e6dmvefopzs4wbg5wo2p".toUpperCase());
    expect(acc.issuer, "AWS");
    expect(acc.duration, 60);
    expect(acc.algorithm, HashAlgorithm.sha256);
  });

  test("Create Account with invalid authority", () {
    var uri = "otpauth://hotp/totp@authenticationtest.com?secret=I65VU7K5ZQL7WB4E";
    expect(() => Account.fromUrl(uri), throwsA(isA<Exception>()));
  });

  test("Create Account with missing secret", () {
    var uri = "otpauth://totp/totp@authenticationtest.com?secret=";
    expect(() => Account.fromUrl(uri), throwsA(isA<ArgumentError>()));

    uri = "otpauth://totp/totp@authenticationtest.com";
    expect(() => Account.fromUrl(uri), throwsA(isA<Exception>()));
  });
}