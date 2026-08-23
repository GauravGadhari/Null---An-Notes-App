import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:null_notes/core/models/note.dart';
import 'package:null_notes/core/models/span_style.dart';

void main() {
  test('QuoteItem serialization and deserialization roundtrip', () {
    const originalQuote = QuoteItem(
      mainText: 'simplicity is the ultimate sophistication.',
      dimPrompt: 'write freely.',
      showTime: true,
      showDivider: true,
      fontFamily: 'Beatrice',
      fontSize: 52.0,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.2,
      height: 1.25,
      backgroundColorValue: 0xFF091410,
    );

    final json = originalQuote.toJson();
    final restoredQuote = QuoteItem.fromJson(json);

    expect(restoredQuote.mainText, originalQuote.mainText);
    expect(restoredQuote.dimPrompt, originalQuote.dimPrompt);
    expect(restoredQuote.showTime, originalQuote.showTime);
    expect(restoredQuote.showDivider, originalQuote.showDivider);
    expect(restoredQuote.fontFamily, originalQuote.fontFamily);
    expect(restoredQuote.fontSize, originalQuote.fontSize);
    expect(restoredQuote.fontWeight, originalQuote.fontWeight);
    expect(restoredQuote.letterSpacing, originalQuote.letterSpacing);
    expect(restoredQuote.height, originalQuote.height);
    expect(restoredQuote.backgroundColorValue, originalQuote.backgroundColorValue);
  });

  test('Note with rich SpanStyle serialization and deserialization roundtrip', () {
    final note = Note(
      id: 'note_12345',
      text: 'clarity of vision',
      createdAt: DateTime(2026, 8, 20, 19, 45),
      quote: const QuoteItem(
        mainText: 'draft quote',
        fontFamily: 'SFProDisplay',
        fontSize: 44.0,
        backgroundColorValue: 0xFF141416,
      ),
      spans: [
        const SpanStyle(
          start: 0,
          end: 7,
          fontFamily: 'Kaftan',
          fontSize: 48.0,
          highlightColorValue: 0x55FFD60A,
          fontWeightIndex: 7, // FontWeight.w800
          isItalic: true,
          isUnderline: true,
        ),
      ],
    );

    final json = note.toJson();
    final restored = Note.fromJson(json);

    expect(restored.id, 'note_12345');
    expect(restored.text, 'clarity of vision');
    expect(restored.quote.backgroundColorValue, 0xFF141416);
    expect(restored.spans.length, 1);

    final span = restored.spans.first;
    expect(span.start, 0);
    expect(span.end, 7);
    expect(span.fontFamily, 'Kaftan');
    expect(span.fontSize, 48.0);
    expect(span.highlightColorValue, 0x55FFD60A);
    expect(span.fontWeightIndex, 7);
    expect(span.fontWeight, FontWeight.w800);
    expect(span.isItalic, isTrue);
    expect(span.isUnderline, isTrue);
  });

  test('QuoteItem with textAlignIndex serialization roundtrip', () {
    const centerQuote = QuoteItem(
      mainText: 'centered thought',
      textAlignIndex: 1, // Center
    );
    expect(centerQuote.textAlign, TextAlign.center);

    final json = centerQuote.toJson();
    final restored = QuoteItem.fromJson(json);
    expect(restored.textAlignIndex, 1);
    expect(restored.textAlign, TextAlign.center);

    const rightQuote = QuoteItem(
      mainText: 'right aligned',
      textAlignIndex: 2, // Right
    );
    expect(rightQuote.textAlign, TextAlign.right);
    expect(QuoteItem.fromJson(rightQuote.toJson()).textAlign, TextAlign.right);
  });

  test('Note with attached image paths serialization roundtrip', () {
    final note = Note(
      id: 'note_img_1',
      text: 'visual memory',
      createdAt: DateTime.now(),
      quote: const QuoteItem(mainText: 'photo note'),
      images: [
        '/data/user/0/null_media/null_img_1.jpg',
        '/data/user/0/null_media/null_img_2.jpg',
      ],
    );

    final json = note.toJson();
    final restored = Note.fromJson(json);

    expect(restored.images.length, 2);
    expect(restored.images[0], '/data/user/0/null_media/null_img_1.jpg');
    expect(restored.images[1], '/data/user/0/null_media/null_img_2.jpg');
  });

  test('Note with native NoteBlock serialization roundtrip', () {
    final note = Note(
      id: 'note_blocks_1',
      text: 'First thought\n\nSecond thought',
      createdAt: DateTime.now(),
      quote: const QuoteItem(mainText: 'block note'),
      images: ['/data/user/0/null_media/img.jpg'],
      blocks: [
        NoteBlock(
          id: 'tb_1',
          type: 'text',
          content: 'First thought',
          spans: [
            const SpanStyle(
              start: 0,
              end: 5,
              fontFamily: 'Beatrice',
              fontSize: 44.0,
            ),
          ],
        ),
        NoteBlock(
          id: 'ib_1',
          type: 'image',
          content: '/data/user/0/null_media/img.jpg',
        ),
        NoteBlock(
          id: 'tb_2',
          type: 'text',
          content: 'Second thought',
        ),
      ],
    );

    final json = note.toJson();
    final restored = Note.fromJson(json);

    expect(restored.blocks.length, 3);
    expect(restored.blocks[0].isText, isTrue);
    expect(restored.blocks[0].content, 'First thought');
    expect(restored.blocks[0].spans.length, 1);
    expect(restored.blocks[0].spans.first.fontFamily, 'Beatrice');

    expect(restored.blocks[1].isImage, isTrue);
    expect(restored.blocks[1].content, '/data/user/0/null_media/img.jpg');

    expect(restored.blocks[2].isText, isTrue);
    expect(restored.blocks[2].content, 'Second thought');
  });

  test('Note backward compatibility: parses legacy [img:path] into clean NoteBlocks', () {
    final legacyJson = {
      'id': 'legacy_1',
      'text': 'Top heading\n[img:/storage/legacy.jpg]\nBottom footer',
      'created_at': DateTime.now().toIso8601String(),
      'quote': {'main_text': 'legacy'},
    };

    final note = Note.fromJson(legacyJson);

    expect(note.blocks.length, 3);
    expect(note.blocks[0].isText, isTrue);
    expect(note.blocks[0].content, 'Top heading');

    expect(note.blocks[1].isImage, isTrue);
    expect(note.blocks[1].content, '/storage/legacy.jpg');

    expect(note.blocks[2].isText, isTrue);
    expect(note.blocks[2].content, 'Bottom footer');

    // Text field is cleaned of raw [img:...] token
    expect(note.text, 'Top heading\n\nBottom footer');
    expect(note.images, ['/storage/legacy.jpg']);
  });
}
