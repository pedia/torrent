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
  test('description', () {
    final d = sha1.convert('data'.codeUnits);
    expect(d.toString().length, 40);
  });
}
