import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:null_notes/core/controllers/null_rich_text_controller.dart';
import 'package:null_notes/core/fonts/app_fonts.dart';
import 'package:null_notes/core/models/custom_smart_word.dart';
import 'package:null_notes/core/models/span_style.dart';
import 'package:null_notes/core/services/notes_service.dart';
import 'package:null_notes/core/typography/smart_words_engine.dart';

void main() {
  group('SmartWordsEngine Tests', () {
    test('detects emotional, slang, and wealth keywords accurately', () {
      final engine = SmartWordsEngine.instance;
      final text = 'I love money but hate chaos, literally so real fr';
      final matches = engine.findMatches(text);

      expect(matches.isNotEmpty, isTrue);

      final words = matches.map((m) => m.word.toLowerCase()).toList();
      expect(words.contains('i'), isTrue);
      expect(words.contains('love'), isTrue);
      expect(words.contains('money'), isTrue);
      expect(words.contains('hate'), isTrue);
      expect(words.contains('literally'), isTrue);
      expect(words.contains('fr'), isTrue);
    });

    test('detects elongated Gen Z texting patterns like omggg and nooooo', () {
      final engine = SmartWordsEngine.instance;
      final text = 'omgggg that is crazy nooooo bruhhh';
      final matches = engine.findMatches(text);

      expect(matches.length, equals(3));
      expect(matches[0].word, equals('omgggg'));
      expect(matches[1].word, equals('nooooo'));
      expect(matches[2].word, equals('bruhhh'));
    });

    test('detects Miraculous Ladybug, Adrien, Cat Noir, and iyamatwm', () {
      final engine = SmartWordsEngine.instance;
      final text = 'adrien and marinette with cat noir save paris iyamatwm';
      final matches = engine.findMatches(text);

      expect(matches.isNotEmpty, isTrue);
      final words = matches.map((m) => m.word.toLowerCase()).toList();
      expect(words.contains('adrien'), isTrue);
      expect(words.contains('marinette'), isTrue);
      expect(words.contains('cat noir'), isTrue);
      expect(words.contains('iyamatwm'), isTrue);
    });

    test('custom user smart words take 100% precedence over built-in smart words on conflict', () {
      final engine = SmartWordsEngine.instance;

      // "love" is built-in Aloevera. We override it with custom Futura
      NotesService.instance.saveCustomSmartWords([
        const CustomSmartWord(
          word: 'love',
          fontFamily: AppFonts.futura,
          fontWeightIndex: 8,
          isUnderline: true,
        ),
      ]);

      final text = 'I love you';
      final matches = engine.findMatches(text);

      final loveMatch = matches.firstWhere((m) => m.word.toLowerCase() == 'love');
      expect(loveMatch.isCustom, isTrue);
      expect(loveMatch.style.fontFamily, equals(AppFonts.futura));
      expect(loveMatch.style.fontWeightIndex, equals(8));
      expect(loveMatch.style.isUnderline, isTrue);

      // Clean up
      NotesService.instance.clearCustomSmartWords();
    });

    test('CustomSmartWord.parseJsonItem parses both words array and single word', () {
      final jsonArrayItem = {
        'words': ['marinette', 'adrien', 'luka'],
        'fontFamily': 'Beatrice',
        'bold': true,
        'italic': true,
        'highlightColorValue': 1157584186,
      };

      final parsedList = CustomSmartWord.parseJsonItem(jsonArrayItem);
      expect(parsedList.length, equals(3));
      expect(parsedList[0].word, equals('marinette'));
      expect(parsedList[1].word, equals('adrien'));
      expect(parsedList[2].word, equals('luka'));
      expect(parsedList[0].fontFamily, equals('Beatrice'));
      expect(parsedList[0].fontWeightIndex, equals(6));
      expect(parsedList[0].isItalic, isTrue);

      final jsonSingleItem = {
        'word': 'bestie',
        'fontFamily': 'Coolvetica',
        'italic': true,
      };

      final singleList = CustomSmartWord.parseJsonItem(jsonSingleItem);
      expect(singleList.length, equals(1));
      expect(singleList.first.word, equals('bestie'));
      expect(singleList.first.fontFamily, equals('Coolvetica'));
    });
  });

  group('NullRichTextController Smart Words Rendering Tests', () {
    testWidgets('buildTextSpan renders smart word styling when enabled', (tester) async {
      NotesService.instance.smartWordsEnabledNotifier.value = true;

      final controller = NullRichTextController(text: 'i love you');

      late TextSpan span;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              span = controller.buildTextSpan(
                context: context,
                withComposing: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(span.children, isNotNull);
      expect(span.children!.length, greaterThanOrEqualTo(3));
    });

    testWidgets('manual user span takes 100% precedence over smart words', (tester) async {
      NotesService.instance.smartWordsEnabledNotifier.value = true;

      // Text: "love" (indices 0..4)
      final controller = NullRichTextController(
        text: 'love',
        spans: [
          const SpanStyle(
            start: 0,
            end: 4,
            fontFamily: AppFonts.kaftan,
            isUnderline: true,
          ),
        ],
      );

      late TextSpan span;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              span = controller.buildTextSpan(
                context: context,
                withComposing: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(span.children, isNotNull);
      expect(span.children!.length, equals(1));
      expect(span.children!.first.style?.fontFamily, equals(AppFonts.kaftan));
      expect(span.children!.first.style?.decoration, equals(TextDecoration.underline));
    });

    testWidgets('disabling smart words settings produces plain text without smart subspans', (tester) async {
      NotesService.instance.smartWordsEnabledNotifier.value = false;

      final controller = NullRichTextController(text: 'i love you');

      late TextSpan span;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              span = controller.buildTextSpan(
                context: context,
                withComposing: false,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      expect(span.text, equals('i love you'));
      expect(span.children, isNull);

      // Restore
      NotesService.instance.smartWordsEnabledNotifier.value = true;
    });

    test('disabling a built-in category stops matching its words until restored', () {
      final engine = SmartWordsEngine.instance;
      const text = 'marinette and adrien';

      // Initially matches
      final initialMatches = engine.findMatches(text);
      expect(initialMatches.any((m) => m.word.toLowerCase() == 'marinette'), isTrue);

      // Disable 'Miraculous Ladybug' category
      NotesService.instance.disableSmartWordCategory('Miraculous Ladybug');

      final matchesAfterDisable = engine.findMatches(text);
      expect(matchesAfterDisable.any((m) => m.word.toLowerCase() == 'marinette'), isFalse);
      expect(matchesAfterDisable.any((m) => m.word.toLowerCase() == 'adrien'), isTrue);

      // Reset
      NotesService.instance.resetSmartWordCategories();
      final matchesAfterReset = engine.findMatches(text);
      expect(matchesAfterReset.any((m) => m.word.toLowerCase() == 'marinette'), isTrue);
    });
  });
}
