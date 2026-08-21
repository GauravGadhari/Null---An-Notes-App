import 'package:flutter/cupertino.dart';
import '../fonts/app_fonts.dart';
import '../models/span_style.dart';
import '../services/notes_service.dart';

class SmartWordMatch {
  final int start;
  final int end;
  final String word;
  final SpanStyle style;
  final bool isCustom;

  const SmartWordMatch({
    required this.start,
    required this.end,
    required this.word,
    required this.style,
    this.isCustom = false,
  });
}

class SmartWordCategory {
  final String title;
  final IconData icon;
  final String description;
  final List<String> words;
  final SpanStyle style;

  const SmartWordCategory({
    required this.title,
    required this.icon,
    required this.description,
    required this.words,
    required this.style,
  });
}

class SmartWordsEngine {
  SmartWordsEngine._();
  static final SmartWordsEngine instance = SmartWordsEngine._();

  // 1. 💖 Love & Affection
  static final RegExp _lovePattern = RegExp(
    r'\b(love|loved|dear|heart|forever|adore|darling|beloved|sweet|kiss|babe|miss you)\b|plea+se',
    caseSensitive: false,
  );
  static const SpanStyle _loveStyle = SpanStyle(
    start: 0,
    end: 0,
    fontFamily: AppFonts.aloevera,
    highlightColorValue: 0x44FF453A, // Soft Rose blush
    isItalic: true,
  );

  // 2. ⚡ Intensity & Outbursts & Drama
  static final RegExp _intensityPattern = RegExp(
    r'\b(hate|rage|anger|never|burn|chaos|fire|raw|scream|break|stop|shut up|cooked|crying|screaming|dying|down bad)\b|noo+|bruh+',
    caseSensitive: false,
  );
  static const SpanStyle _intensityStyle = SpanStyle(
    start: 0,
    end: 0,
    fontFamily: AppFonts.basementGrotesque,
    fontWeightIndex: 8, // FontWeight.w900
  );

  // 3. 💅 Gen Z Slang & Internet Lore
  static final RegExp _slangPattern = RegExp(
    r'\b(fr|frfr|lowkey|highkey|ngl|tbh|nocap|cap|delulu|rizz|aura|slay|valid|period|iykyk|idk|rn|unhinged|canon event)\b|omg+|omfg+',
    caseSensitive: false,
  );
  static const SpanStyle _slangStyle = SpanStyle(
    start: 0,
    end: 0,
    fontFamily: AppFonts.coolvetica,
    highlightColorValue: 0x44BF5AF2, // Soft Violet
    fontWeightIndex: 5, // FontWeight.w600
  );

  // 4. 💰 Wealth, Hustle & Ambition
  static final RegExp _wealthPattern = RegExp(
    r'\b(money|cash|wealth|rich|gold|empire|success|dollar|crypto|bag|secure the bag)\b',
    caseSensitive: false,
  );
  static const SpanStyle _wealthStyle = SpanStyle(
    start: 0,
    end: 0,
    fontFamily: AppFonts.futura,
    highlightColorValue: 0x44FFD60A, // Soft Amber Gold
    fontWeightIndex: 5, // FontWeight.w600
  );

  // 5. ✨ Eras, Energy & Manifestation
  static final RegExp _manifestPattern = RegExp(
    r'\b(era|main character|manifest|manifesting|healing|energy|vibe|vibes|glow up|obsessed|so real|unreal|literally|actually|overthinking)\b|yess+',
    caseSensitive: false,
  );
  static const SpanStyle _manifestStyle = SpanStyle(
    start: 0,
    end: 0,
    fontFamily: AppFonts.beatrice,
    fontWeightIndex: 6, // FontWeight.w700
    isItalic: true,
  );

  // 6. 🌌 Void, Stillness & 3AM Aesthetic
  static final RegExp _voidPattern = RegExp(
    r'\b(dark|light|shadow|void|null|infinite|truth|peace|breathe|sleep|dream|silence|3am|midnight|existential|nostalgia|solitude|cozy)\b|whyy+',
    caseSensitive: false,
  );
  static const SpanStyle _voidStyle = SpanStyle(
    start: 0,
    end: 0,
    fontFamily: AppFonts.agitha,
    highlightColorValue: 0x4464D2FF, // Soft Sky
    isItalic: true,
  );

  // 7. 👤 Self & Identity
  static final RegExp _identityPattern = RegExp(
    r'\b(I|me|myself|you|we|people|human|soul|mind)\b',
    caseSensitive: false,
  );
  static const SpanStyle _identityStyle = SpanStyle(
    start: 0,
    end: 0,
    fontFamily: AppFonts.beatrice,
    fontWeightIndex: 6, // FontWeight.w700
  );

  // 8. 🐞 Miraculous Ladybug & Marinette
  static final RegExp _miraculousLadybugPattern = RegExp(
    r'\b(marinette|merrinette|ladybug|tikki|spots on|spots off|lucky charm|de-evilize)\b',
    caseSensitive: false,
  );
  static const SpanStyle _miraculousLadybugStyle = SpanStyle(
    start: 0,
    end: 0,
    fontFamily: AppFonts.beatrice,
    highlightColorValue: 0x44FF453A, // Parisian Ladybug Rose / Crimson
    fontWeightIndex: 6, // FontWeight.w700
    isItalic: true,
  );

  // 9. 🐾 Cat Noir & Adrien
  static final RegExp _catNoirPattern = RegExp(
    r"\b(adrien|cat noir|chat noir|plagg|claws out|claws in|cataclysm|m'lady|bugaboo)\b",
    caseSensitive: false,
  );
  static const SpanStyle _catNoirStyle = SpanStyle(
    start: 0,
    end: 0,
    fontFamily: AppFonts.coolvetica,
    highlightColorValue: 0x4432D74B, // Cat Noir Neon Lime / Emerald
    fontWeightIndex: 6, // FontWeight.w700
  );

  // 10. ✨ Miraculous Mythology & Iconic Phrases
  static final RegExp _miraculousLorePattern = RegExp(
    r"\b(miraculous|iyamatwm|akuma|amok|hawkmoth|hawk moth|shadow moth|monarch|kwami|pound it|just a friend|she's just a friend|shes just a friend|alya|nino|chloe|luka|felix|kagami|gabriel)\b",
    caseSensitive: false,
  );
  static const SpanStyle _miraculousLoreStyle = SpanStyle(
    start: 0,
    end: 0,
    fontFamily: AppFonts.beatrice,
    highlightColorValue: 0x44BF5AF2, // Mystical Akuma / Kwami Violet
    fontWeightIndex: 6, // FontWeight.w700
    isItalic: true,
  );

  /// Returns catalog of all built-in smart categories
  List<SmartWordCategory> getBuiltInCategories() {
    return const [
      SmartWordCategory(
        title: 'Love & Affection',
        icon: CupertinoIcons.heart_fill,
        description: 'Aloevera • Rose • Italic',
        words: ['love', 'loved', 'dear', 'heart', 'forever', 'adore', 'darling', 'beloved', 'sweet', 'kiss', 'babe', 'miss you', 'please...'],
        style: _loveStyle,
      ),
      SmartWordCategory(
        title: 'Intensity & Drama',
        icon: CupertinoIcons.flame_fill,
        description: 'Basement Grotesque • Heavy w900',
        words: ['hate', 'rage', 'anger', 'never', 'burn', 'chaos', 'fire', 'raw', 'scream', 'break', 'stop', 'shut up', 'cooked', 'crying', 'screaming', 'dying', 'down bad', 'noo...', 'bruh...'],
        style: _intensityStyle,
      ),
      SmartWordCategory(
        title: 'Gen Z Slang',
        icon: CupertinoIcons.bolt_fill,
        description: 'Coolvetica • Violet • w600',
        words: ['fr', 'frfr', 'lowkey', 'highkey', 'ngl', 'tbh', 'nocap', 'cap', 'delulu', 'rizz', 'aura', 'slay', 'valid', 'period', 'iykyk', 'idk', 'rn', 'unhinged', 'canon event', 'omg...', 'omfg...'],
        style: _slangStyle,
      ),
      SmartWordCategory(
        title: 'Wealth & Ambition',
        icon: CupertinoIcons.money_dollar,
        description: 'Futura • Amber Gold • w600',
        words: ['money', 'cash', 'wealth', 'rich', 'gold', 'empire', 'success', 'dollar', 'crypto', 'bag', 'secure the bag'],
        style: _wealthStyle,
      ),
      SmartWordCategory(
        title: 'Manifestation',
        icon: CupertinoIcons.sparkles,
        description: 'Beatrice • Bold Italic',
        words: ['era', 'main character', 'manifest', 'manifesting', 'healing', 'energy', 'vibe', 'vibes', 'glow up', 'obsessed', 'so real', 'unreal', 'literally', 'actually', 'overthinking', 'yess...'],
        style: _manifestStyle,
      ),
      SmartWordCategory(
        title: 'Void & 3AM',
        icon: CupertinoIcons.moon_stars_fill,
        description: 'Agitha • Sky Glow • Italic',
        words: ['dark', 'light', 'shadow', 'void', 'null', 'infinite', 'truth', 'peace', 'breathe', 'sleep', 'dream', 'silence', '3am', 'midnight', 'existential', 'nostalgia', 'solitude', 'cozy', 'whyy...'],
        style: _voidStyle,
      ),
      SmartWordCategory(
        title: 'Identity & Self',
        icon: CupertinoIcons.person_fill,
        description: 'Beatrice • Bold w700',
        words: ['I', 'me', 'myself', 'you', 'we', 'people', 'human', 'soul', 'mind'],
        style: _identityStyle,
      ),
      SmartWordCategory(
        title: 'Miraculous Ladybug',
        icon: CupertinoIcons.circle_grid_hex_fill,
        description: 'Beatrice • Crimson • Italic',
        words: ['marinette', 'merrinette', 'ladybug', 'tikki', 'spots on', 'spots off', 'lucky charm', 'de-evilize'],
        style: _miraculousLadybugStyle,
      ),
      SmartWordCategory(
        title: 'Cat Noir',
        icon: CupertinoIcons.shield_fill,
        description: 'Coolvetica • Emerald • Bold',
        words: ['adrien', 'cat noir', 'chat noir', 'plagg', 'claws out', 'claws in', 'cataclysm', "m'lady", 'bugaboo'],
        style: _catNoirStyle,
      ),
      SmartWordCategory(
        title: 'Miraculous Lore',
        icon: CupertinoIcons.wand_stars,
        description: 'Beatrice • Violet • Bold Italic',
        words: ['miraculous', 'iyamatwm', 'akuma', 'amok', 'hawkmoth', 'hawk moth', 'shadow moth', 'monarch', 'kwami', 'pound it', "just a friend", 'alya', 'nino', 'chloe', 'luka', 'felix', 'kagami', 'gabriel'],
        style: _miraculousLoreStyle,
      ),
    ];
  }

  /// Scans unformatted text and returns all non-overlapping smart matches.
  /// Custom user-defined rules take 100% precedence over built-in defaults.
  List<SmartWordMatch> findMatches(String text) {
    if (text.isEmpty) return const [];

    final customMatches = <SmartWordMatch>[];
    final defaultMatches = <SmartWordMatch>[];

    // 1. Scan Custom Dynamic Smart Words (First Priority)
    final customList = NotesService.instance.customSmartWordsNotifier.value;
    for (final custom in customList) {
      if (custom.word.trim().isEmpty) continue;
      final escaped = RegExp.escape(custom.word.trim());
      final pattern = RegExp(r'\b' + escaped + r'\b', caseSensitive: false);

      final style = SpanStyle(
        start: 0,
        end: 0,
        fontFamily: custom.fontFamily ?? AppFonts.beatrice,
        fontWeightIndex: custom.fontWeightIndex,
        isItalic: custom.isItalic,
        isUnderline: custom.isUnderline,
        highlightColorValue: custom.highlightColorValue,
        colorValue: custom.textColorValue,
      );

      for (final m in pattern.allMatches(text)) {
        customMatches.add(SmartWordMatch(
          start: m.start,
          end: m.end,
          word: m.group(0) ?? '',
          style: style.copyWith(start: m.start, end: m.end),
          isCustom: true,
        ));
      }
    }

    // 2. Scan Built-in Defaults
    void scanDefault(RegExp pattern, SpanStyle style) {
      for (final m in pattern.allMatches(text)) {
        defaultMatches.add(SmartWordMatch(
          start: m.start,
          end: m.end,
          word: m.group(0) ?? '',
          style: style.copyWith(start: m.start, end: m.end),
          isCustom: false,
        ));
      }
    }

    scanDefault(_miraculousLadybugPattern, _miraculousLadybugStyle);
    scanDefault(_catNoirPattern, _catNoirStyle);
    scanDefault(_miraculousLorePattern, _miraculousLoreStyle);
    scanDefault(_lovePattern, _loveStyle);
    scanDefault(_intensityPattern, _intensityStyle);
    scanDefault(_slangPattern, _slangStyle);
    scanDefault(_wealthPattern, _wealthStyle);
    scanDefault(_manifestPattern, _manifestStyle);
    scanDefault(_voidPattern, _voidStyle);
    scanDefault(_identityPattern, _identityStyle);

    // Combine with custom having top precedence
    final allMatches = <SmartWordMatch>[...customMatches];

    // Only add default matches if they do not collide with any custom match
    for (final defMatch in defaultMatches) {
      final overlaps = customMatches.any((c) =>
          (defMatch.start < c.end && defMatch.end > c.start));
      if (!overlaps) {
        allMatches.add(defMatch);
      }
    }

    if (allMatches.isEmpty) return const [];

    // Sort by start index
    allMatches.sort((a, b) {
      final cmp = a.start.compareTo(b.start);
      if (cmp != 0) return cmp;
      // If same start, custom takes precedence
      if (a.isCustom && !b.isCustom) return -1;
      if (!a.isCustom && b.isCustom) return 1;
      return 0;
    });

    final resolved = <SmartWordMatch>[];
    int lastEnd = 0;

    for (final match in allMatches) {
      if (match.start >= lastEnd) {
        resolved.add(match);
        lastEnd = match.end;
      }
    }

    return resolved;
  }
}

