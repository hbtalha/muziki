import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:muziki/models/artist.dart';
import 'package:muziki/models/song.dart';
import 'package:muziki/services/audio_player_handler.dart';
import 'package:muziki/utils/colors.dart';
import 'package:muziki/utils/global_variables.dart';
import 'package:muziki/utils/utils.dart';
import 'package:muziki/widgets/playlist_head.dart';
import 'package:muziki/widgets/widgets.dart';

enum Page { artists, albumArtists, genre }

class ArtistsScreen extends StatefulWidget {
  final Function({required SwipeDirection direction}) swipe;
  final Function(int screenIndex) goToScreen;
  const ArtistsScreen({Key? key, required this.swipe, required this.goToScreen}) : super(key: key);

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
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

  void goToAlbum(Artist artist, double offst) {
    offset = offst;
    pages[1] = ArtistSongsView(
      artist: artist,
      backToFirstView: backToAlbumsView,
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
    pages.add(FirstView(callback: goToAlbum, offset: offset));
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
    pages[0] = FirstView(callback: goToAlbum, offset: offset);

    return SafeArea(
      child: GestureDetector(
        onHorizontalDragEnd: (dragEndDetails) {
          if (dragEndDetails.primaryVelocity != null && dragEndDetails.primaryVelocity! < 0) {
            widget.swipe(direction: SwipeDirection.right);
          } else if (dragEndDetails.primaryVelocity != null && dragEndDetails.primaryVelocity! > 0) {
            widget.swipe(direction: SwipeDirection.left);
          }
        },
        child: pages[_index],
      ),
    );
  }
}

class FirstView extends StatefulWidget {
  final double offset;
  final Function(Artist artist, double offset) callback;
  const FirstView({Key? key, required this.callback, required this.offset}) : super(key: key);

  @override
  State<FirstView> createState() => _FirstViewState();
}

class _FirstViewState extends State<FirstView> {
  Page _page = Page.albumArtists;
  late ScrollController scrollController;
  AudioPlayerHandler audioPlayer = GetIt.I<AudioPlayerHandler>();

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController(initialScrollOffset: widget.offset);
  }

  void setPage(Page page) {
    setState(() {
      _page = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 130,
        backgroundColor: backgroundColor,
        centerTitle: false,
        title: Column(
          children: [
            Row(
              children: [
                circularTextButton(
                  text: Text(
                    "Artists",
                    style: TextStyle(
                      fontSize: 18,
                      color: _page == Page.artists ? blueColor : secondaryColor,
                    ),
                  ),
                  onPressed: () => setPage(Page.artists),
                  borderColor: _page == Page.artists ? blueColor : Colors.white70,
                ),
                const SizedBox(width: 5),
                circularTextButton(
                  text: Text("Album-Artists",
                      style: TextStyle(
                        fontSize: 18,
                        color: _page == Page.albumArtists ? blueColor : secondaryColor,
                      )),
                  onPressed: () => setPage(Page.albumArtists),
                  borderColor: _page == Page.albumArtists ? blueColor : Colors.white70,
                ),
                const SizedBox(width: 5),
                circularTextButton(
                  text: Text("Genre",
                      style: TextStyle(
                        fontSize: 18,
                        color: _page == Page.genre ? blueColor : secondaryColor,
                      )),
                  onPressed: () => setPage(Page.genre),
                  borderColor: _page == Page.genre ? blueColor : Colors.white70,
                ),
                const SizedBox(width: 5),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: const [
                          Icon(Icons.search),
                          Text(
                            '  Search an album...',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.sort),
                  iconSize: 25.0,
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.settings),
                  iconSize: 25.0,
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
      body: StreamBuilder<List<Artist>>(
        stream: audioPlayer.artistsStream,
        builder: (context, snapshot) {
          List<Artist> artists = audioPlayer.artists;
          var data = snapshot.data;
          if (data != null) {
            artists = data;
          }
          return ListView.builder(
              controller: scrollController,
              itemCount: artists.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  onTap: () => widget.callback(artists[index], scrollController.offset),
                  visualDensity: const VisualDensity(vertical: -3),
                  dense: true,
                  title: Text(artists[index].name,
                      style: const TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                      )),
                  subtitle: Text(
                    '${artists[index].songs.length} songs',
                    style: const TextStyle(
                      color: secondaryColor,
                      fontSize: 12,
                    ),
                  ),
                );
              });
        },
      ),
    );
  }
}

class ArtistSongsView extends StatefulWidget {
  final Artist artist;
  final void Function() backToFirstView;
  final void Function(int, List<Song>) playSong;
  const ArtistSongsView({Key? key, required this.artist, required this.backToFirstView, required this.playSong}) : super(key: key);

  @override
  State<ArtistSongsView> createState() => _ArtistSongsViewState();
}

class _ArtistSongsViewState extends State<ArtistSongsView> {
  final ScrollController _scrollController = ScrollController();
  AudioPlayerHandler audioPlayer = GetIt.I<AudioPlayerHandler>();
  List<bool> enabledCards = [];
  List<Song> songs = [];
  Set<String?> albumsSet = {};
  List<String?> albums = [];
  int albumsNum = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    songs.addAll(getSongsFromIndices(audioPlayer.songs, widget.artist.songs));
    albumsSet.addAll(songs.map((e) => e.albumName).toList());
    albums.addAll(albumsSet.toList());
    albumsNum = albums.length;

    enabledCards.addAll(List.generate(albumsNum > 1 ? albumsNum + 1 : albumsNum, (index) => true));
  }

  void filterSongs() {
    songs.clear();

    for (var song in widget.artist.songs) {
      if (audioPlayer.songs[song].albumName != null) {
        int index = albums.indexOf(audioPlayer.songs[song].albumName);
        if (index != -1) {
          if (enabledCards[albumsNum > 1 ? index + 1 : index]) {
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
    int enabledCardsNumber =
        albumsNum > 1 ? enabledCards.where((item) => item == true).length - 1 : enabledCards.where((item) => item == true).length;
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
                toolbarHeight: 190,
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
                                BackButton(onPressed: () => widget.backToFirstView()),
                                Text(
                                  widget.artist.name,
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
                              padding: const EdgeInsets.only(left: 15.0),
                              child: SizedBox(
                                height: 90,
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: albumsNum > 1 ? albumsNum + 1 : albumsNum,
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (context, index) {
                                      String? album = albums.elementAt(albumsNum > 1
                                              ? index == 0
                                                  ? index
                                                  : index - 1
                                              : index) ??
                                          "unknown";
                                      if (album.length > 25) {
                                        album = album.substring(0, 25);
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
                                              if (albums.length == 1) {
                                                if (enabledCards[index] == false) {
                                                  enabledCards[index] = true;
                                                  toggleAllCards(0);
                                                }
                                              } else if (albums.length > 1 && index == 0) {
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
                                                    albumsNum > 1
                                                        ? index == 0
                                                            ? 'All Albums'
                                                            : album
                                                        : album,
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
                      onBackButtonPressed: () => widget.backToFirstView(),
                      textNextToBackButton: widget.artist.name,
                      showBackButton: (!_scrollController.hasClients || _scrollController.offset > 224) ? true : false,
                    );
                  },
                ),
              ),
            ];
          },
          body: songsListView(
            songsOnDisplay: songs,
            allSongs: widget.artist.songs,
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
