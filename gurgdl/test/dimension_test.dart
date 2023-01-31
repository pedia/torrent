import 'package:test/test.dart';

import '../lib/base/dimension.dart';

void main() {
  test('Speed', () {
    expect(Dimension(1000).toString(), '1000 B');
    expect(Dimension(3000).toString(), '3 KB');
    expect(Dimension(3000 * 1023).toString(), '2.9 MB');
    expect(Dimension(3000 * 1023 * 1024).toString(), '2.9 GB');
    expect(Dimension.size(3000 * 1023 * 1024).toString(), '2.9 GB');
    expect(Dimension.speed(3000 * 1023 * 1024).toString(), '2.9 GB/s');

    expect(Dimension.duration(1000).toString(), '17 minute');
    expect(Dimension.duration(2000 * 1024).toString(), '23.7 day');
    expect(Dimension.duration(6000).toString(), '1.7 hour');
  });
}
