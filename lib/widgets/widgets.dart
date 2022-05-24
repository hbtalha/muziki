import 'package:flutter/material.dart';

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
