import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

String? parse(String uri) {
  final u = Uri.parse(uri);
  final v = u.queryParameters['xt'];
  if (v != null) {
    final arr = v.split(':');
    if (arr.length == 3) {
      return arr[2];
    }
  }
  // magnet:?xt=urn:btih:EBB37BD84DFB1D005DA9E06F847EA57787E56640
  return null;
}

// curl 'https://itorrents.org/torrent/EBB37BD84DFB1D005DA9E06F847EA57787E56640.torrent' \
//   -H 'authority: itorrents.org' \
//   -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
//   -H 'accept-language: zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6,ja-CN;q=0.5,ja;q=0.4' \
//   -H 'cache-control: max-age=0' \
//   -H 'dnt: 1' \
//   -H 'referer: https://magnet2torrent.com/' \
//   -H 'sec-ch-ua: "Not.A/Brand";v="8", "Chromium";v="114", "Google Chrome";v="114"' \
//   -H 'sec-ch-ua-mobile: ?0' \
//   -H 'sec-ch-ua-platform: "macOS"' \
//   -H 'sec-fetch-dest: document' \
//   -H 'sec-fetch-mode: navigate' \
//   -H 'sec-fetch-site: cross-site' \
//   -H 'sec-fetch-user: ?1' \
//   -H 'upgrade-insecure-requests: 1' \
//   -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36' \
//   --compressed
Future<Uint8List?> download(String hash) async {
  final uri = Uri.parse('https://itorrents.org/torrent/$hash.torrent');
  await http.get(uri, headers: const {
    'authority': 'itorrents.org',
    'accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'accept-language':
        'q=0.9,en-US;q=0.8,en;q=0.7,zh-TW;q=0.6,ja-CN;q=0.5,ja;q=0.4',
    'cache-control': 'max-age=0',
    'dnt': '1',
    'referer': 'https://magnet2torrent.com/',
    'sec-ch-ua':
        '"Not.A/Brand";v="8", "Chromium";v="114", "Google Chrome";v="114"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"macOS"',
    'sec-fetch-dest': 'document',
    'sec-fetch-mode': 'navigate',
    'sec-fetch-site': 'cross-site',
    'sec-fetch-user': '?1',
    'upgrade-insecure-requests': '1',
    'user-agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36',
  });
  return null;
}
