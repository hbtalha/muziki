import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:muziki/models/song.dart';
import 'package:muziki/screens/settings/folders_to_scan_settings_screen.dart';
import 'package:muziki/services/audio_player_handler.dart';
import 'package:muziki/utils/colors.dart';
import 'package:muziki/utils/utils.dart';
import 'package:settings_ui/settings_ui.dart';

class SongsLibraryAndTagSettingsScrren extends StatefulWidget {
  const SongsLibraryAndTagSettingsScrren({Key? key}) : super(key: key);

  @override
  State<SongsLibraryAndTagSettingsScrren> createState() => _SongsLibraryAndTagSettingsScrrenState();
}

class _SongsLibraryAndTagSettingsScrrenState extends State<SongsLibraryAndTagSettingsScrren> {
  List<String> initialFolders = [];
  bool isIsolateRunning = false;
  bool isScanning = false;
  bool canCancelScanning = false;
  int numberOffilesFound = 0;
  String currentFolderBeingAdded = '';
  ReceivePort receivePort = ReceivePort();
  FlutterIsolate? isolate;
  AudioPlayerHandler audioPlayerHandler = GetIt.I<AudioPlayerHandler>();

  Future<void> scan(List<String> folders, {bool forceScan = false}) async {
    numberOffilesFound = 0;
    currentFolderBeingAdded = 'Listing files...';
    if ((listEqualsInElementsValuesContained(folders, initialFolders) == false) || forceScan) {
      if (!forceScan) {
        await Hive.box('settings').put('foldersToScan', folders);
      }
      if (isIsolateRunning) {
        // TODO: show toast
        return;
      }

      isScanning = true;
      setState(() {});

      if (folders.isNotEmpty) {
        isIsolateRunning = true;
        try {
          isolate = await FlutterIsolate.spawn(scanSongs, [folders, receivePort.sendPort]);
        } finally {
          isIsolateRunning = false;
        }
      } else {
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            isScanning = false;
            audioPlayerHandler.refreshSongsFromScannedFolder([]);
          });
        });
      }
    }
  }

  getFolders() {
    initialFolders.clear();
    var folders = Hive.box('settings').get('foldersToScan', defaultValue: <String>[]);
    if (folders != null) {
      initialFolders.addAll(folders);
    }
  }

  @override
  void initState() {
    super.initState();

    getFolders();

    receivePort.listen((data) {
      numberOffilesFound = data[0];

      String folderPath = data[1];
      if (folderPath.isNotEmpty) {
        folderPath = folderPath.substring(0, folderPath.lastIndexOf('/'));
        currentFolderBeingAdded = shortenPath(folderPath);
      }

      if (data[4] == true) {
        numberOffilesFound = 0;
        currentFolderBeingAdded = "Updating library";
      }

      if (data[2] == true) {
        var songsInJSon = data[3];
        List<Song> songs = [];
        for (var song in songsInJSon) {
          songs.add(Song.fromJson(Map<String, dynamic>.from(song)));
        }

        isolate?.kill();
        isScanning = false;

        audioPlayerHandler.refreshSongsFromScannedFolder(songs);
      }

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return !isScanning;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.grey[800],
          title: const Text('Songs library and tag'),
        ),
        body: Stack(
          children: [
            SettingsList(
              darkTheme: const SettingsThemeData(settingsListBackground: backgroundColor),
              sections: [
                SettingsSection(
                  margin: const EdgeInsetsDirectional.only(start: 1000),
                  title: const Text(
                    'Song Libray',
                    style: TextStyle(fontSize: 13, color: Colors.blue),
                  ),
                  tiles: [
                    SettingsTile(
                      leading: const SizedBox(width: 20),
                      title: const Text(
                        'Folders to scan',
                        style: TextStyle(fontSize: 18),
                      ),
                      onPressed: (context) {
                        getFolders();
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                                builder: (context) => FolderToScanScreen(
                                      folders: initialFolders,
                                    )))
                            .then(
                          (folders) async {
                            Future.delayed(const Duration(seconds: 1), () async {
                              canCancelScanning = false;
                              await scan(folders ?? <String>[]);
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
                SettingsSection(
                  title: const Text(
                    'Scan',
                    style: TextStyle(fontSize: 13, color: Colors.blue),
                  ),
                  tiles: [
                    SettingsTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text(
                        'Scan',
                        style: TextStyle(fontSize: 18),
                      ),
                      onPressed: (context) async {
                        canCancelScanning = true;
                        getFolders();
                        await scan(initialFolders, forceScan: true);
                      },
                    )
                  ],
                )
              ],
            ),
            if (isScanning)
              AlertDialog(
                contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
                title: const Text('Scan'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LinearProgressIndicator(),
                      const SizedBox(height: 5),
                      Text(
                        numberOffilesFound == 0 ? '' : '$numberOffilesFound audio files found',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        currentFolderBeingAdded,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          if (canCancelScanning)
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                              onPressed: () {
                                if (isolate == null) {
                                  print('isNull');
                                } else {
                                  print('NotNull');
                                }

                                isolate?.kill();

                                setState(() {
                                  isScanning = false;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                          const Spacer(),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                            onPressed: () {
                              setState(() {
                                isScanning = false;
                              });
                            },
                            child: const Text('CONTINUE N BACKGROUND'),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // var a = getALbumsAndArtits(audioPlayerHandler.allSongs);
            // var cachedSongs =
            //     Hive.box('playlists').get('allSongs', defaultValue: []);
            // print('Length: ${audioPlayerHandler.albums.length}');
            // print('HowMany: ${audioPlayerHandler.songs.length}');
            // print('HowMany: ${initialFolders.length}');
          },
          child: const Icon(Icons.check),
        ),
      ),
    );
  }
}
