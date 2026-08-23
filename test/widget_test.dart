import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:null_notes/core/controllers/null_rich_text_controller.dart';
import 'package:null_notes/main.dart';
import 'package:null_notes/screens/editor/editor_screen.dart';

void main() {
  testWidgets('Null launches immediately into awake editor state test', (WidgetTester tester) async {
    await tester.pumpWidget(const NullNotesApp());
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 900));

    // Verify EditorScreen is loaded immediately on app open
    expect(find.byType(EditorScreen), findsWidgets);
  });

  test('NullRichTextController word-level selection formatting test', () {
    final controller = NullRichTextController(text: 'hello clarity world');

    // Select the word "clarity" (index 6 to 13)
    controller.selection = const TextSelection(baseOffset: 6, extentOffset: 13);
    controller.applyStyleToSelection(
      fontFamily: 'Beatrice',
      fontSize: 52.0,
      color: Colors.amber,
    );

    expect(controller.spans.length, 1);
    expect(controller.spans.first.start, 6);
    expect(controller.spans.first.end, 13);
    expect(controller.spans.first.fontFamily, 'Beatrice');
    expect(controller.spans.first.fontSize, 52.0);

    // Build text span and verify 3 segments: "hello ", "clarity" (styled), " world"
    final span = controller.buildTextSpan(
      context: DummyBuildContext(),
      style: const TextStyle(fontFamily: 'SFProDisplay', fontSize: 34.0),
      withComposing: false,
    );

    expect(span.children, isNotNull);
    expect(span.children!.length, 3);
    expect((span.children![0] as TextSpan).text, 'hello ');
    expect((span.children![1] as TextSpan).text, 'clarity');
    expect((span.children![1] as TextSpan).style?.fontFamily, 'Beatrice');
    expect((span.children![1] as TextSpan).style?.fontSize, 52.0);
    expect((span.children![2] as TextSpan).text, ' world');
  });

  test('NullRichTextController highlight, bold, italic, underline test', () {
    final controller = NullRichTextController(text: 'minimal aesthetic notes');

    // Select "aesthetic" (index 8 to 17)
    controller.selection = const TextSelection(baseOffset: 8, extentOffset: 17);

    // 1. Cycle highlight
    controller.cycleHighlightAtSelection();
    expect(controller.getEffectiveHighlightAtSelection(), isNotNull);

    // 2. Toggle bold, italic, underline
    controller.toggleBoldAtSelection(FontWeight.w300);
    controller.toggleItalicAtSelection();
    controller.toggleUnderlineAtSelection();

    expect(controller.getEffectiveBoldAtSelection(FontWeight.w300), isTrue);
    expect(controller.getEffectiveItalicAtSelection(), isTrue);
    expect(controller.getEffectiveUnderlineAtSelection(), isTrue);

    // Verify buildTextSpan contains background color and decorations
    final span = controller.buildTextSpan(
      context: DummyBuildContext(),
      style: const TextStyle(fontFamily: 'SFProDisplay', fontSize: 34.0),
      withComposing: false,
    );

    final styledSpan = span.children![1] as TextSpan;
    expect(styledSpan.text, 'aesthetic');
    expect(styledSpan.style?.backgroundColor, isNotNull);
    expect(styledSpan.style?.fontWeight, FontWeight.w700);
    expect(styledSpan.style?.fontStyle, FontStyle.italic);
    expect(styledSpan.style?.decoration, TextDecoration.underline);
  });
}

class DummyBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
