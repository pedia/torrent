String regular(String seg) {
  const reservedNames = [
    'con', 'prn', 'aux', 'clock\$', 'nul', //
    'com0', 'com1', 'com2', 'com3', 'com4',
    'com5', 'com6', 'com7', 'com8', 'com9',
    'lpt0', 'lpt1', 'lpt2', 'lpt3', 'lpt4',
    'lpt5', 'lpt6', 'lpt7', 'lpt8', 'lpt9',
    '..', '.'
  ];

  if (reservedNames.contains(seg)) {
    return '';
  }

  final a = seg.codeUnits.where((c) => c > 33 && c < 127).toList();
  return String.fromCharCodes(a);
}

String sanitizePath(String path) {
  return path
      .replaceAll('\\', '/')
      .split('/')
      .map((x) => regular(x))
      .where((x) => x.isNotEmpty)
      .toList()
      .join('/');
}

///
String? sanitizeUrl(String? url) {
  return url?.trim();
}
