import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../constants.dart';
import '../components/font_comparison_component.dart';

class FontComparisonScreen extends StatefulWidget {
  const FontComparisonScreen({Key? key}) : super(key: key);

  @override
  State<FontComparisonScreen> createState() => _FontComparisonScreenState();
}

class _FontComparisonScreenState extends State<FontComparisonScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _samplePoems = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _loadSamplePoems();
  }

  Future<void> _loadSamplePoems() async {
    try {
      // Load poem data from assets
      final String poemsJson = await rootBundle.loadString('assets/poems.json');
      final List<dynamic> poemsData = json.decode(poemsJson);
      
      // Load translations
      final String transJson = await rootBundle.loadString('assets/lines_trans.json');
      final Map<String, dynamic> translations = json.decode(transJson);
      
      // Extract a few random poems with their verses
      final List<Map<String, dynamic>> sampledPoems = [];
      
      // Pick 3 random poems
      final indices = _getRandomIndices(poemsData.length, 3);
      
      for (final index in indices) {
        if (index < poemsData.length) {
          final poem = poemsData[index];
          final poemId = poem['id'].toString();
          
          // Get a couple of verses
          final List<String> verses = List<String>.from(poem['verses']);
          final List<String> sampleVerses = verses.length > 2 ? verses.sublist(0, 2) : verses;
          
          // Get translations for these verses
          final List<String> translatedVerses = [];
          for (final verse in sampleVerses) {
            final String verseId = "$poemId:${verses.indexOf(verse)}";
            final translation = translations[verseId];
            if (translation != null) {
              translatedVerses.add(translation);
            } else {
              translatedVerses.add("Translation not available");
            }
          }
          
          sampledPoems.add({
            'title': poem['title'],
            'verses': sampleVerses,
            'translations': translatedVerses,
          });
        }
      }
      
      setState(() {
        _samplePoems = sampledPoems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading poems: $e');
      setState(() {
        _isLoading = false;
        _samplePoems = [
          {
            'title': 'Sample Poem',
            'verses': [
              'خودی کا سرِ نہاں لا الہ الا اللہ',
              'خودی ہے تیغ، فساں لا الہ الا اللہ'
            ],
            'translations': [
              'The secret of the Self is hid, In words "There is no god but He."',
              'The Self is just a dullish sword, The whetstone thereof is "He."'
            ],
          }
        ];
      });
    }
  }
  
  List<int> _getRandomIndices(int max, int count) {
    final List<int> indices = [];
    final List<int> available = List.generate(max, (i) => i);
    
    for (int i = 0; i < min(count, max); i++) {
      final randomIndex = _random.nextInt(available.length);
      indices.add(available[randomIndex]);
      available.removeAt(randomIndex);
    }
    
    return indices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Font Comparison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadSamplePoems();
            },
            tooltip: 'Load different poems',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compare Fonts with Real Poems',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'See how different fonts look with actual poetry content to help you choose the perfect reading experience.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Font comparison component
                  const FontComparisonComponent(),
                  
                  const SizedBox(height: 32),
                  
                  // Sample real poems with different fonts
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                    child: Text(
                      'Real Poems with Different Fonts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  ..._samplePoems.map((poem) => _buildPoemFontShowcase(poem)),
                  
                  const SizedBox(height: 24),
                  
                  // Tip card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tip: Different fonts may have varying readability at different sizes. Try adjusting the font size in settings for the optimal reading experience.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildPoemFontShowcase(Map<String, dynamic> poem) {
    // Define the fonts to showcase
    final fonts = ['Jameelnoori', 'MehrNastaliq', 'NotoNastaliqUrdu', 'Amiri'];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poem title
            Text(
              poem['title'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            // Font showcase
            for (final font in fonts)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Font name
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        font,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Poem verses in this font
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Original verses
                            ...List.generate(poem['verses'].length, (i) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Text(
                                  poem['verses'][i],
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize: 18,
                                    height: 1.8,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }),
                            
                            const Divider(height: 24),
                            
                            // Translations
                            ...List.generate(poem['translations'].length, (i) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Text(
                                  poem['translations'][i],
                                  style: const TextStyle(
                                    fontFamily: 'Lora',
                                    fontSize: 14,
                                    height: 1.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
