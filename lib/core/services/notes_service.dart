import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../fonts/app_fonts.dart';
import '../models/custom_smart_word.dart';
import '../models/note.dart';
import '../models/span_style.dart';

class NotesService {
  static final NotesService instance = NotesService._();
  NotesService._();

  Box? _box;
  Timer? _saveDebounceTimer;

  static const String _boxName = 'null_notes_box';
  static const String _notesKey = 'notes_list';
  static const String _openOnNewNoteKey = 'open_on_new_note';
  static const String _lastActivePageKey = 'last_active_page';
  static const String _smartWordsEnabledKey = 'smart_words_enabled';
  static const String _suggestAddTimestampKey = 'suggest_add_timestamp';
  static const String _customSmartWordsKey = 'custom_smart_words';

  final ValueNotifier<bool> openOnNewNoteNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<int> lastActivePageIndexNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> smartWordsEnabledNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> suggestAddTimestampNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<List<CustomSmartWord>> customSmartWordsNotifier = ValueNotifier<List<CustomSmartWord>>([]);

  /// Initializes Hive storage and hydrates saved notes and preferences from disk
  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
      final rawList = _box?.get(_notesKey);
      if (rawList != null && rawList is List) {
        final loadedNotes = <Note>[];
        for (final item in rawList) {
          if (item is Map) {
            try {
              loadedNotes.add(Note.fromJson(Map<String, dynamic>.from(item)));
            } catch (_) {}
          }
        }
        notesNotifier.value = loadedNotes;
      }
      openOnNewNoteNotifier.value = _box?.get(_openOnNewNoteKey, defaultValue: true) as bool? ?? true;
      lastActivePageIndexNotifier.value = _box?.get(_lastActivePageKey, defaultValue: 0) as int? ?? 0;
      smartWordsEnabledNotifier.value = _box?.get(_smartWordsEnabledKey, defaultValue: true) as bool? ?? true;
      suggestAddTimestampNotifier.value = _box?.get(_suggestAddTimestampKey, defaultValue: true) as bool? ?? true;

      final rawCustomWords = _box?.get(_customSmartWordsKey);
      if (rawCustomWords != null && rawCustomWords is List) {
        final list = <CustomSmartWord>[];
        for (final item in rawCustomWords) {
          if (item is Map) {
            try {
              list.add(CustomSmartWord.fromJson(Map<String, dynamic>.from(item)));
            } catch (_) {}
          }
        }
        customSmartWordsNotifier.value = list;
      }
    } catch (_) {
      // In isolated unit tests or cold boots, fail gracefully
    }
  }

  void setOpenOnNewNote(bool value) {
    openOnNewNoteNotifier.value = value;
    _box?.put(_openOnNewNoteKey, value);
  }

  void setLastActivePage(int page) {
    lastActivePageIndexNotifier.value = page;
    _box?.put(_lastActivePageKey, page);
  }

  void setSmartWordsEnabled(bool value) {
    smartWordsEnabledNotifier.value = value;
    _box?.put(_smartWordsEnabledKey, value);
  }

  void setSuggestAddTimestamp(bool value) {
    suggestAddTimestampNotifier.value = value;
    _box?.put(_suggestAddTimestampKey, value);
  }

  void saveCustomSmartWords(List<CustomSmartWord> list) {
    customSmartWordsNotifier.value = list;
    _box?.put(_customSmartWordsKey, list.map((e) => e.toJson()).toList());
  }

  void addCustomSmartWords(List<CustomSmartWord> newWords) {
    final current = List<CustomSmartWord>.from(customSmartWordsNotifier.value);
    for (final nw in newWords) {
      current.removeWhere((item) => item.word.toLowerCase() == nw.word.toLowerCase());
      current.insert(0, nw);
    }
    saveCustomSmartWords(current);
  }

  void removeCustomSmartWord(String word) {
    final current = List<CustomSmartWord>.from(customSmartWordsNotifier.value);
    current.removeWhere((item) => item.word.toLowerCase() == word.toLowerCase());
    saveCustomSmartWords(current);
  }

  void clearCustomSmartWords() {
    saveCustomSmartWords([]);
  }

  int getInitialPageIndex() {
    if (openOnNewNoteNotifier.value) {
      return count; // Index of the new empty draft editor page
    } else {
      final last = lastActivePageIndexNotifier.value;
      if (last >= 0 && last <= count) {
        return last;
      }
      return count;
    }
  }

  void _scheduleSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      saveNow();
    });
  }

  /// Flushes current in-memory notes to Hive binary storage immediately
  Future<void> saveNow() async {
    if (_box == null || !_box!.isOpen) return;
    try {
      final serialized = notesNotifier.value.map((n) => n.toJson()).toList();
      await _box?.put(_notesKey, serialized);
    } catch (_) {}
  }

  static const List<QuoteItem> quotePool = [
    // 1. Clean Minimal SF Pro Display (With Time)
    QuoteItem(
      mainText: "one single\nthought at\na time.",
      showTime: true,
      showDivider: true,
      fontFamily: AppFonts.sfProDisplay,
      fontSize: 44,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.0,
    ),
    // 2. Editorial Serif (Beatrice) - Pure Text, No Time Header
    QuoteItem(
      mainText: "the mind is a garden.\nwhat are you planting?",
      showTime: false,
      showDivider: false,
      fontFamily: AppFonts.beatrice,
      fontSize: 38,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.5,
    ),
    // 3. Bold Statement (Basement Grotesque) - Pure Text, No Time Header
    QuoteItem(
      mainText: "START\nNOW.",
      showTime: false,
      showDivider: false,
      fontFamily: AppFonts.basementGrotesque,
      fontSize: 50,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.2,
    ),
    // 4. Coolvetica Modern Sans - Pure Text, No Time
    QuoteItem(
      mainText: "raw thoughts,\nno filter.",
      showTime: false,
      showDivider: false,
      fontFamily: AppFonts.coolvetica,
      fontSize: 42,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.5,
    ),
    // 5. Classic Serif (Times New Roman) - With Time Header
    QuoteItem(
      mainText: "the best ideas\nhappen in silence.",
      showTime: true,
      showDivider: true,
      fontFamily: AppFonts.timesNewRoman,
      fontSize: 42,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
    ),
    // 6. Geometric Sans (Futura) - With Time Header
    QuoteItem(
      mainText: "what's keeping\nyou awake?",
      showTime: true,
      showDivider: true,
      fontFamily: AppFonts.futura,
      fontSize: 42,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.8,
    ),
    // 7. Expressive Script (Aloevera) - Pure Text, No Time
    QuoteItem(
      mainText: "breathe in.\nbreathe out.",
      showTime: false,
      showDivider: false,
      fontFamily: AppFonts.aloevera,
      fontSize: 44,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.5,
    ),
    // 8. Luxury Editorial Serif (Kaftan) - No Time, With Footer Prompt
    QuoteItem(
      mainText: "in the quiet\nof the night.",
      dimPrompt: "leave it\nhere.",
      showTime: false,
      showDivider: false,
      fontFamily: AppFonts.kaftan,
      fontSize: 40,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.5,
    ),
    // 9. Hyper-clean UI Sans (Inter) - Pure Text, No Time
    QuoteItem(
      mainText: "empty your\nhead.",
      showTime: false,
      showDivider: false,
      fontFamily: AppFonts.inter,
      fontSize: 44,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.0,
    ),
    // 10. Clean Swiss (Europa Nova) - With Time Header
    QuoteItem(
      mainText: "yesterday is gone.\ntomorrow is unwritten.",
      showTime: true,
      showDivider: true,
      fontFamily: AppFonts.europaNova,
      fontSize: 38,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.6,
    ),
    // 11. Modern Tech Sans (Tactic Sans) - Pure Text, No Time
    QuoteItem(
      mainText: "capture the spark\nbefore it fades.",
      showTime: false,
      showDivider: false,
      fontFamily: AppFonts.tacticSans,
      fontSize: 40,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.8,
    ),
    // 12. Soft Rounded (SF Pro Rounded) - With Time Header
    QuoteItem(
      mainText: "it doesn't have\nto be perfect.",
      showTime: true,
      showDivider: true,
      fontFamily: AppFonts.sfProRounded,
      fontSize: 42,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.8,
    ),
    // 13. Elegant Serif (Forever Freedom) - With Time & Footer Prompt
    QuoteItem(
      mainText: "clarity begins\nwith words.",
      dimPrompt: "hold onto\nit.",
      showTime: true,
      showDivider: true,
      fontFamily: AppFonts.foreverFreedom,
      fontSize: 40,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.5,
    ),
    // 14. Modern Geometric (Gotham) - Pure Text, No Time
    QuoteItem(
      mainText: "the night is quiet.\nyour mind is loud.",
      showTime: false,
      showDivider: false,
      fontFamily: AppFonts.gotham,
      fontSize: 40,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.8,
    ),
    // 15. Classical Elegance (Agitha) - Pure Text, No Time
    QuoteItem(
      mainText: "leave your\nthoughts here.",
      showTime: false,
      showDivider: false,
      fontFamily: AppFonts.agitha,
      fontSize: 42,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.5,
    ),
    // 16. Classic Two-Part (SF Pro Display) - With Time & Footer Prompt
    QuoteItem(
      mainText: "and you're\noverthinking\nagain.",
      dimPrompt: "write it\ndown.",
      showTime: true,
      showDivider: true,
      fontFamily: AppFonts.sfProDisplay,
      fontSize: 44,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.0,
    ),
  ];

  int _lastQuoteIndex = -1;

  QuoteItem getRandomQuote() {
    final random = math.Random();
    int newIndex;
    do {
      newIndex = random.nextInt(quotePool.length);
    } while (newIndex == _lastQuoteIndex && quotePool.length > 1);
    _lastQuoteIndex = newIndex;
    final base = quotePool[newIndex];

    // Dynamic optional elements:
    // ~40% chance of showing live clock header
    final showTime = random.nextDouble() < 0.40;
    // ~25% chance of showing footer prompt if template has one
    final hasFooter = base.dimPrompt != null && (random.nextDouble() < 0.25);

    return QuoteItem(
      mainText: base.mainText,
      dimPrompt: hasFooter ? base.dimPrompt : null,
      showTime: showTime,
      showDivider: showTime,
      fontFamily: base.fontFamily,
      fontSize: base.fontSize,
      fontWeight: base.fontWeight,
      letterSpacing: base.letterSpacing,
      height: base.height,
    );
  }

  late final ValueNotifier<QuoteItem> activeDraftQuoteNotifier =
      ValueNotifier<QuoteItem>(getRandomQuote());

  QuoteItem get activeDraftQuote => activeDraftQuoteNotifier.value;

  void refreshActiveDraftQuote() {
    activeDraftQuoteNotifier.value = getRandomQuote();
  }

  // Active Editor Focus & Toolbar Actions
  final ValueNotifier<bool> isEditorFocusedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> activeEditorFontNotifier = ValueNotifier<String>('SFProDisplay');
  final ValueNotifier<int> activeBackgroundColorNotifier = ValueNotifier<int>(0xFF000000);
  VoidCallback? onUndo;
  VoidCallback? onRedo;
  VoidCallback? onCycleFont;
  VoidCallback? onCycleFontSize;
  VoidCallback? onCycleBackground;
  VoidCallback? onExport;
  VoidCallback? onDismissKeyboard;

  final Map<int, VoidCallback> _focusCallbacks = {};

  void registerFocusCallback(int pageIndex, VoidCallback callback) {
    _focusCallbacks[pageIndex] = callback;
  }

  void unregisterFocusCallback(int pageIndex) {
    _focusCallbacks.remove(pageIndex);
  }

  void requestEditorFocus(int pageIndex) {
    _focusCallbacks[pageIndex]?.call();
  }

  final ValueNotifier<List<Note>> notesNotifier = ValueNotifier<List<Note>>([]);

  List<Note> get notes => notesNotifier.value;
  int get count => notesNotifier.value.length;

  Note? getNote(int index) {
    if (index >= 0 && index < notesNotifier.value.length) {
      return notesNotifier.value[index];
    }
    return null;
  }

  void updateNoteText(int index, String text) {
    if (index >= 0 && index < notesNotifier.value.length) {
      notesNotifier.value[index].text = text;
      _scheduleSave();
    }
  }

  void updateNoteSpans(int index, List<SpanStyle> spans) {
    if (index >= 0 && index < notesNotifier.value.length) {
      notesNotifier.value[index].spans = List.from(spans);
      _scheduleSave();
    }
  }

  void updateNoteQuote(int index, QuoteItem quote) {
    if (index >= 0 && index < notesNotifier.value.length) {
      notesNotifier.value[index].quote = quote;
      _scheduleSave();
    }
  }

  Note createNote({
    required String text,
    required QuoteItem quote,
    List<SpanStyle>? spans,
  }) {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      createdAt: DateTime.now(),
      quote: quote,
      spans: spans,
    );
    final list = List<Note>.from(notesNotifier.value)..add(newNote);
    notesNotifier.value = list;
    saveNow(); // Immediate binary flush on creation
    return newNote;
  }
}
