/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2022, Ankit Sangwan
 */

import 'package:flutter/material.dart';

class PlaylistHead extends StatelessWidget {
  bool showBackButton = false;
  String textNextToBackButton;
  final VoidCallback onBackButtonPressed;
  final VoidCallback onShuffleButtonPressed;
  final VoidCallback onSortButtonPressed;
  final VoidCallback onMoreButtonPressed;

  PlaylistHead({
    required this.textNextToBackButton,
    required this.showBackButton,
    required this.onBackButtonPressed,
    required this.onShuffleButtonPressed,
    required this.onMoreButtonPressed,
    required this.onSortButtonPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      alignment: Alignment.center,
      // padding: const EdgeInsets.only(top: 1),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      duration: const Duration(milliseconds: 150),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBackButton)
            BackButton(
              onPressed: () {
                onBackButtonPressed();
              },
            ),
          if (showBackButton)
            Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(textNextToBackButton)),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.shuffle_rounded),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.sort),
            iconSize: 25.0,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
            iconSize: 25.0,
          ),
        ],
      ),
    );
  }
}
