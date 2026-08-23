import 'package:flutter/material.dart';
import 'span_style.dart';

class QuoteItem {
  final String mainText;
  final String? dimPrompt;
  final bool showTime;
  final bool showDivider;
  final String fontFamily;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final double height;
  final int? backgroundColorValue;
  final int timeStyle; // 0: Classic Null, 1: Editorial Serif, 2: Calendar Date, 3: Minimal Zen, 4: 24H Clean
  final bool timeBold;
  final bool timeItalic;
  final String? timeFont;
  final double timeScale;
  final int? timeColorValue;
  final int textAlignIndex; // 0: Left, 1: Center, 2: Right, 3: Justify

  static const List<int> backgroundPalette = [
    0xFF000000, // Pure OLED Obsidian (Default)
    0xFF0A0E17, // Midnight Navy
    0xFF091410, // Forest Nocturne
    0xFF150A14, // Deep Aubergine Noir
    0xFF141416, // Slate Graphite
    0xFF16100A, // Warm Espresso Noir
  ];

  const QuoteItem({
    required this.mainText,
    this.dimPrompt,
    this.showTime = true,
    this.showDivider = true,
    this.fontFamily = 'SFProDisplay',
    this.fontSize = 44.0,
    this.fontWeight = FontWeight.w300,
    this.letterSpacing = -1.0,
    this.height = 1.18,
    this.backgroundColorValue,
    this.timeStyle = 0,
    this.timeBold = false,
    this.timeItalic = false,
    this.timeFont,
    this.timeScale = 1.0,
    this.timeColorValue,
    this.textAlignIndex = 0,
  });

  TextAlign get textAlign {
    switch (textAlignIndex) {
      case 1:
        return TextAlign.center;
      case 2:
        return TextAlign.right;
      case 3:
        return TextAlign.justify;
      case 0:
      default:
        return TextAlign.left;
    }
  }

  QuoteItem copyWith({
    String? mainText,
    String? dimPrompt,
    bool? showTime,
    bool? showDivider,
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    int? backgroundColorValue,
    int? timeStyle,
    bool? timeBold,
    bool? timeItalic,
    String? timeFont,
    double? timeScale,
    int? timeColorValue,
    int? textAlignIndex,
  }) {
    return QuoteItem(
      mainText: mainText ?? this.mainText,
      dimPrompt: dimPrompt ?? this.dimPrompt,
      showTime: showTime ?? this.showTime,
      showDivider: showDivider ?? this.showDivider,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      height: height ?? this.height,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      timeStyle: timeStyle ?? this.timeStyle,
      timeBold: timeBold ?? this.timeBold,
      timeItalic: timeItalic ?? this.timeItalic,
      timeFont: timeFont ?? this.timeFont,
      timeScale: timeScale ?? this.timeScale,
      timeColorValue: timeColorValue ?? this.timeColorValue,
      textAlignIndex: textAlignIndex ?? this.textAlignIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'mainText': mainText,
        'dimPrompt': dimPrompt,
        'showTime': showTime,
        'showDivider': showDivider,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'fontWeightValue': fontWeight.value,
        'letterSpacing': letterSpacing,
        'height': height,
        'bgColor': backgroundColorValue,
        'timeStyle': timeStyle,
        'timeBold': timeBold,
        'timeItalic': timeItalic,
        'timeFont': timeFont,
        'timeScale': timeScale,
        'timeColor': timeColorValue,
        'textAlignIndex': textAlignIndex,
      };

  factory QuoteItem.fromJson(Map<String, dynamic> json) => QuoteItem(
        mainText: json['mainText'] as String? ?? '',
        dimPrompt: json['dimPrompt'] as String?,
        showTime: json['showTime'] as bool? ?? true,
        showDivider: json['showDivider'] as bool? ?? true,
        fontFamily: json['fontFamily'] as String? ?? 'SFProDisplay',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 44.0,
        fontWeight: json['fontWeightValue'] != null
            ? FontWeight.values.firstWhere(
                (w) => w.value == json['fontWeightValue'],
                orElse: () => FontWeight.w300,
              )
            : (json['fontWeightIndex'] != null
                ? FontWeight.values[(json['fontWeightIndex'] as int).clamp(0, FontWeight.values.length - 1)]
                : FontWeight.w300),
        letterSpacing: (json['letterSpacing'] as num?)?.toDouble() ?? -1.0,
        height: (json['height'] as num?)?.toDouble() ?? 1.18,
        backgroundColorValue: json['bgColor'] as int?,
        timeStyle: json['timeStyle'] as int? ?? 0,
        timeBold: json['timeBold'] as bool? ?? false,
        timeItalic: json['timeItalic'] as bool? ?? false,
        timeFont: json['timeFont'] as String?,
        timeScale: (json['timeScale'] as num?)?.toDouble() ?? 1.0,
        timeColorValue: json['timeColor'] as int?,
        textAlignIndex: json['textAlignIndex'] as int? ?? 0,
      );

  Color get backgroundColor =>
      backgroundColorValue != null ? Color(backgroundColorValue!) : const Color(0xFF000000);
}

class Note {
  final String id;
  String text;
  DateTime createdAt;
  QuoteItem quote;
  List<SpanStyle> spans;
  List<String> images;

  Note({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.quote,
    List<SpanStyle>? spans,
    List<String>? images,
  })  : spans = spans ?? [],
        images = images ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'quote': quote.toJson(),
        'spans': spans.map((s) => s.toJson()).toList(),
        'images': images,
      };

  factory Note.fromJson(Map<String, dynamic> json) {
    QuoteItem quoteItem;
    if (json['quote'] != null && json['quote'] is Map) {
      quoteItem = QuoteItem.fromJson(Map<String, dynamic>.from(json['quote'] as Map));
    } else {
      quoteItem = QuoteItem(
        mainText: json['mainText'] as String? ?? '',
        dimPrompt: json['dimPrompt'] as String?,
        fontFamily: json['fontFamily'] as String? ?? 'SFProDisplay',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 44.0,
        backgroundColorValue: json['bgColor'] as int?,
      );
    }

    return Note(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      quote: quoteItem,
      spans: (json['spans'] as List<dynamic>?)
              ?.map((e) => SpanStyle.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
