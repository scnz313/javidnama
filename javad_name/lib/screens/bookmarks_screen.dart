import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../constants.dart';
import 'poem_detail_screen.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  Map<String, List<Map<String, dynamic>>> bookmarkedLines = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String linesData = await rootBundle.loadString('assets/lines_trans.json');
      final List<dynamic> allLines = json.decode(linesData);

      Map<String, List<Map<String, dynamic>>> newBookmarks = {};
      for (String key in prefs.getKeys()) {
        if (key.startsWith('bookmarks_')) {
          final poemId = key.replaceFirst('bookmarks_', '');
          final List<String> bookmarkedIndices = prefs.getStringList(key) ?? [];
          newBookmarks[poemId] = allLines
              .where(
                (line) =>
                    line['poem_id'].toString() == poemId &&
                    bookmarkedIndices.contains(line['order_by'].toString()),
              )
              .cast<Map<String, dynamic>>()
              .toList();
        }
      }
      setState(() {
        bookmarkedLines = newBookmarks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading bookmarks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookmarkedLines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bookmarks yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bookmark your favorite lines to see them here',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: bookmarkedLines.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final poemId = bookmarkedLines.keys.elementAt(index);
                    final lines = bookmarkedLines[poemId]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Text(
                            'Poem #$poemId',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        ...lines.map((line) {
                          return Card(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PoemDetailScreen(
                                      poemId: int.parse(poemId),
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      line['line_text'] ?? '',
                                      textAlign: TextAlign.right,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const Divider(),
                                    if (line['Eng_trans'] != null)
                                      Text(
                                        line['Eng_trans'] ?? '',
                                        textAlign: TextAlign.left,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
    );
  }
}
