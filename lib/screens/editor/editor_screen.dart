import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/controllers/null_rich_text_controller.dart';
import '../../core/fonts/app_fonts.dart';
import '../../core/models/note.dart';
import '../../core/models/span_style.dart';
import '../../core/services/notes_service.dart';
import '../../widgets/null_selection_context_menu.dart';
import 'editor_state.dart';

class EditorScreen extends StatefulWidget {
  final int pageIndex;
  final EditorState state;
  final VoidCallback? onSleepRequested;

  const EditorScreen({
    super.key,
    required this.pageIndex,
    required this.state,
    this.onSleepRequested,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late DateTime _displayTime;
  Timer? _timer;
  late QuoteItem _quote;

  late final NullRichTextController _textController;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _hasCreatedNote = false;

  // Unified Undo/Redo History Stack (Captures Text + Word Spans + Base Styles)
  final List<_EditorSnapshot> _undoStack = [];
  final List<_EditorSnapshot> _redoStack = [];
  bool _isApplyingHistory = false;
  Timer? _textDebounceTimer;
  String _lastRecordedText = '';
  TextSelection _lastSelection = const TextSelection.collapsed(offset: -1);

  static const List<String> _curatedFonts = [
    AppFonts.sfProDisplay,
    AppFonts.beatrice,
    AppFonts.kaftan,
    AppFonts.basementGrotesque,
    AppFonts.coolvetica,
    AppFonts.futura,
    AppFonts.aloevera,
    AppFonts.inter,
    AppFonts.europaNova,
    AppFonts.gotham,
  ];

  static const List<double> _fontSizes = [
    34.0,
    44.0,
    52.0,
    62.0,
  ];

  @override
  void initState() {
    super.initState();
    final notes = NotesService.instance.notes;

    if (widget.pageIndex < notes.length) {
      // Existing Saved Note
      final note = notes[widget.pageIndex];
      _displayTime = note.createdAt;
      _quote = note.quote;
      _hasCreatedNote = true;
      _textController = NullRichTextController(
        text: note.text,
        spans: note.spans,
        onSpansChanged: _onSpansChanged,
      );
    } else {
      // Brand New Blank Editor Page
      _displayTime = DateTime.now();
      _quote = NotesService.instance.activeDraftQuote;
      _hasCreatedNote = false;
      _textController = NullRichTextController(
        onSpansChanged: _onSpansChanged,
      );
      NotesService.instance.activeDraftQuoteNotifier.addListener(_onDraftQuoteRefreshed);

      // Live clock updates for the active blank editor
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && !_hasCreatedNote) {
          setState(() {
            _displayTime = DateTime.now();
          });
        }
      });
    }

    // Initialize baseline snapshot
    _recordSnapshot();

    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_handleFocusChanged);
    NotesService.instance.registerFocusCallback(widget.pageIndex, _requestFocus);
  }

  void _requestFocus() {
    if (mounted) {
      _focusNode.requestFocus();
    }
  }

  void _recordSnapshot() {
    if (_isApplyingHistory) return;

    final currentText = _textController.text;
    final currentSpans = _textController.spans;
    final currentSelection = _textController.selection;

    if (_undoStack.isNotEmpty &&
        _undoStack.last.matches(currentText, currentSpans, _quote)) {
      return;
    }

    _undoStack.add(_EditorSnapshot(
      text: currentText,
      selection: currentSelection,
      spans: List.from(currentSpans),
      quote: _quote,
    ));

    if (_undoStack.length > 60) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.length > 1) {
      _isApplyingHistory = true;
      final current = _undoStack.removeLast();
      _redoStack.add(current);

      final previous = _undoStack.last;
      _restoreSnapshot(previous);
      _isApplyingHistory = false;
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _isApplyingHistory = true;
      final next = _redoStack.removeLast();
      _undoStack.add(next);
      _restoreSnapshot(next);
      _isApplyingHistory = false;
    }
  }

  void _restoreSnapshot(_EditorSnapshot snapshot) {
    setState(() {
      _quote = snapshot.quote;
    });

    _textController.value = TextEditingValue(
      text: snapshot.text,
      selection: snapshot.selection,
    );
    _textController.spans = snapshot.spans;

    if (_hasCreatedNote) {
      NotesService.instance.updateNoteText(widget.pageIndex, snapshot.text);
      NotesService.instance.updateNoteSpans(widget.pageIndex, snapshot.spans);
      final note = NotesService.instance.getNote(widget.pageIndex);
      if (note != null) {
        note.quote = snapshot.quote;
      }
    }
    _updateActiveToolbarFont();
  }

  void _onSpansChanged(List<SpanStyle> spans) {
    if (_hasCreatedNote) {
      NotesService.instance.updateNoteSpans(widget.pageIndex, spans);
    }
    if (!_isApplyingHistory) {
      _recordSnapshot();
    }
    _updateActiveToolbarFont();
  }

  void _updateActiveToolbarFont() {
    if (!mounted) return;
    final currentFont = (_textController.selection.isValid && !_textController.selection.isCollapsed)
        ? (_textController.getEffectiveFontAtSelection(_quote.fontFamily) ?? _quote.fontFamily)
        : _quote.fontFamily;
    NotesService.instance.activeEditorFontNotifier.value = currentFont;
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus) {
      _updateActiveToolbarFont();
      NotesService.instance.activeBackgroundColorNotifier.value =
          _quote.backgroundColorValue ?? 0xFF000000;
      NotesService.instance.onUndo = _undo;
      NotesService.instance.onRedo = _redo;
      NotesService.instance.onCycleFont = _cycleFont;
      NotesService.instance.onCycleFontSize = _cycleFontSize;
      NotesService.instance.onCycleBackground = _cycleBackground;
      NotesService.instance.onDismissKeyboard = () => _focusNode.unfocus();
      NotesService.instance.isEditorFocusedNotifier.value = true;
    } else {
      NotesService.instance.isEditorFocusedNotifier.value = false;
    }
  }

  void _cycleBackground() {
    final palette = QuoteItem.backgroundPalette;
    final currentBg = _quote.backgroundColorValue ?? 0xFF000000;
    int nextIdx = 0;
    for (int i = 0; i < palette.length; i++) {
      if (palette[i] == currentBg) {
        nextIdx = (i + 1) % palette.length;
        break;
      }
    }
    final nextBg = palette[nextIdx];

    setState(() {
      _quote = QuoteItem(
        mainText: _quote.mainText,
        dimPrompt: _quote.dimPrompt,
        showTime: _quote.showTime,
        showDivider: _quote.showDivider,
        fontFamily: _quote.fontFamily,
        fontSize: _quote.fontSize,
        fontWeight: _quote.fontWeight,
        letterSpacing: _quote.letterSpacing,
        height: _quote.height,
        backgroundColorValue: nextBg,
      );
    });

    NotesService.instance.activeBackgroundColorNotifier.value = nextBg;

    if (_hasCreatedNote) {
      NotesService.instance.updateNoteQuote(widget.pageIndex, _quote);
    }
    _recordSnapshot();
  }

  void _cycleFont() {
    // 1. Selection-Based Word Formatting (If words are highlighted/selected)
    if (_textController.selection.isValid && !_textController.selection.isCollapsed) {
      final currentFont = _textController.getEffectiveFontAtSelection(_quote.fontFamily) ?? _quote.fontFamily;
      final currentIndex = _curatedFonts.indexOf(currentFont);
      final nextIndex = (currentIndex + 1) % _curatedFonts.length;
      final nextFont = _curatedFonts[nextIndex];

      _textController.applyStyleToSelection(fontFamily: nextFont);
      if (_hasCreatedNote) {
        NotesService.instance.updateNoteSpans(widget.pageIndex, _textController.spans);
      }
      _updateActiveToolbarFont();
      return;
    }

    // 2. Base Note Font Formatting (If no selection)
    final currentIndex = _curatedFonts.indexOf(_quote.fontFamily);
    final nextIndex = (currentIndex + 1) % _curatedFonts.length;
    final nextFont = _curatedFonts[nextIndex];

    setState(() {
      _quote = QuoteItem(
        mainText: _quote.mainText,
        dimPrompt: _quote.dimPrompt,
        showTime: _quote.showTime,
        showDivider: _quote.showDivider,
        fontFamily: nextFont,
        fontSize: _quote.fontSize,
        fontWeight: _quote.fontWeight,
        letterSpacing: _quote.letterSpacing,
        height: _quote.height,
        backgroundColorValue: _quote.backgroundColorValue,
      );
    });

    if (_hasCreatedNote) {
      NotesService.instance.updateNoteQuote(widget.pageIndex, _quote);
    }
    _updateActiveToolbarFont();
    _recordSnapshot();
  }

  void _cycleFontSize() {
    // 1. Selection-Based Word Formatting (If words are highlighted/selected)
    if (_textController.selection.isValid && !_textController.selection.isCollapsed) {
      final currentSize = _textController.getEffectiveFontSizeAtSelection(_quote.fontSize);
      int nextIndex = 0;
      for (int i = 0; i < _fontSizes.length; i++) {
        if ((_fontSizes[i] - currentSize).abs() < 2.0) {
          nextIndex = (i + 1) % _fontSizes.length;
          break;
        }
      }
      final nextSize = _fontSizes[nextIndex];

      _textController.applyStyleToSelection(fontSize: nextSize);
      if (_hasCreatedNote) {
        NotesService.instance.updateNoteSpans(widget.pageIndex, _textController.spans);
      }
      return;
    }

    // 2. Base Note Font Size Formatting (If no selection)
    final currentSize = _quote.fontSize;
    int nextIndex = 0;
    for (int i = 0; i < _fontSizes.length; i++) {
      if ((_fontSizes[i] - currentSize).abs() < 2.0) {
        nextIndex = (i + 1) % _fontSizes.length;
        break;
      }
    }
    final nextSize = _fontSizes[nextIndex];

    setState(() {
      _quote = QuoteItem(
        mainText: _quote.mainText,
        dimPrompt: _quote.dimPrompt,
        showTime: _quote.showTime,
        showDivider: _quote.showDivider,
        fontFamily: _quote.fontFamily,
        fontSize: nextSize,
        fontWeight: _quote.fontWeight,
        letterSpacing: _quote.letterSpacing,
        height: _quote.height,
        backgroundColorValue: _quote.backgroundColorValue,
      );
    });

    if (_hasCreatedNote) {
      NotesService.instance.updateNoteQuote(widget.pageIndex, _quote);
    }
    _recordSnapshot();
  }

  void _onDraftQuoteRefreshed() {
    if (!_hasCreatedNote && _textController.text.isEmpty && mounted) {
      setState(() {
        _quote = NotesService.instance.activeDraftQuote;
      });
      _recordSnapshot();
    }
  }

  void _onTextChanged() {
    final text = _textController.text;
    final selection = _textController.selection;

    final textChanged = text != _lastRecordedText;
    final selectionChanged = selection != _lastSelection;

    if (textChanged) {
      _lastRecordedText = text;
      if (_hasCreatedNote) {
        // Update existing note text directly in memory
        NotesService.instance.updateNoteText(widget.pageIndex, text);
      } else if (text.isNotEmpty) {
        // User typed the first character in the brand new editor -> create note!
        _hasCreatedNote = true;
        _timer?.cancel();
        NotesService.instance.activeDraftQuoteNotifier.removeListener(_onDraftQuoteRefreshed);
        NotesService.instance.createNote(
          text: text,
          quote: _quote,
          spans: _textController.spans,
        );
        // Spawn new draft quote for the next page
        NotesService.instance.refreshActiveDraftQuote();
      }

      if (!_isApplyingHistory) {
        _textDebounceTimer?.cancel();
        _textDebounceTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            _recordSnapshot();
          }
        });
      }
    }

    if (selectionChanged) {
      _lastSelection = selection;
      _updateActiveToolbarFont();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textDebounceTimer?.cancel();
    NotesService.instance.unregisterFocusCallback(widget.pageIndex);
    if (_focusNode.hasFocus) {
      NotesService.instance.isEditorFocusedNotifier.value = false;
    }
    NotesService.instance.activeDraftQuoteNotifier.removeListener(_onDraftQuoteRefreshed);
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _cycleTimeStyle() {
    final nextStyle = (_quote.timeStyle + 1) % 5;
    setState(() {
      _quote = QuoteItem(
        mainText: _quote.mainText,
        dimPrompt: _quote.dimPrompt,
        showTime: _quote.showTime,
        showDivider: _quote.showDivider,
        fontFamily: _quote.fontFamily,
        fontSize: _quote.fontSize,
        fontWeight: _quote.fontWeight,
        letterSpacing: _quote.letterSpacing,
        height: _quote.height,
        backgroundColorValue: _quote.backgroundColorValue,
        timeStyle: nextStyle,
      );
    });

    if (_hasCreatedNote) {
      final note = NotesService.instance.getNote(widget.pageIndex);
      if (note != null) {
        note.quote = _quote;
        NotesService.instance.saveNow();
      }
    }
    _recordSnapshot();
  }

  String _formatHourMinute(DateTime dt) {
    int hour = dt.hour % 12;
    if (hour == 0) hour = 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatAmPm(DateTime dt) {
    return dt.hour >= 12 ? 'PM' : 'AM';
  }

  String _format24H(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1).clamp(0, 11)];
  }

  String _getWeekdayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[(weekday - 1).clamp(0, 6)];
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 45) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${_formatHourMinute(dt)} ${_formatAmPm(dt)}';
    }
  }

  void _saveCurrentQuote() {
    if (_hasCreatedNote) {
      final note = NotesService.instance.getNote(widget.pageIndex);
      if (note != null) {
        note.quote = _quote;
        NotesService.instance.saveNow();
      }
    }
    _recordSnapshot();
  }

  Widget _buildFormatToggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool isFontWeightBold = false,
    bool isItalic = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.sfProText,
            fontSize: 15,
            fontWeight: isFontWeightBold ? FontWeight.w800 : FontWeight.w500,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            color: isActive ? Colors.black : const Color(0xFFEDEDED),
          ),
        ),
      ),
    );
  }

  Widget _buildFormatCycleButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF8E8E93)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppFonts.sfProText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFEDEDED),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneCycleButton({
    required int? currentColor,
    required VoidCallback onTap,
  }) {
    final color = currentColor != null ? Color(currentColor) : const Color(0xFFEDEDED);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualPreviewCard({
    required int styleIndex,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    String title = '';
    Widget previewContent = const SizedBox();

    if (styleIndex == 0) {
      title = 'Classic';
      previewContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "It's",
            style: TextStyle(
              fontFamily: AppFonts.sfProText,
              fontSize: 8,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            "12:05",
            style: TextStyle(
              fontFamily: AppFonts.sfProDisplay,
              fontSize: 18,
              fontWeight: FontWeight.w200,
              color: Color(0xFFEDEDED),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 14,
            height: 1.5,
            decoration: BoxDecoration(
              color: const Color(0xFF55555A),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      );
    } else if (styleIndex == 1) {
      title = 'Editorial';
      previewContent = const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "written at",
            style: TextStyle(
              fontFamily: AppFonts.beatrice,
              fontSize: 7.5,
              fontStyle: FontStyle.italic,
              color: Color(0xFF8E8E93),
            ),
          ),
          SizedBox(height: 1),
          Text(
            "12:05 PM",
            style: TextStyle(
              fontFamily: AppFonts.timesNewRoman,
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: Color(0xFFEDEDED),
              height: 1.0,
            ),
          ),
          SizedBox(height: 4),
          SizedBox(
            width: 20,
            height: 1.0,
            child: Divider(color: Color(0xFF636366), height: 1, thickness: 1),
          ),
        ],
      );
    } else if (styleIndex == 2) {
      title = 'Journal';
      previewContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "FRI, AUG 21",
            style: TextStyle(
              fontFamily: AppFonts.sfProText,
              fontSize: 7,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            "12:05",
            style: TextStyle(
              fontFamily: AppFonts.sfProDisplay,
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: Color(0xFFEDEDED),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 3,
            height: 3,
            decoration: const BoxDecoration(
              color: Color(0xFF636366),
              shape: BoxShape.circle,
            ),
          ),
        ],
      );
    } else if (styleIndex == 3) {
      title = 'Minimal';
      previewContent = const Center(
        child: Text(
          "12:05 AM",
          style: TextStyle(
            fontFamily: AppFonts.sfProDisplay,
            fontSize: 14,
            fontWeight: FontWeight.w200,
            color: Color(0xFFEDEDED),
            letterSpacing: 0.2,
          ),
        ),
      );
    } else if (styleIndex == 4) {
      title = '24H Clean';
      previewContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "// 24H",
            style: TextStyle(
              fontFamily: AppFonts.sfProText,
              fontSize: 7,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: Color(0xFF55555A),
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            "00:05",
            style: TextStyle(
              fontFamily: AppFonts.sfProRounded,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD1D1D6),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 14,
            height: 1.5,
            color: const Color(0xFF48484A),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        height: 88,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF222226) : const Color(0xFF161618),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppFonts.sfProText,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: isSelected ? Colors.white : const Color(0xFF636366),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
              ],
            ),
            const Spacer(),
            previewContent,
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? const Color(0xFFFF453A) : const Color(0xFFEDEDED),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.sfProText,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: isDestructive ? const Color(0xFFFF453A) : const Color(0xFFEDEDED),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimestampMenu() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Timestamp Options',
                        style: TextStyle(
                          fontFamily: AppFonts.sfProDisplay,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEDEDED),
                          letterSpacing: -0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
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
                  const SizedBox(height: 16),

                  // Visual Previews Section
                  const Text(
                    'CHOOSE STYLE (PREVIEWS)',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF636366),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal Visual Card Previews
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: 5,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        return _buildVisualPreviewCard(
                          styleIndex: idx,
                          isSelected: _quote.timeStyle == idx,
                          onTap: () {
                            setModalState(() {});
                            setState(() {
                              _quote = QuoteItem(
                                mainText: _quote.mainText,
                                dimPrompt: _quote.dimPrompt,
                                showTime: _quote.showTime,
                                showDivider: _quote.showDivider,
                                fontFamily: _quote.fontFamily,
                                fontSize: _quote.fontSize,
                                fontWeight: _quote.fontWeight,
                                letterSpacing: _quote.letterSpacing,
                                height: _quote.height,
                                backgroundColorValue: _quote.backgroundColorValue,
                                timeStyle: idx,
                                timeBold: _quote.timeBold,
                                timeItalic: _quote.timeItalic,
                                timeFont: _quote.timeFont,
                                timeScale: _quote.timeScale,
                                timeColorValue: _quote.timeColorValue,
                              );
                            });
                            _saveCurrentQuote();
                            HapticFeedback.selectionClick();
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Fine-Tune Formatting Options Bar ──
                  const Text(
                    'CUSTOMIZE SELECTED',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF636366),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      // 1. Bold Toggle
                      _buildFormatToggleButton(
                        label: 'B',
                        isFontWeightBold: true,
                        isActive: _quote.timeBold,
                        onTap: () {
                          setModalState(() {});
                          setState(() {
                            _quote = QuoteItem(
                              mainText: _quote.mainText,
                              dimPrompt: _quote.dimPrompt,
                              showTime: _quote.showTime,
                              showDivider: _quote.showDivider,
                              fontFamily: _quote.fontFamily,
                              fontSize: _quote.fontSize,
                              fontWeight: _quote.fontWeight,
                              letterSpacing: _quote.letterSpacing,
                              height: _quote.height,
                              backgroundColorValue: _quote.backgroundColorValue,
                              timeStyle: _quote.timeStyle,
                              timeBold: !_quote.timeBold,
                              timeItalic: _quote.timeItalic,
                              timeFont: _quote.timeFont,
                              timeScale: _quote.timeScale,
                              timeColorValue: _quote.timeColorValue,
                            );
                          });
                          _saveCurrentQuote();
                          HapticFeedback.selectionClick();
                        },
                      ),
                      const SizedBox(width: 8),

                      // 2. Italic Toggle
                      _buildFormatToggleButton(
                        label: 'I',
                        isItalic: true,
                        isActive: _quote.timeItalic,
                        onTap: () {
                          setModalState(() {});
                          setState(() {
                            _quote = QuoteItem(
                              mainText: _quote.mainText,
                              dimPrompt: _quote.dimPrompt,
                              showTime: _quote.showTime,
                              showDivider: _quote.showDivider,
                              fontFamily: _quote.fontFamily,
                              fontSize: _quote.fontSize,
                              fontWeight: _quote.fontWeight,
                              letterSpacing: _quote.letterSpacing,
                              height: _quote.height,
                              backgroundColorValue: _quote.backgroundColorValue,
                              timeStyle: _quote.timeStyle,
                              timeBold: _quote.timeBold,
                              timeItalic: !_quote.timeItalic,
                              timeFont: _quote.timeFont,
                              timeScale: _quote.timeScale,
                              timeColorValue: _quote.timeColorValue,
                            );
                          });
                          _saveCurrentQuote();
                          HapticFeedback.selectionClick();
                        },
                      ),
                      const SizedBox(width: 8),

                      // 3. Font Cycle
                      Expanded(
                        child: _buildFormatCycleButton(
                          label: _quote.timeFont ?? 'Font',
                          icon: CupertinoIcons.textformat,
                          onTap: () {
                            const fonts = [
                              null,
                              AppFonts.sfProDisplay,
                              AppFonts.timesNewRoman,
                              AppFonts.beatrice,
                              AppFonts.kaftan,
                              AppFonts.coolvetica,
                              AppFonts.sfProRounded,
                              AppFonts.inter,
                            ];
                            int curIdx = fonts.indexOf(_quote.timeFont);
                            int nextIdx = (curIdx + 1) % fonts.length;
                            final nextFont = fonts[nextIdx];

                            setModalState(() {});
                            setState(() {
                              _quote = QuoteItem(
                                mainText: _quote.mainText,
                                dimPrompt: _quote.dimPrompt,
                                showTime: _quote.showTime,
                                showDivider: _quote.showDivider,
                                fontFamily: _quote.fontFamily,
                                fontSize: _quote.fontSize,
                                fontWeight: _quote.fontWeight,
                                letterSpacing: _quote.letterSpacing,
                                height: _quote.height,
                                backgroundColorValue: _quote.backgroundColorValue,
                                timeStyle: _quote.timeStyle,
                                timeBold: _quote.timeBold,
                                timeItalic: _quote.timeItalic,
                                timeFont: nextFont,
                                timeScale: _quote.timeScale,
                                timeColorValue: _quote.timeColorValue,
                              );
                            });
                            _saveCurrentQuote();
                            HapticFeedback.selectionClick();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 4. Size Cycle
                      _buildFormatCycleButton(
                        label: '${_quote.timeScale}x',
                        icon: CupertinoIcons.textformat_size,
                        onTap: () {
                          const scales = [0.8, 1.0, 1.25];
                          int curIdx = scales.indexOf(_quote.timeScale);
                          if (curIdx < 0) curIdx = 1;
                          int nextIdx = (curIdx + 1) % scales.length;
                          final nextScale = scales[nextIdx];

                          setModalState(() {});
                          setState(() {
                            _quote = QuoteItem(
                              mainText: _quote.mainText,
                              dimPrompt: _quote.dimPrompt,
                              showTime: _quote.showTime,
                              showDivider: _quote.showDivider,
                              fontFamily: _quote.fontFamily,
                              fontSize: _quote.fontSize,
                              fontWeight: _quote.fontWeight,
                              letterSpacing: _quote.letterSpacing,
                              height: _quote.height,
                              backgroundColorValue: _quote.backgroundColorValue,
                              timeStyle: _quote.timeStyle,
                              timeBold: _quote.timeBold,
                              timeItalic: _quote.timeItalic,
                              timeFont: _quote.timeFont,
                              timeScale: nextScale,
                              timeColorValue: _quote.timeColorValue,
                            );
                          });
                          _saveCurrentQuote();
                          HapticFeedback.selectionClick();
                        },
                      ),
                      const SizedBox(width: 8),

                      // 5. Tone / Brightness Cycle (Monochrome)
                      _buildToneCycleButton(
                        currentColor: _quote.timeColorValue,
                        onTap: () {
                          const tones = [
                            null,
                            0xFFFFFFFF,
                            0xFFEDEDED,
                            0xFF8E8E93,
                            0xFF636366,
                          ];
                          int curIdx = tones.indexOf(_quote.timeColorValue);
                          if (curIdx < 0) curIdx = 0;
                          int nextIdx = (curIdx + 1) % tones.length;
                          final nextTone = tones[nextIdx];

                          setModalState(() {});
                          setState(() {
                            _quote = QuoteItem(
                              mainText: _quote.mainText,
                              dimPrompt: _quote.dimPrompt,
                              showTime: _quote.showTime,
                              showDivider: _quote.showDivider,
                              fontFamily: _quote.fontFamily,
                              fontSize: _quote.fontSize,
                              fontWeight: _quote.fontWeight,
                              letterSpacing: _quote.letterSpacing,
                              height: _quote.height,
                              backgroundColorValue: _quote.backgroundColorValue,
                              timeStyle: _quote.timeStyle,
                              timeBold: _quote.timeBold,
                              timeItalic: _quote.timeItalic,
                              timeFont: _quote.timeFont,
                              timeScale: _quote.timeScale,
                              timeColorValue: nextTone,
                            );
                          });
                          _saveCurrentQuote();
                          HapticFeedback.selectionClick();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 14),

                  // Action 1: Update to Current Time
                  _buildMenuActionItem(
                    icon: CupertinoIcons.clock,
                    title: 'Update to Current Time',
                    onTap: () {
                      setModalState(() {});
                      setState(() {
                        _displayTime = DateTime.now();
                      });
                      if (_hasCreatedNote) {
                        final note = NotesService.instance.getNote(widget.pageIndex);
                        if (note != null) {
                          note.createdAt = _displayTime;
                          NotesService.instance.saveNow();
                        }
                      }
                      HapticFeedback.lightImpact();
                    },
                  ),

                  const SizedBox(height: 6),

                  // Action 2: Remove / Hide Timestamp
                  _buildMenuActionItem(
                    icon: CupertinoIcons.eye_slash,
                    title: 'Remove Timestamp',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _quote = QuoteItem(
                          mainText: _quote.mainText,
                          dimPrompt: _quote.dimPrompt,
                          showTime: false,
                          showDivider: _quote.showDivider,
                          fontFamily: _quote.fontFamily,
                          fontSize: _quote.fontSize,
                          fontWeight: _quote.fontWeight,
                          letterSpacing: _quote.letterSpacing,
                          height: _quote.height,
                          backgroundColorValue: _quote.backgroundColorValue,
                          timeStyle: _quote.timeStyle,
                          timeBold: _quote.timeBold,
                          timeItalic: _quote.timeItalic,
                          timeFont: _quote.timeFont,
                          timeScale: _quote.timeScale,
                          timeColorValue: _quote.timeColorValue,
                        );
                      });
                      _saveCurrentQuote();
                      HapticFeedback.mediumImpact();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimestampHeader() {
    final style = _quote.timeStyle;
    final bool isBold = _quote.timeBold;
    final bool isItalic = _quote.timeItalic;
    final double scale = _quote.timeScale;
    final Color? customColor = _quote.timeColorValue != null ? Color(_quote.timeColorValue!) : null;

    final String baseFont = _quote.timeFont ?? (
      style == 1 ? AppFonts.timesNewRoman :
      (style == 4 ? AppFonts.sfProRounded : AppFonts.sfProDisplay)
    );

    final currentKey = 'timestamp_${style}_${isBold}_${isItalic}_${scale}_${_quote.timeColorValue}_$baseFont';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _cycleTimeStyle,
      onLongPress: _showTimestampMenu,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[
              ...previousChildren,
              ?currentChild,
            ],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          final isCurrent = (child.key as ValueKey?)?.value == currentKey;
          final offsetTween = isCurrent
              ? Tween<Offset>(begin: const Offset(0.0, 0.45), end: Offset.zero)
              : Tween<Offset>(begin: const Offset(0.0, -0.45), end: Offset.zero);

          return ClipRect(
            child: SlideTransition(
              position: offsetTween.animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              ),
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(currentKey),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (style == 0) ...[
                // Style 0: Classic Null (Stacked Big Time)
                Text(
                  "It's",
                  style: TextStyle(
                    fontFamily: AppFonts.sfProText,
                    fontSize: 22 * scale,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF636366),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatHourMinute(_displayTime),
                      style: TextStyle(
                        fontFamily: baseFont,
                        fontSize: 70 * scale,
                        fontWeight: isBold ? FontWeight.w700 : FontWeight.w200,
                        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                        letterSpacing: -2.0,
                        color: customColor ?? const Color(0xFFB5B5BA),
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatAmPm(_displayTime),
                      style: TextStyle(
                        fontFamily: AppFonts.sfProText,
                        fontSize: 18 * scale,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                        color: const Color(0xFF55555A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: 26 * scale,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3D),
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ] else if (style == 1) ...[
                // Style 1: Editorial Serif (Vogue / Fashion)
                Text(
                  "written at",
                  style: TextStyle(
                    fontFamily: AppFonts.beatrice,
                    fontSize: 18 * scale,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF8E8E93),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${_formatHourMinute(_displayTime)} ${_formatAmPm(_displayTime)}",
                  style: TextStyle(
                    fontFamily: baseFont,
                    fontSize: 52 * scale,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w300,
                    fontStyle: isItalic ? FontStyle.italic : FontStyle.italic,
                    color: customColor ?? const Color(0xFFEDEDED),
                    letterSpacing: -1.0,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 38 * scale,
                  height: 1.2,
                  color: const Color(0xFF48484A),
                ),
              ] else if (style == 2) ...[
                // Style 2: Journal / Calendar Date & Day
                Text(
                  "${_getWeekdayName(_displayTime.weekday)}, ${_getMonthName(_displayTime.month)} ${_displayTime.day}",
                  style: TextStyle(
                    fontFamily: AppFonts.sfProText,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: const Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatHourMinute(_displayTime),
                      style: TextStyle(
                        fontFamily: baseFont,
                        fontSize: 54 * scale,
                        fontWeight: isBold ? FontWeight.w700 : FontWeight.w300,
                        fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                        letterSpacing: -1.5,
                        color: customColor ?? const Color(0xFFEDEDED),
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatAmPm(_displayTime),
                      style: TextStyle(
                        fontFamily: AppFonts.sfProText,
                        fontSize: 16 * scale,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF636366),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: 5 * scale,
                  height: 5 * scale,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3A3A3D),
                    shape: BoxShape.circle,
                  ),
                ),
              ] else if (style == 3) ...[
                // Style 3: Minimal Zen (Whisper)
                Text(
                  "${_formatHourMinute(_displayTime)} ${_formatAmPm(_displayTime)}",
                  style: TextStyle(
                    fontFamily: baseFont,
                    fontSize: 42 * scale,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w200,
                    fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                    letterSpacing: -0.5,
                    color: customColor ?? const Color(0xFF8E8E93),
                    height: 1.1,
                  ),
                ),
              ] else if (style == 4) ...[
                // Style 4: Modern 24-Hour Clean (Pure Monochrome)
                Text(
                  "// 24H TIMESTAMP",
                  style: TextStyle(
                    fontFamily: AppFonts.sfProText,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: const Color(0xFF55555A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _format24H(_displayTime),
                  style: TextStyle(
                    fontFamily: baseFont,
                    fontSize: 58 * scale,
                    fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                    fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                    letterSpacing: -1.0,
                    color: customColor ?? const Color(0xFFD1D1D6),
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 32 * scale,
                  height: 2.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF48484A),
                    borderRadius: BorderRadius.circular(1.0),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomBarHeight = MediaQuery.of(context).padding.bottom;
    final topPadding = screenHeight * 0.28;
    final bottomPadding = screenHeight * 0.55;
    final bgColor = _quote.backgroundColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_focusNode.hasFocus) {
          _focusNode.unfocus();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        color: bgColor,
        child: Stack(
          children: [
            // 1. Full-Height Scrollable Content Body
            Positioned.fill(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 32.0,
                        right: 32.0,
                        top: topPadding,
                        bottom: bottomPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tappable Multi-Style Timestamp Header
                          if (_quote.showTime) ...[
                            _buildTimestampHeader(),
                          ] else if (NotesService.instance.suggestAddTimestampNotifier.value && _isFocused) ...[
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _quote = QuoteItem(
                                    mainText: _quote.mainText,
                                    dimPrompt: _quote.dimPrompt,
                                    showTime: true,
                                    showDivider: _quote.showDivider,
                                    fontFamily: _quote.fontFamily,
                                    fontSize: _quote.fontSize,
                                    fontWeight: _quote.fontWeight,
                                    letterSpacing: _quote.letterSpacing,
                                    height: _quote.height,
                                    backgroundColorValue: _quote.backgroundColorValue,
                                    timeStyle: _quote.timeStyle,
                                  );
                                });
                                if (_hasCreatedNote) {
                                  final note = NotesService.instance.getNote(widget.pageIndex);
                                  if (note != null) {
                                    note.quote = _quote;
                                    NotesService.instance.saveNow();
                                  }
                                }
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.clock,
                                      size: 13,
                                      color: Colors.white.withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '+ add timestamp',
                                      style: TextStyle(
                                        fontFamily: AppFonts.sfProText,
                                        fontSize: 12,
                                        color: Color(0xFFEDEDED),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),

                          // Main Quote / Note Body with In-Between Dim Placeholder
                          TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            scrollPhysics: const NeverScrollableScrollPhysics(),
                            cursorColor: Colors.white,
                            cursorWidth: 2.0,
                            contextMenuBuilder: (BuildContext context, EditableTextState editableTextState) {
                              return NullSelectionContextMenu(
                                editableTextState: editableTextState,
                                controller: _textController,
                                quote: _quote,
                                onFormatChanged: () {
                                  _recordSnapshot();
                                  _updateActiveToolbarFont();
                                  if (_hasCreatedNote) {
                                    NotesService.instance.updateNoteSpans(widget.pageIndex, _textController.spans);
                                  }
                                },
                              );
                            },
                            style: TextStyle(
                              fontFamily: _quote.fontFamily,
                              fontSize: _quote.fontSize,
                              fontWeight: _quote.fontWeight,
                              color: const Color(0xFFEDEDED),
                              letterSpacing: _quote.letterSpacing,
                              height: _quote.height,
                            ),
                            decoration: InputDecoration(
                              hintText: _quote.mainText,
                              hintStyle: TextStyle(
                                fontFamily: _quote.fontFamily,
                                fontSize: _quote.fontSize,
                                fontWeight: _quote.fontWeight,
                                color: _isFocused
                                    ? const Color(0xFF48484C)
                                    : const Color(0xFF9E9EA4), // In-between white & dark dim
                                letterSpacing: _quote.letterSpacing,
                                height: _quote.height,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),

                          // Bottom-Right Timestamp Tag on Saved Notes: "~ 2m ago"
                          if (_hasCreatedNote && _textController.text.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '~  ${_formatTimeAgo(_displayTime)}',
                                style: const TextStyle(
                                  fontFamily: AppFonts.sfProText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF636366),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],

                          // Optional Dim Prompt Typo (Only rendered if present)
                          if (_quote.dimPrompt != null && _quote.dimPrompt!.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Text(
                              _quote.dimPrompt!,
                              style: TextStyle(
                                fontFamily: _quote.fontFamily,
                                fontSize: _quote.fontSize * 0.95,
                                fontWeight: _quote.fontWeight,
                                color: const Color(0xFF333336),
                                letterSpacing: _quote.letterSpacing,
                                height: _quote.height,
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Feathered Top Gradient Overlay for THIS note/tab
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 90 + statusBarHeight,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        bgColor,
                        bgColor.withValues(alpha: 0.85),
                        bgColor.withValues(alpha: 0.40),
                        bgColor.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.35, 0.70, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Feathered Bottom Gradient Overlay for THIS note/tab
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 110 + bottomBarHeight,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        bgColor.withValues(alpha: 0.0),
                        bgColor.withValues(alpha: 0.40),
                        bgColor.withValues(alpha: 0.85),
                        bgColor,
                      ],
                      stops: const [0.0, 0.45, 0.80, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorSnapshot {
  final String text;
  final TextSelection selection;
  final List<SpanStyle> spans;
  final QuoteItem quote;

  _EditorSnapshot({
    required this.text,
    required this.selection,
    required this.spans,
    required this.quote,
  });

  bool matches(String currentText, List<SpanStyle> currentSpans, QuoteItem currentQuote) {
    if (text != currentText) return false;
    if (quote.fontFamily != currentQuote.fontFamily ||
        quote.fontSize != currentQuote.fontSize ||
        quote.backgroundColorValue != currentQuote.backgroundColorValue) {
      return false;
    }
    if (spans.length != currentSpans.length) return false;
    for (int i = 0; i < spans.length; i++) {
      final a = spans[i];
      final b = currentSpans[i];
      if (a.start != b.start ||
          a.end != b.end ||
          a.fontFamily != b.fontFamily ||
          a.fontSize != b.fontSize ||
          a.colorValue != b.colorValue ||
          a.highlightColorValue != b.highlightColorValue ||
          a.fontWeightIndex != b.fontWeightIndex ||
          a.isItalic != b.isItalic ||
          a.isUnderline != b.isUnderline) {
        return false;
      }
    }
    return true;
  }
}
