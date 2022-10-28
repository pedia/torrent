import 'package:convert/convert.dart';
import 'package:torrent/error.dart';
import 'package:crypto/crypto.dart';
import 'package:torrent/magnet.dart';
import 'package:test/test.dart';

void main() {
  test('normal', () {
    final p = Magnet.parse(
        'magnet:?xt=urn:btih:3dd586237d548bc66a5bc9e9dd2ae1c08b3c6a1b');
    expect(p, isNotNull);
  });

  test('parse_mixed_case', () {
    final p = Magnet.parse(
        'magnet:?XT=urn:btih:cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdc%64'
        '&dN=foobar&Ws=http://foo.com/bar');

    expect(p.name, 'foobar');
    expect(
      p.infoHashe.v1.toString(),
      'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd',
    );
    expect(p.urlSeeds.length, 1);
    expect(p.urlSeeds[0], 'http://foo.com/bar');
  });

  test('parse_invalid_escaped_hash_parameter', () {
    expect(
        () => Magnet.parse('magnet:?xt=urn%%3A'), throwsA(isA<TorrentError>()));
  });

  test('parse_magnet_uri_quoted', () {
    final p = Magnet.parse(
        'magnet:?"foo=bar&xt=urn:btih:cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd');
    expect(
      p.infoHashe.v1.toString(),
      'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd',
    );
  });

  test('throwing_overload', () {
    expect(() => Magnet.parse('magnet:?xt=urn%%3A'),
        throwsA(isA<TorrentError>())); // TODO: error code
  });

  test('parse_missing_hash', () {
    expect(
      () => Magnet.parse('magnet:?dn=foo&dht=127.0.0.1:43'),
      throwsA(isA<TorrentError>()),
    );
    // Magnet.parse('magnet:?dn=foo&dht=127.0.0.1:43');
  });

  test('parse_base32_hash', () {
    final p =
        Magnet.parse('magnet:?xt=urn:btih:MFRGCYTBMJQWEYLCMFRGCYTBMJQWEYLC');

    final d = Digest(hex.decode('abababababababababab'));
    expect(d == p.infoHashe.v1, isTrue);
  }, skip: true); // TODO: 2.0

  test('parse_web_seeds', () {
    final p = Magnet.parse(
        'magnet:?xt=urn:btih:cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd'
        '&ws=http://foo.com/bar&ws=http://bar.com/foo');
    expect(p.urlSeeds.length, 2);
    expect(p.urlSeeds[0], 'http://foo.com/bar');
    expect(p.urlSeeds[1], 'http://bar.com/foo');
  });

  test('parse_missing_hash2', () {
    expect(
      () => Magnet.parse('magnet:?xt=blah&dn=foo&dht=127.0.0.1:43'),
      throwsA(isA<TorrentError>()), // TODO:
    );
  });

  test('parse_short_hash', () {
    expect(
      () => Magnet.parse('magnet:?xt=urn:btih:abababab'),
      throwsA(isA<TorrentError>()), // TODO:
    );
  });

  test('parse_long_hash', () {
    expect(
      () => Magnet.parse('magnet:?xt=urn:btih:ababababababababababab'),
      throwsA(isA<TorrentError>()), // TODO:
    );
  });

  test('parse_space_hash', () {
    expect(
      () => Magnet.parse('magnet:?xt=urn:btih: abababababababababab'),
      throwsA(isA<TorrentError>()), // TODO:
    );
  });

  test('parse_v2_hash', () {
    final p = Magnet.parse(
        'magnet:?xt=urn:btmh:1220cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd');

    expect(p.infoHashe.hasV1, isFalse);
    expect(p.infoHashe.hasV2, isTrue);
    expect(
        p.infoHashe.v2,
        Digest(hex.decode(
          'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd',
        )));
  });

  test('parse_v2_short_hash', () {
    expect(
      () => Magnet.parse(
          'magnet:?xt=urn:btmh:1220cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdccdcdcdcdcdcdcd'),
      throwsA(isA<TorrentError>()), // TODO:
    );
  });

  test('parse_v2_invalid_hash_prefix', () {
    expect(
      () => Magnet.parse(
          'magnet:?xt=urn:btmh:1221cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd'),
      throwsA(isA<TorrentError>()), // TODO:
    );
  });

  test('parse_hybrid_uri', () {
    final p = Magnet.parse(
      'magnet:?'
      'xt=urn:btmh:1220cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd'
      '&xt=urn:btih:cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd',
    );

    expect(p.infoHashe.hasV1, isTrue);
    expect(
        p.infoHashe.v1,
        Digest(hex.decode(
          'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd',
        )));
    expect(p.infoHashe.hasV2, isTrue);
    expect(
        p.infoHashe.v2,
        Digest(hex.decode(
          'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd',
        )));
  });

  test('parse_peer', () {
    final p = Magnet.parse(
        'magnet:?xt=urn:btih:cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd'
        '&dn=foo&x.pe=127.0.0.1:43&x.pe=<invalid1>&x.pe=<invalid2>:100&x.pe=[::1]:45');

    expect(p.peers.length, 2);
    expect(p.peers[0].toString(), '127.0.0.1:43');
    expect(p.peers[1].toString(), '[::1]:45');
  });

  test('parse_dht_node', () {
    final p = Magnet.parse(
        'magnet:?xt=urn:btih:cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd'
        '&dn=foo&dht=127.0.0.1:43&dht=10.0.0.1:1337');

    expect(p.infoHashe.v1,
        Digest(hex.decode('cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd')));
    expect(p.dhtNodes.length, 2);
    expect(p.dhtNodes[0].toString(), '127.0.0.1:43');
    expect(p.dhtNodes[1].toString(), '10.0.0.1:1337');
  });

  test('trailing_whitespace', () {
    final p = Magnet.parse(
        'magnet:?xt=urn:btih:cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd\n');

    expect(p.infoHashe.v1,
        Digest(hex.decode('cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd')));
  });

  test('magnet_tr_x_uri', () {
    final p = Magnet.parse('magnet:'
        '?tr.0=udp://1'
        '&tr.1=http://2'
        '&tr=http://3'
        '&xt=urn:btih:c352cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd');

    expect(p.infoHashe.v1,
        Digest(hex.decode('c352cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd')));
    expect(p.trackers, [
      'udp://1',
      'http://2',
      'http://3',
    ]);
  });
}
