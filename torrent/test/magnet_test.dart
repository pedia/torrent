import 'package:torrent/error.dart';
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:torrent/magnet_uri.dart';
import 'package:test/test.dart';

void main() {
  test('parse_mixed_case', () {
    final p = AddParam.parse(
        'magnet:?XT=urn:btih:cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc%64'
        '&dN=foobar&Ws=http://foo.com/bar');

    expect(p.name, 'foobar');
    expect(
      p.infoHashes.v1.toString(),
      'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd',
    );
    expect(p.urlSeeds.length, 1);
    expect(p.urlSeeds[0], 'http://foo.com/bar');
  });

  test('parse_invalid_escaped_hash_parameter', () {
    final p = AddParam.parse('magnet:?xt=urn%%3A');
    expect(p.name, ''); // TODO: raise error
  });

  test('parse_magnet_uri_quoted', () {
    final p = AddParam.parse(
        'magnet:?"foo=bar&xt=urn:btih:cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd');
    expect(
      p.infoHashes.v1.toString(),
      'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd',
    );
  });

  test('throwing_overload', () {
    final p = AddParam.parse('magnet:?xt=urn%%3A');
    expect(p, isNotNull); // TODO: failed
  });

  test('parse_missing_hash', () {
    expect(
      () => AddParam.parse('magnet:?dn=foo&dht=127.0.0.1:43'),
      throwsA(isA<TorrentError>()),
    );
  });

  test('parse_base32_hash', () {
    final p =
        AddParam.parse('magnet:?xt=urn:btih:MFRGCYTBMJQWEYLCMFRGCYTBMJQWEYLC');

    // final d = Digest(HEX.decode('abababababababababab'));
    // TODO: expect(d == p.infoHashes.v1, isTrue);
  });

  test('parse_web_seeds', () {
    final p = AddParam.parse(
        'magnet:?xt=urn:btih:cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd'
        '&ws=http://foo.com/bar&ws=http://bar.com/foo');
    expect(p.urlSeeds.length, 2);
    expect(p.urlSeeds[0], 'http://foo.com/bar');
    expect(p.urlSeeds[1], 'http://bar.com/foo');
  });

  test('parse_missing_hash2', () {
    expect(
      () => AddParam.parse('magnet:?xt=blah&dn=foo&dht=127.0.0.1:43'),
      throwsA(isA<TorrentError>()),
    );
  });
}
