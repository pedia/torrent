import 'package:bencode/bencode.dart';
import 'package:test/test.dart';

void main() {
  test('SingleTest', () {
    final pairs = [
      'h', '1:h', //
      'helloworld', '10:helloworld',
      '', '0:',
      'omg hay thurrr', '14:omg hay thurrr',
      2234, 'i2234e',
      0, 'i0e',
      -0, 'i0e',
      -2234, 'i-2234e',
      2222222222, 'i2222222222e',
    ];

    for (int i = 0; i < pairs.length; i += 2) {
      expect(encode(pairs[i]), pairs[i + 1]);
      expect(decode(pairs[i + 1] as String), pairs[i]);
    }
  });

  test('SimpleListTest', () {
    final pairs = [
      ['hello'], 'l5:helloe', //
      [''], 'l0:e',
      ['', ''], 'l0:0:e',
      ['', '', []], 'l0:0:lee',
      ['hello', 'world'], 'l5:hello5:worlde',
      ['hello', 'world', '!'], 'l5:hello5:world1:!e',
      ['hello', 'world', 'again'], 'l5:hello5:world5:againe',
      [22], 'li22ee',
      [23, 67], 'li23ei67ee',
      [23, 67, 99], 'li23ei67ei99ee',
      [23, 'hello', 99], 'li23e5:helloi99ee',
      [23, 'hello', 99, 'world'], 'li23e5:helloi99e5:worlde',
      ['hello', 23, 'world', 99], 'l5:helloi23e5:worldi99ee',
    ];

    for (int i = 0; i < pairs.length; i += 2) {
      expect(encode(pairs[i]), pairs[i + 1]);
      expect(decode(pairs[i + 1] as String), pairs[i]);
    }
  });
  test('ComplexList', () {
    final pairs = [
      ['a', [], 'b'], 'l1:ale1:be', //
      [
        ['a'],
        'b',
      ],
      'll1:ae1:be',

      ['b', []], 'l1:blee',
      [
        'b',
        ['a']
      ],
      'l1:bl1:aee',

      [
        'b',
        ['a'],
        []
      ],
      'l1:bl1:aelee',

      [[], []], 'llelee',
      [[], [], []], 'llelelee',

      [
        [[]]
      ],
      'llleee',

      [
        [[]],
        []
      ],
      'llleelee',

      [
        [[]],
        [[]]
      ],
      'llleelleee',
    ];

    for (int i = 0; i < pairs.length; i += 2) {
      expect(encode(pairs[i]), pairs[i + 1]);
      expect(decode(pairs[i + 1] as String), pairs[i]);
    }
  });

  test('ComplexMap', () {
    final pairs = [
      {}, 'de', //
      {1: 2}, 'di1ei2ee',
      {'a': 2}, 'd1:ai2ee',
      {'a': ''}, 'd1:a0:e',
    ];

    for (int i = 0; i < pairs.length; i += 2) {
      expect(encode(pairs[i]), pairs[i + 1]);
      expect(decode(pairs[i + 1] as String), pairs[i]);
    }
  });

  test('BenCodecUnsupportTypeTest', () {
    expect(() => encode(3.2), throwsException);
    expect(() => encode([3.2]), throwsException);
    expect(() => encode({1: 3.2}), throwsException);
    expect(() => encode(Object()), throwsException);
    // expect(() => encode(null), throwsException);
  });
}
