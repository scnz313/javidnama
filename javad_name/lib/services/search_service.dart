import 'dart:async';
import 'package:flutter/foundation.dart'; // Import for compute

class SearchResult {
  final int poemId;
  final String poemTitle;
  final String? matchLine;
  final int? lineIndex;

  SearchResult({
    required this.poemId,
    required this.poemTitle,
    this.matchLine,
    this.lineIndex,
  });
}

class SearchService {
  static final SearchService instance = SearchService._();
  SearchService._();

  List<_SearchablePoem> _poems = [];

  Future<void> init(List<dynamic> poems) async {
    _poems = poems.map((poem) {
      final id = poem['_id'] ?? 0;
      final title = poem['title'] ?? '';
      final englishTitle = poem['englishTitle'] ?? '';
      final lines = (poem['lines'] as List?)?.map((l) => l.toString()).toList() ?? [];
      return _SearchablePoem(
        id: id,
        title: title,
        englishTitle: englishTitle,
        lines: lines,
      );
    }).toList();
  }

  /// filter: 0=all, 1=titles, 2=lines
  Future<List<SearchResult>> search(String query, {int filter = 0, String? language}) async {
    // Use compute to run the search in a separate isolate
    return compute(_performSearch, {
      'query': query,
      'filter': filter,
      'poems': _poems, // Pass the poem data
      // 'language': language, // Pass language if used later
    });
  }
}

// Top-level function to be executed by compute
List<SearchResult> _performSearch(Map<String, dynamic> params) {
  final String query = params['query'] as String;
  final int filter = params['filter'] as int;
  final List<_SearchablePoem> poems = params['poems'] as List<_SearchablePoem>;
  // final String? language = params['language'] as String?;

  final q = query.toLowerCase();
  final List<SearchResult> results = [];

  for (final poem in poems) {
    bool added = false;
    if (filter == 0 || filter == 1) {
      // Title match
      if (poem.title.toLowerCase().contains(q) || poem.englishTitle.toLowerCase().contains(q)) {
        results.add(SearchResult(poemId: poem.id, poemTitle: poem.title, matchLine: null, lineIndex: null));
        added = true;
      }
    }
    if (!added && (filter == 0 || filter == 2)) {
      // Line match
      for (int i = 0; i < poem.lines.length; i++) {
        final line = poem.lines[i];
        // (Future: filter by language if line objects have language info)
        if (line.toLowerCase().contains(q)) {
          results.add(SearchResult(poemId: poem.id, poemTitle: poem.title, matchLine: line, lineIndex: i));
          break; // Only first match per poem for now
        }
      }
    }
  }
  return results;
}

class _SearchablePoem {
  final int id;
  final String title;
  final String englishTitle;
  final List<String> lines;
  _SearchablePoem({required this.id, required this.title, required this.englishTitle, required this.lines});
} 