import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../controllers/theme_controller.dart';
import '../components.dart';
import '../animations.dart';
import 'main_screen.dart';
import 'font_comparison_screen.dart';

class FontSettingsScreen extends StatefulWidget {
  const FontSettingsScreen({Key? key}) : super(key: key);

  @override
  State<FontSettingsScreen> createState() => _FontSettingsScreenState();
}

class _FontSettingsScreenState extends State<FontSettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String currentFont = 'Jameelnoori';
  double currentFontSize = 1.0;
  final Map<String, String> _fontSampleTexts = {
    'Jameelnoori': 'جاوید نامہ - اقبال', 
    'NotoNastaliqUrdu': 'آج سے تیرا آغاز', 
    'MehrNastaliq': 'شاعری کی دنیا', 
    'Amiri': 'الجمال في الكلام', 
    'Lora': 'Beautiful Poetry', 
    'OpenSans': 'Modern Interface',
    'Roboto': 'Clean Design'
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadCurrentSettings();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentFont = prefs.getString('font_family_preference') ?? 'Jameelnoori';
      currentFontSize = prefs.getDouble('font_size_factor') ?? 1.0;
    });
    _animationController.forward();
  }

  Future<void> _setFontFamily(String fontFamily) async {
    if (fontFamily == currentFont) return;
    
    _animationController.reset();
    
    try {
      await ThemeController.setFontFamily(fontFamily);
      setState(() => currentFont = fontFamily);
      _animationController.forward();
    } catch (e) {
      debugPrint('Error changing font: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing font: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _setFontSize(double size) async {
    if (size == currentFontSize) return;
    try {
      await ThemeController.setFontSize(size);
      setState(() => currentFontSize = size);
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

  void _applyChanges() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  Widget _buildFontCard(String fontName) {
    final bool isSelected = currentFont == fontName;
    final String sampleText = _fontSampleTexts[fontName] ?? fontName;
    
    // Determine text direction based on font
    final bool isRTL = ['Jameelnoori', 'NotoNastaliqUrdu', 'MehrNastaliq', 'Amiri'].contains(fontName);
    
    return GestureDetector(
      onTap: () => _setFontFamily(fontName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected 
            ? [BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              )] 
            : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Font name
            Text(
              fontName,
              style: TextStyle(
                fontFamily: 'Roboto', // Always show font name in Roboto
                fontSize: 14,
                color: AppColors.textMedium,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            // Sample text in the selected font
            Directionality(
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 80,
                    alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                    child: FadeTransition(
                      opacity: _animationController,
                      child: Text(
                        sampleText,
                        style: TextStyle(
                          fontFamily: fontName,
                          fontSize: 24 * currentFontSize,
                          color: AppColors.textDark,
                        ),
                        textAlign: isRTL ? TextAlign.right : TextAlign.left,
                      ),
                    ),
                  );
                }
              ),
            ),
            // Font tag
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSelected ? 'Selected' : 'Tap to select',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppColors.textMedium,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Font Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _applyChanges,
            tooltip: 'Apply Changes',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Font Size Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Font Size',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.text_decrease, size: 20),
                        Expanded(
                          child: Slider(
                            value: currentFontSize,
                            min: 0.8,
                            max: 1.5,
                            divisions: 7,
                            label: currentFontSize.toStringAsFixed(1) + 'x',
                            onChanged: _setFontSize,
                          ),
                        ),
                        const Icon(Icons.text_increase, size: 24),
                      ],
                    ),
                    // Font size preview
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Directionality(
                          textDirection: 
                              ['Jameelnoori', 'NotoNastaliqUrdu', 'MehrNastaliq', 'Amiri'].contains(currentFont) 
                              ? TextDirection.rtl 
                              : TextDirection.ltr,
                          child: Text(
                            _fontSampleTexts[currentFont] ?? 'Sample Text',
                            style: TextStyle(
                              fontFamily: currentFont,
                              fontSize: 22 * currentFontSize,
                              color: AppColors.textDark,
                            ),
                            textAlign: ['Jameelnoori', 'NotoNastaliqUrdu', 'MehrNastaliq', 'Amiri'].contains(currentFont) 
                                ? TextAlign.right 
                                : TextAlign.left,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Font Family Section
            const Text(
              'Font Family',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Font Cards - Arabic/Urdu Fonts
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Arabic/Urdu Fonts',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            _buildFontCard('Jameelnoori'),
            _buildFontCard('NotoNastaliqUrdu'),
            _buildFontCard('MehrNastaliq'),
            _buildFontCard('Amiri'),
            
            const SizedBox(height: 16),
            
            // Font Cards - Latin Fonts
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Latin Fonts',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            _buildFontCard('Lora'),
            _buildFontCard('OpenSans'),
            _buildFontCard('Roboto'),
            
            const SizedBox(height: 24),
            
            // Font Comparison Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const FontComparisonScreen())
                  );
                },
                icon: const Icon(Icons.compare),
                label: const Text('Compare Fonts with Real Poems'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Apply Button
            AppComponents.modernButton(
              text: 'Apply Changes',
              onPressed: _applyChanges,
              backgroundColor: AppColors.primary,
              isFullWidth: true,
              borderRadius: 12.0,
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
