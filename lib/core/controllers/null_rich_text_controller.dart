import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/span_style.dart';
import '../services/notes_service.dart';
import '../typography/smart_words_engine.dart';

typedef ImageSpanBuilder = InlineSpan Function(
  BuildContext context,
  String imagePath,
  int tokenStart,
  int tokenEnd,
);

/// Ultra high-performance RichTextEditingController supporting word/selection-level formatting
/// and inline image placement.
/// Uses native interval slicing for 120fps fluid editing with zero layout jank.
class NullRichTextController extends TextEditingController {
  List<SpanStyle> _spans = [];
  ValueChanged<List<SpanStyle>>? onSpansChanged;
  ImageSpanBuilder? imageSpanBuilder;

  NullRichTextController({
    super.text,
    List<SpanStyle>? spans,
    this.onSpansChanged,
    this.imageSpanBuilder,
  }) {
    if (spans != null) {
      _spans = List.from(spans);
    }
  }

  List<SpanStyle> get spans => List.unmodifiable(_spans);

  set spans(List<SpanStyle> newSpans) {
    _spans = List.from(newSpans);
    notifyListeners();
    onSpansChanged?.call(_spans);
  }

  /// Automatically adjusts span boundaries on text edits (insertions / deletions)
  @override
  set value(TextEditingValue newValue) {
    final oldText = text;
    final newText = newValue.text;

    if (oldText != newText && _spans.isNotEmpty) {
      _adjustSpansOnTextChange(oldText, newText);
    }

    super.value = newValue;
  }

  void _adjustSpansOnTextChange(String oldText, String newText) {
    if (newText.isEmpty) {
      _spans.clear();
      onSpansChanged?.call(_spans);
      return;
    }

    // Find common prefix
    int prefixLen = 0;
    final minLen = math.min(oldText.length, newText.length);
    while (prefixLen < minLen && oldText[prefixLen] == newText[prefixLen]) {
      prefixLen++;
    }

    // Find common suffix
    int oldSuffix = oldText.length - 1;
    int newSuffix = newText.length - 1;
    while (oldSuffix >= prefixLen &&
        newSuffix >= prefixLen &&
        oldText[oldSuffix] == newText[newSuffix]) {
      oldSuffix--;
      newSuffix--;
    }

    final deletedLen = (oldSuffix - prefixLen + 1).clamp(0, oldText.length);
    final insertedLen = (newSuffix - prefixLen + 1).clamp(0, newText.length);
    final delta = insertedLen - deletedLen;

    final updated = <SpanStyle>[];

    for (final span in _spans) {
      int s = span.start;
      int e = span.end;

      if (e <= prefixLen) {
        // Change occurred after this span
        updated.add(span);
      } else if (s >= prefixLen + deletedLen) {
        // Change occurred before this span -> shift by delta
        final newS = (s + delta).clamp(0, newText.length);
        final newE = (e + delta).clamp(0, newText.length);
        if (newE > newS) {
          updated.add(span.copyWith(start: newS, end: newE));
        }
      } else {
        // Change intersects this span
        final newS = s <= prefixLen ? s : (prefixLen + insertedLen);
        final newE = e >= (prefixLen + deletedLen) ? (e + delta) : (prefixLen + insertedLen);
        final clampedS = newS.clamp(0, newText.length);
        final clampedE = newE.clamp(0, newText.length);
        if (clampedE > clampedS) {
          updated.add(span.copyWith(start: clampedS, end: clampedE));
        }
      }
    }

    _spans = updated;
    _mergeAdjacentSpans();
    onSpansChanged?.call(_spans);
  }

  /// Returns the effective fontFamily at the current selection or cursor
  String? getEffectiveFontAtSelection(String defaultFont) {
    if (_spans.isEmpty) return defaultFont;
    final pos = selection.isValid ? selection.start : 0;
    for (final s in _spans.reversed) {
      if (s.start <= pos && s.end >= pos && s.fontFamily != null) {
        return s.fontFamily;
      }
    }
    return defaultFont;
  }

  /// Returns the effective fontSize at the current selection or cursor
  double getEffectiveFontSizeAtSelection(double defaultSize) {
    if (_spans.isEmpty) return defaultSize;
    final pos = selection.isValid ? selection.start : 0;
    for (final s in _spans.reversed) {
      if (s.start <= pos && s.end >= pos && s.fontSize != null) {
        return s.fontSize!;
      }
    }
    return defaultSize;
  }

  static const List<int?> highlightPalette = [
    null, // None
    0x55FFD60A, // Soft Amber / Gold
    0x55FF453A, // Soft Coral / Rose
    0x5532D74B, // Soft Emerald / Neon Lime
    0x5564D2FF, // Soft Cyan / Sky
    0x55BF5AF2, // Soft Violet / Lavender
  ];

  /// Returns the effective highlight color at the current selection or cursor
  int? getEffectiveHighlightAtSelection() {
    if (_spans.isEmpty) return null;
    final pos = selection.isValid ? selection.start : 0;
    for (final s in _spans.reversed) {
      if (s.start <= pos && s.end >= pos) {
        return s.highlightColorValue;
      }
    }
    return null;
  }

  /// Returns whether the current selection is bold
  bool getEffectiveBoldAtSelection(FontWeight defaultWeight) {
    if (_spans.isEmpty) return defaultWeight == FontWeight.w700 || defaultWeight == FontWeight.bold;
    final pos = selection.isValid ? selection.start : 0;
    for (final s in _spans.reversed) {
      if (s.start <= pos && s.end >= pos && s.fontWeight != null) {
        return s.fontWeight == FontWeight.w700 || s.fontWeight == FontWeight.bold;
      }
    }
    return defaultWeight == FontWeight.w700 || defaultWeight == FontWeight.bold;
  }

  /// Returns whether the current selection is italic
  bool getEffectiveItalicAtSelection() {
    if (_spans.isEmpty) return false;
    final pos = selection.isValid ? selection.start : 0;
    for (final s in _spans.reversed) {
      if (s.start <= pos && s.end >= pos && s.isItalic != null) {
        return s.isItalic!;
      }
    }
    return false;
  }

  /// Returns whether the current selection is underlined
  bool getEffectiveUnderlineAtSelection() {
    if (_spans.isEmpty) return false;
    final pos = selection.isValid ? selection.start : 0;
    for (final s in _spans.reversed) {
      if (s.start <= pos && s.end >= pos && s.isUnderline != null) {
        return s.isUnderline!;
      }
    }
    return false;
  }

  void toggleBoldAtSelection(FontWeight defaultWeight) {
    final currentBold = getEffectiveBoldAtSelection(defaultWeight);
    applyStyleToSelection(fontWeight: currentBold ? FontWeight.w300 : FontWeight.w700);
  }

  void toggleItalicAtSelection() {
    final currentItalic = getEffectiveItalicAtSelection();
    applyStyleToSelection(isItalic: !currentItalic);
  }

  void toggleUnderlineAtSelection() {
    final currentUnderline = getEffectiveUnderlineAtSelection();
    applyStyleToSelection(isUnderline: !currentUnderline);
  }

  void cycleHighlightAtSelection() {
    final currentHl = getEffectiveHighlightAtSelection();
    int nextIdx = 0;
    for (int i = 0; i < highlightPalette.length; i++) {
      if (highlightPalette[i] == currentHl) {
        nextIdx = (i + 1) % highlightPalette.length;
        break;
      }
    }
    final nextHl = highlightPalette[nextIdx];
    applyStyleToSelection(
      highlightColorValue: nextHl,
      clearHighlight: nextHl == null,
    );
  }

  /// Applies or cycles formatting across the selected range [selection.start, selection.end]
  void applyStyleToSelection({
    String? fontFamily,
    double? fontSize,
    Color? color,
    int? highlightColorValue,
    bool clearHighlight = false,
    FontWeight? fontWeight,
    bool? isItalic,
    bool? isUnderline,
  }) {
    if (!selection.isValid || selection.isCollapsed) return;

    final start = math.min(selection.start, selection.end);
    final end = math.max(selection.start, selection.end);
    if (start >= end || start < 0 || end > text.length) return;

    // Find any existing span at selection to inherit other unset properties
    SpanStyle? existing;
    for (final s in _spans) {
      if (s.start <= start && s.end >= end) {
        existing = s;
        break;
      }
    }

    // Split any existing overlapping spans and apply new attributes to [start, end]
    final newSpans = <SpanStyle>[];

    for (final s in _spans) {
      if (s.end <= start || s.start >= end) {
        // Non-overlapping
        newSpans.add(s);
      } else {
        // Left remainder
        if (s.start < start) {
          newSpans.add(s.copyWith(end: start));
        }
        // Right remainder
        if (s.end > end) {
          newSpans.add(s.copyWith(start: end));
        }
      }
    }

    // Add new span
    newSpans.add(SpanStyle(
      start: start,
      end: end,
      fontFamily: fontFamily ?? existing?.fontFamily,
      fontSize: fontSize ?? existing?.fontSize,
      colorValue: color != null ? color.toARGB32() : existing?.colorValue,
      highlightColorValue: clearHighlight
          ? null
          : (highlightColorValue ?? existing?.highlightColorValue),
      fontWeightIndex: fontWeight != null
          ? FontWeight.values.indexOf(fontWeight)
          : existing?.fontWeightIndex,
      isItalic: isItalic ?? existing?.isItalic,
      isUnderline: isUnderline ?? existing?.isUnderline,
    ));

    newSpans.sort((a, b) => a.start.compareTo(b.start));
    _spans = newSpans;
    _mergeAdjacentSpans();
    notifyListeners();
    onSpansChanged?.call(_spans);
  }

  /// Merges adjacent or contiguous identical spans for maximum memory & rendering efficiency
  void _mergeAdjacentSpans() {
    if (_spans.length < 2) return;
    _spans.sort((a, b) => a.start.compareTo(b.start));

    final merged = <SpanStyle>[];
    SpanStyle current = _spans.first;

    for (int i = 1; i < _spans.length; i++) {
      final next = _spans[i];
      if (current.end >= next.start &&
          current.fontFamily == next.fontFamily &&
          current.fontSize == next.fontSize &&
          current.colorValue == next.colorValue &&
          current.highlightColorValue == next.highlightColorValue &&
          current.fontWeightIndex == next.fontWeightIndex &&
          current.isItalic == next.isItalic &&
          current.isUnderline == next.isUnderline) {
        // Merge
        current = current.copyWith(end: math.max(current.end, next.end));
      } else {
        merged.add(current);
        current = next;
      }
    }
    merged.add(current);
    _spans = merged;
  }

  List<TextSpan> _buildSmartSubSpans(String chunk, TextStyle baseStyle) {
    final matches = SmartWordsEngine.instance.findMatches(chunk);
    if (matches.isEmpty) {
      return [TextSpan(text: chunk, style: baseStyle)];
    }

    final subSpans = <TextSpan>[];
    int currentPos = 0;

    for (final match in matches) {
      if (match.start > currentPos) {
        subSpans.add(TextSpan(
          text: chunk.substring(currentPos, match.start),
          style: baseStyle,
        ));
      }

      subSpans.add(TextSpan(
        text: match.word,
        style: match.style.applyTo(baseStyle),
      ));

      currentPos = match.end;
    }

    if (currentPos < chunk.length) {
      subSpans.add(TextSpan(
        text: chunk.substring(currentPos),
        style: baseStyle,
      ));
    }

    return subSpans;
  }

  static final RegExp _imageTokenRegex = RegExp(r'\[img:([^\]]+)\]');

  /// High-performance interval slicing text builder with Smart Words typography and inline image support
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle(color: Color(0xFFEDEDED));
    if (text.isEmpty) {
      return TextSpan(style: baseStyle, text: '');
    }

    final isSmartWordsEnabled = NotesService.instance.smartWordsEnabledNotifier.value;
    final imageMatches = _imageTokenRegex.allMatches(text).toList();

    if (imageMatches.isEmpty || imageSpanBuilder == null) {
      return _buildTextSpanForRange(context, 0, text.length, baseStyle, isSmartWordsEnabled);
    }

    // Segment text around [img:path] tokens
    final rootChildren = <InlineSpan>[];
    int cursor = 0;

    for (final match in imageMatches) {
      if (match.start > cursor) {
        final textSpan = _buildTextSpanForRange(
          context,
          cursor,
          match.start,
          baseStyle,
          isSmartWordsEnabled,
        );
        rootChildren.add(textSpan);
      }

      final imagePath = match.group(1)!;
      final imageSpan = imageSpanBuilder!(context, imagePath, match.start, match.end);
      rootChildren.add(imageSpan);

      cursor = match.end;
    }

    if (cursor < text.length) {
      final textSpan = _buildTextSpanForRange(
        context,
        cursor,
        text.length,
        baseStyle,
        isSmartWordsEnabled,
      );
      rootChildren.add(textSpan);
    }

    return TextSpan(children: rootChildren, style: baseStyle);
  }

  TextSpan _buildTextSpanForRange(
    BuildContext context,
    int rangeStart,
    int rangeEnd,
    TextStyle baseStyle,
    bool isSmartWordsEnabled,
  ) {
    final rangeText = text.substring(rangeStart, rangeEnd);
    if (rangeText.isEmpty) {
      return const TextSpan(text: '');
    }

    // Filter relevant spans shifted to range offsets
    final activeSpans = _spans
        .where((s) => s.end > rangeStart && s.start < rangeEnd)
        .map((s) => s.copyWith(
              start: math.max(0, s.start - rangeStart),
              end: math.min(rangeText.length, s.end - rangeStart),
            ))
        .toList();

    if (activeSpans.isEmpty) {
      if (isSmartWordsEnabled) {
        return TextSpan(
          children: _buildSmartSubSpans(rangeText, baseStyle),
          style: baseStyle,
        );
      }
      return TextSpan(style: baseStyle, text: rangeText);
    }

    final points = <int>{0, rangeText.length};
    for (final s in activeSpans) {
      if (s.start >= 0 && s.start <= rangeText.length) points.add(s.start);
      if (s.end >= 0 && s.end <= rangeText.length) points.add(s.end);
    }

    final sortedPoints = points.toList()..sort();
    final children = <TextSpan>[];

    for (int i = 0; i < sortedPoints.length - 1; i++) {
      final start = sortedPoints[i];
      final end = sortedPoints[i + 1];
      if (start >= end) continue;

      final chunk = rangeText.substring(start, end);
      TextStyle chunkStyle = baseStyle;
      bool hasManualSpan = false;

      for (final span in activeSpans) {
        if (span.start <= start && span.end >= end) {
          chunkStyle = span.applyTo(chunkStyle);
          hasManualSpan = true;
        }
      }

      if (hasManualSpan) {
        children.add(TextSpan(text: chunk, style: chunkStyle));
      } else {
        if (isSmartWordsEnabled) {
          children.addAll(_buildSmartSubSpans(chunk, baseStyle));
        } else {
          children.add(TextSpan(text: chunk, style: baseStyle));
        }
      }
    }

    return TextSpan(children: children, style: baseStyle);
  }
}
