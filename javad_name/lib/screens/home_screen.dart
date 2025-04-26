import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../constants.dart';
import 'poem_detail_screen.dart';
import '../services/search_service.dart';

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
  List<SearchResult> _searchResults = [];
  int _searchFilter = 0; // 0: All, 1: Titles, 2: Lines
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchPoems();
    _loadFavorites();
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
      await SearchService.instance.init(poems);
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

  void _onSearchChanged(String value) async {
    setState(() => _searchQuery = value);
    if (value.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    // Debounce: cancel previous timer
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final results = await SearchService.instance.search(value, filter: _searchFilter);
      setState(() => _searchResults = results.take(50).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Javied Nama'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search poems or lines...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _searchResults = [];
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_searchQuery.isNotEmpty
                    ? _buildSearchResults(context)
                    : _buildPoemList(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _searchFilter == 0,
                onSelected: (v) {
                  setState(() => _searchFilter = 0);
                  _onSearchChanged(_searchQuery);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Titles'),
                selected: _searchFilter == 1,
                onSelected: (v) {
                  setState(() => _searchFilter = 1);
                  _onSearchChanged(_searchQuery);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Lines'),
                selected: _searchFilter == 2,
                onSelected: (v) {
                  setState(() => _searchFilter = 2);
                  _onSearchChanged(_searchQuery);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: AppColors.textLight),
                      const SizedBox(height: 16),
                      Text('No results found', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return Card(
                      child: ListTile(
                        title: Text(result.poemTitle, style: Theme.of(context).textTheme.titleMedium),
                        subtitle: result.matchLine != null
                            ? Text(result.matchLine!, style: Theme.of(context).textTheme.bodySmall)
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PoemDetailScreen(
                                poemId: result.poemId,
                                initialLineIndex: result.lineIndex,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPoemList(BuildContext context) {
    return ListView.builder(
      itemCount: poems.length,
      itemBuilder: (context, index) {
        final poem = poems[index];
        final poemId = poem['_id'] ?? 0;
        final heroTag = 'poem_card_$poemId';
        
        // IMPORTANT: Hero is a child of Card, not wrapping the Card
        // This prevents "Hero widget cannot be the descendant of another Hero" errors
        return Card(
          child: Hero(
            tag: heroTag,
            // Add transitionOnUserGestures for smoother hero transitions when navigating back
            transitionOnUserGestures: true,
            child: Material(
              color: Colors.transparent, // Keep transparent to respect Card styling
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Add a slight delay before navigation for better visual effect
                  Future.delayed(const Duration(milliseconds: 50), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PoemDetailScreen(
                        poemId: poemId,
                        heroTag: heroTag,
                      ),
                    ),
                  );
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              poem['title'] ?? 'Untitled',
                              textAlign: TextAlign.right,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (poem['englishTitle'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  poem['englishTitle'] ?? '',
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context).textTheme.bodySmall,
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
                          color: favoritePoems.contains(poemId)
                              ? Colors.red
                              : AppColors.primary,
                        ),
                        onPressed: () => _toggleFavorite(poemId),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
