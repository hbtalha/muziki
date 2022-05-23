import 'package:flutter/material.dart';
import 'package:muziki/utils/global_variables.dart';

class ArtistsScreen extends StatefulWidget {
  final Function({required SwipeDirection direction}) swipe;
  final Function(int screenIndex) goToScreen;
  const ArtistsScreen({Key? key, required this.swipe, required this.goToScreen}) : super(key: key);

  @override
  State<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends State<ArtistsScreen> {
  
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
      child:  Center(
          child: Scaffold(
        appBar: AppBar(
          title: Text('data'),
        ),
      )),
    );
  }
}
