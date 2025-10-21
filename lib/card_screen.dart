import 'package:flutter/material.dart';
import 'database_helper.dart';

class CardScreen extends StatefulWidget {
  final Folder folder;

  const CardScreen({super.key, required this.folder});

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<CardItem> cards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final data = await dbHelper.getCardsByFolder(widget.folder.id!);
    setState(() => cards = data);
  }

  Future<void> _removeCard(int cardId) async {
    if (cards.length <= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Folder must have at least 3 cards")),
      );
      return;
    }

    final card = cards.firstWhere((c) => c.id == cardId);
    card.folderId = null;
    await dbHelper.updateCard(card);
    _loadCards();
  }

  Future<void> _addCardToFolder() async {
    if (cards.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Folder is full (max 6 cards)")),
      );
      return;
    }

    final unassigned = await dbHelper.getUnassignedCards();
    if (unassigned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No unassigned cards available")),
      );
      return;
    }

    final selected = await showDialog<CardItem>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text("Add a card to folder"),
          children: unassigned.map((card) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, card),
              child: Text(card.name),
            );
          }).toList(),
        );
      },
    );

    if (selected != null) {
      selected.folderId = widget.folder.id;
      await dbHelper.updateCard(selected);
      _loadCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.name),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCardToFolder,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: cards.isEmpty
            ? const Center(child: Text("No cards in this folder"))
            : GridView.builder(
                itemCount: cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              card.imageUrl,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),

                            const SizedBox(height: 8),

                            Text(
                              card.name,
                              style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text(
                              card.suit,
                              style: const TextStyle(color: Colors.grey)
                            ),
                          ],
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeCard(card.id!),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}