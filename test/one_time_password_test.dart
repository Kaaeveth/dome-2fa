import 'package:base32/base32.dart';
import 'package:test/test.dart';
import 'package:dome_2fa/core/one_time_password.dart';

final KEY = base32.decode("I65VU7K5ZQL7WB4E");
const TIME_STEP = 30;

void main() {
  test("TOTP at epoch 1737904186s and SHA1", () {
    var code = generateOneTimePassword(KEY, 1737904186, TIME_STEP, HashAlgorithm.sha1);
    expect(code, "338980");
  });
  test("TOTP at epoch 59s and SHA1", () {
    var code = generateOneTimePassword(KEY, 59, TIME_STEP, HashAlgorithm.sha1);
    expect(code, "642601");
  });
  test("TOTP at epoch 1737905042s and SHA1", () {
    var code = generateOneTimePassword(KEY, 1737905042, TIME_STEP, HashAlgorithm.sha1);
    expect(code, "107767");
  });

  test("TOTP at epoch 1737904186s and SHA256", () {
    var code = generateOneTimePassword(KEY, 1737904186, TIME_STEP, HashAlgorithm.sha256);
    expect(code, "660175");
  });
  test("TOTP at epoch 59s and SHA256", () {
    var code = generateOneTimePassword(KEY, 59, TIME_STEP, HashAlgorithm.sha256);
    expect(code, "578322");
  });
  test("TOTP at epoch 1737905042s and SHA256", () {
    var code = generateOneTimePassword(KEY, 1737905042, TIME_STEP, HashAlgorithm.sha256);
    expect(code, "168096");
  });

  test("TOTP at epoch 1737904186s and SHA512", () {
    var code = generateOneTimePassword(KEY, 1737904186, TIME_STEP, HashAlgorithm.sha512);
    expect(code, "933482");
  });
  test("TOTP at epoch 59s and SHA512", () {
    var code = generateOneTimePassword(KEY, 59, TIME_STEP, HashAlgorithm.sha512);
    expect(code, "028356");
  });
  test("TOTP at epoch 1737905042s and SHA512", () {
    var code = generateOneTimePassword(KEY, 1737905042, TIME_STEP, HashAlgorithm.sha512);
    expect(code, "532067");
  });
}