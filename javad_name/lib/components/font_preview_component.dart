import 'package:flutter/material.dart';
import '../constants.dart';

class FontPreviewComponent extends StatefulWidget {
  const FontPreviewComponent({Key? key}) : super(key: key);

  @override
  State<FontPreviewComponent> createState() => _FontPreviewComponentState();
}

class _FontPreviewComponentState extends State<FontPreviewComponent> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fontSize;
  int _currentFontIndex = 0;
  
  // Define showcase fonts and sample texts
  final List<Map<String, dynamic>> _showcaseFonts = [
    {'font': 'Jameelnoori', 'text': 'جاوید نامہ - اقبال', 'rtl': true},
    {'font': 'MehrNastaliq', 'text': 'شاعری کی دنیا', 'rtl': true},
    {'font': 'Lora', 'text': 'Beautiful Poetry', 'rtl': false},
    {'font': 'NotoNastaliqUrdu', 'text': 'آج سے تیرا آغاز', 'rtl': true},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _showcaseFonts.length,
      vsync: this,
    );
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fontSize = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _tabController.addListener(_handleTabChange);
    _animationController.repeat(reverse: true);
    
    // Auto-switch fonts
    Future.delayed(const Duration(seconds: 2), _switchToNextFont);
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentFontIndex = _tabController.index;
      });
    }
  }
  
  void _switchToNextFont() {
    if (!mounted) return;
    
    int nextIndex = (_currentFontIndex + 1) % _showcaseFonts.length;
    _tabController.animateTo(nextIndex);
    
    // Schedule next switch
    Future.delayed(const Duration(seconds: 3), _switchToNextFont);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Font preview card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: TabBarView(
            controller: _tabController,
            children: _showcaseFonts.map((fontData) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Directionality(
                    textDirection: fontData['rtl'] ? TextDirection.rtl : TextDirection.ltr,
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Text(
                          fontData['text'],
                          style: TextStyle(
                            fontFamily: fontData['font'],
                            fontSize: 32 * _fontSize.value,
                            color: AppColors.textDark,
                            height: 1.5,
                          ),
                          textAlign: fontData['rtl'] ? TextAlign.right : TextAlign.left,
                        );
                      },
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        // Font name display
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showcaseFonts[_currentFontIndex]['font'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMedium,
                ),
              ),
              Text(
                '${_currentFontIndex + 1}/${_showcaseFonts.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
        
        // Font dots indicator
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_showcaseFonts.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentFontIndex == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentFontIndex == index
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
