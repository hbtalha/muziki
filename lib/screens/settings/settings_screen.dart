import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:muziki/screens/settings/songs_library_tag_settings_screen.dart';
import 'package:muziki/utils/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        title: const Text('Settings'),
      ),
      body: Container(
        height: 60,
        padding: const EdgeInsets.only(left: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SongsLibraryAndTagSettingsScrren()));
                },
                child: ListTile(
                  minLeadingWidth: 10,
                  leading: Transform.rotate(
                    angle: 14.9,
                    child: const Icon(
                      CupertinoIcons.tag_fill,
                      color: primaryColor,
                    ),
                  ),
                  title: const Text(
                    'Song library and tags',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
