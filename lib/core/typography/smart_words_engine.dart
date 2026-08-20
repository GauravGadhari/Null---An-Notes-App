import '../fonts/app_fonts.dart';
import '../models/span_style.dart';

class SmartWordMatch {
  final int start;
  final int end;
  final String word;
  final SpanStyle style;

  const SmartWordMatch({
    required this.start,
    required this.end,
    required this.word,
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

  // 10. ✨ Miraculous Mythology & Iconic Phrases (iyamatwm, kwami, akuma)
  static final RegExp _miraculousLorePattern = RegExp(
    r"\b(miraculous|iyamatwm|akuma|amok|hawkmoth|hawk moth|shadow moth|monarch|kwami|pound it|just a friend|she's just a friend|shes just a friend|alya|nino|chloe|luka|felix|kagami|gabriel)\b",
    caseSensitive: false,
  );
  static const SpanStyle _miraculousLoreStyle = SpanStyle(
    start: 0,
    end: 0,
    fontFamily: AppFonts.foreverFreedom,
    highlightColorValue: 0x44BF5AF2, // Mystical Akuma / Kwami Violet
    isItalic: true,
  );

  /// Scans unformatted text and returns all non-overlapping smart matches
  List<SmartWordMatch> findMatches(String text) {
    if (text.isEmpty) return const [];

    final matches = <SmartWordMatch>[];

    void scan(RegExp pattern, SpanStyle style) {
      for (final m in pattern.allMatches(text)) {
        matches.add(SmartWordMatch(
          start: m.start,
          end: m.end,
          word: m.group(0) ?? '',
          style: style.copyWith(start: m.start, end: m.end),
        ));
      }
    }

    // Scan in specific precedence order
    scan(_miraculousLadybugPattern, _miraculousLadybugStyle);
    scan(_catNoirPattern, _catNoirStyle);
    scan(_miraculousLorePattern, _miraculousLoreStyle);
    scan(_lovePattern, _loveStyle);
    scan(_intensityPattern, _intensityStyle);
    scan(_slangPattern, _slangStyle);
    scan(_wealthPattern, _wealthStyle);
    scan(_manifestPattern, _manifestStyle);
    scan(_voidPattern, _voidStyle);
    scan(_identityPattern, _identityStyle);

    if (matches.isEmpty) return const [];

    // Sort by start index and eliminate any overlapping collisions
    matches.sort((a, b) => a.start.compareTo(b.start));

    final resolved = <SmartWordMatch>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start >= lastEnd) {
        resolved.add(match);
        lastEnd = match.end;
      }
    }

    return resolved;
  }
}
