import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/translation_service.dart';

import '../constants.dart';

class PoemDetailScreen extends StatefulWidget {
  final int poemId;
  const PoemDetailScreen({Key? key, required this.poemId}) : super(key: key);

  @override
  State<PoemDetailScreen> createState() => _PoemDetailScreenState();
}

class _PoemDetailScreenState extends State<PoemDetailScreen> {
  List<dynamic> lines = [];
  Map<String, dynamic> definitions = {};
  Set<int> bookmarkedLines = {};
  Map<int, String> lineNotes = {};
  late SharedPreferences prefs;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TranslationService _translationService = TranslationService();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchLines();
    // Correct Urdu translations after loading
  }

  Future<void> _loadPreferences() async {
    prefs = await SharedPreferences.getInstance();
    final bookmarksList = prefs.getStringList('bookmarks_${widget.poemId}') ?? [];
    setState(() {
      bookmarkedLines = Set<int>.from(bookmarksList.map(int.parse));
    });
    final notesString = prefs.getString('notes_poem_${widget.poemId}');
    if (notesString != null) {
      try {
        final Map<String, dynamic> notesMap = jsonDecode(notesString);
        setState(() {
          lineNotes = Map<int, String>.from(
            notesMap.map((k, v) => MapEntry(int.parse(k), v.toString())),
          );
        });
      } catch (e) {
        debugPrint('Error loading notes: $e');
      }
    }
  }

  Future<void> _fetchLines() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all lines for this poem, then sort locally to avoid Firestore index requirements
      final snapshot = await _firestore
          .collection('poems')
          .where('poem_id', isEqualTo: widget.poemId)
          .get();
      final docs = snapshot.docs;
      // Prepare local list with doc references
      final linesData = docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['_ref'] = doc.reference;
        return data;
      }).toList();
      // Sort by order_by field
      linesData.sort((a, b) => (a['order_by'] as int).compareTo(b['order_by'] as int));
      // Translate untranslated lines
      final toTranslate = linesData.where((l) => l['translated'] != true).toList();
      if (toTranslate.isNotEmpty) {
        for (var line in toTranslate) {
          try {
            final result = await _translationService.translateLine(line['line_text'] ?? '');
            await (line['_ref'] as DocumentReference)
                .update({
                  // Save generated translations back to Firestore
                  'eng_trans': result['eng'],
                  'urdu_trans': result['ur'],
                  'translated': true,
                });
            line['eng_trans'] = result['eng'];
            line['urdu_trans'] = result['ur'];
            line['translated'] = true;
          } catch (e) {
            debugPrint('Translation failed for line: $e');
          }
        }
      }
      setState(() {
        lines = linesData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching lines: $e');
    }
  }

  Future<void> _fetchDefinitions() async {
    try {
      final snapshot = await _firestore.collection('definitions').get();
      final Map<String, dynamic> defs = {};
      for (var doc in snapshot.docs) {
        defs[doc.id] = doc.data();
      }
      setState(() {
        definitions = defs;
      });
    } catch (e) {
      debugPrint('Error fetching definitions from Firebase: $e');
    }
  }

  void _showWordDefinition(String word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, ctrl) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(word, style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              Expanded(
                child: FutureBuilder<Map<String, String>>(
                  future: _fetchWordMeanings(word),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: \\${snap.error}'));
                    }
                    final meanings = snap.data ?? {};
                    return ListView(
                      controller: ctrl,
                      children: [
                        _definitionTile('Urdu', meanings['urdu'] ?? 'Not available'),
                        _definitionTile('Persian', meanings['persian'] ?? 'Not available'),
                        _definitionTile('English', meanings['english'] ?? 'Not available'),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _definitionTile(String language, String meaning) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMedium)),
          const SizedBox(height: 4),
          Text(meaning, style: TextStyle(color: AppColors.textDark, fontSize: 16)),
        ],
      ),
    );
  }

  void _toggleBookmark(int lineId) async {
    setState(() {
      if (bookmarkedLines.contains(lineId)) bookmarkedLines.remove(lineId);
      else bookmarkedLines.add(lineId);
    });
    await prefs.setStringList('bookmarks_${widget.poemId}', bookmarkedLines.map((e) => e.toString()).toList());
  }

  void _addNote(int lineId) async {
    final controller = TextEditingController(text: lineNotes[lineId]);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Add Note', style: Theme.of(context).textTheme.titleMedium),
        content: TextField(controller: controller, maxLines: 3, decoration: InputDecoration(hintText: 'Enter your note...', filled: true, fillColor: AppColors.background)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final note = controller.text;
              final key = 'note_${widget.poemId}_$lineId';
              if (note.isEmpty) {
                await prefs.remove(key);
                setState(() => lineNotes.remove(lineId));
              } else {
                await prefs.setString(key, note);
                setState(() => lineNotes[lineId] = note);
              }
              final map = lineNotes.map((k,v) => MapEntry(k.toString(), v));
              await prefs.setString('notes_poem_${widget.poemId}', jsonEncode(map));
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved successfully')));
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>> _fetchWordMeanings(String word) async {
    try {
      final translator = GoogleTranslator();
      final results = await Future.wait([
        translator.translate(word, from: 'fa', to: 'ur'),
        translator.translate(word, from: 'fa', to: 'en'),
      ]);
      return {'urdu': results[0].text, 'english': results[1].text, 'persian': word};
    } catch (e) {
      debugPrint('Translation error: $e');
      return {'urdu': 'Translation not available', 'english': 'Translation not available', 'persian': word};
    }
  }

  void _shareLine(String text) => Share.share(text);

  Future<void> _shareAsImage() async {
    try {
      final text = lines.map((l) => l['line_text'] ?? '').join('\n');
      await Share.share(text, subject: 'Sharing poem from Javied Nama');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error sharing: Falling back to text sharing')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Poem Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [IconButton(icon: const Icon(Icons.share), onPressed: _shareAsImage)],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : lines.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No lines found for this poem',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Original poem line
                              SelectableText(
                                line['line_text'] ?? '',
                                textAlign: TextAlign.right,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Divider(),
                              // Show translations if present
                              if ((line['urdu_trans'] as String?)?.isNotEmpty == true || (line['eng_trans'] as String?)?.isNotEmpty == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Column(
                                    children: [
                                      if ((line['urdu_trans'] as String?)?.isNotEmpty == true)
                                        Text(
                                          line['urdu_trans'] ?? '',
                                          textAlign: TextAlign.right,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      const SizedBox(height: 8),
                                      if ((line['eng_trans'] as String?)?.isNotEmpty == true)
                                        Text(
                                          line['eng_trans'] ?? '',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                    ],
                                  ),
                                ),
                              const Divider(),
                              if (lineNotes.containsKey(index))
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Your Note:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.textMedium,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 16),
                                            color: AppColors.primary,
                                            onPressed: () => _addNote(index),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        lineNotes[index]!,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        bookmarkedLines.contains(index) ? Icons.bookmark : Icons.bookmark_border,
                                        color: bookmarkedLines.contains(index) ? AppColors.primary : AppColors.textMedium,
                                      ),
                                      onPressed: () => _toggleBookmark(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.note_add),
                                      color: AppColors.textMedium,
                                      onPressed: () => _addNote(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.share),
                                      color: AppColors.textMedium,
                                      onPressed: () => _shareLine(line['line_text'] ?? ''),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
