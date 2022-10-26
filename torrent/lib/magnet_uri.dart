import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:base32/base32.dart';

import 'error.dart';

class AddParam {
  final String name;
  final String? trackerid;
  final InfoHash infoHashes;
  final List<String> urlSeeds;

  AddParam({
    required this.name,
    this.trackerid,
    required this.infoHashes,
    this.urlSeeds = const <String>[],
  });

  // TODO: 统计
  // TODO: http_seeds, url_seeds
  // TODO: peers
  // TODO: ...

  static AddParam parse(String uri) {
    if (uri.substring(0, 8) != 'magnet:?') {
      throw TorrentError(ErrorCode.unsupportedUrlProtocol);
    }

    final u = Uri.parse(uri);

    final m = u.queryParameters
        .map((key, value) => MapEntry(key.toLowerCase(), value));
    final ma = u.queryParametersAll
        .map((key, value) => MapEntry(key.toLowerCase(), value));

    Digest? v1, v2;

    final xt = m['xt'];
    if (xt != null) {
      if (xt.startsWith('urn:btih:')) {
        final left = xt.substring(9);
        if (left.length == 40) {
          v1 = Digest(HEX.decode(left));
        } else if (left.length == 32) {
          v1 = Digest(base32.decode(left));
        }

        if (v1 != null && v1.bytes.length != 20) {
          throw TorrentError(ErrorCode.invalidInfoHash);
        }
      } else if (xt.startsWith('urn:btmh:')) {
        var left = xt.substring(9);
        // hash must be sha256
        if (!left.startsWith('1220')) {
          throw TorrentError(ErrorCode.invalidInfoHash);
        }

        left = left.substring(4);
        if (left.length != 64) {
          throw TorrentError(ErrorCode.invalidInfoHash);
        }

        v2 = Digest(HEX.decode(left));
      }
    }

    if (v1 == null && v2 == null) {
      throw TorrentError(ErrorCode.missingInfoHashInUri);
    }

    return AddParam(
      name: m['dn'] ?? '',
      urlSeeds: ma['ws'] ?? const <String>[],
      infoHashes: InfoHash(v1, v2),
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
