
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:hive/hive.dart';
import 'package:muziki/models/album.dart';
import 'package:muziki/models/artist.dart';
import 'package:muziki/models/song.dart';
import 'package:muziki/services/just_audio.dart';
import 'package:muziki/utils/global_variables.dart';
import 'package:muziki/utils/utils.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

class ProgressState {
  final Duration current;
  final Duration total;
  final Duration buffered;

  const ProgressState({
    required this.current,
    required this.total,
    required this.buffered,
  });
}

class AudioPlayerHandler {
  final AudioPlayer _player = AudioPlayer();
  late final _playlist = ConcatenatingAudioSource(children: []);
  final BehaviorSubject<List<Album>> _albumsSubject = BehaviorSubject.seeded(<Album>[]);

  final List<Album> _albums = [];
  final List<Artist> _artists = [];
  final List<Song> _allSongs = [];
  List<Song> currentQueue = [];

  Stream<ProgressState> get positionDataStream => Rx.combineLatest3<Duration, Duration, Duration?, ProgressState>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          (position, bufferedPosition, duration) => ProgressState(current: position, buffered: bufferedPosition, total: duration ?? Duration.zero))
      .distinct();

  AudioPlayerHandler() {
    var lastQueueSongs = Hive.box('cache').get('lastQueue', defaultValue: []);

    for (var song in lastQueueSongs) {
      currentQueue.add(Song.fromJson(Map<String, dynamic>.from(song)));
    }

    _init();

    var cachedSongs = Hive.box('playlists').get('allSongs', defaultValue: []);

    for (var song in cachedSongs) {
      _allSongs.add(Song.fromJson(Map<String, dynamic>.from(song)));
    }

    refreshAlbumsAndArtists();
  }

  Future<void> _init() async {
    final AudioSession audioSession = await AudioSession.instance;
    await audioSession.configure(const AudioSessionConfiguration.music());

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _player.stop();
        _player.seek(Duration.zero, index: 0);
      }
    });

    int lastIndex = await Hive.box('cache').get('lastIndex', defaultValue: 0) as int;

    final int lastPos = await Hive.box('cache').get('lastPos', defaultValue: 0) as int;

    await _playlist.addAll(_createPlaylist(currentQueue));
    await _player.setAudioSource(
      _playlist,
      initialIndex: lastIndex,
      initialPosition: Duration(seconds: lastPos),
    );
    _player.setShuffleModeEnabled(true); // a hack so I can control shuffleOrder indices and thus being able to sort the playing playlist as I wish
  }

  void refreshAlbumsAndArtists() {
    _albums.clear();
    _artists.clear();
    final albumsAndArtists = getALbumsAndArtits(_allSongs);
    _albums.addAll(albumsAndArtists[0]);
    _artists.addAll(albumsAndArtists[1]);

    _albumsSubject.add(_albums);
  }

  void refreshSongsFromScannedFolder(List<Song> newSongs) async {
    _allSongs.clear();
    _allSongs.addAll(newSongs);
    refreshAlbumsAndArtists();
    if (_playlist.length == 0) {
      updateQueue(_allSongs);
    }
  }

  AudioSource _createSource(Song song) {
    return AudioSource.uri(
      Uri.file(song.filePath!),
      tag: MediaItem(
        id: const Uuid().v1(),
        album: song.albumName ?? '',
        title: song.trackName ?? '',
        artUri: Uri.file(song.tempAlbumArtPath ?? ''),
        duration: song.trackDuration != null ? Duration(milliseconds: song.trackDuration!) : Duration.zero,
        extras: song.toJson(),
      ),
    );
  }

  List<AudioSource> _createPlaylist(List<Song> songs) => songs.map(_createSource).toList();

  bool get isPlaying => _player.playing;

  Future<void> addToPlayist(Song song) async {
    await _playlist.add(_createSource(song));
  }

  Future<void> addToQueue(List<Song> songs) async {
    await _playlist.addAll(_createPlaylist(songs));
  }

  Future<void> updateQueue(List<Song> songs, {bool autoPlay = false, int index = 0}) async {
    currentQueue.clear();
    currentQueue.addAll(songs);

    _playlist.clear();

    await _playlist.addAll(_createPlaylist(songs));

    if (autoPlay) {
      _player.seek(Duration.zero, index: index);
      play();
    }

    await Hive.box('cache').put('lastQueue', songs.map((e) => e.toJson()).toList());
  }

  Future<void> insertQueueItem(int index, Song song) async {
     await _playlist.insert(index, _createSource(song));
  }

  Future<void> updateMediaItem(MediaItem mediaItem) async {
    // final index = queue.value.indexWhere((item) => item.id == mediaItem.id);
    // _mediaItemExpando[_player.sequence![index]] = mediaItem;
  }

  Future<void> removeQueueItem(MediaItem mediaItem) async {
    await _playlist.removeAt(0);
  }

  Future<void> removeQueueItemAt(int index) async {
    await _playlist.removeAt(index);
  }

  Future<void> clearQueue() async {
    await _playlist.clear();
  }

  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    _player.moveQueueItem(currentIndex, newIndex);
  }

  void sortAlbums({AlbumsSorting sorting = AlbumsSorting.byAlbumArtist, SortingOrder sortingOrder = SortingOrder.ascending}) {
    int sort = (sortingOrder == SortingOrder.ascending) ? 1 : -1;
    _albums.sort((albumA, albumB) {

      var defaultSorting = sort * albumA.artistName!.compareTo(albumB.artistName!);
      if (sorting == AlbumsSorting.byAlbumArtist) {
        return defaultSorting;
      } else if (sorting == AlbumsSorting.byDuration) {
        return sort * albumA.albumlength!.compareTo(albumB.albumlength!);
      } else if (sorting == AlbumsSorting.byYear) {
        return sort * albumA.year!.compareTo(albumB.year!);
      } else if (sorting == AlbumsSorting.byNumberOfSongs) {
        return sort * albumA.songs.length.compareTo(albumB.songs.length);
      } else if (sorting == AlbumsSorting.byName) {
        return sort * albumA.albumName!.compareTo(albumB.albumName!);
      }

      return defaultSorting;
    });

    _albumsSubject.add(_albums);
  }

  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
      //_player.currentIndexSubject.add(_currentIndex);
    } else {
      showToast('End of the current queue reached');
    }
  }

  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      //_player.currentIndexSubject.add(_currentIndex);
    } else {
      showToast('End of the current queue reached');
    }
  }

  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.children.length) return;

    _player.seek(
      Duration.zero,
      // index: _player.shuffleModeEnabled ? _player.shuffleIndices![index] : index,
    );
  }

  Future<void> play() async => await _player.play();

  Future<void> pause() async {
    await _player.pause();
    await Hive.box('cache').put('lastPos', _player.position.inSeconds);
  }

  Future<void> setLoopMode(LoopMode loopMode) async => await _player.setLoopMode(loopMode);

  Future<void> shuffle() async => await _player.shuffle();

  Future<void> seek(Duration duration, {int? index}) async => await _player.seek(duration, index: index);

  Future<void> setVolume(double volume) async => await _player.setVolume(volume);

  Song? get currentSong {
    var metadata = _player.sequenceState?.currentSource?.tag;

    if (metadata != null) {
      return Song.fromJson((metadata as MediaItem).extras!);
    }

    return null;
  }

  List<Song> get songs => _allSongs;
  List<Album> get albums => _albums;
  List<Artist> get artists => _artists;

  Duration get position => _player.position;

  int? get currentIndex => _player.currentIndex;

  List<int>? get indices => _player.effectiveIndices;

  List<IndexedAudioSource>? get sequence => _player.sequence;

  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream.distinct();

  Stream<PlayerState> get playerStateStream => _player.playerStateStream.distinct();

  Stream<LoopMode> get loopModeStream => _player.loopModeStream;

  Stream<bool> get shuffleEnabledStream => _player.shuffleModeEnabledStream;

  Stream<List<Album>> get albumsStream => _albumsSubject.stream;

  void test() {
    refreshSongsFromScannedFolder(List.of(_allSongs));
    
     _player.sort(currentQueue, PlaylistSorting.byDuration);

    // print('--------------Effective Indices----------');
    // for (var i in _player.effectiveIndices!) {
    //   print('$i - ${_player.sequence![i].tag.title}');
    // }
    // print('--------------Shuffle Indices----------');
    // for (var i in _player.shuffleIndices!) {
    //   print('$i - ${_player.sequence![i].tag.title}');
    // }
  }
}
