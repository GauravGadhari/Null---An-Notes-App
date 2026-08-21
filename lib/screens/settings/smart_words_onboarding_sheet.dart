import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/fonts/app_fonts.dart';
import '../../core/models/custom_smart_word.dart';
import '../../core/models/span_style.dart';
import '../../core/services/notes_service.dart';
import 'smart_words_screen.dart';

class SmartWordsOnboardingSheet extends StatefulWidget {
  const SmartWordsOnboardingSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => const SmartWordsOnboardingSheet(),
    );
  }

  @override
  State<SmartWordsOnboardingSheet> createState() => _SmartWordsOnboardingSheetState();
}

class _SmartWordsOnboardingSheetState extends State<SmartWordsOnboardingSheet> {
  final PageController _pageController = PageController();
  final TextEditingController _jsonController = TextEditingController();

  int _currentPage = 0;
  String? _errorMessage;
  List<CustomSmartWord> _importedWords = [];

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
  void dispose() {
    _pageController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.selectionClick();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _prevPage() {
    HapticFeedback.selectionClick();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _copyPromptAndAdvance() {
    Clipboard.setData(const ClipboardData(text: _chatGptPrompt));
    HapticFeedback.mediumImpact();
    // Smoothly and automatically transition to ChatGPT step
    _nextPage();
  }

  Future<void> _openChatGpt() async {
    final uri = Uri.parse('https://chatgpt.com');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _applyRules() {
    final text = _jsonController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Paste the JSON response first.');
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
      HapticFeedback.heavyImpact();

      setState(() {
        _errorMessage = null;
        _importedWords = newCustomWords;
      });

      _nextPage();
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid JSON: Check ChatGPT code block.';
      });
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Navigation & Close Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0 && _currentPage < 3)
                GestureDetector(
                  onTap: _prevPage,
                  child: const Icon(CupertinoIcons.chevron_back, size: 20, color: Color(0xFF8E8E93)),
                )
              else
                const SizedBox(width: 20),
              _buildStepIndicator(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.xmark, size: 14, color: Color(0xFF8E8E93)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Swiping Page View Body
          Flexible(
            child: SizedBox(
              height: 360,
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildPage1VisualCopy(),
                  _buildPage2VisualChatGpt(),
                  _buildPage3PasteAndApply(),
                  _buildPage4PreviewSuccess(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Centered Visual Copy Button ──
  Widget _buildPage1VisualCopy() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Visual Header
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.0,
            ),
          ),
          child: const Icon(
            CupertinoIcons.sparkles,
            size: 26,
            color: Color(0xFFEDEDED),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'AI Smart Words',
          style: TextStyle(
            fontFamily: AppFonts.sfProDisplay,
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEDEDED),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Personalize typography with your slang & names',
          style: TextStyle(
            fontFamily: AppFonts.sfProText,
            fontSize: 13,
            color: Color(0xFF8E8E93),
          ),
        ),
        const Spacer(),

        // Centered Copy Button
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _copyPromptAndAdvance,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.doc_on_clipboard_fill,
                  size: 16,
                  color: Colors.black,
                ),
                SizedBox(width: 8),
                Text(
                  'Copy AI Prompt',
                  style: TextStyle(
                    fontFamily: AppFonts.sfProText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'press it to copy & continue',
          style: TextStyle(
            fontFamily: AppFonts.sfProText,
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: Color(0xFF636366),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // ── Step 2: Visual ChatGPT Flow ──
  Widget _buildPage2VisualChatGpt() {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Text(
          'Paste in ChatGPT',
          style: TextStyle(
            fontFamily: AppFonts.sfProDisplay,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEDEDED),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Send prompt & copy the JSON response',
          style: TextStyle(
            fontFamily: AppFonts.sfProText,
            fontSize: 12,
            color: Color(0xFF8E8E93),
          ),
        ),
        const Spacer(),

        // Visual 3-Step Flow Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              _buildVisualRow(
                icon: CupertinoIcons.chat_bubble_2_fill,
                title: '1. Paste in ChatGPT',
                subtitle: 'Send the copied prompt in your chat',
              ),
              const SizedBox(height: 12),
              _buildVisualRow(
                icon: CupertinoIcons.sparkles,
                title: '2. Generate Rules',
                subtitle: 'AI analyzes your vocabulary',
              ),
              const SizedBox(height: 12),
              _buildVisualRow(
                icon: CupertinoIcons.arrow_down_doc_fill,
                title: '3. Copy JSON Block',
                subtitle: 'Copy the output and come back',
              ),
            ],
          ),
        ),
        const Spacer(),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _openChatGpt,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.arrow_up_right, size: 14, color: Color(0xFFEDEDED)),
                      SizedBox(width: 6),
                      Text(
                        'Open ChatGPT',
                        style: TextStyle(
                          fontFamily: AppFonts.sfProText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFEDEDED),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _nextPage,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Paste Code →',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  // ── Step 3: Paste & Activate ──
  Widget _buildPage3PasteAndApply() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Paste JSON Response',
          style: TextStyle(
            fontFamily: AppFonts.sfProDisplay,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFEDEDED),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: TextField(
              controller: _jsonController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: AppFonts.sfProText,
                fontSize: 12,
                color: Color(0xFFEDEDED),
              ),
              decoration: InputDecoration(
                hintText: 'Paste the [ { "words": [...] } ] JSON here...',
                hintStyle: TextStyle(
                  fontFamily: AppFonts.sfProText,
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontFamily: AppFonts.sfProText,
              fontSize: 11,
              color: Color(0xFFFF453A),
            ),
          ),
        ],
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _applyRules,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const Text(
              '⚡ Activate Rules',
              style: TextStyle(
                fontFamily: AppFonts.sfProText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ── Step 4: Preview Activated Words & Done ──
  Widget _buildPage4PreviewSuccess() {
    final words = _importedWords.isNotEmpty
        ? _importedWords
        : NotesService.instance.customSmartWordsNotifier.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(CupertinoIcons.checkmark_seal_fill, size: 20, color: Color(0xFF32D74B)),
            const SizedBox(width: 8),
            Text(
              '${words.length} Rules Activated',
              style: const TextStyle(
                fontFamily: AppFonts.sfProDisplay,
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEDEDED),
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: words.map((item) {
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

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: style.highlightColorValue != null
                          ? Color(style.highlightColorValue!)
                          : const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      item.word,
                      style: TextStyle(
                        fontFamily: style.fontFamily,
                        fontSize: 13,
                        fontWeight: style.fontWeight,
                        fontStyle: style.isItalic == true ? FontStyle.italic : FontStyle.normal,
                        decoration: style.isUnderline == true ? TextDecoration.underline : TextDecoration.none,
                        color: style.colorValue != null ? Color(style.colorValue!) : const Color(0xFFEDEDED),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const SmartWordsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Smart Words Studio',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEDEDED),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildVisualRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFFEDEDED)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: AppFonts.sfProDisplay,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEDEDED),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: AppFonts.sfProText,
                  fontSize: 11,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
