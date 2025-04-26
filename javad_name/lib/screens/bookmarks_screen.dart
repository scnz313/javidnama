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

  // Map to store poem titles by poem ID
  Map<String, String> poemTitles = {};

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load poem titles first
      final String poemsData = await rootBundle.loadString('assets/poems.json');
      final List<dynamic> allPoems = json.decode(poemsData);
      
      // Create a map of poem IDs to poem titles
      for (final poem in allPoems) {
        final String poemId = poem['_id'].toString();
        final String title = poem['title'] ?? 'Untitled';
        poemTitles[poemId] = title;
      }
      
      // Now load the bookmarked lines
      final String linesData = await rootBundle.loadString('assets/lines_trans.json');
      final List<dynamic> allLines = json.decode(linesData);
      
      // Create an efficient lookup map for quick access
      // Key format: "poemId:orderBy" -> Line data
      final Map<String, Map<String, dynamic>> lineMap = {};
      for (final line in allLines) {
        final String poemId = line['poem_id'].toString();
        final String orderBy = line['order_by'].toString();
        final String key = "$poemId:$orderBy";
        lineMap[key] = Map<String, dynamic>.from(line);
      }
      
      Map<String, List<Map<String, dynamic>>> newBookmarks = {};
      final bookmarkKeys = prefs.getKeys().where((key) => key.startsWith('bookmarks_')).toList();
      
      // For each bookmarked poem
      for (String key in bookmarkKeys) {
        final poemId = key.replaceFirst('bookmarks_', '');
        final List<String> bookmarkedIndices = prefs.getStringList(key) ?? [];
        
        // Direct lookup from map instead of filtering entire list
        final poemBookmarks = <Map<String, dynamic>>[];
        for (final orderBy in bookmarkedIndices) {
          final String lookupKey = "$poemId:$orderBy";
          final lineData = lineMap[lookupKey];
          if (lineData != null) {
            poemBookmarks.add(lineData);
          }
        }
        
        if (poemBookmarks.isNotEmpty) {
          newBookmarks[poemId] = poemBookmarks;
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
      appBar: AppBar(
        title: const Text('Bookmarks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh bookmarks',
            onPressed: _loadBookmarks,
          ),
        ],
      ),
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
              : RefreshIndicator(
                  onRefresh: () => _loadBookmarks(),
                  child: ListView.builder(
                    itemCount: bookmarkedLines.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                    final poemId = bookmarkedLines.keys.elementAt(index);
                    final lines = bookmarkedLines[poemId]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add divider between poems (except for the first one)
                        if (index > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Divider(
                              color: AppColors.divider,
                              thickness: 1,
                            ),
                          ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                poemTitles[poemId] ?? 'Untitled',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Poem #$poemId',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textLight,
                                    ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                        ),
                        ...lines.map((line) {
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PoemDetailScreen(
                                      poemId: int.parse(poemId),
                                      initialLineIndex: int.parse(line['order_by'].toString()), // Jump directly to the bookmarked line
                                    ),
                                  ),
                                ).then((_) => _loadBookmarks()); // Reload bookmarks when returning
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Text(
                                        line['line_text'] ?? '',
                                        textAlign: TextAlign.right,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          height: 1.8,
                                          fontFamily: 'Jameelnoori',
                                        ),
                                      ),
                                    ),
                                    if (line['Eng_trans'] != null) const Divider(height: 24),
                                    if (line['Eng_trans'] != null)
                                      Text(
                                        line['Eng_trans'] ?? '',
                                        textAlign: TextAlign.left,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          height: 1.5,
                                        ),
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
              ),
    );
  }
}
