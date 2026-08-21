import 'package:flutter/material.dart';
import 'package:null_notes/core/controllers/null_rich_text_controller.dart';
import 'package:null_notes/core/fonts/app_fonts.dart';
import 'package:null_notes/core/models/note.dart';

enum ExportAspectRatio {
  story9_16('9:16', 'Story', 9 / 16),
  portrait4_5('4:5', 'Portrait', 4 / 5),
  square1_1('1:1', 'Square', 1 / 1),
  wallpaper19_9('19.5:9', 'Wallpaper', 9 / 19.5),
  landscape16_9('16:9', 'Wide', 16 / 9);

  final String label;
  final String description;
  final double ratio;

  const ExportAspectRatio(this.label, this.description, this.ratio);
}

class NullCardPreview extends StatelessWidget {
  final Note note;
  final ExportAspectRatio aspectRatio;
  final bool showTimestamp;
  final bool showWatermark;
  final bool showGlassFrame;
  final bool smartWordsEnabled;
  final double scaleFactor;

  const NullCardPreview({
    super.key,
    required this.note,
    this.aspectRatio = ExportAspectRatio.story9_16,
    this.showTimestamp = true,
    this.showWatermark = true,
    this.showGlassFrame = false,
    this.smartWordsEnabled = true,
    this.scaleFactor = 1.0,
  });

  Widget _buildCardTimeHeader(QuoteItem quote, DateTime time) {
    int hour = time.hour % 12;
    if (hour == 0) hour = 12;
    final String minuteStr = time.minute < 10 ? '0${time.minute}' : '${time.minute}';
    final String period = time.hour >= 12 ? 'PM' : 'AM';
    final style = quote.timeStyle;

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    final String baseFont = quote.timeFont ?? (
      style == 1 ? AppFonts.timesNewRoman :
      (style == 4 ? AppFonts.sfProRounded : AppFonts.sfProDisplay)
    );
    final FontWeight baseWeight = quote.timeBold ? FontWeight.w700 : (
      style == 4 ? FontWeight.w600 : FontWeight.w300
    );
    final FontStyle baseStyle = quote.timeItalic ? FontStyle.italic : (
      style == 1 ? FontStyle.italic : FontStyle.normal
    );
    final double customScale = quote.timeScale;
    final Color? customColor = quote.timeColorValue != null ? Color(quote.timeColorValue!) : null;

    if (style == 1) {
      // Style 1: Editorial Serif
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'written at',
            style: TextStyle(
              fontFamily: AppFonts.beatrice,
              fontSize: 10.0 * scaleFactor * customScale,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          SizedBox(height: 2.0 * scaleFactor),
          Text(
            '$hour:$minuteStr $period',
            style: TextStyle(
              fontFamily: baseFont,
              fontSize: 26.0 * scaleFactor * customScale,
              fontWeight: baseWeight,
              fontStyle: baseStyle,
              color: customColor ?? Colors.white.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: 8.0 * scaleFactor),
          Container(
            width: 28.0 * scaleFactor,
            height: 1.0 * scaleFactor,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          SizedBox(height: 18.0 * scaleFactor),
        ],
      );
    } else if (style == 2) {
      // Style 2: Calendar Date
      final weekday = days[(time.weekday - 1).clamp(0, 6)];
      final month = months[(time.month - 1).clamp(0, 11)];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$weekday, $month ${time.day}'.toUpperCase(),
            style: TextStyle(
              fontFamily: AppFonts.sfProText,
              fontSize: 11.0 * scaleFactor * customScale,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0 * scaleFactor,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          SizedBox(height: 2.0 * scaleFactor),
          Text(
            '$hour:$minuteStr $period',
            style: TextStyle(
              fontFamily: baseFont,
              fontSize: 26.0 * scaleFactor * customScale,
              fontWeight: baseWeight,
              fontStyle: baseStyle,
              color: customColor ?? Colors.white.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: 8.0 * scaleFactor),
          Container(
            width: 4.0 * scaleFactor,
            height: 4.0 * scaleFactor,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(height: 18.0 * scaleFactor),
        ],
      );
    } else if (style == 3) {
      // Style 3: Minimal Zen
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$hour:$minuteStr $period',
            style: TextStyle(
              fontFamily: baseFont,
              fontSize: 20.0 * scaleFactor * customScale,
              fontWeight: quote.timeBold ? FontWeight.w700 : FontWeight.w200,
              fontStyle: baseStyle,
              color: customColor ?? Colors.white.withValues(alpha: 0.55),
            ),
          ),
          SizedBox(height: 18.0 * scaleFactor),
        ],
      );
    } else if (style == 4) {
      // Style 4: Digital 24H (Pure Monochrome)
      final h24 = time.hour.toString().padLeft(2, '0');
      final m24 = time.minute.toString().padLeft(2, '0');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '// 24H TIMESTAMP',
            style: TextStyle(
              fontFamily: AppFonts.sfProText,
              fontSize: 9.5 * scaleFactor * customScale,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5 * scaleFactor,
              color: Colors.white.withValues(alpha: 0.40),
            ),
          ),
          SizedBox(height: 2.0 * scaleFactor),
          Text(
            '$h24:$m24',
            style: TextStyle(
              fontFamily: baseFont,
              fontSize: 28.0 * scaleFactor * customScale,
              fontWeight: baseWeight,
              fontStyle: baseStyle,
              color: customColor ?? Colors.white.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: 8.0 * scaleFactor),
          Container(
            width: 22.0 * scaleFactor,
            height: 1.5 * scaleFactor,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          SizedBox(height: 18.0 * scaleFactor),
        ],
      );
    }

    // Default Style 0: Classic Null
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "It's",
          style: TextStyle(
            fontFamily: AppFonts.sfProText,
            fontSize: 11.0 * scaleFactor * customScale,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        Text(
          "$hour:$minuteStr $period",
          style: TextStyle(
            fontFamily: baseFont,
            fontSize: 26.0 * scaleFactor * customScale,
            color: customColor ?? Colors.white.withValues(alpha: 0.75),
            height: 1.15,
            fontWeight: baseWeight,
            fontStyle: baseStyle,
            letterSpacing: 0.5 * scaleFactor,
          ),
        ),
        SizedBox(height: 12.0 * scaleFactor),
        Container(
          width: 24.0 * scaleFactor,
          height: 2.0 * scaleFactor,
          color: Colors.white.withValues(alpha: 0.18),
        ),
        SizedBox(height: 24.0 * scaleFactor),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final quote = note.quote;
    final String rawText = note.text.isNotEmpty ? note.text : quote.mainText;
    final String displayText = rawText.isEmpty ? 'pure dark.\nzero friction.\njust your thoughts.' : rawText;
    final double baseFontSize = (quote.fontSize > 0 ? quote.fontSize : 44.0) * scaleFactor;

    final TextStyle baseStyle = TextStyle(
      fontFamily: quote.fontFamily.isNotEmpty ? quote.fontFamily : AppFonts.sfProDisplay,
      fontSize: baseFontSize,
      color: Colors.white,
      fontWeight: quote.fontWeight,
      letterSpacing: quote.letterSpacing * scaleFactor,
      height: quote.height,
    );

    final NullRichTextController controller = NullRichTextController(
      text: displayText,
      spans: note.spans,
    );

    final TextSpan contentSpan = controller.buildTextSpan(
      context: context,
      style: baseStyle,
      withComposing: false,
    );

    return Container(
      decoration: BoxDecoration(
        color: quote.backgroundColor,
        border: showGlassFrame
            ? Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5 * scaleFactor)
            : null,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 28.0 * scaleFactor,
        vertical: 36.0 * scaleFactor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Section: Optional Time Header
          if (showTimestamp && quote.showTime) ...[
            _buildCardTimeHeader(quote, note.createdAt),
          ] else ...[
            SizedBox(height: 12.0 * scaleFactor),
          ],

          // 2. Middle Section: Note Text
          Expanded(
            child: Center(
              widthFactor: 1.0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: RichText(
                    text: contentSpan,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ),
          ),

          // 3. Bottom Section: Minimalist Signature (- written on null)
          if (showWatermark) ...[
            SizedBox(height: 14.0 * scaleFactor),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '— written on null',
                style: TextStyle(
                  fontFamily: AppFonts.sfProText,
                  fontSize: 11.5 * scaleFactor,
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 0.2 * scaleFactor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
