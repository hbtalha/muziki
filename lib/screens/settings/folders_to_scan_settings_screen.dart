import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:muziki/utils/utils.dart';

class FolderToScanScreen extends StatefulWidget {
  final List<String> folders;
  const FolderToScanScreen({Key? key, required this.folders}) : super(key: key);

  @override
  State<FolderToScanScreen> createState() => _FolderToScanScreenState();
}

class _FolderToScanScreenState extends State<FolderToScanScreen> {
  List<Widget> listTiles = [];
  List<String> folders = [];

  @override
  void initState() {
    super.initState();

    folders.addAll([...widget.folders]);
    for (var folder in folders) {
      addListTitle(folder);
    }
  }

  void addListTitle(String folder) {
    listTiles.add(
      SizedBox(
        width: 280,
        child: ListTile(
          horizontalTitleGap: -10,
          leading: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Icon(
              Icons.folder,
              size: 20,
            ),
          ),
          title: Text(
            lastInPath(folder),
            style: const TextStyle(fontSize: 15),
          ),
          subtitle: Text(
            shortenPath(folder),
            style: const TextStyle(fontSize: 10),
          ),
          trailing: IconButton(
            onPressed: () {
              var index = folders.indexOf(folder);
              folders.remove(folder);
              listTiles.removeAt(index);
              setState(() {});
            },
            icon: Transform.rotate(
              angle: 150,
              child: const Icon(
                Icons.add_circle_outline_sharp,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, folders.isEmpty ? <String>[] : folders);
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40, left: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Folders to scan',
                      style: TextStyle(
                          fontSize: 30, color: Colors.white.withAlpha(210)),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Select the folders where you keep your audio files',
                      style: TextStyle(fontSize: 15, color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: const BorderSide(color: Colors.white38, width: 1),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < listTiles.length; ++i)
                            listTiles[i]
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 7.0, top: 15),
                      child: ElevatedButton(
                        onPressed: () async {
                          String? selectedDirectory =
                              await FilePicker.platform.getDirectoryPath();

                          if (selectedDirectory != null) {
                            for (var folder in folders) {
                              if (selectedDirectory.contains(folder) &&
                                  selectedDirectory != folder) {
                                showAlertDialogMessage(context,
                                    'Folder "${lastInPath(selectedDirectory)}" is already accessible as it is subfolder of ${lastInPath(folder)}.');
                                return;
                              }
                            }

                            if (folders.contains(selectedDirectory)) {
                              showAlertDialogMessage(context,
                                  'Folder "${shortenPath(selectedDirectory)}" is already added.');
                              return;
                            }

                            var tempFolders = [];
                            tempFolders.addAll([...folders]);
                            for (int i = 0; i < tempFolders.length; ++i) {
                              if (tempFolders[i].contains(selectedDirectory) &&
                                  tempFolders[i] != selectedDirectory) {
                                var index = folders.indexOf(tempFolders[i]);
                                folders.removeAt(index);
                                listTiles.removeAt(index);
                              }
                            }

                            addListTitle(selectedDirectory);
                            folders.add(selectedDirectory);
                            Future.delayed(const Duration(milliseconds: 100),
                                () {
                              setState(() {});
                            });
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.create_new_folder_rounded),
                            SizedBox(width: 5),
                            Text(
                              'ADD FOLDER',
                              style: TextStyle(fontSize: 17),
                            ),
                          ],
                        ),
                        style: ElevatedButton.styleFrom(
                            primary: Colors.transparent,
                            minimumSize: const Size(100, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                              side: const BorderSide(color: Colors.white38),
                            )),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: folders.isEmpty
              ? const SizedBox.shrink()
              : FloatingActionButton(
                  onPressed: () {
                    Navigator.pop(
                        context, folders.isEmpty ? <String>[] : folders);
                  },
                  child: const Icon(Icons.check),
                ),
        ),
      ),
    );
  }
}
