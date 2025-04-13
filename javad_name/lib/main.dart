import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart'; // Added for web compatibility
// Added for toast notifications
import 'package:share_plus/share_plus.dart'; // For sharing functionality
// For image rendering
// For image conversion
// Add this import for temporary file storage
// Add this import for file operations
// Replace Google Fonts with Persian Fonts
// For fetching meanings and translations
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart'; // Ensure the translator package is imported
// Add this import
import 'constants.dart';

void main() {
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      print(message); // Ensure logs are printed to the terminal
    }
  };
  setUrlStrategy(PathUrlStrategy()); // Added for web compatibility
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _loadThemePreferences();
  }

  Future<void> _loadThemePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme preference
      final themeName = prefs.getString('theme_preference') ?? 'light';
      ThemeType themeType;
      switch (themeName) {
        case 'dark':
          themeType = ThemeType.dark;
          break;
        case 'sepia':
          themeType = ThemeType.sepia;
          break;
        default:
          themeType = ThemeType.light;
      }

      // Load font size preference
      final fontSize = prefs.getDouble('font_size_factor') ?? 1.0;

      setState(() {
        AppTheme.setTheme(themeType);
        AppTheme.setFontSize(fontSize);
      });
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Javied Nama',
      theme: AppTheme.theme,
      themeMode: ThemeMode.light, // We'll handle theme modes ourselves
      home: const MainScreen(),
    );
  }
}

// Create a theme controller to manage theme changes
class ThemeController {
  static Future<void> setTheme(ThemeType themeType) async {
    final prefs = await SharedPreferences.getInstance();
    String themeName;

    switch (themeType) {
      case ThemeType.dark:
        themeName = 'dark';
        break;
      case ThemeType.sepia:
        themeName = 'sepia';
        break;
      default:
        themeName = 'light';
    }

    await prefs.setString('theme_preference', themeName);
    AppTheme.setTheme(themeType);
  }

  static Future<void> setFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size_factor', fontSize);
    AppTheme.setFontSize(fontSize);
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookmarksScreen(),
    const SettingsScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.primaryLight.withOpacity(0.2),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bookmark_border_outlined),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> poems = [];
  Set<int> favoritePoems = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPoems();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPoems() async {
    setState(() => _isLoading = true);
    try {
      final String response = await rootBundle.loadString('assets/poems.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        poems = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading poems: $e');
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoritePoems = Set<int>.from(
        prefs.getStringList('favorite_poems')?.map(int.parse) ?? [],
      );
    });
  }

  Future<void> _toggleFavorite(int poemId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favoritePoems.contains(poemId)) {
        favoritePoems.remove(poemId);
      } else {
        favoritePoems.add(poemId);
      }
    });
    await prefs.setStringList(
      'favorite_poems',
      favoritePoems.map((id) => id.toString()).toList(),
    );
  }

  List<dynamic> get _filteredPoems {
    if (_searchQuery.isEmpty) {
      return poems;
    }
    return poems.where((poem) {
      final title = poem['title'] ?? '';
      final englishTitle = poem['englishTitle'] ?? '';
      return title.toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          englishTitle.toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Javied Nama'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Javied Nama',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2023 Javied Nama',
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'A collection of Persian poetry with translations.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search poems...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Poems List
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredPoems.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No poems found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredPoems.length,
                      itemBuilder: (context, index) {
                        final poem = _filteredPoems[index];
                        final poemId = poem['_id'] ?? 0;
                        return Card(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          PoemDetailScreen(poemId: poemId),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          poem['title'] ?? 'Untitled',
                                          textAlign: TextAlign.right,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                        ),
                                        if (poem['englishTitle'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              poem['englishTitle'] ?? '',
                                              textAlign: TextAlign.right,
                                              style:
                                                  Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: Icon(
                                      favoritePoems.contains(poemId)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color:
                                          favoritePoems.contains(poemId)
                                              ? Colors.red
                                              : AppColors.primary,
                                    ),
                                    onPressed: () => _toggleFavorite(poemId),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class PoemDetailScreen extends StatefulWidget {
  final int poemId;

  const PoemDetailScreen({super.key, required this.poemId});

  @override
  State<PoemDetailScreen> createState() => _PoemDetailScreenState();
}

class _PoemDetailScreenState extends State<PoemDetailScreen> {
  List<dynamic> lines = [];
  Map<String, dynamic> definitions = {};
  Set<int> bookmarkedLines = {};
  Map<int, String> lineNotes = {};
  String? selectedWord;
  late SharedPreferences prefs;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchLines();
    _fetchDefinitions();
  }

  Future<void> _loadPreferences() async {
    prefs = await SharedPreferences.getInstance();

    // Load bookmarks
    final bookmarksList =
        prefs.getStringList('bookmarks_${widget.poemId}') ?? [];
    setState(() {
      bookmarkedLines = Set<int>.from(bookmarksList.map(int.parse));
    });

    // Load notes
    final notesString = prefs.getString('notes_poem_${widget.poemId}');
    if (notesString != null) {
      try {
        final Map<String, dynamic> notesMap = jsonDecode(notesString);
        setState(() {
          lineNotes = Map<int, String>.from(
            notesMap.map(
              (key, value) => MapEntry(int.parse(key), value.toString()),
            ),
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
      final String response = await rootBundle.loadString(
        'assets/lines_trans.json',
      );
      final List<dynamic> data = json.decode(response);
      setState(() {
        lines = data.where((line) => line['poem_id'] == widget.poemId).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading lines: $e');
    }
  }

  Future<void> _fetchDefinitions() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/definitions.json',
      );
      final Map<String, dynamic> data = json.decode(response);
      setState(() {
        definitions = data;
      });
    } catch (e) {
      debugPrint('Error loading definitions: $e');
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
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word, style: Theme.of(context).textTheme.titleLarge),
                  const Divider(),
                  Expanded(
                    child: FutureBuilder<Map<String, String>>(
                      future: _fetchWordMeanings(word),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        final meanings = snapshot.data ?? {};
                        return ListView(
                          controller: controller,
                          children: [
                            _definitionTile(
                              'Urdu',
                              meanings['urdu'] ?? 'Not available',
                            ),
                            _definitionTile(
                              'Persian',
                              meanings['persian'] ?? 'Not available',
                            ),
                            _definitionTile(
                              'English',
                              meanings['english'] ?? 'Not available',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _definitionTile(String language, String meaning) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            language,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meaning,
            style: TextStyle(color: AppColors.textDark, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _toggleBookmark(int lineId) async {
    setState(() {
      if (bookmarkedLines.contains(lineId)) {
        bookmarkedLines.remove(lineId);
      } else {
        bookmarkedLines.add(lineId);
      }
    });
    await prefs.setStringList(
      'bookmarks_${widget.poemId}',
      bookmarkedLines.map((e) => e.toString()).toList(),
    );
  }

  void _addNote(int lineId) async {
    final TextEditingController noteController = TextEditingController(
      text: lineNotes[lineId],
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              'Add Note',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            content: TextField(
              controller: noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter your note...',
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final note = noteController.text;
                  final key = 'note_${widget.poemId}_$lineId';

                  try {
                    if (note.isEmpty) {
                      await prefs.remove(key);
                      setState(() {
                        lineNotes.remove(lineId);
                      });
                    } else {
                      await prefs.setString(key, note);
                      setState(() {
                        lineNotes[lineId] = note;
                      });
                    }

                    // Save all notes for this poem
                    final notesMap = lineNotes.map(
                      (key, value) => MapEntry(key.toString(), value),
                    );
                    await prefs.setString(
                      'notes_poem_${widget.poemId}',
                      jsonEncode(notesMap),
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Note saved successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving note: $e')),
                      );
                    }
                  }

                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  Future<Map<String, String>> _fetchWordMeanings(String word) async {
    try {
      final translator = GoogleTranslator();

      // Make translations concurrent
      final results = await Future.wait([
        translator.translate(word, from: 'fa', to: 'ur'),
        translator.translate(word, from: 'fa', to: 'en'),
      ]);

      return {
        'urdu': results[0].text,
        'english': results[1].text,
        'persian': word,
      };
    } catch (e) {
      debugPrint('Translation error: $e');
      return {
        'urdu': 'Translation not available',
        'english': 'Translation not available',
        'persian': word,
      };
    }
  }

  void _shareLine(String text) {
    Share.share(text);
  }

  Future<void> _shareAsImage() async {
    try {
      // Simple text sharing as a fallback
      final text = lines.map((line) => line['line_text'] ?? '').join('\n');
      await Share.share(text, subject: 'Sharing poem from Javied Nama');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error sharing: Falling back to text sharing'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintBoundaryKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Poem Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.share), onPressed: _shareAsImage),
          ],
        ),
        body:
            _isLoading
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
                            // Persian Text
                            SelectableText(
                              line['line_text'] ?? '',
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.titleMedium,
                              onSelectionChanged: (selection, cause) {
                                if (cause == SelectionChangedCause.longPress) {
                                  final selectedWord = selection.textInside(
                                    line['line_text'] ?? '',
                                  );
                                  if (selectedWord.isNotEmpty) {
                                    _showWordDefinition(selectedWord);
                                  }
                                }
                              },
                            ),
                            const Divider(),

                            // Translations
                            if (line['urdu_trans'] != null ||
                                line['Eng_trans'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  children: [
                                    // Urdu Translation
                                    if (line['urdu_trans'] != null)
                                      Text(
                                        line['urdu_trans'] ?? '',
                                        textAlign: TextAlign.right,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                    const SizedBox(height: 8),
                                    // English Translation
                                    if (line['Eng_trans'] != null)
                                      Text(
                                        line['Eng_trans'] ?? '',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                  ],
                                ),
                              ),

                            const Divider(),

                            // Notes Section
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 16,
                                          ),
                                          color: AppColors.primary,
                                          onPressed: () => _addNote(index),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      lineNotes[index]!,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),

                            // Action Buttons
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      bookmarkedLines.contains(index)
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      color:
                                          bookmarkedLines.contains(index)
                                              ? AppColors.primary
                                              : AppColors.textMedium,
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
                                    onPressed:
                                        () =>
                                            _shareLine(line['line_text'] ?? ''),
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

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

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
      final String linesData = await rootBundle.loadString(
        'assets/lines_trans.json',
      );
      final List<dynamic> allLines = json.decode(linesData);

      Map<String, List<Map<String, dynamic>>> newBookmarks = {};

      for (String key in prefs.getKeys()) {
        if (key.startsWith('bookmarks_')) {
          final poemId = key.replaceFirst('bookmarks_', '');
          final List<String> bookmarkedIndices = prefs.getStringList(key) ?? [];

          newBookmarks[poemId] =
              allLines
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
      body:
          _isLoading
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Text(
                          'Poem #$poemId',
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(
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
                                  builder:
                                      (context) => PoemDetailScreen(
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
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const Divider(),
                                  if (line['Eng_trans'] != null)
                                    Text(
                                      line['Eng_trans'] ?? '',
                                      textAlign: TextAlign.left,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences prefs;
  bool showTranslations = true;
  bool autoSaveNotes = true;
  double fontSize = 1.0; // Scale factor, not absolute size
  String currentTheme = 'light';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      prefs = await SharedPreferences.getInstance();
      setState(() {
        showTranslations = prefs.getBool('showTranslations') ?? true;
        autoSaveNotes = prefs.getBool('autoSaveNotes') ?? true;
        fontSize = prefs.getDouble('font_size_factor') ?? 1.0;
        currentTheme = prefs.getString('theme_preference') ?? 'light';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await prefs.setBool('showTranslations', showTranslations);
      await prefs.setBool('autoSaveNotes', autoSaveNotes);

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _setTheme(String themeName) async {
    if (themeName == currentTheme) return;

    ThemeType themeType;
    switch (themeName) {
      case 'dark':
        themeType = ThemeType.dark;
        break;
      case 'sepia':
        themeType = ThemeType.sepia;
        break;
      default:
        themeType = ThemeType.light;
    }

    try {
      await ThemeController.setTheme(themeType);
      setState(() {
        currentTheme = themeName;
      });

      // Force app to rebuild with new theme
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error changing theme: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing theme: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _setFontSize(double size) async {
    if (size == fontSize) return;

    try {
      await ThemeController.setFontSize(size);
      setState(() {
        fontSize = size;
      });

      // Force app to rebuild with new font size
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error changing font size: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing font size: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _clearData(String type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Clear ${type.capitalize()}'),
            content: Text('Are you sure you want to clear all $type?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final prefix = type == 'bookmarks' ? 'bookmarks_' : 'notes_';
        final keys = prefs.getKeys().where((key) => key.startsWith(prefix));
        for (final key in keys) {
          await prefs.remove(key);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All $type cleared'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing $type: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Theme Settings Section
                  _sectionHeader('Theme Settings'),
                  Card(
                    child: Column(
                      children: [
                        // Theme Selection
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'App Theme',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _themeOption(
                                    'Light',
                                    'light',
                                    Icons.light_mode,
                                    AppColors.lightBackground,
                                    AppColors.lightSurface,
                                    AppColors.lightPrimary,
                                  ),
                                  _themeOption(
                                    'Dark',
                                    'dark',
                                    Icons.dark_mode,
                                    AppColors.darkBackground,
                                    AppColors.darkSurface,
                                    AppColors.darkPrimary,
                                  ),
                                  _themeOption(
                                    'Sepia',
                                    'sepia',
                                    Icons.auto_stories,
                                    AppColors.sepiaBackground,
                                    AppColors.sepiaSurface,
                                    AppColors.sepiaPrimary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(),

                        // Font Size Adjustment
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Font Size',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Text(
                                    'A',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: fontSize,
                                      min: 0.8,
                                      max: 1.5,
                                      divisions: 7,
                                      label: '${(fontSize * 100).round()}%',
                                      onChanged: (value) {
                                        setState(() {
                                          fontSize = value;
                                        });
                                      },
                                      onChangeEnd: (value) {
                                        _setFontSize(value);
                                      },
                                    ),
                                  ),
                                  const Text(
                                    'A',
                                    style: TextStyle(fontSize: 24),
                                  ),
                                ],
                              ),
                              Center(
                                child: Text(
                                  'Preview Text',
                                  style: TextStyle(
                                    fontSize: 16 * fontSize,
                                    fontFamily: 'Jameelnoori',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Display Settings Section
                  _sectionHeader('Display Settings'),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Show Translations'),
                          subtitle: const Text(
                            'Display translations under each line',
                          ),
                          value: showTranslations,
                          onChanged: (value) {
                            setState(() {
                              showTranslations = value;
                              _saveSettings();
                            });
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Auto-save Notes'),
                          subtitle: const Text(
                            'Automatically save notes while typing',
                          ),
                          value: autoSaveNotes,
                          onChanged: (value) {
                            setState(() {
                              autoSaveNotes = value;
                              _saveSettings();
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Data Management Section
                  _sectionHeader('Data Management'),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Clear Bookmarks'),
                          leading: const Icon(Icons.bookmark_remove),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _clearData('bookmarks'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Clear Notes'),
                          leading: const Icon(Icons.note_alt_outlined),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _clearData('notes'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // About Section
                  _sectionHeader('About'),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Version'),
                          subtitle: const Text('1.0.0'),
                          leading: const Icon(Icons.info_outline),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Text('Feedback'),
                          subtitle: const Text(
                            'Send comments or report issues',
                          ),
                          leading: const Icon(Icons.feedback_outlined),
                          onTap: () {
                            // Implement feedback mechanism
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _themeOption(
    String label,
    String value,
    IconData icon,
    Color backgroundColor,
    Color cardColor,
    Color accentColor,
  ) {
    final isSelected = currentTheme == value;

    return InkWell(
      onTap: () => _setTheme(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 6,
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 20,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: accentColor.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? accentColor : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? accentColor : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
