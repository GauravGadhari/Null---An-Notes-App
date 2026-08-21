import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/controllers/null_rich_text_controller.dart';
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
  late final NullRichTextController _sandboxController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pasteJsonController = TextEditingController();

  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _copiedPrompt = false;
  String? _jsonErrorText;

  static const String _chatGptPrompt = '''
You are an aesthetic typography stylist for "Null" (an ultra-minimalist luxury notes app).

YOUR TASK:
1. Analyze our entire past conversation history, my messages, and writing style.
2. Extract my personal vocabulary:
   - Known person names, friends, characters, or nicknames I frequently mention
   - Domain-specific terms (coding, design, fandoms, work, gaming, daily topics)
   - Unique texting quirks, repeated expressions, and slang (e.g. "ohkkk", "gotchaa", "frfr")
3. Return 20-40 tailored words/phrases with ideal typography from the supported fonts below.

Available Font Families (choose one per style):
- Beatrice (Editorial, Elegant, Serif/Display)
- Coolvetica (Modern, Tech, Y2K Slang)
- Aloevera (Soft, Romantic, Organic)
- BasementGrotesque (Heavy, Brutalist, Bold)
- Futura (Geometric, Luxury, Ambition)
- Agitha (3AM Void, Dreamy, Solitude)
- TimesNewRoman (Classic Literary Serif)
- SFProDisplay (Clean Modern Standard)

Available Highlight Hexes (or null):
- 0x44FF453A (Rose)
- 0x44BF5AF2 (Violet)
- 0x44FFD60A (Amber)
- 0x4464D2FF (Sky)
- 0x4432D74B (Emerald)
- 0x33FFFFFF (Glow)

FORMAT (You can use "words" array or "word" string):
```json
[
  {
    "words": ["adrien", "marinette", "luka"],
    "fontFamily": "Beatrice",
    "bold": true,
    "italic": true,
    "highlightColorValue": 1157584186
  },
  {
    "words": ["ohkkk", "gotchaa", "frfr"],
    "fontFamily": "Coolvetica",
    "bold": false,
    "italic": true,
    "highlightColorValue": 1153374962
  }
]
```
Return ONLY the JSON code block without filler text.
''';

  @override
  void initState() {
    super.initState();
    _sandboxController = NullRichTextController(
      text: 'i love 3am vibes, manifesting money and peace adrien frfr',
    );
  }

  @override
  void dispose() {
    _sandboxController.dispose();
    _searchController.dispose();
    _pasteJsonController.dispose();
    super.dispose();
  }

  void _copyPrompt() {
    Clipboard.setData(const ClipboardData(text: _chatGptPrompt));
    HapticFeedback.mediumImpact();
    setState(() {
      _copiedPrompt = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _copiedPrompt = false;
        });
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prompt copied. Paste into ChatGPT to generate your custom rules.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _importJsonRules() {
    final text = _pasteJsonController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _jsonErrorText = 'Paste the JSON from ChatGPT first.';
      });
      return;
    }

    try {
      String cleaned = text;
      if (cleaned.contains('```json')) {
        cleaned = cleaned.split('```json').last.split('```').first.trim();
      } else if (cleaned.contains('```')) {
        cleaned = cleaned.split('```').last.split('```').first.trim();
      }

      final dynamic parsed = jsonDecode(cleaned);
      if (parsed is! List) {
        throw const FormatException('Expected a JSON array.');
      }

      final newCustomWords = <CustomSmartWord>[];
      for (final item in parsed) {
        if (item is Map<String, dynamic>) {
          newCustomWords.addAll(CustomSmartWord.parseJsonItem(item));
        } else if (item is Map) {
          newCustomWords.addAll(CustomSmartWord.parseJsonItem(Map<String, dynamic>.from(item)));
        }
      }

      if (newCustomWords.isEmpty) {
        throw const FormatException('No valid words found.');
      }

      NotesService.instance.addCustomSmartWords(newCustomWords);
      _pasteJsonController.clear();
      setState(() {
        _jsonErrorText = null;
        _selectedCategory = 'custom';
      });
      HapticFeedback.heavyImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Activated ${newCustomWords.length} custom smart words.'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _jsonErrorText = 'Invalid JSON: Check ChatGPT code block.';
      });
    }
  }

  void _showManualAddDialog() {
    HapticFeedback.lightImpact();
    final wordController = TextEditingController();
    String selectedFont = AppFonts.beatrice;
    bool isBold = false;
    bool isItalic = true;
    bool isUnderline = false;
    int? selectedHighlight;

    const availableFonts = [
      AppFonts.beatrice,
      AppFonts.coolvetica,
      AppFonts.aloevera,
      AppFonts.basementGrotesque,
      AppFonts.futura,
      AppFonts.agitha,
      AppFonts.timesNewRoman,
      AppFonts.sfProDisplay,
    ];

    const availableHighlights = <String, int?>{
      'None': null,
      'Rose': 0x44FF453A,
      'Violet': 0x44BF5AF2,
      'Amber': 0x44FFD60A,
      'Sky': 0x4464D2FF,
      'Emerald': 0x4432D74B,
      'Glow': 0x33FFFFFF,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return Container(
              margin: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: bottomInset > 0 ? bottomInset + 16 : 24,
                top: 40,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Smart Word',
                          style: TextStyle(
                            fontFamily: AppFonts.sfProDisplay,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEDEDED),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(modalCtx),
                          child: const Icon(CupertinoIcons.xmark, size: 16, color: Color(0xFF8E8E93)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: wordController,
                      autofocus: true,
                      style: const TextStyle(
                        fontFamily: AppFonts.sfProText,
                        fontSize: 15,
                        color: Color(0xFFEDEDED),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter word, name, or phrase...',
                        hintStyle: TextStyle(
                          fontFamily: AppFonts.sfProText,
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        filled: true,
                        fillColor: const Color(0xFF1C1C1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'TYPOGRAPHY',
                      style: TextStyle(
                        fontFamily: AppFonts.sfProText,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableFonts.map((f) {
                        final isSelected = selectedFont == f;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedFont = f);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontFamily: f,
                                fontSize: 13,
                                color: isSelected ? Colors.black : const Color(0xFFEDEDED),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _buildDialogToggle(
                          label: 'Bold',
                          isActive: isBold,
                          onTap: () => setDialogState(() => isBold = !isBold),
                        ),
                        const SizedBox(width: 8),
                        _buildDialogToggle(
                          label: 'Italic',
                          isActive: isItalic,
                          onTap: () => setDialogState(() => isItalic = !isItalic),
                        ),
                        const SizedBox(width: 8),
                        _buildDialogToggle(
                          label: 'Underline',
                          isActive: isUnderline,
                          onTap: () => setDialogState(() => isUnderline = !isUnderline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'HIGHLIGHT',
                      style: TextStyle(
                        fontFamily: AppFonts.sfProText,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: availableHighlights.entries.map((e) {
                        final isSelected = selectedHighlight == e.value;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedHighlight = e.value);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: e.value != null
                                  ? Color(e.value!)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                fontFamily: AppFonts.sfProText,
                                fontSize: 12,
                                color: Color(0xFFEDEDED),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    GestureDetector(
                      onTap: () {
                        final word = wordController.text.trim();
                        if (word.isEmpty) return;

                        NotesService.instance.addCustomSmartWords([
                          CustomSmartWord(
                            word: word,
                            fontFamily: selectedFont,
                            fontWeightIndex: isBold ? 7 : null,
                            isItalic: isItalic,
                            isUnderline: isUnderline,
                            highlightColorValue: selectedHighlight,
                          ),
                        ]);
                        Navigator.pop(modalCtx);
                        setState(() {
                          _selectedCategory = 'custom';
                        });
                        HapticFeedback.mediumImpact();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Save Word',
                          style: TextStyle(
                            fontFamily: AppFonts.sfProText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
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

  Widget _buildDialogToggle({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: isActive ? 0.3 : 0.08),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.sfProText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.black : const Color(0xFFEDEDED),
            ),
          ),
        ),
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
            // ── Top Header ──
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 8),
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
                      width: 38,
                      height: 38,
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
                        size: 17,
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
                    onTap: _showManualAddDialog,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.plus,
                        size: 17,
                        color: Color(0xFFEDEDED),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Body ──
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  // ── 1. Live Interactive Typing Sandbox ──
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(CupertinoIcons.pencil_outline, size: 14, color: Color(0xFF8E8E93)),
                            SizedBox(width: 6),
                            Text(
                              'Live Preview',
                              style: TextStyle(
                                fontFamily: AppFonts.sfProText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8E8E93),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF000000),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: TextField(
                            controller: _sandboxController,
                            maxLines: 2,
                            style: const TextStyle(
                              fontFamily: AppFonts.sfProDisplay,
                              fontSize: 15,
                              color: Color(0xFFEDEDED),
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type to test smart typography...',
                              hintStyle: TextStyle(
                                fontFamily: AppFonts.sfProDisplay,
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── 2. AI Custom Generator Studio ──
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(CupertinoIcons.sparkles, size: 16, color: Color(0xFFEDEDED)),
                            SizedBox(width: 8),
                            Text(
                              'Generate with AI',
                              style: TextStyle(
                                fontFamily: AppFonts.sfProDisplay,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEDEDED),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Extracts names, slang, and domain vocabulary from your chat history.',
                          style: TextStyle(
                            fontFamily: AppFonts.sfProText,
                            fontSize: 12,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Copy Button
                        GestureDetector(
                          onTap: _copyPrompt,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: _copiedPrompt ? const Color(0xFF32D74B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _copiedPrompt ? CupertinoIcons.checkmark_alt : CupertinoIcons.doc_on_clipboard_fill,
                                  size: 14,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _copiedPrompt ? 'Prompt Copied' : '1. Copy AI Prompt',
                                  style: const TextStyle(
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

                        const SizedBox(height: 10),

                        // Paste Area
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D0D0E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _pasteJsonController,
                                maxLines: 2,
                                style: const TextStyle(
                                  fontFamily: AppFonts.sfProText,
                                  fontSize: 12,
                                  color: Color(0xFFEDEDED),
                                ),
                                decoration: InputDecoration(
                                  hintText: '2. Paste JSON response here...',
                                  hintStyle: TextStyle(
                                    fontFamily: AppFonts.sfProText,
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                              if (_jsonErrorText != null) ...[
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _jsonErrorText!,
                                    style: const TextStyle(
                                      fontFamily: AppFonts.sfProText,
                                      fontSize: 11,
                                      color: Color(0xFFFF453A),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _importJsonRules,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C2C2E),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.10),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'Apply Rules',
                                    style: TextStyle(
                                      fontFamily: AppFonts.sfProText,
                                      fontSize: 12,
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

                  const SizedBox(height: 18),

                  // ── 3. Category Pills Filter ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildCategoryPill('all', 'All', CupertinoIcons.square_grid_2x2),
                        const SizedBox(width: 8),
                        ValueListenableBuilder<List<CustomSmartWord>>(
                          valueListenable: NotesService.instance.customSmartWordsNotifier,
                          builder: (context, cList, _) {
                            return _buildCategoryPill(
                              'custom',
                              'Custom (${cList.length})',
                              CupertinoIcons.slider_horizontal_3,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        ...categories.map((c) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildCategoryPill(
                              c.title.toLowerCase(),
                              c.title,
                              c.icon,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── 4. Search Bar ──
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 14,
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
                              fontSize: 13,
                              color: Color(0xFFEDEDED),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search words...',
                              hintStyle: TextStyle(
                                fontFamily: AppFonts.sfProText,
                                fontSize: 13,
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
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(
                              CupertinoIcons.clear_thick_circled,
                              size: 14,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── 5. Word Catalog Display ──
                  if (_selectedCategory == 'all' || _selectedCategory == 'custom') ...[
                    ValueListenableBuilder<List<CustomSmartWord>>(
                      valueListenable: NotesService.instance.customSmartWordsNotifier,
                      builder: (context, cList, _) {
                        final filteredCustom = _searchQuery.isEmpty
                            ? cList
                            : cList.where((c) => c.word.toLowerCase().contains(_searchQuery)).toList();

                        if (filteredCustom.isEmpty && _selectedCategory == 'custom') {
                          return Container(
                            padding: const EdgeInsets.all(28),
                            alignment: Alignment.center,
                            child: const Text(
                              'No custom words yet.\nGenerate with AI or tap + above.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppFonts.sfProText,
                                fontSize: 12,
                                color: Color(0xFF8E8E93),
                                height: 1.4,
                              ),
                            ),
                          );
                        }

                        if (filteredCustom.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(CupertinoIcons.slider_horizontal_3, size: 12, color: Color(0xFF8E8E93)),
                                    SizedBox(width: 6),
                                    Text(
                                      'CUSTOM RULES',
                                      style: TextStyle(
                                        fontFamily: AppFonts.sfProText,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        color: Color(0xFF8E8E93),
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    NotesService.instance.clearCustomSmartWords();
                                    setState(() {});
                                    HapticFeedback.lightImpact();
                                  },
                                  child: const Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontFamily: AppFonts.sfProText,
                                      fontSize: 11,
                                      color: Color(0xFFFF453A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
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
                                return _buildInteractiveWordCard(
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
                            const SizedBox(height: 20),
                          ],
                        );
                      },
                    ),
                  ],

                  // Built-in categories
                  ...categories.map((cat) {
                    final catKey = cat.title.toLowerCase();
                    if (_selectedCategory != 'all' && _selectedCategory != catKey) {
                      return const SizedBox.shrink();
                    }

                    final filteredWords = _searchQuery.isEmpty
                        ? cat.words
                        : cat.words.where((w) => w.toLowerCase().contains(_searchQuery)).toList();

                    if (filteredWords.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(cat.icon, size: 12, color: const Color(0xFF8E8E93)),
                              const SizedBox(width: 6),
                              Text(
                                cat.title.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: AppFonts.sfProText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                cat.description,
                                style: const TextStyle(
                                  fontFamily: AppFonts.sfProText,
                                  fontSize: 11,
                                  color: Color(0xFF636366),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: filteredWords.map((w) {
                              return _buildInteractiveWordCard(
                                word: w,
                                style: cat.style,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String key, String title, IconData icon) {
    final isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedCategory = key;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF141416),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: isSelected ? Colors.black : const Color(0xFF8E8E93),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.sfProText,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.black : const Color(0xFFEDEDED),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveWordCard({
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

    return GestureDetector(
      onTap: () {
        final current = _sandboxController.text;
        _sandboxController.text = current.isEmpty ? word : '$current $word';
        _sandboxController.selection = TextSelection.collapsed(offset: _sandboxController.text.length);
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: style.highlightColorValue != null
              ? Color(style.highlightColorValue!)
              : const Color(0xFF141416),
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
                child: const Icon(
                  CupertinoIcons.xmark,
                  size: 11,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
