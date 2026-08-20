import 'package:flutter/cupertino.dart';

/// Custom TextSelectionControls based on Cupertino (Apple iOS) selection handles.
/// Ensures the context menu is ALWAYS shown on any selection (full word, partial word, single character, drag).
class NullTextSelectionControls extends CupertinoTextSelectionControls {
  @override
  bool canSelectAll(TextSelectionDelegate delegate) => true;

  @override
  bool canCopy(TextSelectionDelegate delegate) => true;

  @override
  bool canCut(TextSelectionDelegate delegate) => true;

  @override
  bool canPaste(TextSelectionDelegate delegate) => true;
}
