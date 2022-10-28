import 'dart:convert' show Converter, Codec;
import 'dart:typed_data';

/// Bencoding is a common representation in bittorrent used for dictionary,
/// list, int and string hierarchies. It's used to encode .torrent files and
/// some messages in the network protocol.
///
/// Strings in bencoded structures do not necessarily represent text.
/// Strings are raw byte buffers of a certain length. If a string is meant to be
/// interpreted as text, it is required to be UTF-8 encoded. See `BEP 3`_.
///
/// The function for decoding bencoded data [decode], returning [Object].
///
/// It's possible to construct an entry from a bdecode_node, if a structure needs
/// to be altered and re-encoded.

/// Error thrown in encoding if an object cannot be converted
///
/// The [unsupportedObject] field holds that object that failed to be converted.
class BencodeUnsupportObjectError extends Error {
  /// The object that could not be serialized.
  final Object unsupportedObject;

  BencodeUnsupportObjectError(this.unsupportedObject);

  @override
  String toString() => 'Unsupport ${Error.safeToString(unsupportedObject)}';
}

/// Error thrown in decoding if an object cannot be converted
class BencodeInvalidError extends Error {
  final int positionStart;

  BencodeInvalidError(this.positionStart);

  @override
  String toString() => 'Invlida bencoded sequence at $positionStart';
}

/// [encode] will encode data to bencoded form.
///
String encode(Object input) {
  return BenEncoder().convert(input);
}

class BenEncoder extends Converter<Object, String> {
  @override
  String convert(Object input) {
    if (input is String) {
      return '${input.length}:$input';
    } else if (input is int) {
      return 'i${input}e';
    } else if (input is List) {
      // TODO: Uint8List
      final s = input.map((i) => encode(i)).toList().join('');
      return 'l${s}e';
    } else if (input is Map) {
      final es = input.entries.toList(growable: false)
        ..sort((a, b) => a.key.compareTo(b.key));

      final s =
          es.map((e) => encode(e.key) + encode(e.value)).toList().join('');
      return 'd${s}e';
    } else {
      throw BencodeUnsupportObjectError(input);
    }
  }
}

/// [decode] decodes/parses bdecoded data (for example a .torrent file).
///
Object decode(String input) => BenDecoder().convert(input);

Object decodeBytes(Uint8List input) =>
    BenDecoder(forceUtf8: false).convertBytes(input);

///
class BenDecoder extends Converter<String, Object> {
  final bool forceUtf8;

  /// CodeUnits of input String
  late List<int> source;
  int pos;

  /// [result] used in decoding, contain the result of list or map.
  final result = [];

  BenDecoder({this.source = const [], this.pos = 0, this.forceUtf8 = true});

  @override
  Object convert(String input) {
    source = input.codeUnits;
    return _decode();
  }

  Object convertBytes(Uint8List input) {
    source = input;
    return _decode();
  }

  /// Recursive decode
  Object _decode() {
    const $semicolon = 0x3a; // :
    const $e = 101; // e

    if (source.isEmpty) {
      throw BencodeInvalidError(0);
    }

    final c = source[pos];
    switch (c) {
      case 105: // i
        final $epos = source.indexOf($e, pos);
        if ($epos == -1) {
          throw BencodeInvalidError(pos);
        }
        int i = pos;
        pos = $epos; // left last char of integer
        int? v =
            int.tryParse(String.fromCharCodes(source.sublist(i + 1, $epos)));
        if (v == null) {
          throw BencodeInvalidError(i + 1);
        }
        return v;
      case 100: // d
        pos += 1;
        while (pos < source.length - 1) {
          if (source[pos] == $e) {
            break;
          }

          final d = BenDecoder(source: source, pos: pos, forceUtf8: forceUtf8);
          result.add(d._decode());
          pos = d.pos + 1; // left last char of list
        }

        final m = {};
        for (int i = 0; i < result.length; i += 2) {
          if (forceUtf8) {
            m[result[i]] = result[i + 1];
          } else {
            final key = String.fromCharCodes(result[i]);
            m[key] = result[i + 1];
          }
        }
        return m;
      case 108: // l
        pos += 1;

        while (pos < source.length - 1) {
          if (source[pos] == $e) {
            break;
          }

          final d = BenDecoder(source: source, pos: pos, forceUtf8: forceUtf8);
          result.add(d._decode());
          pos = d.pos + 1; // left last char of list
        }

        return result;
      default:
        // find 0x3a ':'
        final spos = source.indexOf($semicolon, pos);
        if (spos == -1) {
          throw BencodeInvalidError(pos);
        }
        int len = int.parse(String.fromCharCodes(source.sublist(pos, spos)));
        if (spos + 1 + len > source.length) {
          throw BencodeInvalidError(spos);
        }
        pos = spos + len; // left last char of string
        if (forceUtf8) {
          return String.fromCharCodes(source.sublist(spos + 1, spos + 1 + len));
        }
        return Uint8List.fromList(source.sublist(spos + 1, spos + 1 + len));
    }
  }
}

const BenCodec ben = BenCodec();

class BenCodec extends Codec {
  const BenCodec();

  @override
  BenDecoder get decoder => BenDecoder();

  @override
  BenEncoder get encoder => BenEncoder();
}
