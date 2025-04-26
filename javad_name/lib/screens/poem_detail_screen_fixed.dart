import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/translation_service.dart';
import '../constants.dart';
import '../controllers/theme_controller.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:flutter/services.dart'; // For clipboard functionality

class PoemDetailScreen extends StatefulWidget {
  final int poemId;
  final int? initialLineIndex;
  const PoemDetailScreen({Key? key, required this.poemId, this.initialLineIndex}) : super(key: key);

  @override
  State<PoemDetailScreen> createState() => _PoemDetailScreenState();
}

class _PoemDetailScreenState extends State<PoemDetailScreen> with SingleTickerProviderStateMixin {
  List<dynamic> lines = [];
  Map<String, dynamic> definitions = {};
  Set<int> bookmarkedLines = {};
  Map<int, String> lineNotes = {};
  late SharedPreferences prefs;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isLoading = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TranslationService _translationService = TranslationService();
  final ScrollController _scrollController = ScrollController();
  int? _highlightedLineIndex;
  bool _showAppBar = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isImmersiveMode = false;
  int? _expandedLineIndex;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _fetchLines();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
    
    _scrollController.addListener(_scrollListener);
    
    if (widget.initialLineIndex != null) {
      _highlightedLineIndex = widget.initialLineIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToLine(widget.initialLineIndex!);
      });
    }
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    // Hide app bar on scroll down, show on scroll up
    if (_scrollController.position.userScrollDirection == AxisDirection.down) {
      if (_showAppBar) {
        setState(() {
          _showAppBar = false;
          _animationController.forward();
        });
      }
    } else if (_scrollController.position.userScrollDirection == AxisDirection.up) {
      if (!_showAppBar) {
        setState(() {
          _showAppBar = true;
          _animationController.reverse();
        });
      }
    }
  }

  // Rest of the code remains the same
} 