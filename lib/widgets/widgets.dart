import 'package:flutter/material.dart';
import 'package:muziki/models/song.dart';
import 'package:muziki/services/audio_player_handler.dart';
import 'package:muziki/utils/colors.dart';
import 'package:muziki/utils/utils.dart';

Widget circularTextButton({required Text text, required Function() onPressed, Color borderColor = Colors.white70}) {
  return SizedBox(
    height: 40,
    child: TextButton(
      onPressed: onPressed,
      child: text,
      style: ButtonStyle(
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
            side: BorderSide(color: borderColor),
          ),
        ),
      ),
    ),
  );
}

Widget songsListView({
  required List<Song> songsOnDisplay,
  required List<int?> allSongs,
  required ValueChanged<int> onTap,
  required AudioPlayerHandler audioPlayer,
}) {
  return ListView.builder(
    itemExtent: 50.0,
    itemCount: songsOnDisplay.length,
    itemBuilder: (context, index) {
      const double albumArtSize = 35;
      return ListTile(
        onTap: () {
          onTap(index);
        },
        horizontalTitleGap: 4,
        leading: Image(
          height: albumArtSize,
          width: albumArtSize,
          image: MemoryImage(songsOnDisplay[index].albumArt!),
          errorBuilder: (_, __, ___) {
            return Image.asset(
              'assets/cover.jpg',
              fit: BoxFit.cover,
            );
          },
        ),
        trailing: IconButton(
          icon: Container(
              height: 23,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: primaryColor),
              child: const Icon(Icons.more_horiz, color: backgroundColor)),
          onPressed: () {},
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 2),
          child: Text(songsOnDisplay[index].trackName ?? songsOnDisplay[index].filenameWOExt,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 14,
              )),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                (songsOnDisplay[index].albumArtistName!),
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                formattedDuration(Duration(milliseconds: audioPlayer.songs[allSongs[index]!].trackDuration!)),
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
