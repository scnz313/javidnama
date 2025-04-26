import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard functionality
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Add this import
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/translation_service.dart';
import '../constants.dart';
import '../controllers/theme_controller.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

class PoemDetailScreen extends StatefulWidget {
  final int poemId;
  final int? initialLineIndex;
  final String? heroTag;
  const PoemDetailScreen({
    Key? key,
    required this.poemId,
    this.initialLineIndex,
    this.heroTag,
  }) : super(key: key);

  @override
  State<PoemDetailScreen> createState() => _PoemDetailScreenState();
}

class _PoemDetailScreenState extends State<PoemDetailScreen> with SingleTickerProviderStateMixin {
  List<dynamic> lines = [];
  Map<String, dynamic> definitions = {};
  Set<int> bookmarkedLines = {};
  Map<int, String> lineNotes = {};
  late SharedPreferences prefs;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TranslationService _translationService = TranslationService();
  final ScrollController _scrollController = ScrollController();
  int? _highlightedLineIndex;
  bool _showAppBar = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isImmersiveMode = false;
  int? _expandedLineIndex;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchLines();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
    
    _scrollController.addListener(_scrollListener);
    
    if (widget.initialLineIndex != null) {
      _highlightedLineIndex = widget.initialLineIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToLine(widget.initialLineIndex!);
      });
    }
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    // Hide app bar on scroll down, show on scroll up
    if (_scrollController.position.userScrollDirection == AxisDirection.down) {
      if (_showAppBar) {
        setState(() {
          _showAppBar = false;
          _animationController.forward();
        });
      }
    } else if (_scrollController.position.userScrollDirection == AxisDirection.up) {
      if (!_showAppBar) {
        setState(() {
          _showAppBar = true;
          _animationController.reverse();
        });
      }
    }
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

  void _toggleImmersiveMode() {
    final scrollOffset = _scrollController.offset;
    setState(() {
      _isImmersiveMode = !_isImmersiveMode;
      if (_isImmersiveMode) {
        _showAppBar = false;
        _animationController.forward();
        // Add a small delay before scrolling to ensure the UI has updated
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(scrollOffset);
          }
        });
      } else {
        _showAppBar = true;
        _animationController.reverse();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(scrollOffset);
          }
        });
      }
    });
  }
  
  void _toggleExpandLine(int index) {
    setState(() {
      if (_expandedLineIndex == index) {
        _expandedLineIndex = null;
      } else {
        _expandedLineIndex = index;
      }
    });
  }

  void _showWordDefinition(String word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, ctrl) => Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    word, 
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontFamily: AppTheme.fontFamily,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Divider(height: 32),
                  Expanded(
                    child: FutureBuilder<Map<String, String>>(
                      future: _fetchWordMeanings(word),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snap.hasError) {
                          return Center(
                            child: Text('Error: ${snap.error}'),
                          );
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
        ),
      ),
    );
  }

  Widget _definitionTile(String language, String meaning) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            language, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              color: AppColors.primary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            meaning, 
            style: TextStyle(
              color: AppColors.textDark, 
              fontSize: 16,
              height: 1.6,
            ),
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
        Fluttertoast.showToast(
          msg: "Bookmarked successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: AppColors.primary, 
          textColor: Colors.white,
          fontSize: 16.0
        );
      }
    });
    await prefs.setStringList('bookmarks_${widget.poemId}', bookmarkedLines.map((e) => e.toString()).toList());
  }

  void _addNote(int lineId) async {
    final controller = TextEditingController(text: lineNotes[lineId]);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Note', style: Theme.of(context).textTheme.titleMedium),
        content: TextField(
          controller: controller, 
          maxLines: 5, 
          decoration: InputDecoration(
            hintText: 'Enter your note...',
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('Cancel', style: TextStyle(color: AppColors.textLight)),
          ),
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
              if (mounted) {
                Fluttertoast.showToast(
                  msg: "Note saved",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: AppColors.primary,
                  textColor: Colors.white,
                  fontSize: 16.0
                );
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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

  void _shareLine(String text) async {
    try {
      await Share.share(text, subject: 'Line from Javied Nama');
    } catch (e) {
      debugPrint('Error sharing line: $e'); // Add this line to log the error
      // Fallback sharing method
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) { // Keep the mounted check
        Fluttertoast.showToast(
          msg: "Sharing failed. Line copied to clipboard.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.grey[700], // Example color
          textColor: Colors.white,
          fontSize: 16.0
        );
      }
    }
  }

  Future<void> _shareAsImage() async {
    try {
      final text = lines.map((l) => l['line_text'] ?? '').join('\n');
      await Share.share(text, subject: 'Poem from Javied Nama');
    } catch (e) {
      // Fallback sharing method
      final fallbackText = lines.map((l) => l['line_text'] ?? '').join('\n');
      await Clipboard.setData(ClipboardData(text: fallbackText));
      if (mounted) {
        Fluttertoast.showToast(
          msg: "Sharing failed. Poem copied to clipboard.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.grey[700],
          textColor: Colors.white,
          fontSize: 16.0
        );
      }
    }
  }

  void _showFontSizeBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Adjust Font Size',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('A', style: TextStyle(fontSize: 14)),
                Expanded(
                  child: ValueListenableBuilder<double>(
                    valueListenable: AppTheme.fontSizeNotifier,
                    builder: (context, value, _) => Slider(
                      value: value,
                      min: 0.8,
                      max: 1.5,
                      divisions: 7,
                      activeColor: AppColors.primary,
                      label: '${(value * 100).round()}%',
                      onChanged: (v) {
                        ThemeController.setFontSize(v);
                      },
                    ),
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ValueListenableBuilder<double>(
                valueListenable: AppTheme.fontSizeNotifier,
                builder: (context, value, _) => Text(
                  'جاویِد نامہ',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 24 * value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _scrollToLine(int index) {
    // Each card is about 120px tall, adjust as needed
    _scrollController.animateTo(
      index * 120.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Main content widget that will be wrapped by Hero
    Widget content = Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _showAppBar ? Offset.zero : const Offset(0, 2),
        child: FloatingActionButton(
          heroTag: null,
          onPressed: _toggleImmersiveMode,
          backgroundColor: AppColors.primary,
          child: Icon(
            _isImmersiveMode ? Icons.fullscreen_exit : Icons.fullscreen,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : lines.isEmpty
              ? _buildEmptyState()
              : _buildPoemContent(isTablet),
    );

    // Wrap the content with Hero if heroTag is provided
    if (widget.heroTag != null) {
      return Hero(
        tag: widget.heroTag!,
        child: content,
      );
    } else {
      return content;
    }
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: 80,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: AppColors.surface.withOpacity(0.7),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      title: FadeTransition(
        opacity: _fadeAnimation,
        child: const Text(
          'Poem Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.text_fields),
          tooltip: 'Adjust Font Size',
          onPressed: _showFontSizeBottomSheet,
        ),
        IconButton(
          icon: const Icon(Icons.share_outlined),
          tooltip: 'Share Poem',
          onPressed: _shareAsImage,
        ),
      ],
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading poem...',
            style: TextStyle(color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
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
    );
  }
  
  Widget _buildPoemContent(bool isTablet) {
    return GestureDetector(
      onTap: () {
        if (_isImmersiveMode) {
          setState(() {
            _showAppBar = !_showAppBar;
            if (_showAppBar) {
              _animationController.reverse();
            } else {
              _animationController.forward();
            }
          });
        }
      },
      child: Stack(
        children: [
          // Subtle decorative background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withOpacity(0.5),
                  AppColors.background,
                ],
              ),
            ),
          ),
          
          // Content
          ValueListenableBuilder<double>(
            valueListenable: AppTheme.fontSizeNotifier,
            builder: (context, fontSize, _) {
              return SafeArea(
                top: _isImmersiveMode,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.only(
                    top: _isImmersiveMode ? 0 : 80,
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      left: isTablet ? 32 : 16,
                      right: isTablet ? 32 : 16,
                      top: _isImmersiveMode ? 24 : 20,
                      bottom: 24,
                    ),
                    itemCount: lines.length,
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      final isHighlighted = _highlightedLineIndex == index;
                      final isExpanded = _expandedLineIndex == index;
                      
                      return AnimatedPadding(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.only(
                          bottom: 16,
                          top: index == 0 ? (_isImmersiveMode ? 16 : 8) : 0,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isHighlighted 
                              ? AppColors.primary.withOpacity(0.08)
                              : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isHighlighted
                                  ? AppColors.primary.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.05),
                                blurRadius: isHighlighted ? 8 : 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              splashColor: AppColors.primary.withOpacity(0.1),
                              onTap: () => _toggleExpandLine(index),
                              onLongPress: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.surface.withOpacity(0.95),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                                      ),
                                      padding: const EdgeInsets.all(24),
                                      child: _buildLineActionSheet(line, index),
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Line text with animation for selection
                                    TweenAnimationBuilder<double>(
                                      tween: Tween<double>(begin: 0.9, end: 1.0),
                                      duration: const Duration(milliseconds: 200),
                                      builder: (context, scale, child) {
                                        return Transform.scale(
                                          scale: scale,
                                          child: child,
                                        );
                                      },
                                      child: SelectableText(
                                        line['line_text'] ?? '',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 20 * fontSize,
                                          fontFamily: AppTheme.fontFamily,
                                          height: 1.8,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).textTheme.titleLarge?.color,
                                        ),
                                        onSelectionChanged: (selection, cause) {
                                          if (cause == SelectionChangedCause.longPress) {
                                            final selectedWord = selection.textInside(line['line_text'] ?? '');
                                            if (selectedWord.isNotEmpty) _showWordDefinition(selectedWord);
                                          }
                                        },
                                      ),
                                    ),
                                    
                                    // Translations with animated expansion
                                    AnimatedSize(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      child: Container(
                                        height: (!isExpanded && !isHighlighted && line['urdu_trans'] == null && line['Eng_trans'] == null) ? 0 : null,
                                        padding: (isExpanded || isHighlighted) && (line['urdu_trans'] != null || line['Eng_trans'] != null)
                                          ? const EdgeInsets.only(top: 16)
                                          : EdgeInsets.zero,
                                        child: AnimatedOpacity(
                                          opacity: (isExpanded || isHighlighted) ? 1.0 : 0.0,
                                          duration: const Duration(milliseconds: 200),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              if (line['urdu_trans'] != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 8),
                                                  child: Text(
                                                    line['urdu_trans'] ?? '',
                                                    textAlign: TextAlign.right,
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontSize: 16 * fontSize,
                                                      height: 1.6,
                                                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.9),
                                                    ),
                                                  ),
                                                ),
                                              if (line['Eng_trans'] != null)
                                                Text(
                                                  line['Eng_trans'] ?? '',
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    fontSize: 16 * fontSize,
                                                    fontStyle: FontStyle.italic,
                                                    height: 1.5,
                                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.85),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Notes with card styling
                                    if (lineNotes.containsKey(index))
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.only(top: 16),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.primary.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.note,
                                                      size: 16,
                                                      color: AppColors.primary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Your Note:',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.edit, size: 16),
                                                  color: AppColors.primary,
                                                  onPressed: () => _addNote(index),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              lineNotes[index]!,
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontSize: 15 * fontSize,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                    // Action buttons
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          _actionIconButton(
                                            icon: bookmarkedLines.contains(index) 
                                              ? Icons.bookmark 
                                              : Icons.bookmark_border,
                                            color: bookmarkedLines.contains(index) 
                                              ? AppColors.primary 
                                              : AppColors.textLight,
                                            onPressed: () => _toggleBookmark(index),
                                            tooltip: 'Bookmark',
                                          ),
                                          const SizedBox(width: 8),
                                          _actionIconButton(
                                            icon: lineNotes.containsKey(index) 
                                              ? Icons.note 
                                              : Icons.note_add_outlined,
                                            color: lineNotes.containsKey(index) 
                                              ? AppColors.primary 
                                              : AppColors.textLight,
                                            onPressed: () => _addNote(index),
                                            tooltip: 'Add Note',
                                          ),
                                          const SizedBox(width: 8),
                                          _actionIconButton(
                                            icon: Icons.share_outlined,
                                            color: AppColors.textLight,
                                            onPressed: () => _shareLine(line['line_text'] ?? ''),
                                            tooltip: 'Share',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: color,
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        padding: const EdgeInsets.all(8),
        splashRadius: 20,
      ),
    );
  }

  Widget _buildLineActionSheet(dynamic line, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
          margin: const EdgeInsets.only(bottom: 24),
        ),
        const Text(
          'Line Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 32),
        _actionTile(
          Icons.bookmark,
          bookmarkedLines.contains(index) ? 'Remove Bookmark' : 'Add Bookmark',
          () {
            _toggleBookmark(index);
            Navigator.pop(context);
          },
          color: bookmarkedLines.contains(index) ? AppColors.primary : null,
        ),
        _actionTile(
          Icons.note,
          lineNotes.containsKey(index) ? 'Edit Note' : 'Add Note',
          () {
            Navigator.pop(context);
            _addNote(index);
          },
        ),
        _actionTile(
          Icons.share,
          'Share Line',
          () {
            Navigator.pop(context);
            _shareLine(line['line_text'] ?? '');
          },
        ),
        _actionTile(
          Icons.content_copy,
          'Copy Text',
          () async {
            await Clipboard.setData(ClipboardData(text: line['line_text'] ?? ''));
            Navigator.pop(context);
            if (mounted) {
              Fluttertoast.showToast(
                msg: "Text copied to clipboard",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.grey[700],
                textColor: Colors.white,
                fontSize: 16.0
              );
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(fontSize: 16),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }
}
