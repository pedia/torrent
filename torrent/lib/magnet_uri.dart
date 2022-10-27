import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:base32/base32.dart';
import 'src/endpoint.dart';

import 'error.dart';

class AddParam {
  final String? name;
  final InfoHash infoHashes;
  final List<String> urlSeeds;
  final List<Endpoint> peers;
  final List<Endpoint> dhtNodes;
  final List<String> trackers;

  AddParam({
    this.name,
    required this.infoHashes,
    List<String>? urlSeeds,
    List<Endpoint>? peers,
    List<Endpoint>? dhtNodes,
    List<String>? trackers,
  })  : urlSeeds = urlSeeds ?? const <String>[],
        peers = peers ?? const <Endpoint>[],
        dhtNodes = dhtNodes ?? const <Endpoint>[],
        trackers = trackers ?? const <String>[];

  // TODO: 统计
  // TODO: http_seeds, url_seeds
  // TODO: peers
  // TODO: ...

  static AddParam parse(String uri) {
    uri = uri.trim();

    if (uri.substring(0, 8) != 'magnet:?') {
      throw TorrentError(ErrorCode.unsupportedUrlProtocol);
    }

    final u = Uri.parse(uri);

    // lower key
    final m = u.queryParameters
        .map((key, value) => MapEntry(key.toLowerCase(), value));
    final ma = u.queryParametersAll
        .map((key, value) => MapEntry(key.toLowerCase(), value));

    Digest? v1, v2;

    final xts = ma['xt'];
    if (xts != null) {
      for (var xt in xts) {
        if (xt.startsWith('urn:btih:')) {
          final left = xt.substring(9);
          if (left.length == 40) {
            v1 = Digest(hex.decode(left));
          } else if (left.length == 32) {
            v1 = Digest(base32.decode(left));
          }

          if (v1 != null && v1.bytes.length != 20) {
            throw TorrentError(ErrorCode.invalidInfoHash);
          }
        }
        if (xt.startsWith('urn:btmh:')) {
          var left = xt.substring(9);
          // hash must be sha256
          if (!left.startsWith('1220')) {
            throw TorrentError(ErrorCode.invalidInfoHash);
          }

          left = left.substring(4);
          if (left.length != 64) {
            throw TorrentError(ErrorCode.invalidInfoHash);
          }

          v2 = Digest(hex.decode(left));
        }
      }
    }

    if (v1 == null && v2 == null) {
      throw TorrentError(ErrorCode.missingInfoHashInUri);
    }

    //
    final trs = <String>[];
    ma.forEach((k, v) {
      if (k == 'tr' || k.startsWith('tr.')) {
        trs.addAll(v);
      }
    });

    return AddParam(
      name: m['dn'],
      urlSeeds: ma['ws'],
      infoHashes: InfoHash(v1, v2),
      peers: ma['x.pe']
          ?.map((e) => Endpoint.tryParse(e))
          .where((v) => v != null)
          .cast<Endpoint>()
          .toList(),
      dhtNodes: ma['dht']
          ?.map((e) => Endpoint.tryParse(e))
          .where((v) => v != null)
          .cast<Endpoint>()
          .toList(),
      trackers: trs,
    );
  }
}

class InfoHash {
  const InfoHash(this.v1, this.v2);

  final Digest? v1;
  final Digest? v2;

  bool get hasV1 => v1 != null;
  bool get hasV2 => v2 != null;
}
