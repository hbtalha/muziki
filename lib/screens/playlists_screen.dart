import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:muziki/services/audio_player_handler.dart';
import 'package:muziki/utils/global_variables.dart';

class PlaylistsScreen extends StatefulWidget {
  final Function({required SwipeDirection direction}) swipe;
  final Function(int screenIndex) goToScreen;
  const PlaylistsScreen({Key? key, required this.swipe, required this.goToScreen}) : super(key: key);

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final AudioPlayerHandler _player = GetIt.I<AudioPlayerHandler>();
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (dragEndDetails) {
        if (dragEndDetails.primaryVelocity != null && dragEndDetails.primaryVelocity! < 0) {
          widget.swipe(direction: SwipeDirection.right);
        } else if (dragEndDetails.primaryVelocity != null && dragEndDetails.primaryVelocity! > 0) {
          widget.swipe(direction: SwipeDirection.left);
        }
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {});
                },
                icon: const Icon(Icons.check),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.donut_large_rounded),
              ),
            ],
          ),
          body: 1 == 1
              ? const SizedBox()
              : ReorderableListView(
                  buildDefaultDragHandles: true,
                  onReorder: (int oldIndex, int newIndex) {
                    if (_player.indices == null || _player.indices!.isEmpty) return;
                    if (oldIndex < newIndex) newIndex--;
                    _player.moveQueueItem(oldIndex, newIndex);
                    setState(() {});
                  },
                  children: [
                    if (_player.sequence != null && _player.sequence!.isNotEmpty && _player.sequence!.length == _player.indices!.length)
                      for (var i in _player.indices!)
                        Dismissible(
                          key: ValueKey(_player.sequence![i]),
                          background: Container(
                            color: Colors.redAccent,
                            alignment: Alignment.centerRight,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 8.0),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                          ),
                          onDismissed: (dismissDirection) {
                            // _playlist.removeAt(i);
                          },
                          child: Material(
                            // color: i == _player.currentIndex ? Colors.pink : null,
                            child: ListTile(
                              title: Text(_player.sequence![i].tag.title as String),
                              onTap: () {
                                _player.seek(Duration.zero, index: i);
                              },
                            ),
                          ),
                        ),
                  ],
                ),
          floatingActionButton: FloatingActionButton(onPressed: () {
            print(_player.songs.length);
            // _player.test();
          }),
        ),
      ),
    );
  }
}
