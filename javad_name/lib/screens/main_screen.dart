import 'package:flutter/material.dart';
import '../constants.dart';
import 'home_screen.dart';
import 'bookmarks_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookmarksScreen(),
    const SettingsScreen(),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeType>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, themeType, _) {
        // Define navigation destinations once
        const List<NavigationDestination> destinations = [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_outlined),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            // Define a breakpoint for switching navigation types
            const double tabletBreakpoint = 600; // Adjust as needed

            if (constraints.maxWidth < tabletBreakpoint) {
              // Use Bottom Navigation Bar for smaller screens
              return Scaffold(
                body: IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onTabSelected,
                  labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                  destinations: destinations,
                ),
              );
            } else {
              // Use Navigation Rail for larger screens
              return Scaffold(
                body: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _onTabSelected,
                      labelType: NavigationRailLabelType.selected, // Or .all, .none
                      destinations: destinations
                          .map((dest) => NavigationRailDestination(
                                icon: dest.icon,
                                selectedIcon: dest.selectedIcon,
                                label: Text(dest.label),
                              ))
                          .toList(),
                    ),
                    const VerticalDivider(thickness: 1, width: 1),
                    // Main content area takes the remaining space
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _screens,
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }
}
