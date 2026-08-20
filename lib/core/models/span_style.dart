import 'package:flutter/material.dart';

/// Lightweight, immutable representation of a formatted text span range [start, end).
class SpanStyle {
  final int start;
  final int end;
  final String? fontFamily;
  final double? fontSize;
  final int? colorValue;
  final int? highlightColorValue;
  final int? fontWeightIndex; // 0..8 corresponding to FontWeight.w100..w900
  final bool? isItalic;
  final bool? isUnderline;

  const SpanStyle({
    required this.start,
    required this.end,
    this.fontFamily,
    this.fontSize,
    this.colorValue,
    this.highlightColorValue,
    this.fontWeightIndex,
    this.isItalic,
    this.isUnderline,
  });

  Color? get color => colorValue != null ? Color(colorValue!) : null;
  Color? get highlightColor =>
      highlightColorValue != null ? Color(highlightColorValue!) : null;

  FontWeight? get fontWeight =>
      fontWeightIndex != null ? FontWeight.values[fontWeightIndex!] : null;

  SpanStyle copyWith({
    int? start,
    int? end,
    String? fontFamily,
    double? fontSize,
    int? colorValue,
    int? highlightColorValue,
    bool clearHighlight = false,
    int? fontWeightIndex,
    bool? isItalic,
    bool? isUnderline,
  }) {
    return SpanStyle(
      start: start ?? this.start,
      end: end ?? this.end,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
      highlightColorValue:
          clearHighlight ? null : (highlightColorValue ?? this.highlightColorValue),
      fontWeightIndex: fontWeightIndex ?? this.fontWeightIndex,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
    );
  }

  TextStyle applyTo(TextStyle base) {
    return base.copyWith(
      fontFamily: fontFamily ?? base.fontFamily,
      fontSize: fontSize ?? base.fontSize,
      color: color ?? base.color,
      backgroundColor: highlightColor ?? base.backgroundColor,
      fontWeight: fontWeight ?? base.fontWeight,
      fontStyle: isItalic == true ? FontStyle.italic : base.fontStyle,
      decoration: isUnderline == true ? TextDecoration.underline : base.decoration,
    );
  }

  Map<String, dynamic> toJson() => {
        's': start,
        'e': end,
        if (fontFamily != null) 'ff': fontFamily,
        if (fontSize != null) 'fs': fontSize,
        if (colorValue != null) 'c': colorValue,
        if (highlightColorValue != null) 'hl': highlightColorValue,
        if (fontWeightIndex != null) 'fw': fontWeightIndex,
        if (isItalic != null) 'it': isItalic,
        if (isUnderline != null) 'u': isUnderline,
      };

  factory SpanStyle.fromJson(Map<String, dynamic> json) => SpanStyle(
        start: json['s'] as int,
        end: json['e'] as int,
        fontFamily: json['ff'] as String?,
        fontSize: (json['fs'] as num?)?.toDouble(),
        colorValue: json['c'] as int?,
        highlightColorValue: json['hl'] as int?,
        fontWeightIndex: json['fw'] as int?,
        isItalic: json['it'] as bool?,
        isUnderline: json['u'] as bool?,
      );
}
