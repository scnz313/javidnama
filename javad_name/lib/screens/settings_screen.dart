import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../controllers/theme_controller.dart';
import 'main_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences prefs;
  bool showTranslations = true;
  bool autoSaveNotes = true;
  double fontSize = 1.0;
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
      setState(() => currentTheme = themeName);
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
      setState(() => fontSize = size);
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
      builder: (_) => AlertDialog(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Theme Settings
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Theme Settings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('App Theme', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _themeOption('Light', 'light', Icons.light_mode, AppColors.lightBackground, AppColors.lightSurface, AppColors.lightPrimary),
                                _themeOption('Dark', 'dark', Icons.dark_mode, AppColors.darkBackground, AppColors.darkSurface, AppColors.darkPrimary),
                                _themeOption('Sepia', 'sepia', Icons.auto_stories, AppColors.sepiaBackground, AppColors.sepiaSurface, AppColors.sepiaPrimary),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Font Size', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Text('A', style: TextStyle(fontSize: 14)),
                                Expanded(
                                  child: Slider(
                                    value: fontSize,
                                    min: 0.8,
                                    max: 1.5,
                                    divisions: 7,
                                    label: '${(fontSize * 100).round()}%',
                                    onChanged: (value) => setState(() => fontSize = value),
                                    onChangeEnd: _setFontSize,
                                  ),
                                ),
                                const Text('A', style: TextStyle(fontSize: 24)),
                              ],
                            ),
                            Center(child: Text('Preview Text', style: TextStyle(fontSize: 16 * fontSize, fontFamily: 'Jameelnoori'))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Display Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5)),
                ),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Show Translations'),
                        subtitle: const Text('Display translations under each line'),
                        value: showTranslations,
                        onChanged: (value) => setState(() { showTranslations = value; _saveSettings(); }),
                      ),
                      SwitchListTile(
                        title: const Text('Auto-save Notes'),
                        subtitle: const Text('Automatically save notes while typing'),
                        value: autoSaveNotes,
                        onChanged: (value) => setState(() { autoSaveNotes = value; _saveSettings(); }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Data Management', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5)),
                ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('About', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5)),
                ),
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
                        subtitle: const Text('Send comments or report issues'),
                        leading: const Icon(Icons.feedback_outlined),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _themeOption(String label, String value, IconData icon, Color backgroundColor, Color cardColor, Color accentColor) {
    final isSelected = currentTheme == value;
    return InkWell(
      onTap: () => _setTheme(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? accentColor : Colors.grey.withOpacity(0.3), width: isSelected ? 2 : 1),
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
                  Container(width: 40, height: 6, margin: const EdgeInsets.only(bottom: 4), decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(3))),
                  Container(width: 40, height: 20, decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(4), border: Border.all(color: accentColor.withOpacity(0.5), width: 1))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: isSelected ? accentColor : Colors.grey),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? accentColor : Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
