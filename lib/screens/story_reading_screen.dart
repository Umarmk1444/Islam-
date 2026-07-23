import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/library_item.dart';
import '../models/fatwa_item.dart';
import '../models/roqua_item.dart';
import '../services/library_service.dart';
import '../theme_notifier.dart';

class StoryReadingScreen extends StatefulWidget {
  final LibraryItem? item;
  final FatwaItem? fatwaItem;
  final RoquaItem? roquaItem;

  const StoryReadingScreen({
    super.key,
    this.item,
    this.fatwaItem,
    this.roquaItem,
  }) : assert(item != null || fatwaItem != null || roquaItem != null);

  @override
  State<StoryReadingScreen> createState() => _StoryReadingScreenState();
}

class _StoryReadingScreenState extends State<StoryReadingScreen> {
  final LibraryService _libraryService = LibraryService();
  
  bool _isFav = false;
  bool _isLoading = true;
  String _content = '';
  double _fontSize = 22.0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (widget.item != null) {
      _isFav = widget.item!.isFav;
      _libraryService.recordReading(widget.item!.id, widget.item!.numReadings);
      _content = await _libraryService.getLibraryStory(widget.item!.id);
    } else if (widget.fatwaItem != null) {
      _content = await _libraryService.getFatwaAnswer(widget.fatwaItem!.id);
    } else if (widget.roquaItem != null) {
      _content = await _libraryService.getRoquaStory(widget.roquaItem!.id);
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFav() async {
    if (widget.item != null) {
      final newFav = !_isFav;
      await _libraryService.toggleFavorite(widget.item!.id, newFav);
      setState(() {
        _isFav = newFav;
      });
    }
  }

  void _increaseFontSize() {
    setState(() {
      if (_fontSize < 40) _fontSize += 2.0;
    });
  }

  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > 14) _fontSize -= 2.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.notifier.value;
    final isDark = theme == QuranTheme.dark;
    
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;

    final String title = widget.item != null 
        ? widget.item!.title 
        : widget.fatwaItem != null 
            ? widget.fatwaItem!.question 
            : widget.roquaItem!.title;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.remove_circle_outline_rounded, color: textColor),
            onPressed: _decreaseFontSize,
            tooltip: 'Decrease Font',
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: textColor),
            onPressed: _increaseFontSize,
            tooltip: 'Increase Font',
          ),
          if (widget.item != null)
            IconButton(
              icon: Icon(
                _isFav ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                color: _isFav ? Colors.redAccent : textColor,
              ),
              onPressed: _toggleFav,
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.emeraldLight))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              _content,
              style: TextStyle(
                color: textColor,
                fontSize: _fontSize,
                height: 1.8,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
    );
  }
}
