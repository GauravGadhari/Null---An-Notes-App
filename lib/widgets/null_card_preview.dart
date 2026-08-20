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

  String _formatTime(DateTime time) {
    int hour = time.hour;
    final int minute = time.minute;
    final String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final String minuteStr = minute < 10 ? '0$minute' : '$minute';
    return "It's\n$hour:$minuteStr $period";
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
      height: 1.18,
      letterSpacing: -0.8 * scaleFactor,
      fontWeight: quote.fontWeight,
    );

    // Build rich text with controller to render both user spans and smart words styling
    final controller = NullRichTextController(
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
            Text(
              _formatTime(note.createdAt),
              style: TextStyle(
                fontFamily: AppFonts.sfProDisplay,
                fontSize: 16.0 * scaleFactor,
                color: Colors.white.withValues(alpha: 0.45),
                height: 1.25,
                fontWeight: FontWeight.w300,
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
