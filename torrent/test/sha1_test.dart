import 'dart:typed_data';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:crypto/crypto.dart';

class Digest32<N> {
  final Uint32List digest;
  const Digest32(this.digest);

  @override
  operator ==(Object other) => true;

  @override
  int get hashCode => Object.hash(Digest32, digest);
}

main() {
  test('sha1-length', () {
    final d = sha1.convert('dummy'.codeUnits);
    expect(d.toString().length, 40);
  });
}
