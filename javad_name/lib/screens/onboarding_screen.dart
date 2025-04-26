import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components.dart';
import '../constants.dart';
import '../animations.dart';
// TODO: Import your main app screen, e.g., import 'home_screen.dart';

// Data structure for onboarding content
class OnboardingPageData {
  final String title;
  final IconData icon;
  final List<FeatureItem> features;

  const OnboardingPageData({
    required this.title,
    required this.icon,
    required this.features,
  });
}

class FeatureItem {
  final String title;
  final String description;
  final IconData icon; // Use an icon for the list tile leading widget

  const FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}

// Define the onboarding content based on your feature sections
final List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    title: "Basic Features",
    icon: Icons.search, // Example icon
    features: [
      FeatureItem(title: "Search", description: "Find poems easily.", icon: Icons.search),
      FeatureItem(title: "View Poems", description: "Read and explore.", icon: Icons.article),
    ],
  ),
  OnboardingPageData(
    title: "Navigation & Interaction",
    icon: Icons.translate, // Example icon
    features: [
      FeatureItem(title: "Expand for Translation", description: "Tap lines for Urdu/English.", icon: Icons.translate),
      FeatureItem(title: "Word Meanings", description: "Understand difficult words.", icon: Icons.book),
    ],
  ),
  OnboardingPageData(
    title: "Personalization",
    icon: Icons.bookmark, // Example icon
    features: [
      FeatureItem(title: "Bookmarking", description: "Save your favorites.", icon: Icons.bookmark_border),
      FeatureItem(title: "Notes", description: "Add personal notes.", icon: Icons.note_add),
      FeatureItem(title: "Share", description: "Share poems with others.", icon: Icons.share),
    ],
  ),
  OnboardingPageData(
    title: "Customization",
    icon: Icons.text_fields, // Example icon
    features: [
      FeatureItem(title: "Font & Size", description: "Adjust text appearance.", icon: Icons.font_download),
      FeatureItem(title: "Theme", description: "Choose light or dark mode.", icon: Icons.color_lens),
      FeatureItem(title: "Display Options", description: "Customize layout.", icon: Icons.display_settings),
    ],
  ),
  OnboardingPageData(
    title: "Data Management",
    icon: Icons.cleaning_services, // Example icon
    features: [
      FeatureItem(title: "Clear Data", description: "Manage stored data.", icon: Icons.delete_sweep),
    ],
  ),
];

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;
  late AnimationController _iconAnimationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward(); // Start animation on init

    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward(); // Start animation on init

    _pageController.addListener(() {
      int nextPage = _pageController.page?.round() ?? 0;
      if (nextPage != _currentPage) {
        setState(() {
          _currentPage = nextPage;
          _animationController.reset(); // Reset animation for new page
          _animationController.forward();
          _iconAnimationController.reset(); // Reset icon animation for new page
          _iconAnimationController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    widget.onComplete();
  }

  void _nextPage() {
    if (_currentPage < onboardingPages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: AppAnimations.pageTransitionDuration,
        curve: AppAnimations.pageTransitionCurve,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      onboardingPages.length - 1,
      duration: AppAnimations.pageTransitionDuration,
      curve: AppAnimations.pageTransitionCurve,
    );
  }

  Widget _buildFeatureItem(FeatureItem item) {
    return AppComponents.modernListTile(
      title: item.title,
      subtitle: item.description,
      leading: Icon(item.icon, color: AppColors.primary),
      backgroundColor: AppColors.surface.withOpacity(0.7),
      borderRadius: 12.0,
    );
  }

  Widget _buildPageContent(OnboardingPageData page) {
    final iconAnimation = CurvedAnimation(
      parent: _iconAnimationController,
      curve: Curves.elasticOut,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevent column from taking more space than needed
        children: [
          const SizedBox(height: 20.0),
          // Animated icon
          Center(
            child: SizedBox( // Constrain the size to prevent potential overflow
              width: 120,
              height: 120,
              child: AppAnimations.fadeScaleIn(
                child: ScaleTransition(
                  scale: iconAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      page.icon,
                      size: 60.0,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32.0),
          // Title
          AppAnimations.fadeIn(
            child: Text(
              page.title,
              style: const TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF442C14),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          // Feature items list with staggered animation
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true, // Ensure ListView doesn't try to be bigger than available space
              itemCount: page.features.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12.0),
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Staggered animation delay based on index
                    final double delayedValue = _animationController.value -
                        (index * 0.2); // 0.2 seconds delay between items
                    // Ensure opacity is strictly between 0.0 and 1.0
                    final double opacity = delayedValue.clamp(0.0, 1.0);
                    // Ensure slideValue is also properly constrained
                    final double slideValue = (1.0 - opacity.clamp(0.0, 1.0)) * 0.25;

                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, 30 * slideValue),
                        child: child,
                      ),
                    );
                  },
                  child: _buildFeatureItem(page.features[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(onboardingPages.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: _currentPage == index ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.primary
                : AppColors.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4.0),
          ),
        );
      }),
    );
  }

  Widget _buildButtons() {
    final isLastPage = _currentPage == onboardingPages.length - 1;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Skip button (not shown on last page)
          if (!isLastPage)
            TextButton(
              onPressed: _skipToEnd,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const SizedBox.shrink(), // Empty widget when on last page
            
          // Next/Get Started button  
          AppComponents.modernButton(
            text: isLastPage ? 'Get Started' : 'Next',
            onPressed: _nextPage,
            backgroundColor: AppColors.primary,
            isFullWidth: false,
            borderRadius: 12.0,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // PageView for swipeable content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingPages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPageContent(onboardingPages[index]);
                },
              ),
            ),
            const SizedBox(height: 20.0),
            // Dot indicator
            _buildDotIndicator(),
            const SizedBox(height: 40.0),
            // Navigation buttons
            _buildButtons(),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }
}
