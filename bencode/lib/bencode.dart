import 'dart:convert' show Converter, Codec;

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
      throw Exception('Unsupport ${input.runtimeType}');
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

    final c = source[pos];
    switch (c) {
      case 105: // i
        final $epos = source.indexOf($e, pos);
        if ($epos == -1) {
          throw Exception('Invalid bencoded sequence');
        }
        int i = pos;
        pos = $epos; // left last char of integer
        return int.parse(String.fromCharCodes(source.sublist(i + 1, $epos)));
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
          throw Exception('Invalid bencoded sequence');
        }
        int len = int.parse(String.fromCharCodes(source.sublist(pos, spos)));
        if (spos + 1 + len > source.length) {
          throw Exception('Invalid bencoded sequence');
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
