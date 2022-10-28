enum ErrorCode {
  invalidBencoding,
  noFilesInTorrent,
  tooManyPiecesInTorrent,

  /// the torrent file has an unknown meta version
  torrentUnknownVersion,
  torrentFileParseFailed,
  torrentInconsistentFiles,
  torrentInvalidHashes,
  torrentInvalidLength,
  torrentInvalidName,
  torrentInvalidPadFile,
  torrentInvalidPieceLayer,
  torrentIsNoDict,
  torrentInfoNoDict,
  torrentMissingInfo,
  torrentMissingName,
  torrentMissingPieceLength,
  torrentMissingPieces,
  torrentMissingPiecesRoot,
  torrentMissingFileTree,

  /// The URL used an unknown protocol. Currently ``http`` and
  /// ``https`` (if built with openssl support) are recognized. For
  /// trackers ``udp`` is recognized as well.
  unsupportedUrlProtocol,

  // The peer sent an unknown info-hash
  invalidInfoHash,

  // The specified URI does not contain a valid info-hash
  missingInfoHashInUri,
}

///
class TorrentError extends Error {
  final ErrorCode code;
  TorrentError(this.code);
}
