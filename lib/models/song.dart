import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:muziki/utils/utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class Song {
  /// Name of the track.
  final String? trackName;

  /// Names of the artists performing in the track.
  final List<String>? trackArtistNames;

  /// Name of the album.
  final String? albumName;

  /// Name of the album artist.
  final String? albumArtistName;

  /// Position of track in the album.
  final int? trackNumber;

  /// Number of tracks in the album.
  final int? albumLength;

  /// Year of the track.
  final int? year;

  /// Genre of the track.
  final String? genre;

  /// Author of the track.
  final String? authorName;

  /// Writer of the track.
  final String? writerName;

  /// Number of the disc.
  final int? discNumber;

  /// Mime type.
  final String? mimeType;

  /// Duration of the track in milliseconds.
  final int? trackDuration;

  /// Bitrate of the track.
  final int? bitrate;

  /// [Uint8List] having album art data.
  final Uint8List? albumArt;

  /// File path of the media file. `null` on web.
  final String? filePath;

  Duration get duration => Duration(milliseconds: trackDuration ?? 0);

  String? tempAlbumArtPath;

  String filename = '';

  String filenameWOExt = '';

  Song(
      {this.trackName,
      this.trackArtistNames,
      this.albumName,
      this.albumArtistName,
      this.trackNumber,
      this.albumLength,
      this.year,
      this.genre,
      this.authorName,
      this.writerName,
      this.discNumber,
      this.mimeType,
      this.trackDuration,
      this.bitrate,
      this.albumArt,
      this.filePath}) {
    _createTempAlbumArtPath();
    filename = lastInPath(filePath ?? '');
    if (filename.isNotEmpty) {
      filenameWOExt = filename.substring(0, filename.lastIndexOf('.'));
    }
  }

  void _createTempAlbumArtPath() async {
    final tempDir = await getTemporaryDirectory();
    File file = await File('${tempDir.path}/${const Uuid().v1()}.png').create();
    file.writeAsBytesSync(albumArt ?? []);
    tempAlbumArtPath = file.path;
  }

  factory Song.fromMetadata(Metadata metadata) => Song(
        trackName: metadata.trackName,
        trackArtistNames: metadata.trackArtistNames,
        albumName: metadata.albumName,
        albumArtistName: metadata.albumArtistName,
        trackNumber: parseInteger(metadata.trackNumber),
        albumLength: parseInteger(metadata.albumLength),
        year: parseInteger(metadata.year),
        genre: metadata.genre,
        authorName: metadata.authorName,
        writerName: metadata.writerName,
        discNumber: parseInteger(metadata.discNumber),
        mimeType: metadata.mimeType,
        trackDuration: parseInteger(metadata.trackDuration),
        bitrate: parseInteger(metadata.bitrate),
        albumArt: metadata.albumArt,
        filePath: metadata.filePath,
      );

  factory Song.fromJson(Map<String, dynamic> map) => Song(
        trackName: map['trackName'],
        trackArtistNames: map['trackArtistNames'],
        albumName: map['albumName'],
        albumArtistName: map['albumArtistName'],
        trackNumber: parseInteger(map['trackNumber']),
        albumLength: parseInteger(map['albumLength']),
        year: parseInteger(map['year']),
        genre: map['genre'],
        authorName: map['authorName'],
        writerName: map['writerName'],
        discNumber: parseInteger(map['discNumber']),
        mimeType: map['mimeType'],
        trackDuration: parseInteger(map['trackDuration']),
        bitrate: parseInteger(map['bitrate']),
        albumArt: map['albumArt'],
        filePath: map['filePath'],
      );

  Map<String, dynamic> toJson() => {
        'trackName': trackName,
        'trackArtistNames': trackArtistNames,
        'albumName': albumName,
        'albumArtistName': albumArtistName,
        'trackNumber': trackNumber,
        'albumLength': albumLength,
        'year': year,
        'genre': genre,
        'authorName': authorName,
        'writerName': writerName,
        'discNumber': discNumber,
        'mimeType': mimeType,
        'trackDuration': trackDuration,
        'bitrate': bitrate,
        'albumArt': albumArt,
        'filePath': filePath,
      };

  @override
  String toString() => toJson().toString();
}
