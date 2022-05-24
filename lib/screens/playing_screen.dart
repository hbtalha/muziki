import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:muziki/services/just_audio.dart';
import 'package:muziki/services/just_audio_background.dart';
import 'package:mmoo_lyric/lyric_util.dart';
import 'package:muziki/models/song.dart';
import 'package:muziki/services/audio_player_handler.dart';
import 'package:muziki/utils/colors.dart';
import 'package:muziki/utils/global_variables.dart';
import 'package:muziki/widgets/lyric_page.dart';
import 'package:muziki/widgets/seekBar.dart';
// import 'package:just_audio/just_audio.dart';

class PlayingScreen extends StatefulWidget {
  final Function({required SwipeDirection direction}) swipe;
  final Function(int screenIndex) goToScreen;
  const PlayingScreen({Key? key, required this.swipe, required this.goToScreen}) : super(key: key);

  @override
  State<PlayingScreen> createState() => _PlayingScreenState();
}

class _PlayingScreenState extends State<PlayingScreen> {
  AudioPlayerHandler audioPlayer = GetIt.I<AudioPlayerHandler>();
  FlipCardController flipCardController = FlipCardController();

  ///in seconds
  int lyricsPositionAdjustment = 0;

  @override
  Widget build(BuildContext context) {
    print('Fuck you');
    String songLyc =
        "[00:33.320]Look' if you had one shot' or one opportunity\n[00:42.630]To seize everything you ever wanted…In One moment\n[00:47.840]Would you capture it or just let it slip?\n[00:50.730]\n[00:52.400]His palms are sweaty' knees weak' arms are heavy\n[00:55.200]There's vomit on his sweater already' mom's spaghetti\n[00:58.020]He's nervous' but on the surface he looks calm and ready\n[01:00.779]To drop bombs' but he keeps on forgetting\n[01:03.569]What he wrote down' the whole crowd goes so loud\n[01:06.308]He opens his mouth' but the words won't  come out\n[01:09.069]He's chokin' how everybody's joking now\n[01:11.819]The clock's run out' time's up over' bloah!\n[01:14.748]Snap back to reality' Oh there goes gravity\n[01:17.700]Oh' there goes Rabbit' he choked\n[01:19.650]He's so mad but he won't give up that Easy?\n[01:21.620]No\n[01:22.248]He won't have it he knows his whole back to these ropes\n[01:25.328]It don't matter' he's dope\n[01:26.780]He knows that' but he's broke\n[01:28.430]He's so stagnant he knows\n[01:29.748]When he goes back  to this mobile home' that's when it's\n[01:32.120]Back to the lab again yo\n[01:33.909]this whole rhapsody\n[01:35.120]He better go capture this moment and hope it don't pass him\n[01:37.480]You better lose yourself in the music' the moment\n[01:40.400]You own it' you better never let it go\n[01:43.218]You only get one shot' do not miss your chance to blow\n[01:46.000]This opportunity comes once in a lifetime yo\n[01:48.700]You better lose yourself in the music' the moment\n[01:51.599]You own it' you better never let it go\n[01:54.180]You only get one shot' do not miss your chance to blow\n[01:57.290]This opportunity comes once in a lifetime yo\n[01:59.840]\n[02:00.459]The soul's escaping' through this hole that it's gaping\n[02:03.120]This world is mine for the taking\n[02:05.188]Make me king' as we move toward a' new world order\n[02:08.439]A normal life is borin' but superstardom's close to post-mortem\n[02:12.869]It only grows harder homie grows hotter\n[02:15.849]He blows us all over these hoes is all on him\n[02:18.595]Coast to coast shows, he' s known as the globetrotter\n[02:21.129]Lonely roads, God only knows\n[02:22.687]He' s grown farther from home, he' s no father\n[02:25.256]He goes home and barely knows his own daughter\n[02:28.066]But hold your nose cuz here goes the cold water\n[02:30.837]These hoes don' t want him no mo, he' s cold product\n[02:33.652]They moved on to the next schmoe who flows\n[02:35.964]He nose dove and sold nada\n[02:37.840]So the soap opera is told, it unfolds\n[02:40.646]I suppose it＇s old partner, but the beat goes on\n[02:43.485]Da da dum da dum da da\n[02:44.869]You better lose yourself in the music, the moment\n[02:47.470]You own it, you better never let it go\n[02:49.580]You only get one shot, do not miss your chance to blow\n[02:53.387]This opportunity comes once in a lifetime yo\n[02:56.167]You better lose yourself in the music\n[02:58.924]The moment, you own it, you better never let it go (Go!)\n[03:01.348]You only get one shot, do not miss your chance to blow\n[03:04.260]This opportunity comes once in a lifetime, yo\n[03:07.237]You better…\n[03:07.968]No more games' I'ma change what you call rage\n[03:10.598]Tear this *********in roof off like 2 dogs caged\n[03:12.997]I was playin in the beginnin' the mood all changed\n[03:15.647]I been chewed up and spit out and booed off stage\n[03:18.596]But I kept rhymin and stepped right in  the next cypher\n[03:21.384]Best believe somebody's payin the pied piper\n[03:24.496]All the pain inside amplified by the fact\n[03:27.046]That I can't get by with my 9 to 5\n[03:30.626]And I can't provide the right type of life for my family\n[03:33.657]Cuz man' these goddamn food stamps don't buy diapers\n[03:36.917]And there's no movie' there's no Mekhi Phifer' this is my life\n[03:40.715]And these times are so hard and it's getting even harder\n[03:43.843]Tryna feed and water my seed' plus\n[03:45.947]Teeter totter caught up between being a father and a prima donna\n[03:49.235]Baby mama drama's screaming on her\n[03:51.105]Too much for me to wanna\n[03:52.514]Stay in one spot' another day of monotony's\n[03:54.835]Gotten me to the point' I'm like a snail\n[03:57.054]I've got to formulate a plot or end up in jail or shot\n[04:00.394]Success is my only *********in option' failure's not\n[04:03.973]Mom' I love you' but this trailer's got to go\n[04:06.443]I cannot grow old in Salem's lot\n[04:09.094]So here I go is my shot.\n[04:10.495]Feet fail me not this maybe the only opportunity that I got\n[04:14.054]You better lose yourself in the music' the moment\n[04:17.057]You own it' you better never let it go\n[04:19.523]You only get one shot' do not miss your chance to blow\n[04:22.605]This opportunity comes once in a lifetime yo\n[04:25.187]You better lose yourself in the music' the moment\n[04:28.033]You own it' you better never let it go\n[04:30.605]You only get one shot' do not miss your chance to blow\n[04:33.694]This opportunity comes once in a lifetime yo\n[04:36.264]\n[04:39.041]You can do anything you set your mind to' man\n[04:41.146]\n";

    var lyrics = LyricUtil.formatLyric(songLyc);
    return GestureDetector(
      onHorizontalDragEnd: (dragEndDetails) {
        if (dragEndDetails.primaryVelocity != null && dragEndDetails.primaryVelocity! < 0) {
          widget.swipe(direction: SwipeDirection.right);
        } else if (dragEndDetails.primaryVelocity != null && dragEndDetails.primaryVelocity! > 0) {
          widget.swipe(direction: SwipeDirection.left);
        }
      },
      child: Scaffold(
        appBar: AppBar(backgroundColor: backgroundColor),
        body: Column(
          children: [
            StreamBuilder<SequenceState?>(
              stream: audioPlayer.sequenceStateStream,
              builder: (context, snapshot) {
                double width = 360;
                double height = 375;
                final state = snapshot.data;
                final defaultAlbumArt = Image.asset(
                  'assets/cover.jpg',
                  fit: BoxFit.cover,
                );
                if (state?.sequence.isEmpty ?? true) {
                  return Container(
                    height: height,
                    width: width,
                    padding: const EdgeInsets.all(10),
                    child: defaultAlbumArt,
                  );
                }
                final metadata = state!.currentSource!.tag as MediaItem;
                final song = Song.fromJson((metadata.extras ?? {}));
                return Container(
                  height: height,
                  width: width,
                  padding: const EdgeInsets.all(10),
                  child: FlipCard(
                    flipOnTouch: true,
                    controller: flipCardController,
                    //TODO
                    back: 1 == 1
                        ? const SizedBox.shrink()
                        : StreamBuilder<ProgressState>(
                            stream: audioPlayer.positionDataStream,
                            builder: (context, snapshot) {
                              final progressState = snapshot.data;
                              Duration currentProgress = progressState?.current ?? Duration.zero;
                              if (lyricsPositionAdjustment < 0) {
                                currentProgress -= Duration(seconds: (lyricsPositionAdjustment * (-1)));
                              } else if (lyricsPositionAdjustment > 0) {
                                currentProgress += Duration(seconds: lyricsPositionAdjustment);
                              }
                              return LyricPage(
                                callback: (Duration? duration) async {
                                  if (duration != null) {
                                    await audioPlayer.seek(duration);
                                  }
                                },
                                lyrics: lyrics,
                                progress: currentProgress,
                                lyricStyle: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                                currLyricStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                draggingLyricStyle: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                              );
                            }),
                    front: Image(
                      image: MemoryImage(song.albumArt!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return defaultAlbumArt;
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 50),
            StreamBuilder<SequenceState?>(
                stream: audioPlayer.sequenceStateStream,
                builder: (context, snapshot) {
                  String title = '';
                  String artists = '';
                  String albumArtist = '';
                  String album = '';
                  final state = snapshot.data;
                  if (state?.sequence.isEmpty ?? true) {
                    title = '[No song in queue]';
                    artists = '[unknown]';
                    albumArtist = '[unknown]';
                    album = '[unknown]';
                  } else {
                    final metadata = state?.currentSource!.tag as MediaItem;
                    final song = Song.fromJson((metadata.extras ?? {}));
                    title = song.trackName!;
                    artists = song.trackArtistNames!.join('/');
                    albumArtist = song.albumArtistName!;
                    album = song.albumName!;
                  }

                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 23, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          albumArtist,
                          style: const TextStyle(fontSize: 18, color: Colors.white54),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {},
                        child: Text(
                          album,
                          style: const TextStyle(fontSize: 18, color: Colors.white54),
                        ),
                      ),
                    ],
                  );
                }),
            const SizedBox(height: 20),
            Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.playlist_add),
                  color: Colors.white70,
                ),
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz), color: Colors.white70),
                const Spacer(),
                StreamBuilder<LoopMode>(
                  stream: audioPlayer.loopModeStream,
                  builder: (context, snapshot) {
                    final loopMode = snapshot.data ?? Hive.box('settings').get('loopMode', defaultValue: LoopMode.all);
                    const icons = [
                      Icon(Icons.repeat, color: Colors.white70),
                      Icon(Icons.repeat, color: Colors.white),
                      Icon(Icons.repeat_one, color: Colors.white),
                    ];
                    const cycleModes = [
                      LoopMode.off,
                      LoopMode.all,
                      LoopMode.one,
                    ];
                    final index = cycleModes.indexOf(loopMode);
                    return IconButton(
                      icon: icons[index],
                      onPressed: () {
                        final newLoopMode = cycleModes[(cycleModes.indexOf(loopMode) + 1) % cycleModes.length];

                        Hive.box('settings').put('loopMode', newLoopMode);
                        audioPlayer.setLoopMode(newLoopMode);
                      },
                    );
                  },
                ),
                StreamBuilder<bool>(
                  stream: audioPlayer.shuffleEnabledStream,
                  builder: (context, snapshot) {
                    const shuffleEnabled = true; // snapshot.data ?? Hive.box('settings').get('shuffleEnable', defaultValue: false);
                    return IconButton(
                      icon: shuffleEnabled ? const Icon(Icons.shuffle, color: Colors.white) : const Icon(Icons.shuffle, color: Colors.white70),
                      onPressed: () async {
                        await Hive.box('settings').put('shuffleEnable', !shuffleEnabled);
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 5),
            StreamBuilder<ProgressState>(
              stream: audioPlayer.positionDataStream,
              builder: (context, snapshot) {
                final progressState = snapshot.data;
                Duration? duration = progressState?.total;
                if (duration == null || progressState?.total == Duration.zero) {
                  duration = audioPlayer.currentSong?.duration;
                }
                return Padding(
                  padding: const EdgeInsets.all(0),
                  child: SeekBar(
                    duration: duration ?? Duration.zero,
                    position: progressState?.current ?? Duration.zero,
                    bufferedPosition: Duration.zero,
                    onChangeEnd: (newPosition) => audioPlayer.seek(newPosition),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            StreamBuilder<PlayerState>(
                stream: audioPlayer.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  // final processingState = playerState?.processingState;
                  final playing = playerState?.playing;
                  return StreamBuilder<ProgressState>(
                    builder: (context, snapshot) {
                      const double? forwardRewindButtonsSize = 25;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.volume_down,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => audioPlayer.skipToPrevious(),
                            icon: Icon(
                              Icons.skip_previous,
                              size: 45,
                              color: Colors.white.withAlpha(245),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: IconButton(
                              onPressed: () {
                                Duration rewindDurartion = audioPlayer.position - const Duration(seconds: 10);
                                audioPlayer.seek(rewindDurartion.isNegative ? Duration.zero : rewindDurartion);
                              },
                              icon: const Icon(
                                Icons.fast_rewind_sharp,
                                size: forwardRewindButtonsSize,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              audioPlayer.isPlaying ? await audioPlayer.pause() : await audioPlayer.play();
                              setState(() {});
                            },
                            icon: Icon(
                              (playing == true ? Icons.pause : Icons.play_arrow),
                              size: 50,
                              color: Colors.white.withAlpha(245),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15, left: 15),
                            child: IconButton(
                              onPressed: () => audioPlayer.seek(Duration(seconds: audioPlayer.position.inSeconds + 10)),
                              icon: const Icon(
                                Icons.fast_forward_sharp,
                                size: forwardRewindButtonsSize,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: IconButton(
                              onPressed: () => audioPlayer.skipToNext(),
                              icon: Icon(
                                Icons.skip_next,
                                size: 45,
                                color: Colors.white.withAlpha(245),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.equalizer,
                                  size: 20,
                                  color: Colors.white,
                                )),
                          ),
                        ],
                      );
                    },
                  );
                }),
          ],
        ),
      ),
    );
  }
}
