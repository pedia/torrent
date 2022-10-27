import 'dart:io';

/// Simply wrap for ip:port like 127.0.0.1:80
class Endpoint {
  final InternetAddress addr;
  final int port;

  const Endpoint(this.addr, this.port);

  @override
  String toString() {
    if (addr.type == InternetAddressType.IPv4) {
      return '${addr.address}:$port';
    } else if (addr.type == InternetAddressType.IPv6) {
      return '[${addr.address}]:$port';
    }
    return super.toString();
  }

  static Endpoint? tryParse(String s) {
    if (s.startsWith('[')) {
      final pos = s.lastIndexOf(']:');
      final addr = InternetAddress.tryParse(s.substring(1, pos));
      final port = int.tryParse(s.substring(pos + 2));

      if (addr != null && port != null) {
        return Endpoint(addr, port);
      }
      return null;
    }

    final pos = s.lastIndexOf(':');
    if (pos != -1) {
      final addr = InternetAddress.tryParse(s.substring(0, pos));
      final port = int.tryParse(s.substring(pos + 1));
      if (addr != null && port != null) {
        return Endpoint(addr, port);
      }
    }
    return null;
  }
}
