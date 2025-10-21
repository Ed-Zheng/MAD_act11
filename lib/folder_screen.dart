import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'card_screen.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  State<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Folder> folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final data = await dbHelper.getAllFolders();
    setState(() => folders = data);
  }

  Future<int> _getCardCount(int folderId) async {
    final cards = await dbHelper.getCardsByFolder(folderId);
    return cards.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Folders")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: folders.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final folder = folders[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CardScreen(),
                  ),
                ).then((_) => _loadFolders());
              },
              child: FutureBuilder<int>(
                future: _getCardCount(folder.id!),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        folder.previewImage != null
                          ? Image.network(
                              folder.previewImage!,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.folder, size: 80),

                        const SizedBox(height: 8),

                        Text(
                          folder.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        Text(
                          "$count cards",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
