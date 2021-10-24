import 'dart:convert' show Converter, Codec;

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

/// Convert Map/List/String/Integer to bencoded string
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

/// Convert bencoded string to Map/List/String/Integer
///
Object decode(String input) => BenDecoder(input.codeUnits).convert(input);

///
class BenDecoder extends Converter<String, Object> {
  /// CodeUnits of input String
  late List<int> source;
  int pos;

  /// [result] used in decoding, contain the result of list or map.
  final result = [];

  BenDecoder([this.source = const [], this.pos = 0]);

  @override
  Object convert(String input) {
    source = input.codeUnits;
    return _decode();
  }

  /// Resurse function
  Object _decode() {
    // igore [input]
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

          final d = BenDecoder(source, pos);
          result.add(d._decode());
          pos = d.pos + 1; // left last char of list
        }

        final m = {};
        for (int i = 0; i < result.length; i += 2) {
          m[result[i]] = result[i + 1];
        }
        return m;
      case 108: // l
        pos += 1;

        while (pos < source.length - 1) {
          if (source[pos] == $e) {
            break;
          }

          final d = BenDecoder(source, pos);
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
        return String.fromCharCodes(source.sublist(spos + 1, spos + 1 + len));
    }
  }
}

const BenCodec bencodec = BenCodec();

class BenCodec extends Codec {
  const BenCodec();

  @override
  BenDecoder get decoder => BenDecoder([]);

  @override
  BenEncoder get encoder => BenEncoder();
}
