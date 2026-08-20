import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/fonts/app_fonts.dart';

/// The signature Null morphing bottom dock widget.
/// Seamlessly morphs between:
/// 1. Circular glowing ring (32px)
/// 2. Rectangular page indicator container (72px - 240px)
/// 3. Floating bottom toolbar container (280px x 44px) when input is focused.
class NullBottomDock extends StatelessWidget {
  final double morphProgress; // 0.0 = Circle, 1.0 = Fully Expanded Indicator Rectangle
  final double toolbarProgress; // 0.0 = Indicator/Circle, 1.0 = Floating Toolbar
  final double currentPage; // Real-time scroll page
  final int pageCount; // Total dynamic pages
  final double baseSize;
  final double strokeWidth;
  final double glowOpacity;
  final ValueChanged<int>? onPageSelected;
  final VoidCallback? onTap;

  final String activeFontFamily;
  final int activeBackgroundColor;

  // Toolbar action callbacks
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onFontTap;
  final VoidCallback? onSizeTap;
  final VoidCallback? onBackgroundTap;
  final VoidCallback? onDismissKeyboard;

  const NullBottomDock({
    super.key,
    required this.morphProgress,
    this.toolbarProgress = 0.0,
    required this.currentPage,
    this.pageCount = 3,
    this.baseSize = 32.0,
    this.strokeWidth = 1.6,
    this.glowOpacity = 0.22,
    this.activeFontFamily = AppFonts.sfProDisplay,
    this.activeBackgroundColor = 0xFF000000,
    this.onPageSelected,
    this.onTap,
    this.onUndo,
    this.onRedo,
    this.onFontTap,
    this.onSizeTap,
    this.onBackgroundTap,
    this.onDismissKeyboard,
  });

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
      case AppFonts.timesNewRoman:
        return 'Times';
      case AppFonts.tacticSans:
        return 'Tactic';
      case AppFonts.agitha:
        return 'Agitha';
      case AppFonts.foreverFreedom:
        return 'Freedom';
      default:
        return family;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = toolbarProgress.clamp(0.0, 1.0);

    // --- Stage 1 (0.0 -> 0.65): Shape morphs completely first ---
    const double shapeMorphCutoff = 0.65;
    final double rawShapeT = (tp / shapeMorphCutoff).clamp(0.0, 1.0);
    final double shapeT = rawShapeT * rawShapeT * (3.0 - 2.0 * rawShapeT); // Smooth Hermite curve

    // --- Stage 2 (0.65 -> 1.0): Toolbar items appear only AFTER shape completes (and disappear first on closing) ---
    final double rawItemsT = ((tp - shapeMorphCutoff) / (1.0 - shapeMorphCutoff)).clamp(0.0, 1.0);
    final double itemsOpacity = Curves.easeOutCubic.transform(rawItemsT);
    final double itemsScale = 0.92 + 0.08 * itemsOpacity;

    // Previous tab indicators fade out swiftly at the start of morph
    final double indicatorOpacity = ((1.0 - (tp / 0.22)).clamp(0.0, 1.0)) * morphProgress.clamp(0.0, 1.0);

    // 1. Calculate Tab Indicator Geometry
    final visibleDots = math.max(1, pageCount);
    final targetIndicatorWidth = math.min(32.0 + visibleDots * 20.0, 240.0);
    final indicatorWidth = baseSize + morphProgress.clamp(0.0, 1.0) * (targetIndicatorWidth - baseSize);

    // 2. Calculate Toolbar Geometry (368px x 54px pill)
    const double targetToolbarWidth = 368.0;
    const double targetToolbarHeight = 54.0;

    final width = (1.0 - shapeT) * indicatorWidth + shapeT * targetToolbarWidth;
    final height = (1.0 - shapeT) * baseSize + shapeT * targetToolbarHeight;
    final borderRadius = height / 2.0;

    final isToolbarActive = tp > 0.50;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (!isToolbarActive && morphProgress < 0.3) ? onTap : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: (1.0 - shapeT) * 1.0 + shapeT * 0.18),
            width: (1.0 - shapeT) * strokeWidth + shapeT * 1.0,
          ),
          boxShadow: [
            // White glow only in resting circle/dock mode; zero glow in toolbar mode
            if (shapeT < 0.99)
              BoxShadow(
                color: Colors.white.withValues(alpha: glowOpacity * (1.0 - shapeT)),
                blurRadius: baseSize * 0.35 * (1.0 - shapeT),
                spreadRadius: 0.5 * (1.0 - shapeT),
              ),
            // Clean dark elevation shadow in toolbar mode
            if (shapeT > 0.01)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55 * shapeT),
                blurRadius: 16 * shapeT,
                offset: Offset(0, 4 * shapeT),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // --- A. Page Indicator Dots (Fades out swiftly at start of morph) ---
              if (indicatorOpacity > 0.01)
                Opacity(
                  opacity: indicatorOpacity,
                  child: ClipRect(
                    child: OverflowBox(
                      minWidth: 0,
                      maxWidth: math.max(width, targetIndicatorWidth),
                      minHeight: 0,
                      maxHeight: height,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: targetIndicatorWidth,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(visibleDots, (index) {
                            final distance = (currentPage - index).abs();
                            final activeFactor = (1.0 - distance).clamp(0.0, 1.0);

                            final dotWidth = 5.0 + activeFactor * 10.0;
                            final dotOpacity = 0.28 + activeFactor * 0.72;

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onPageSelected?.call(index),
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: dotWidth,
                                  height: 4.5,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: dotOpacity),
                                    borderRadius: BorderRadius.circular(3.0),
                                    boxShadow: activeFactor > 0.6
                                        ? [
                                            BoxShadow(
                                              color: Colors.white.withValues(alpha: 0.6),
                                              blurRadius: 4,
                                              spreadRadius: 0.5,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),

              // --- B. Floating Toolbar Items (Smoothly appears after shape completes / disappears first on close) ---
              if (itemsOpacity > 0.01)
                Opacity(
                  opacity: itemsOpacity,
                  child: Transform.scale(
                    scale: itemsScale,
                    child: ClipRect(
                      child: OverflowBox(
                        minWidth: 0,
                        maxWidth: math.max(width, targetToolbarWidth),
                        minHeight: 0,
                        maxHeight: height,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: targetToolbarWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 1. Undo
                              _ToolbarButton(
                                icon: Icons.undo_rounded,
                                onTap: onUndo,
                              ),

                              // 2. Redo
                              _ToolbarButton(
                                icon: Icons.redo_rounded,
                                onTap: onRedo,
                              ),

                              // Divider
                              Container(
                                width: 1.0,
                                height: 16.0,
                                color: Colors.white.withValues(alpha: 0.18),
                              ),

                              // 3. Typo / Font Family Display Button (Rendered in its own typeface)
                              _ToolbarFontButton(
                                fontName: _getFontDisplayName(activeFontFamily),
                                fontFamily: activeFontFamily,
                                onTap: onFontTap,
                              ),

                              // 4. Font Size Toggle
                              _ToolbarButton(
                                icon: Icons.format_size_rounded,
                                onTap: onSizeTap,
                              ),

                              // 5. Background Color Swatch (Multi-tap to cycle atmospheric dark background colors)
                              _ToolbarBackgroundButton(
                                activeColorValue: activeBackgroundColor,
                                onTap: onBackgroundTap,
                              ),

                              // Divider
                              Container(
                                width: 1.0,
                                height: 16.0,
                                color: Colors.white.withValues(alpha: 0.18),
                              ),

                              // 6. Dismiss Keyboard
                              _ToolbarButton(
                                icon: Icons.keyboard_hide_rounded,
                                onTap: onDismissKeyboard,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ToolbarButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 21,
          color: const Color(0xFFEDEDED),
        ),
      ),
    );
  }
}

class _ToolbarBackgroundButton extends StatelessWidget {
  final int activeColorValue;
  final VoidCallback? onTap;

  const _ToolbarBackgroundButton({
    required this.activeColorValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(activeColorValue);
    final isPureBlack = activeColorValue == 0xFF000000;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Color Swatch Disc
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPureBlack
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.75),
                  width: 1.5,
                ),
                boxShadow: !isPureBlack
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            // Subtle palette / sparkle glyph
            Icon(
              Icons.palette_outlined,
              size: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarFontButton extends StatelessWidget {
  final String fontName;
  final String fontFamily;
  final VoidCallback? onTap;

  const _ToolbarFontButton({
    required this.fontName,
    required this.fontFamily,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          fontName,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFEDEDED),
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}
