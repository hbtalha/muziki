import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:muziki/screens/albums_screen.dart';
import 'package:muziki/screens/artists_screen.dart';
import 'package:muziki/screens/playing_screen.dart';
import 'package:muziki/screens/playlists_screen.dart';
import 'package:muziki/screens/queues._screen.dart';
import 'package:muziki/screens/settings/settings_screen.dart';
import 'package:muziki/screens/storage_screen.dart';
import 'package:muziki/services/audio_player_handler.dart';
import 'package:muziki/utils/colors.dart';
import 'package:muziki/utils/global_variables.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  await Hive.openBox('playlists');
  await Hive.openBox('settings');
  await Hive.openBox('cache');
  await initAudioHandler();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.hbatalha.muziki.channel.audio',
    androidNotificationChannelName: 'Muziki',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Muziki',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: backgroundColor),
      home: const MyApp(),
    ),
  );
}

Future<void> initAudioHandler() async {
  AudioPlayerHandler audioPlayer = AudioPlayerHandler();
  GetIt.I.registerSingleton<AudioPlayerHandler>(audioPlayer);
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _index = 1;

  List<Widget> pageViews = [];
  @override
  void initState() {
    super.initState();

    pageViews.addAll([
      QueuesScreen(swipe: swipeScreen, goToScreen: _onPageChanged),
      PlayingScreen(swipe: swipeScreen, goToScreen: _onPageChanged),
      StorageScreen(swipe: swipeScreen, goToScreen: _onPageChanged),
      AlbumsScreen(swipe: swipeScreen, goToScreen: _onPageChanged),
      ArtistsScreen(swipe: swipeScreen, goToScreen: _onPageChanged),
      PlaylistsScreen(swipe: swipeScreen, goToScreen: _onPageChanged),
    ]);
  }

  void _onPageChanged(int index) {
    setState(() {
      _index = index;
    });
  }

  void swipeScreen({required SwipeDirection direction}) {
    if (direction == SwipeDirection.left) {
      if (_index - 1 >= 0) {
        _onPageChanged(_index - 1);
      }
    } else if (direction == SwipeDirection.right) {
      if (_index + 1 <= 5) {
        _onPageChanged(_index + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: IndexedStack(
          children: pageViews,
          index: _index,
        ),
        bottomNavigationBar: CupertinoTabBar(
          onTap: _onPageChanged,
          backgroundColor: Colors.grey[900],
          activeColor: primaryColor,
          inactiveColor: secondaryColor,
          iconSize: 25,
          height: 45,
          currentIndex: _index,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.queue_music), tooltip: "Queues", label: ''),
            const BottomNavigationBarItem(icon: Icon(Icons.play_circle), tooltip: "Now Playing", label: ''),
            const BottomNavigationBarItem(icon: Icon(Icons.folder), tooltip: "Storage", label: ''),
            const BottomNavigationBarItem(icon: Icon(Icons.album), tooltip: "Albums", label: ''),
            const BottomNavigationBarItem(icon: Icon(Icons.person), tooltip: "Artists", label: ''),
            const BottomNavigationBarItem(icon: Icon(Icons.library_music), tooltip: "Playlists", label: ''),
            BottomNavigationBarItem(
              icon: PopupMenuButton(
                  offset: const Offset(0, -112),
                  icon: const Icon(
                    Icons.more_vert_rounded,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  ),
                  onSelected: (var value) async {
                    if (value == 'settings') {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
                    }
                    if (value == 'scan') {}
                  },
                  itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'scan',
                          child: Row(
                            children: [
                              Icon(
                                Icons.refresh,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              const SizedBox(width: 10.0),
                              const Text('Scan'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(
                                Icons.settings,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              const SizedBox(width: 10.0),
                              const Text('Settings'),
                            ],
                          ),
                        ),
                      ]),
            ),
          ],
        ),
      ),
    );
  }
}
