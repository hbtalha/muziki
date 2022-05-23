import 'package:flutter/material.dart';
import 'package:muziki/utils/global_variables.dart';

class QueuesScreen extends StatefulWidget {
  final Function({required SwipeDirection direction}) swipe;
  final Function(int screenIndex) goToScreen;
  const QueuesScreen({Key? key, required this.swipe, required this.goToScreen}) : super(key: key);

  @override
  State<QueuesScreen> createState() => _QueuesScreenState();
}

class _QueuesScreenState extends State<QueuesScreen> {
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
      child: Scaffold(),
    );
  }
}
