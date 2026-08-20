import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/controllers/null_rich_text_controller.dart';
import '../core/fonts/app_fonts.dart';
import '../core/models/note.dart';

/// Ultra-smooth custom selection context menu for Null.
/// Provides rich multi-tap word formatting (Highlight, Bold, Italic, Underline, Font, Size)
/// without auto-dismissing on every tap.
class NullSelectionContextMenu extends StatefulWidget {
  final EditableTextState editableTextState;
  final NullRichTextController controller;
  final QuoteItem quote;
  final VoidCallback onFormatChanged;

  const NullSelectionContextMenu({
    super.key,
    required this.editableTextState,
    required this.controller,
    required this.quote,
    required this.onFormatChanged,
  });

  @override
  State<NullSelectionContextMenu> createState() => _NullSelectionContextMenuState();
}

class _NullSelectionContextMenuState extends State<NullSelectionContextMenu> {
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

  String _getFontDisplayName(String family) {
    switch (family) {
      case AppFonts.sfProDisplay:
      case AppFonts.sfProText:
      case AppFonts.sfProRounded:
        return 'SF Pro';
      case AppFonts.beatrice:
        return 'Beatrice';
      case AppFonts.kaftan:
        return 'Kaftan';
      case AppFonts.basementGrotesque:
        return 'Basement';
      case AppFonts.coolvetica:
        return 'Coolvetica';
      case AppFonts.futura:
        return 'Futura';
      case AppFonts.aloevera:
        return 'Aloevera';
      case AppFonts.inter:
        return 'Inter';
      case AppFonts.europaNova:
        return 'Europa';
      case AppFonts.gotham:
        return 'Gotham';
      default:
        return family;
    }
  }

  void _onCut() {
    final selection = widget.controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final start = math.min(selection.start, selection.end);
    final end = math.max(selection.start, selection.end);
    final selectedText = widget.controller.text.substring(start, end);

    Clipboard.setData(ClipboardData(text: selectedText));

    final newText = widget.controller.text.replaceRange(start, end, '');
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start),
    );

    widget.editableTextState.hideToolbar();
  }

  void _onCopy() {
    final selection = widget.controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final start = math.min(selection.start, selection.end);
    final end = math.max(selection.start, selection.end);
    final selectedText = widget.controller.text.substring(start, end);

    Clipboard.setData(ClipboardData(text: selectedText));
    HapticFeedback.lightImpact();
  }

  Future<void> _onPaste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null) return;

    final selection = widget.controller.selection;
    final start = selection.isValid ? math.min(selection.start, selection.end) : 0;
    final end = selection.isValid ? math.max(selection.start, selection.end) : 0;

    final newText = widget.controller.text.replaceRange(start, end, data!.text!);
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + data.text!.length),
    );

    widget.editableTextState.hideToolbar();
  }

  void _onCycleHighlight() {
    widget.controller.cycleHighlightAtSelection();
    widget.onFormatChanged();
    setState(() {});
  }

  void _onToggleBold() {
    widget.controller.toggleBoldAtSelection(widget.quote.fontWeight);
    widget.onFormatChanged();
    setState(() {});
  }

  void _onToggleItalic() {
    widget.controller.toggleItalicAtSelection();
    widget.onFormatChanged();
    setState(() {});
  }

  void _onToggleUnderline() {
    widget.controller.toggleUnderlineAtSelection();
    widget.onFormatChanged();
    setState(() {});
  }

  void _onCycleFont() {
    final currentFont = widget.controller.getEffectiveFontAtSelection(widget.quote.fontFamily) ??
        widget.quote.fontFamily;
    final currentIndex = _curatedFonts.indexOf(currentFont);
    final nextIndex = (currentIndex + 1) % _curatedFonts.length;
    final nextFont = _curatedFonts[nextIndex];

    widget.controller.applyStyleToSelection(fontFamily: nextFont);
    widget.onFormatChanged();
    setState(() {});
  }

  void _onCycleFontSize() {
    final currentSize = widget.controller.getEffectiveFontSizeAtSelection(widget.quote.fontSize);
    int nextIndex = 0;
    for (int i = 0; i < _fontSizes.length; i++) {
      if ((_fontSizes[i] - currentSize).abs() < 2.0) {
        nextIndex = (i + 1) % _fontSizes.length;
        break;
      }
    }
    final nextSize = _fontSizes[nextIndex];

    widget.controller.applyStyleToSelection(fontSize: nextSize);
    widget.onFormatChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final anchors = widget.editableTextState.contextMenuAnchors;

    final currentFont = widget.controller.getEffectiveFontAtSelection(widget.quote.fontFamily) ??
        widget.quote.fontFamily;
    final isBold = widget.controller.getEffectiveBoldAtSelection(widget.quote.fontWeight);
    final isItalic = widget.controller.getEffectiveItalicAtSelection();
    final isUnderline = widget.controller.getEffectiveUnderlineAtSelection();
    final highlightValue = widget.controller.getEffectiveHighlightAtSelection();
    final highlightColor = highlightValue != null ? Color(highlightValue) : null;

    return CustomSingleChildLayout(
      delegate: TextSelectionToolbarLayoutDelegate(
        anchorAbove: anchors.primaryAnchor,
        anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF18181A).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 4),

                  // --- 1. Highlight Tool (Cycles soft pastel colors on tap) ---
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onCycleHighlight,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: highlightColor != null
                            ? highlightColor.withValues(alpha: 0.45)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        border: highlightColor != null
                            ? Border.all(color: highlightColor.withValues(alpha: 0.8), width: 1.0)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.brush_rounded,
                            size: 15,
                            color: highlightColor ?? const Color(0xFFD5D5D8),
                          ),
                          if (highlightColor != null) ...[
                            const SizedBox(width: 5),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: highlightColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // --- 2. Bold Toggle ---
                  _ContextToggleAction(
                    label: 'B',
                    isActive: isBold,
                    textStyle: const TextStyle(
                      fontFamily: AppFonts.sfProDisplay,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                    ),
                    onTap: _onToggleBold,
                  ),

                  // --- 3. Italic Toggle ---
                  _ContextToggleAction(
                    label: 'I',
                    isActive: isItalic,
                    textStyle: const TextStyle(
                      fontFamily: AppFonts.sfProDisplay,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.5,
                    ),
                    onTap: _onToggleItalic,
                  ),

                  // --- 4. Underline Toggle ---
                  _ContextToggleAction(
                    label: 'U',
                    isActive: isUnderline,
                    textStyle: const TextStyle(
                      fontFamily: AppFonts.sfProDisplay,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                      fontSize: 15.5,
                    ),
                    onTap: _onToggleUnderline,
                  ),

                  _buildDivider(),

                  // --- 5. Font Family Cycle (Rendered in current selection's font) ---
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onCycleFont,
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                          width: 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getFontDisplayName(currentFont),
                        style: TextStyle(
                          fontFamily: currentFont,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFEDEDED),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),

                  // --- 6. Font Size Cycle ---
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onCycleFontSize,
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.format_size_rounded,
                        size: 19,
                        color: Color(0xFFEDEDED),
                      ),
                    ),
                  ),

                  _buildDivider(),

                  // --- 7. Clipboard Tools (At the end) ---
                  _ContextTextAction(label: 'Cut', onTap: _onCut),
                  _ContextTextAction(label: 'Copy', onTap: _onCopy),
                  _ContextTextAction(label: 'Paste', onTap: _onPaste),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1.0,
      height: 16.0,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: Colors.white.withValues(alpha: 0.18),
    );
  }
}

class _ContextTextAction extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ContextTextAction({
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppFonts.sfProText,
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: Color(0xFFEDEDED),
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _ContextToggleAction extends StatelessWidget {
  final String label;
  final bool isActive;
  final TextStyle textStyle;
  final VoidCallback? onTap;

  const _ContextToggleAction({
    required this.label,
    required this.isActive,
    required this.textStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          border: isActive
              ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.0)
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: textStyle.copyWith(
            color: isActive ? Colors.white : const Color(0xFFC7C7CC),
          ),
        ),
      ),
    );
  }
}
