import 'dart:typed_data';

import 'package:crypto/crypto.dart';

enum HashAlgorithm {
  sha1,
  sha256,
  sha512
}

/// Generate a timed one time password according to https://datatracker.ietf.org/doc/html/rfc6238
/// The [key] and [alg] are the secret and hash algorithm to use provided by the auth provider.
/// [keyTimeStep] is the duration in seconds for which the generated code is valid, usually from the auth provider.
/// [unixEpoch] is the current unix time in seconds.
String generateOneTimePassword(Uint8List key, int unixEpoch, int keyTimeStep, HashAlgorithm alg)
{
  int T = unixEpoch ~/ keyTimeStep;
  var hmacPayload = Uint8List(8);
  // convert to big-endian
  for (var i = 8; i-- > 0; T >>>= 8) {
    hmacPayload[i] = T;
  }

  var hmacDigest = Hmac(switch (alg) {
    HashAlgorithm.sha1 => sha1,
    HashAlgorithm.sha256 => sha256,
    HashAlgorithm.sha512 => sha512
  }, key).convert(hmacPayload).bytes;

  // truncate to 6 digits as describes in the RFC
  var offset = hmacDigest[hmacDigest.length - 1] & 0xF;
  var binCode = (hmacDigest[offset] & 0x7F) << 24;
  for(var i = 1; i <= 3; i++) {
    binCode |= (hmacDigest[offset+i] & 0xFF) << (24 - i*8);
  }

  var oneTimeCode = (binCode % 1_000_000).toString();

  // fill with 0 from the left
  var result = StringBuffer();
  for(var i = 6-oneTimeCode.length; i > 0; --i) {
    result.write("0");
  }
  result.write(oneTimeCode);

  return result.toString();
}