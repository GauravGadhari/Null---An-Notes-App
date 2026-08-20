import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:null_notes/core/fonts/app_fonts.dart';
import 'package:null_notes/core/models/note.dart';
import 'package:null_notes/core/services/notes_service.dart';
import 'package:null_notes/widgets/null_card_preview.dart';
import 'package:null_notes/widgets/null_phone_frame.dart';

class ExportStudioScreen extends StatefulWidget {
  final int initialPageIndex;

  const ExportStudioScreen({
    super.key,
    this.initialPageIndex = 0,
  });

  @override
  State<ExportStudioScreen> createState() => _ExportStudioScreenState();
}

class _ExportStudioScreenState extends State<ExportStudioScreen> {
  late PageController _pageController;
  late int _currentPageIndex;
  ExportAspectRatio _selectedRatio = ExportAspectRatio.square1_1;

  bool _showTimestamp = true;
  bool _showWatermark = false;
  bool _showGlassFrame = false;
  bool _isExporting = false;

  final GlobalKey _repaintBoundaryKey = GlobalKey();

  List<Note> get _allNotes => NotesService.instance.notes;

  @override
  void initState() {
    super.initState();
    final totalNotes = _allNotes.length;
    _currentPageIndex = widget.initialPageIndex.clamp(0, totalNotes > 0 ? totalNotes - 1 : 0);
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _exportAndShare() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 60));

      final RenderRepaintBoundary? boundary =
          _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Unable to capture preview boundary');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to encode PNG bytes');
      }

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final File tempFile = File('${tempDir.path}/null_card_$timestamp.png');
      await tempFile.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1C1C1E),
            content: Text(
              'Export failed: $e',
              style: const TextStyle(color: Colors.white, fontFamily: AppFonts.sfProText),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = _allNotes;
    final bool hasNotes = notes.isNotEmpty;
    final int totalCount = hasNotes ? notes.length : 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Minimal Top Navigation Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38.0,
                      height: 38.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416).withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: Color(0xFFEDEDED),
                        size: 16.0,
                      ),
                    ),
                  ),

                  // Header title & Note Counter
                  Column(
                    children: [
                      const Text(
                        'export card',
                        style: TextStyle(
                          fontFamily: AppFonts.sfProDisplay,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '${_currentPageIndex + 1} of $totalCount',
                        style: TextStyle(
                          fontFamily: AppFonts.sfProText,
                          fontSize: 11.0,
                          color: Colors.white.withValues(alpha: 0.40),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 38.0),
                ],
              ),
            ),

            // ── 2. Center Interactive Phone Mockup with Swipeable Notes ──
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: NullPhoneFrame(
                    aspectRatio: _selectedRatio.ratio,
                    showDeviceBezel: true,
                    child: hasNotes
                        ? PageView.builder(
                            controller: _pageController,
                            itemCount: notes.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final isCurrent = index == _currentPageIndex;
                              final cardWidget = NullCardPreview(
                                note: notes[index],
                                aspectRatio: _selectedRatio,
                                showTimestamp: _showTimestamp,
                                showWatermark: _showWatermark,
                                showGlassFrame: _showGlassFrame,
                                smartWordsEnabled: NotesService.instance.smartWordsEnabledNotifier.value,
                                scaleFactor: _getScaleFactorForRatio(_selectedRatio),
                              );

                              if (isCurrent) {
                                return RepaintBoundary(
                                  key: _repaintBoundaryKey,
                                  child: cardWidget,
                                );
                              }
                              return cardWidget;
                            },
                          )
                        : RepaintBoundary(
                            key: _repaintBoundaryKey,
                            child: NullCardPreview(
                              note: Note(
                                id: 'placeholder',
                                text: 'pure dark.\nzero friction.\njust your thoughts.',
                                createdAt: DateTime.now(),
                                quote: const QuoteItem(
                                  mainText: 'pure dark.\nzero friction.\njust your thoughts.',
                                  fontFamily: AppFonts.sfProDisplay,
                                ),
                              ),
                              aspectRatio: _selectedRatio,
                              showTimestamp: _showTimestamp,
                              showWatermark: _showWatermark,
                              showGlassFrame: _showGlassFrame,
                              scaleFactor: _getScaleFactorForRatio(_selectedRatio),
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // ── 3. Style Options Row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToggleChip(
                    label: 'Time',
                    isActive: _showTimestamp,
                    onTap: () => setState(() => _showTimestamp = !_showTimestamp),
                  ),
                  const SizedBox(width: 8.0),
                  _buildToggleChip(
                    label: 'Signature',
                    isActive: _showWatermark,
                    onTap: () => setState(() => _showWatermark = !_showWatermark),
                  ),
                  const SizedBox(width: 8.0),
                  _buildToggleChip(
                    label: 'Border Glow',
                    isActive: _showGlassFrame,
                    onTap: () => setState(() => _showGlassFrame = !_showGlassFrame),
                  ),
                ],
              ),
            ),

            // ── 4. Minimal Aspect Ratio Selector Pills ──
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: ExportAspectRatio.values.map((ratio) {
                    final bool isSelected = _selectedRatio == ratio;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRatio = ratio),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ratio.label,
                                style: TextStyle(
                                  fontFamily: AppFonts.sfProDisplay,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                ratio.description,
                                style: TextStyle(
                                  fontFamily: AppFonts.sfProText,
                                  fontSize: 11.0,
                                  color: isSelected ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── 5. Bottom Share / Export Action Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 52.0,
                child: ElevatedButton(
                  onPressed: _isExporting ? null : _exportAndShare,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26.0),
                    ),
                  ),
                  child: _isExporting
                      ? const SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.share, size: 18.0, color: Colors.black),
                            SizedBox(width: 8.0),
                            Text(
                              'Share Card',
                              style: TextStyle(
                                fontFamily: AppFonts.sfProDisplay,
                                fontSize: 15.0,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getScaleFactorForRatio(ExportAspectRatio ratio) {
    switch (ratio) {
      case ExportAspectRatio.story9_16:
      case ExportAspectRatio.wallpaper19_9:
        return 0.85;
      case ExportAspectRatio.portrait4_5:
        return 0.90;
      case ExportAspectRatio.square1_1:
        return 0.75;
      case ExportAspectRatio.landscape16_9:
        return 0.65;
    }
  }

  Widget _buildToggleChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isActive ? Colors.white.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.15),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.sfProText,
            fontSize: 12.0,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}
