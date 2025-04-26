import 'package:flutter/material.dart';
import '../constants.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use Javied Nama'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Javied Nama!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This guide will help you understand all the features available in the app.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Basic Features
          _buildFeatureSection(
            context,
            'Basic Features',
            [
              _buildFeatureItem(
                'Search',
                'Use the search bar on the home screen to find poems or lines.',
                Icons.search,
              ),
              _buildFeatureItem(
                'View Poems',
                'Tap a poem to view its details and lines.',
                Icons.article,
              ),
            ],
          ),
          
          // Navigation & Interaction
          _buildFeatureSection(
            context,
            'Navigation & Interaction',
            [
              _buildFeatureItem(
                'Expand for Translation',
                'Tap a line to expand and see its Urdu/English translation.',
                Icons.translate,
              ),
              _buildFeatureItem(
                'Word Meanings',
                'Long-press any word in a line to see its meaning in Urdu, Persian, and English.',
                Icons.touch_app,
              ),
            ],
          ),
          
          // Personalization
          _buildFeatureSection(
            context,
            'Personalization',
            [
              _buildFeatureItem(
                'Bookmarking',
                'Tap the heart icon to bookmark poems or lines for quick access.',
                Icons.bookmark,
              ),
              _buildFeatureItem(
                'Notes',
                'Add personal notes to any line by tapping the note icon.',
                Icons.note_add,
              ),
              _buildFeatureItem(
                'Share',
                'Share lines or poems using the share icon.',
                Icons.share,
              ),
            ],
          ),
          
          // Customization
          _buildFeatureSection(
            context,
            'Customization',
            [
              _buildFeatureItem(
                'Font & Size',
                'Change font family and adjust text size from settings or the poem detail screen.',
                Icons.text_fields,
              ),
              _buildFeatureItem(
                'Theme',
                'Switch between Light, Dark, and Sepia themes in settings.',
                Icons.palette,
              ),
              _buildFeatureItem(
                'Display Options',
                'Toggle translation visibility and configure auto-save for notes.',
                Icons.settings_display,
              ),
            ],
          ),
          
          // Data Management
          _buildFeatureSection(
            context,
            'Data Management',
            [
              _buildFeatureItem(
                'Clear Data',
                'Clear all bookmarks or notes from settings if needed.',
                Icons.cleaning_services,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(BuildContext context, String title, List<Widget> features) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...features,
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppColors.textMedium),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
