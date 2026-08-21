import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/fonts/app_fonts.dart';
import '../../core/models/custom_smart_word.dart';
import '../../core/models/span_style.dart';
import '../../core/services/notes_service.dart';
import '../../core/typography/smart_words_engine.dart';

class SmartWordsScreen extends StatefulWidget {
  const SmartWordsScreen({super.key});

  @override
  State<SmartWordsScreen> createState() => _SmartWordsScreenState();
}

class _SmartWordsScreenState extends State<SmartWordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showChatGptImportSheet() {
    HapticFeedback.mediumImpact();
    final jsonController = TextEditingController();
    String? errorText;

    const String chatGptPrompt = '''
You are an aesthetic typography stylist for the "Null" minimalist notes app.
Analyze my unique vocabulary, slang, phrases, names, and emotional expressions, or generate 15-30 custom smart word typography rules tailored to my vibe.

Available Font Families (choose one per word):
- Beatrice (Editorial, Elegant, High-fashion serif/sans)
- Coolvetica (Modern, Trendy, Y2K Slang & Punchy)
- Aloevera (Soft, Romantic, Organic, Expressive)
- BasementGrotesque (Heavy, Brutalist, Bold impact)
- Futura (Geometric, Clean, High-end Luxe)
- Agitha (Atmospheric, Dreamy, 3AM Void)
- ForeverFreedom (Mystical, Expressive script)
- TimesNewRoman (Classic Editorial Serif)
- SFProDisplay (Clean Apple Standard)

Available Highlight Color Hexes (or null):
- 0x44FF453A (Rose Crimson)
- 0x44BF5AF2 (Lilac Violet)
- 0x44FFD60A (Amber Gold)
- 0x4464D2FF (Sky Blue)
- 0x4432D74B (Emerald Green)
- 0x33FFFFFF (Minimalist Glow)

Return ONLY a valid JSON code block with an array of objects matching this schema:
```json
[
  {
    "word": "bestie",
    "fontFamily": "Coolvetica",
    "bold": true,
    "italic": true,
    "highlightColorValue": 1153374962
  },
  {
    "word": "iconic",
    "fontFamily": "Beatrice",
    "bold": false,
    "italic": true,
    "highlightColorValue": 1157584186
  }
]
```
''';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              margin: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: bottomInset > 0 ? bottomInset + 16 : 24,
                top: 50,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 36,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text(
                              '✨',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'AI Smart Words Import',
                              style: TextStyle(
                                fontFamily: AppFonts.sfProDisplay,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEDEDED),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(modalCtx),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Generate custom smart word typography rules tailored to your personality using ChatGPT.',
                      style: TextStyle(
                        fontFamily: AppFonts.sfProText,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // STEP 1: Copy Prompt
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1B1E),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'STEP 1',
                                style: TextStyle(
                                  fontFamily: AppFonts.sfProText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Copy Prompt to ChatGPT',
                                style: TextStyle(
                                  fontFamily: AppFonts.sfProDisplay,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEDEDED),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Paste into ChatGPT to extract and style your frequently used words.',
                            style: TextStyle(
                              fontFamily: AppFonts.sfProText,
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(const ClipboardData(text: chatGptPrompt));
                              HapticFeedback.mediumImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('AI Prompt copied to clipboard! Paste into ChatGPT.'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.copy_rounded, size: 14, color: Colors.black),
                                  SizedBox(width: 6),
                                  Text(
                                    'Copy Prompt',
                                    style: TextStyle(
                                      fontFamily: AppFonts.sfProText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // STEP 2: Paste Output
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1B1E),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'STEP 2',
                                style: TextStyle(
                                  fontFamily: AppFonts.sfProText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Paste JSON Output Here',
                                style: TextStyle(
                                  fontFamily: AppFonts.sfProDisplay,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEDEDED),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: jsonController,
                            maxLines: 6,
                            style: const TextStyle(
                              fontFamily: AppFonts.sfProText,
                              fontSize: 12,
                              color: Color(0xFFEDEDED),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Paste the JSON response from ChatGPT here...',
                              hintStyle: TextStyle(
                                fontFamily: AppFonts.sfProText,
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF141416),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.white, width: 1.2),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          if (errorText != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              errorText!,
                              style: const TextStyle(
                                fontFamily: AppFonts.sfProText,
                                fontSize: 12,
                                color: Color(0xFFFF453A),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              final text = jsonController.text.trim();
                              if (text.isEmpty) {
                                setModalState(() {
                                  errorText = 'Please paste the JSON from ChatGPT first.';
                                });
                                return;
                              }

                              try {
                                // Strip markdown codeblock if present
                                String cleaned = text;
                                if (cleaned.contains('```json')) {
                                  cleaned = cleaned.split('```json').last.split('```').first.trim();
                                } else if (cleaned.contains('```')) {
                                  cleaned = cleaned.split('```').last.split('```').first.trim();
                                }

                                final dynamic parsed = jsonDecode(cleaned);
                                if (parsed is! List) {
                                  throw const FormatException('Expected a JSON array of words.');
                                }

                                final newCustomWords = <CustomSmartWord>[];
                                for (final item in parsed) {
                                  if (item is Map<String, dynamic>) {
                                    newCustomWords.add(CustomSmartWord.fromJson(item));
                                  } else if (item is Map) {
                                    newCustomWords.add(CustomSmartWord.fromJson(Map<String, dynamic>.from(item)));
                                  }
                                }

                                if (newCustomWords.isEmpty) {
                                  throw const FormatException('No valid words found in JSON.');
                                }

                                NotesService.instance.addCustomSmartWords(newCustomWords);
                                HapticFeedback.mediumImpact();
                                Navigator.pop(modalCtx);
                                setState(() {});

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Successfully imported ${newCustomWords.length} custom smart words!'),
                                    duration: const Duration(seconds: 3),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                setModalState(() {
                                  errorText = 'Invalid JSON: Please check the ChatGPT output format.';
                                });
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1.0,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Parse & Apply Rules',
                                style: TextStyle(
                                  fontFamily: AppFonts.sfProDisplay,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEDEDED),
                                ),
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
          },
        );
      },
    );
  }

  Widget _buildSmartWordTag({
    required String word,
    required SpanStyle style,
    VoidCallback? onDelete,
  }) {
    final TextStyle wordStyle = TextStyle(
      fontFamily: style.fontFamily,
      fontSize: 13,
      fontWeight: style.fontWeight,
      fontStyle: style.isItalic == true ? FontStyle.italic : FontStyle.normal,
      decoration: style.isUnderline == true ? TextDecoration.underline : TextDecoration.none,
      color: style.colorValue != null ? Color(style.colorValue!) : const Color(0xFFEDEDED),
    );

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.highlightColorValue != null
            ? Color(style.highlightColorValue!)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(word, style: wordStyle),
          if (onDelete != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close_rounded,
                size: 13,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = SmartWordsEngine.instance.getBuiltInCategories();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Top Bar ──
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.back,
                        size: 18,
                        color: Color(0xFFEDEDED),
                      ),
                    ),
                  ),
                  const Text(
                    'Smart Words',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProDisplay,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEDEDED),
                      letterSpacing: -0.2,
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showChatGptImportSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                          width: 1.0,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.sparkles,
                            size: 13,
                            color: Color(0xFFEDEDED),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'AI Import',
                            style: TextStyle(
                              fontFamily: AppFonts.sfProText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFEDEDED),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── 2. Search & Filter Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim().toLowerCase();
                          });
                        },
                        style: const TextStyle(
                          fontFamily: AppFonts.sfProText,
                          fontSize: 14,
                          color: Color(0xFFEDEDED),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search words, slang, categories...',
                          hintStyle: TextStyle(
                            fontFamily: AppFonts.sfProText,
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── 3. Content List (Spacious & Generous Padding) ──
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 48),
                children: [
                  // Section A: Custom User / AI Imported Words
                  ValueListenableBuilder<List<CustomSmartWord>>(
                    valueListenable: NotesService.instance.customSmartWordsNotifier,
                    builder: (context, customList, _) {
                      final filteredCustom = _searchQuery.isEmpty
                          ? customList
                          : customList.where((c) => c.word.toLowerCase().contains(_searchQuery)).toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141416),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('🎯', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Custom Dynamic Rules',
                                      style: TextStyle(
                                        fontFamily: AppFonts.sfProDisplay,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFEDEDED),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${customList.length}',
                                        style: const TextStyle(
                                          fontFamily: AppFonts.sfProText,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFEDEDED),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (customList.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      NotesService.instance.clearCustomSmartWords();
                                      setState(() {});
                                      HapticFeedback.lightImpact();
                                    },
                                    child: const Text(
                                      'Clear All',
                                      style: TextStyle(
                                        fontFamily: AppFonts.sfProText,
                                        fontSize: 12,
                                        color: Color(0xFFFF453A),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Custom rules take highest priority over default dictionaries.',
                              style: TextStyle(
                                fontFamily: AppFonts.sfProText,
                                fontSize: 12,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (filteredCustom.isEmpty)
                              GestureDetector(
                                onTap: _showChatGptImportSheet,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.plus_circle,
                                        size: 16,
                                        color: Colors.white.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Import Custom Words via ChatGPT Prompt',
                                        style: TextStyle(
                                          fontFamily: AppFonts.sfProText,
                                          fontSize: 13,
                                          color: Color(0xFFEDEDED),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Wrap(
                                children: filteredCustom.map((item) {
                                  final style = SpanStyle(
                                    start: 0,
                                    end: 0,
                                    fontFamily: item.fontFamily ?? AppFonts.beatrice,
                                    fontWeightIndex: item.fontWeightIndex,
                                    isItalic: item.isItalic,
                                    isUnderline: item.isUnderline,
                                    highlightColorValue: item.highlightColorValue,
                                    colorValue: item.textColorValue,
                                  );
                                  return _buildSmartWordTag(
                                    word: item.word,
                                    style: style,
                                    onDelete: () {
                                      NotesService.instance.removeCustomSmartWord(item.word);
                                      setState(() {});
                                      HapticFeedback.lightImpact();
                                    },
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Section B: Built-In Categories
                  ...categories.map((cat) {
                    final filteredWords = _searchQuery.isEmpty
                        ? cat.words
                        : cat.words
                            .where((w) =>
                                w.toLowerCase().contains(_searchQuery) ||
                                cat.title.toLowerCase().contains(_searchQuery))
                            .toList();

                    if (filteredWords.isEmpty) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Text(
                                cat.title,
                                style: const TextStyle(
                                  fontFamily: AppFonts.sfProDisplay,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEDEDED),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            cat.description,
                            style: const TextStyle(
                              fontFamily: AppFonts.sfProText,
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            children: filteredWords.map((w) {
                              return _buildSmartWordTag(
                                word: w,
                                style: cat.style,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
