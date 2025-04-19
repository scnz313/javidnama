import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import 'poem_detail_screen.dart';

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
          ) || englishTitle.toString().toLowerCase().contains(
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search poems...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
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
          Expanded(
            child: _isLoading
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
                                    builder: (context) => PoemDetailScreen(poemId: poemId),
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
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
