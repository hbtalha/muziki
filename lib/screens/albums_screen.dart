import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:muziki/models/album.dart';
import 'package:muziki/models/song.dart';
import 'package:muziki/services/audio_player_handler.dart';
import 'package:muziki/utils/colors.dart';
import 'package:muziki/utils/global_variables.dart';
import 'package:muziki/utils/utils.dart';
import 'package:muziki/widgets/playlist_head.dart';
import 'package:muziki/widgets/widgets.dart';

class AlbumsScreen extends StatefulWidget {
  final Function({required SwipeDirection direction}) swipe;
  final Function(int screenIndex) goToScreen;
  const AlbumsScreen({Key? key, required this.swipe, required this.goToScreen}) : super(key: key);

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> {
  int _index = 0;
  double offset = 0;
  AudioPlayerHandler audioPlayer = GetIt.I<AudioPlayerHandler>();

  void backToAlbumsView() {
    setState(() {
      _index = 0;
    });
  }

  void playSong(int index, List<Song> songs) {
    audioPlayer.updateQueue(songs, autoPlay: true, index: index);
    widget.goToScreen(1);
  }

  void goToAlbum(Album album, double offst) {
    offset = offst;
    pages[1] = AlbumView(
      album: album,
      backToAlbumsView: backToAlbumsView,
      playSong: playSong,
    );
    setState(() {
      _index = 1;
    });
  }

  List<Widget> pages = [];

  @override
  void initState() {
    super.initState();
    pages.add(allAlbumsView(callback: goToAlbum, player: audioPlayer, offset: offset));
    pages.add(widget);
    BackButtonInterceptor.add(handleBackButton);
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(handleBackButton);
    super.dispose();
  }

  bool handleBackButton(bool stopDefaultButtonEvent, RouteInfo info) {
    if (_index == 1) {
      setState(() {
        _index = 0;
      });
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    pages[0] = allAlbumsView(callback: goToAlbum, player: audioPlayer, offset: offset);

    return GestureDetector(
      onHorizontalDragEnd: (dragEndDetails) {
        if (dragEndDetails.primaryVelocity != null && dragEndDetails.primaryVelocity! < 0) {
          widget.swipe(direction: SwipeDirection.right);
        } else if (dragEndDetails.primaryVelocity != null && dragEndDetails.primaryVelocity! > 0) {
          widget.swipe(direction: SwipeDirection.left);
        }
      },
      child: pages[_index],
    );
  }
}

Widget allAlbumsView({required AudioPlayerHandler player, required Function(Album album, double offset) callback, required double offset}) {
  ScrollController scrollController = ScrollController(initialScrollOffset: offset);
  return Scaffold(
    appBar: AppBar(
      shadowColor: Colors.grey,
      elevation: .8,
      backgroundColor: backgroundColor,
      title: TextButton(
        onPressed: () {},
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.search),
            Text('  Search an album...'),
          ],
        ),
      ),
    ),
    body: Padding(
        padding: const EdgeInsets.all(5),
        child: StreamBuilder<List<Album>>(
          stream: player.albumsStream,
          builder: (context, snapshot) {
            List<Album> albums = player.albums;
            var data = snapshot.data;
            if (data != null) {
              albums = data;
            }
            return GridView.builder(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: albums.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
                mainAxisExtent: 175,
              ),
              itemBuilder: (context, index) {
                return Card(
                  clipBehavior: Clip.antiAlias,
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: const BorderSide(color: Colors.white38, width: 1),
                  ),
                  child: InkWell(
                    onTap: () => callback(albums[index], scrollController.offset),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (albums[index].albumArt != null)
                          Image(
                            fit: BoxFit.cover,
                            image: MemoryImage(albums[index].albumArt!),
                            height: 130,
                            width: 80,
                            errorBuilder: (_, __, ___) {
                              return Image.asset(
                                'assets/cover.jpg',
                                fit: BoxFit.cover,
                                height: 130,
                                width: 80,
                              );
                            },
                          )
                        else
                          Image.asset(
                            'assets/cover.jpg',
                            fit: BoxFit.cover,
                            height: 130,
                            width: 80,
                          ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            albums[index].albumName ?? '<unknown>',
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            '${albums[index].artistName}',
                            style: const TextStyle(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        )),
  );
}

class AlbumView extends StatefulWidget {
  final Album album;
  final void Function() backToAlbumsView;
  final void Function(int, List<Song>) playSong;
  const AlbumView({Key? key, required this.album, required this.backToAlbumsView, required this.playSong}) : super(key: key);

  @override
  State<AlbumView> createState() => _AlbumViewState();
}

class _AlbumViewState extends State<AlbumView> {
  final ScrollController _scrollController = ScrollController();
  AudioPlayerHandler audioPlayer = GetIt.I<AudioPlayerHandler>();
  String dropdownValue = 'Artists';
  List<bool> enabledCards = [];
  List<Song> songs = [];
  List<String> albumArtists = [];
  int albumArtistsNum = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    albumArtistsNum = widget.album.artists.length;
    enabledCards.addAll(List.generate(albumArtistsNum > 1 ? albumArtistsNum + 1 : albumArtistsNum, (index) => true));

    songs.addAll(getSongsFromIndices(audioPlayer.songs, widget.album.songs));
    albumArtists.addAll(widget.album.artists.toList());
  }

  void filterSongs() {
    songs.clear();
    for (var song in widget.album.songs) {
      if (audioPlayer.songs[song!].trackArtistNames != null) {
        int index = albumArtists.indexOf(audioPlayer.songs[song].trackArtistNames!.join('/'));
        if (index != -1) {
          if (enabledCards[albumArtistsNum > 1 ? index + 1 : index]) {
            songs.add(audioPlayer.songs[song]);
          }
        }
      }
    }
  }

  void toggleAllCards(int i) {
    bool enable = enabledCards[i];
    int length = enabledCards.length;
    enabledCards.clear();
    enabledCards.addAll(List.generate(length, (index) => enable));
  }

  @override
  Widget build(BuildContext context) {
    bool showArtists = (dropdownValue == 'Artists');
    int enabledCardsNumber =
        albumArtistsNum > 1 ? enabledCards.where((item) => item == true).length - 1 : enabledCards.where((item) => item == true).length;
    if (enabledCardsNumber < 0) enabledCardsNumber = 0;

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 0,
                backgroundColor: Colors.transparent,
                elevation: 0,
                toolbarHeight: 240,
                automaticallyImplyLeading: false,
                flexibleSpace: LayoutBuilder(
                  builder: (
                    BuildContext context,
                    BoxConstraints constraints,
                  ) {
                    return FlexibleSpaceBar(
                      background: GestureDetector(
                        onTap: () async {},
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                BackButton(onPressed: () => widget.backToAlbumsView()),
                                Text(
                                  widget.album.albumName!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.settings),
                                  iconSize: 20,
                                )
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 15.0, right: 10),
                              child: DropdownButton(
                                isDense: true,
                                value: dropdownValue,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Theme.of(context).textTheme.bodyText1!.color,
                                ),
                                underline: const SizedBox(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      dropdownValue = newValue;
                                    });
                                  }
                                },
                                items: <String>['Artists', 'Album-Artists'].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 15.0),
                              child: SizedBox(
                                height: 90,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: showArtists
                                        ? albumArtistsNum > 1
                                            ? albumArtistsNum + 1
                                            : albumArtistsNum
                                        : 1,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (context, index) {
                                      String artists = '';

                                      if (showArtists) {
                                        artists = widget.album.artists.elementAt(albumArtistsNum > 1
                                            ? index == 0
                                                ? index
                                                : index - 1
                                            : index);
                                        if (artists.length > 25) {
                                          artists = artists.substring(0, 25);
                                        }
                                      }

                                      return Card(
                                        clipBehavior: Clip.antiAlias,
                                        color: backgroundColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                          side: const BorderSide(color: Colors.white38, width: 1),
                                        ),
                                        child: SizedBox(
                                          height: 90,
                                          width: 80,
                                          child: InkWell(
                                            onTap: () {
                                              enabledCards[index] = !enabledCards[index];
                                              if (index == 0) {
                                                toggleAllCards(0);
                                              }
                                              filterSongs();
                                              setState(() {});
                                            },
                                            onLongPress: () {
                                              if (albumArtists.length == 1) {
                                                if (enabledCards[index] == false) {
                                                  enabledCards[index] = true;
                                                  toggleAllCards(0);
                                                }
                                              } else if (albumArtists.length > 1 && index == 0) {
                                                enabledCards[index] = !enabledCards[index];
                                                toggleAllCards(0);
                                              } else {
                                                enabledCards[index] = true;
                                                for (int i = 0; i < enabledCards.length; ++i) {
                                                  if (i != index) {
                                                    enabledCards[i] = false;
                                                  }
                                                }
                                              }
                                              filterSongs();
                                              setState(() {});
                                            },
                                            highlightColor: Colors.blue.withOpacity(.4),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 30),
                                                  child: Text(
                                                    showArtists
                                                        ? albumArtistsNum > 1
                                                            ? index == 0
                                                                ? 'All Artists'
                                                                : artists
                                                            : widget.album.artists.elementAt(index)
                                                        : widget.album.artistName!,
                                                    style: TextStyle(fontSize: 13, color: enabledCards[index] ? Colors.blue : Colors.grey),
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 10, right: 10),
                                                  child: Divider(
                                                    thickness: 2,
                                                    color: enabledCards[index] ? Colors.blue : Colors.grey,
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 15, top: 10),
                              child: Text(
                                showArtists ? '$enabledCardsNumber/$albumArtistsNum artists' : '1/1 album-artists',
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 15, top: 10),
                              child: Row(
                                children: [
                                  Text(
                                    '${songs.length} songs',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.timer_sharp,
                                    size: 15,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    formattedDuration(totalDuration(songs)),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider()
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SliverAppBar(
                titleSpacing: 0.0,
                centerTitle: false,
                shadowColor: Colors.grey,
                automaticallyImplyLeading: false,
                pinned: true,
                backgroundColor: backgroundColor,
                elevation: 1,
                stretch: true,
                toolbarHeight: 40,
                title: AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, child) {
                    return PlaylistHead(
                        onMoreButtonPressed: () {},
                        onShuffleButtonPressed: () {},
                        onSortButtonPressed: () {},
                        onBackButtonPressed: () => widget.backToAlbumsView(),
                        textNextToBackButton: widget.album.albumName!,
                        showBackButton: (!_scrollController.hasClients || _scrollController.offset > 224) ? true : false);
                  },
                ),
              ),
            ];
          },
          body: songsListView(
            songsOnDisplay: songs,
            allSongs: widget.album.songs,
            onTap: (index) {
              widget.playSong(index, songs);
            },
            audioPlayer: audioPlayer,
          ),
        ),
      ),
    );
  }
}
