import 'dart:typed_data';

import 'package:muziki/utils/utils.dart';

class Album {
  String? albumName;
  String? artistName;
  Duration? albumlength;
  int? year;
  Uint8List? albumArt;
  List<int?> songs = [];
  Set<String> artists = {};

  Album({this.albumName});

  String get length => formattedDuration(albumlength ?? Duration.zero);

  set setYear(int? v) {
    year = v;
  }

  set setName(String album) {
    albumName = album;
  }

  set setArtistName(String? v) {
    artistName = v;
  }

  set setAbumArt(Uint8List? v) {
    albumArt = v;
  }

  set setLength(Duration? v) {
    albumlength = v;
  }
}
