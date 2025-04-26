import 'package:flutter/material.dart';
import '../constants.dart';
import '../animations.dart';

class FontComparisonComponent extends StatefulWidget {
  const FontComparisonComponent({Key? key}) : super(key: key);

  @override
  State<FontComparisonComponent> createState() => _FontComparisonComponentState();
}

class _FontComparisonComponentState extends State<FontComparisonComponent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  
  // Sample poem couplet for comparison (Urdu/Arabic)
  final String _poemSample = 'خودی کا سرِ نہاں لا الہ الا اللہ\nخودی ہے تیغ، فساں لا الہ الا اللہ';
  
  // Sample poem in English
  final String _poemSampleEng = 'The secret of the Self is hid, In words "There is no god but He."\nThe Self is just a dullish sword, The whetstone thereof is "He."';
  
  // Font pairs to compare (Arabic/Urdu font + Latin font)
  final List<List<String>> _fontPairs = [
    ['Jameelnoori', 'Lora'],
    ['MehrNastaliq', 'OpenSans'],
    ['NotoNastaliqUrdu', 'Roboto'],
    ['Amiri', 'Lora'],
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _fontPairs.length,
      vsync: this,
    );
    
    _tabController.addListener(() {
      setState(() {
        if (_tabController.indexIsChanging) {
          _currentIndex = _tabController.index;
        }
      });
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab bar for font pairs
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _fontPairs.map((pair) {
            return Tab(text: '${pair[0]} / ${pair[1]}');
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // Font comparison view
        SizedBox(
          height: 220,
          child: TabBarView(
            controller: _tabController,
            children: _fontPairs.map((pair) {
              return _buildComparisonCard(pair[0], pair[1]);
            }).toList(),
          ),
        ),
        
        // Caption
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
          child: Text(
            'Swipe to compare different font pairs',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textLight,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildComparisonCard(String urduFont, String latinFont) {
    return AppAnimations.fadeIn(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Urdu text
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Center(
                      child: Text(
                        _poemSample,
                        style: TextStyle(
                          fontFamily: urduFont,
                          fontSize: 18,
                          height: 1.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Divider with font labels
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.divider,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$urduFont → $latinFont',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.divider,
                    ),
                  ),
                ],
              ),
              
              // English text
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _poemSampleEng,
                      style: TextStyle(
                        fontFamily: latinFont,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
