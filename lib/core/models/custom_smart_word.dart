class CustomSmartWord {
  final String word;
  final String? fontFamily;
  final int? fontWeightIndex;
  final bool isItalic;
  final bool isUnderline;
  final int? highlightColorValue;
  final int? textColorValue;

  const CustomSmartWord({
    required this.word,
    this.fontFamily,
    this.fontWeightIndex,
    this.isItalic = false,
    this.isUnderline = false,
    this.highlightColorValue,
    this.textColorValue,
  });

  Map<String, dynamic> toJson() => {
        'word': word,
        'fontFamily': fontFamily,
        'fontWeightIndex': fontWeightIndex,
        'isItalic': isItalic,
        'isUnderline': isUnderline,
        'highlightColorValue': highlightColorValue,
        'textColorValue': textColorValue,
      };

  factory CustomSmartWord.fromJson(Map<String, dynamic> json) {
    final list = parseJsonItem(json);
    if (list.isNotEmpty) return list.first;
    return CustomSmartWord(word: json['word']?.toString().trim() ?? '');
  }

  static List<CustomSmartWord> parseJsonItem(Map<String, dynamic> json) {
    final font = json['fontFamily']?.toString() ?? json['font']?.toString();

    int? weightIdx;
    if (json['fontWeightIndex'] != null) {
      weightIdx = (json['fontWeightIndex'] as num).toInt();
    } else if (json['bold'] == true ||
        json['fontWeight'] == 'bold' ||
        json['fontWeight'] == 'w700' ||
        json['fontWeight'] == 'w800' ||
        json['fontWeight'] == 'w900') {
      weightIdx = 6;
    }

    final bool italic = json['isItalic'] == true ||
        json['italic'] == true ||
        json['fontStyle'] == 'italic';

    final bool underline = json['isUnderline'] == true || json['underline'] == true;

    int? highlight;
    if (json['highlightColorValue'] != null) {
      highlight = (json['highlightColorValue'] as num).toInt();
    } else if (json['highlight'] == true || json['highlightColor'] != null) {
      final hc = json['highlightColor']?.toString().toLowerCase();
      if (hc == 'rose' || hc == 'red') {
        highlight = 0x44FF453A;
      } else if (hc == 'violet' || hc == 'purple') {
        highlight = 0x44BF5AF2;
      } else if (hc == 'amber' || hc == 'gold' || hc == 'yellow') {
        highlight = 0x44FFD60A;
      } else if (hc == 'sky' || hc == 'blue') {
        highlight = 0x4464D2FF;
      } else if (hc == 'emerald' || hc == 'green') {
        highlight = 0x4432D74B;
      } else {
        highlight = 0x33FFFFFF;
      }
    }

    int? textCol;
    if (json['textColorValue'] != null) {
      textCol = (json['textColorValue'] as num).toInt();
    }

    final wordsList = <String>[];
    if (json['words'] is List) {
      for (final w in (json['words'] as List)) {
        final str = w?.toString().trim();
        if (str != null && str.isNotEmpty) {
          wordsList.add(str);
        }
      }
    } else if (json['word'] != null) {
      final str = json['word'].toString().trim();
      if (str.isNotEmpty) {
        wordsList.add(str);
      }
    }

    return wordsList.map((w) => CustomSmartWord(
      word: w,
      fontFamily: font,
      fontWeightIndex: weightIdx,
      isItalic: italic,
      isUnderline: underline,
      highlightColorValue: highlight,
      textColorValue: textCol,
    )).toList();
  }
}
