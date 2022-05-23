import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:muziki/models/album.dart';
import 'package:muziki/models/artist.dart';
import 'package:muziki/models/song.dart';
import 'package:muziki/utils/global_variables.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_android/path_provider_android.dart';

String lastInPath(String path) {
  if (path.isEmpty) {
    return '';
  }
  return path.substring(path.lastIndexOf('/') + 1, path.length);
}

String shortenPath(String path) {
  if (path.isEmpty) return '';
  String folder = lastInPath(path);
  return path.startsWith('/storage/emulated/') ? 'Internal Storage > $folder' : 'SD card > $folder';
}

String formattedDuration(Duration duration) {
  String dur = duration.toString();
  return dur.substring(duration.inHours > 0 ? 0 : dur.indexOf(':') + 1, dur.lastIndexOf('.'));
}

int? parseInteger(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  } else if (value is String) {
    try {
      try {
        return int.parse(value);
      } catch (_) {
        return int.parse(value.split('/').first);
      }
    } catch (_) {}
  }
  return null;
}

bool isSupported(String filePath) {
  List<String> supported = ['.mp3', '.m4a', '.ogg'];
  for (var element in supported) {
    if (filePath.endsWith(element)) {
      return true;
    }
  }

  return false;
}

/// check if the two list contain the same elements disregarding the order
bool listEqualsInElementsValuesContained(List<dynamic>? list1, List<dynamic>? list2) {
  if (list1 == null && list2 == null) {
    return true;
  }

  if (list1 != null && list2 == null) {
    return false;
  }

  if (list1 == null && list2 != null) {
    return false;
  }

  if (list1?.length != list2?.length) return false;

  for (var e in list1!) {
    if (!list2!.contains(e)) return false;
  }

  return true;
}

Duration totalDuration(List<Song> songs) {
  var allDurations = songs.map((e) => Duration(milliseconds: e.trackDuration ?? 0)).toList();
  return allDurations.fold(const Duration(seconds: 0), (previousValue, element) => previousValue + element);
}

Future<String?> getLyrics({String? artist, String? titke}) async {
  String res = '';
  try {
    var http;
    String getResponse = (await http.get(Uri.parse(Uri.encodeFull(
            'http://api.genius.com/search?q=no love eminem&access_token=0dNqRey5zXDXXTr7f4-ekhWIT2J11CAy36nA8i1Lp737byx2m-jQgK-RjmdYaybd'))))
        .body;

    Map<String, dynamic> json = jsonDecode(getResponse);

    String url = (json['response']['hits'][0]['result']['url']);

    getResponse = (await http.get(Uri.parse(Uri.encodeFull(url)))).body;

    BeautifulSoup bs = BeautifulSoup(getResponse.replaceAll('<br/>', '\n'));

    String? lyrics = bs.find("div", class_: "Lyrics__Root")?.getText() ?? bs.find("div", class_: "lyrics")?.getText();

    return lyrics?.trim();
  } catch (e) {
    res = 'Error: ${e.toString()}';
  }

  return res;
}

Map<String, dynamic> metadataToJson(Metadata metadata) {
  Map<String, dynamic> song = {};
  song.addAll(metadata.toJson());
  song.addAll({"albumArt": metadata.albumArt});
  return song;
}

Future<void> scanSongs(List<Object> args) async {
  PathProviderAndroid.registerWith();
  Directory dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  await Hive.openBox('playlists');

  List<String> folders = args[0] as List<String>;
  SendPort sendPort = args[1] as SendPort;
  List<Map<String, dynamic>> songsInJson = [];

  int filesFound = 0;
  for (var folder in folders) {
    final dir = Directory(folder);
    List<FileSystemEntity> enitities = dir.listSync(recursive: true);
    for (var entity in enitities) {
      if (await entity.exists() && isSupported(entity.path)) {
        File file = File(entity.path);

        if (await file.length() != 0) {
          sendPort.send([++filesFound, file.path, false, <Map<String, dynamic>>[], false]);

          songsInJson.add((metadataToJson(await MetadataRetriever.fromFile(file))));
        }
      }
    }
  }

  sendPort.send([++filesFound, '', false, <Map<String, dynamic>>[], true]);

  await Hive.box('playlists').put('allSongs', songsInJson);

  sendPort.send([filesFound, '', true, songsInJson, true]);
}

// ------ album songs as list of int ---------------------- //
List getALbumsAndArtitsI(List<Song> songs) {
  List<AArtist> artists = [];
  List<AAlbum> albums = [];
  Set<String> artistsNames = {};
  Set<String> albumsNames = {};

  for (int i = 0; i < songs.length; ++i) {
    artistsNames.add(songs[i].albumArtistName ?? '<unknown>');
  }

  artists.addAll(artistsNames.map((e) => AArtist(name: e)).toList());

  for (var artist in artists) {
    var artistSongs = songs.where((element) => element.albumArtistName == artist.name);
    artist.songs.addAll(artistSongs.map((e) => songs.indexOf(e)).toList());
  }

  albumsNames.addAll(songs.map((e) => e.albumName ?? '<unknown>').toList());

  albums.addAll(albumsNames.map((e) => AAlbum(albumName: e)).toList());

  for (var artistName in artistsNames) {
    for (var album in albums) {
      List<Song> albumSongs = songs.where((song) => song.albumName == album.albumName && song.albumArtistName == artistName) as List<Song>;

      album.songs.addAll(albumSongs.map((e) => songs.indexOf(e)).toList());

      album.artistName ??= artistName;

      if (album.albumArt == null) {
        int? albumArtIndex = album.songs.firstWhere((index) => songs[index!].albumArt != null, orElse: () => null);
        album.albumArt = albumArtIndex == null ? null : songs[albumArtIndex].albumArt;
      }

      if (album.year == null) {
        int? albumYearIndex = album.songs.firstWhere((index) => songs[index!].year != null, orElse: () => null);
        album.year = albumYearIndex == null ? null : (songs[albumYearIndex]).year;
      }

      album.albumlength ??= totalDuration(albumSongs);
      album.artists.addAll(album.songs.map((index) => songs[index!].trackArtistNames?.join('/') ?? '<unknown>').toList());
    }
  }

  return [albums, artists];
}

List getALbumsAndArtits(List<Song> songs) {
  List<Artist> artists = [];
  List<Album> albums = [];
  Set<String> artistsNames = {};
  Set<String> albumsNames = {};

  for (int i = 0; i < songs.length; ++i) {
    artistsNames.add(songs[i].albumArtistName ?? '<unknown>');
  }

  artists.addAll(artistsNames.map((e) => Artist(name: e)).toList());

  for (var artist in artists) {
    artist.songs.addAll(songs.where((element) => element.albumArtistName == artist.name));
  }

  albumsNames.addAll(songs.map((e) => e.albumName ?? '<unknown>').toList());

  albums.addAll(albumsNames.map((e) => Album(albumName: e)).toList());

  for (var artistName in artistsNames) {
    for (var album in albums) {
      album.songs.addAll(songs.where((song) => song.albumName == album.albumName && song.albumArtistName == artistName));

      album.artistName ??= artistName;
      album.albumArt ??= album.songs.firstWhere((song) => song.albumArt != null, orElse: () => Song()).albumArt;
      album.year ??= album.songs.firstWhere((song) => song.year != null, orElse: () => Song()).year;
      album.albumlength ??= totalDuration(album.songs);
      album.artists.addAll(album.songs.map((song) => song.trackArtistNames?.join('/') ?? '<unknown>').toList());
    }
  }

  return [albums, artists];
}

List getALbumsAndArtitsObsolete(List<Song> songs) {
  List<Artist> artists = [];
  List<Album> albums = [];
  Set<String> artistsNames = {};

  for (int i = 0; i < songs.length; ++i) {
    artistsNames.add(songs[i].albumArtistName ?? '<unknown>');
  }

  artists.addAll(artistsNames.map((e) => Artist(name: e)).toList());

  for (int i = 0; i < artists.length; ++i) {
    for (int j = 0; j < songs.length; ++j) {
      if (artists[i].name == songs[j].albumArtistName) {
        artists[i].songs.add(songs[j]);
      }
    }
    Set<String> albumsNames = {};
    for (int k = 0; k < artists[i].songs.length; ++k) {
      albumsNames.add(artists[i].songs[k].albumName ?? '<unknown>');
    }

    for (var element in albumsNames) {
      Album album = Album();
      album.setArtistName = artists[i].name;
      album.setName = element;

      for (int y = 0; y < artists[i].songs.length; ++y) {
        if (element == artists[i].songs[y].albumName) {
          if (album.year == null) {
            if (artists[i].songs[y].year != null) {
              album.setYear = artists[i].songs[y].year;
            }
          }

          if (album.albumArt == null) {
            if (artists[i].songs[y].albumArt != null) {
              album.albumArt = artists[i].songs[y].albumArt;
            }
          }

          album.artists.add(artists[i].songs[y].trackArtistNames?.join('/') ?? "<unknown>");
          album.songs.add(artists[i].songs[y]);
        }
      }

      Duration albumLength = Duration.zero;

      for (var song in album.songs) {
        albumLength += Duration(milliseconds: song.trackDuration ?? 0);
      }

      album.setLength = albumLength;

      albums.add(album);
    }
  }

  return [albums, artists];
}

List<Song> sortedSongs(List<Song> songs, PlaylistSorting playlistSorting, {SortingOrder sortingOrder = SortingOrder.ascending}) {
  List<Song> sortedSongs = List.of(songs);

  if (playlistSorting == PlaylistSorting.randomly) {
    sortedSongs.shuffle();
    return sortedSongs;
  }

  int sort = (sortingOrder == SortingOrder.ascending) ? 1 : -1;

  sortedSongs.sort((songA, songB) {
    var defaultSorting = sort * songA.trackName!.compareTo(songB.trackName!);

    if (playlistSorting == PlaylistSorting.byTitle) {
      return defaultSorting;
    } else if (playlistSorting == PlaylistSorting.byFilename) {
      return sort * songA.filenameWOExt.compareTo(songB.filenameWOExt);
    } else if (playlistSorting == PlaylistSorting.byAlbumm) {
      return sort * songA.albumName!.compareTo(songB.albumName!);
    } else if (playlistSorting == PlaylistSorting.byAlbumArtist) {
      return sort * songA.albumArtistName!.compareTo(songB.albumArtistName!);
    } else if (playlistSorting == PlaylistSorting.byTrackNumber) {
      return sort * songA.trackNumber!.compareTo(songB.trackNumber!);
    } else if (playlistSorting == PlaylistSorting.byDuration) {
      return sort * songA.duration.compareTo(songB.duration);
    } else if (playlistSorting == PlaylistSorting.byYear) {
      return sort * songA.year!.compareTo(songB.year!);
    } else {
      return defaultSorting;
    }
  });

  return sortedSongs;
}

showToast(String msg) {
  Fluttertoast.showToast(
    msg: msg,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 2,
    backgroundColor: Colors.grey[600],
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

showAlertDialogMessage(BuildContext context, String title) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.only(left: 24, right: 490),
          // insetPadding: EdgeInsets.zero,
          title: const Text(''),
          content: Text(title),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      });

  // showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
// insetPadding: const EdgeInsets.symmetric(vertical: 330.0, horizontal: 0),
  //         content: SizedBox(
  //           width: MediaQuery.of(context).size.width - 90,
  //           height: 510,
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 title,
  //                 style: const TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 16,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text("OK"),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(5),
  //         ),
  //       );
  //     });
}
