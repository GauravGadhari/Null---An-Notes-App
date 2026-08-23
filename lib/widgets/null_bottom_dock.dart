import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/fonts/app_fonts.dart';

/// The signature Null morphing bottom dock widget.
/// Seamlessly morphs between:
/// 1. Circular glowing ring (32px)
/// 2. Rectangular page indicator container (72px - 240px)
/// 3. Floating bottom toolbar container (360px x 54px) when input is focused.
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
  final int activeTextAlignIndex;

  // Toolbar action callbacks
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onFontTap;
  final VoidCallback? onSizeTap;
  final VoidCallback? onAlignmentTap;
  final VoidCallback? onImageTap;
  final VoidCallback? onImageLongPress;
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
    this.activeTextAlignIndex = 0,
    this.onPageSelected,
    this.onTap,
    this.onUndo,
    this.onRedo,
    this.onFontTap,
    this.onSizeTap,
    this.onAlignmentTap,
    this.onImageTap,
    this.onImageLongPress,
    this.onBackgroundTap,
    this.onDismissKeyboard,
  });

  IconData _getAlignmentIcon(int index) {
    switch (index) {
      case 1:
        return Icons.format_align_center_rounded;
      case 2:
        return Icons.format_align_right_rounded;
      case 0:
      default:
        return Icons.format_align_left_rounded;
    }
  }

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
      case AppFonts.agitha:
        return 'Agitha';
      case AppFonts.foreverFreedom:
        return 'Freedom';
      default:
        return 'SF Pro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double tp = toolbarProgress.clamp(0.0, 1.0);

    // --- Stage 1 (0.0 -> 0.65): Morph shape from circle/indicator pill to rounded toolbar rectangle ---
    const double shapeMorphCutoff = 0.65;
    final double shapeT = Curves.easeInOutCubic.transform((tp / shapeMorphCutoff).clamp(0.0, 1.0));

    // --- Stage 2 (0.65 -> 1.0): Toolbar items appear only AFTER shape completes (and disappear first on closing) ---
    final double rawItemsT = ((tp - shapeMorphCutoff) / (1.0 - shapeMorphCutoff)).clamp(0.0, 1.0);
    final double itemsOpacity = Curves.easeOutCubic.transform(rawItemsT);
    final double itemsScale = 0.92 + 0.08 * itemsOpacity;

    // Previous tab indicators fade out swiftly at the start of morph
    final double indicatorOpacity = ((1.0 - (tp / 0.22)).clamp(0.0, 1.0)) * morphProgress.clamp(0.0, 1.0);

    // 1. Calculate Tab Indicator Geometry (Smooth sliding window for > 6 pages)
    final visibleDots = math.max(1, pageCount);
    final targetIndicatorWidth = visibleDots <= 6
        ? math.max(baseSize, 24.0 + visibleDots * 18.0)
        : 148.0;
    final indicatorWidth = baseSize + morphProgress.clamp(0.0, 1.0) * (targetIndicatorWidth - baseSize);

    // 2. Calculate Toolbar Geometry (360px x 54px pill)
    const double targetToolbarWidth = 360.0;
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
                blurRadius: 16.0,
                spreadRadius: 2.0,
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Sliding Dot Indicators
            if (indicatorOpacity > 0.01)
              Opacity(
                opacity: indicatorOpacity,
                child: _buildSlidingDotIndicator(
                  totalDots: pageCount,
                  currentPage: currentPage,
                  containerWidth: indicatorWidth,
                  onPageSelected: onPageSelected,
                ),
              ),

            // 2. Floating Toolbar Items
            if (itemsOpacity > 0.01)
              Opacity(
                opacity: itemsOpacity,
                child: Transform.scale(
                  scale: itemsScale,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) => true, // Absorb toolbar scrolling so it doesn't bubble up to page dismissals
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.min,
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

                            // 3. Dynamic Font Pill
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

                            // 5. Text Alignment Cycle (Left -> Center -> Right)
                            _ToolbarButton(
                              icon: _getAlignmentIcon(activeTextAlignIndex),
                              onTap: onAlignmentTap,
                            ),

                            // 6. Attach Image (Tap: Recent Action, Hold: Action Sheet)
                            _ToolbarButton(
                              icon: CupertinoIcons.photo,
                              onTap: onImageTap,
                              onLongPress: onImageLongPress,
                            ),

                            // 7. Background Color Swatch
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

                            // 8. Dismiss Keyboard
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
    );
  }

  Widget _buildSlidingDotIndicator({
    required int totalDots,
    required double currentPage,
    required double containerWidth,
    required ValueChanged<int>? onPageSelected,
  }) {
    // If 6 or fewer dots, layout centered evenly
    if (totalDots <= 6) {
      return SizedBox(
        width: containerWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(totalDots, (index) {
            final distance = (currentPage - index).abs();
            final activeFactor = (1.0 - distance).clamp(0.0, 1.0);
            final dotWidth = 5.0 + activeFactor * 10.0;
            final dotOpacity = 0.28 + activeFactor * 0.72;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPageSelected != null ? () => onPageSelected(index) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
                child: Container(
                  width: dotWidth,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: dotOpacity),
                    borderRadius: BorderRadius.circular(2.0),
                    boxShadow: activeFactor > 0.3
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.25 * activeFactor),
                              blurRadius: 3.0,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            );
          }),
        ),
      );
    }

    // Dynamic Sliding Window for many dots (Instagram / Apple style)
    const double dotSpacing = 16.0;
    final double centerOffset = containerWidth / 2.0;
    final double scrollOffset = centerOffset - (currentPage * dotSpacing) - (dotSpacing / 2.0);

    return SizedBox(
      width: containerWidth,
      height: 32.0,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: scrollOffset,
              top: 0,
              bottom: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(totalDots, (index) {
                  final distance = (currentPage - index).abs();

                  double dotWidth;
                  const double dotHeight = 4.0;
                  double dotOpacity;

                  if (distance <= 0.5) {
                    final activeFactor = 1.0 - (distance / 0.5);
                    dotWidth = 5.0 + activeFactor * 10.0;
                    dotOpacity = 0.5 + activeFactor * 0.5;
                  } else if (distance <= 1.5) {
                    final f = 1.0 - ((distance - 0.5) / 1.0);
                    dotWidth = 4.2 + f * 0.8;
                    dotOpacity = 0.35 + f * 0.25;
                  } else if (distance <= 2.5) {
                    final f = 1.0 - ((distance - 1.5) / 1.0);
                    dotWidth = 3.0 + f * 1.2;
                    dotOpacity = 0.18 + f * 0.17;
                  } else if (distance <= 3.5) {
                    final f = 1.0 - ((distance - 2.5) / 1.0);
                    dotWidth = 1.5 + f * 1.5;
                    dotOpacity = 0.05 + f * 0.13;
                  } else {
                    dotWidth = 0.0;
                    dotOpacity = 0.0;
                  }

                  if (dotWidth <= 0.0 || dotOpacity <= 0.0) {
                    return const SizedBox(width: dotSpacing);
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onPageSelected != null ? () => onPageSelected(index) : null,
                    child: Container(
                      width: dotSpacing,
                      alignment: Alignment.center,
                      child: Container(
                        width: dotWidth,
                        height: dotHeight,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: dotOpacity),
                          borderRadius: BorderRadius.circular(2.0),
                          boxShadow: distance <= 0.5
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withValues(
                                      alpha: 0.25 * (1.0 - distance / 0.5),
                                    ),
                                    blurRadius: 3.0,
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
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ToolbarButton({
    required this.icon,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
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
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
        child: Text(
          fontName,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFEDEDED),
            letterSpacing: -0.2,
          ),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.palette_outlined,
              size: 21,
              color: Color(0xFFEDEDED),
            ),
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: color == const Color(0xFF000000) ? const Color(0xFF2C2C2E) : color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
