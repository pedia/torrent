import 'package:torrent/src/endpoint.dart';
import 'package:test/test.dart';

void main() {
  test('endpoint_parse', () {
    expect(Endpoint.tryParse('127.0.0.1:33').toString(), '127.0.0.1:33');
    expect(Endpoint.tryParse('[::1]:34').toString(), '[::1]:34');
  });
}
