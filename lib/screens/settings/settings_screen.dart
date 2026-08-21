import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/fonts/app_fonts.dart';
import '../../core/models/custom_smart_word.dart';
import '../../core/services/notes_service.dart';
import 'smart_words_screen.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onSleepRequested;

  const SettingsScreen({
    super.key,
    this.onSleepRequested,
  });

  Future<void> _openUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = screenHeight * 0.12;

    return Container(
      color: const Color(0xFF000000),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                left: 28.0,
                right: 28.0,
                top: topPadding,
                bottom: 120.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'settings',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProDisplay,
                      fontSize: 46,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1.2,
                      color: Color(0xFFEDEDED),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'pure dark.\nzero friction.\njust your thoughts.',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProDisplay,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF55555A),
                      height: 1.35,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 44),

                  // ── 1. Launch Behavior Toggle ──
                  ValueListenableBuilder<bool>(
                    valueListenable: NotesService.instance.openOnNewNoteNotifier,
                    builder: (context, openOnNewNote, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141416).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Open to New Note',
                                    style: TextStyle(
                                      fontFamily: AppFonts.sfProDisplay,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFEDEDED),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    openOnNewNote
                                        ? 'Opens clean draft on launch'
                                        : 'Resumes where you left off',
                                    style: const TextStyle(
                                      fontFamily: AppFonts.sfProText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                NotesService.instance.setOpenOnNewNote(!openOnNewNote);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                width: 50,
                                height: 30,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: openOnNewNote
                                      ? const Color(0xFFEDEDED)
                                      : const Color(0xFF2C2C2E),
                                ),
                                alignment: openOnNewNote
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: openOnNewNote
                                        ? const Color(0xFF000000)
                                        : const Color(0xFF8E8E93),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── 2. Smart Words Styling Toggle ──
                  ValueListenableBuilder<bool>(
                    valueListenable: NotesService.instance.smartWordsEnabledNotifier,
                    builder: (context, smartWordsEnabled, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141416).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Smart Words Styling',
                                    style: TextStyle(
                                      fontFamily: AppFonts.sfProDisplay,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFEDEDED),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    smartWordsEnabled
                                        ? 'Expressive styles for emotions & slang'
                                        : 'Pure unformatted text baseline',
                                    style: const TextStyle(
                                      fontFamily: AppFonts.sfProText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                NotesService.instance.setSmartWordsEnabled(!smartWordsEnabled);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                width: 50,
                                height: 30,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: smartWordsEnabled
                                      ? const Color(0xFFEDEDED)
                                      : const Color(0xFF2C2C2E),
                                ),
                                alignment: smartWordsEnabled
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: smartWordsEnabled
                                        ? const Color(0xFF000000)
                                        : const Color(0xFF8E8E93),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // ── 3. Smart Words Catalog & AI Import Tile ──
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => const SmartWordsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'Smart Words Catalog',
                                      style: TextStyle(
                                        fontFamily: AppFonts.sfProDisplay,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFEDEDED),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text('✨', style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ValueListenableBuilder<List<CustomSmartWord>>(
                                  valueListenable: NotesService.instance.customSmartWordsNotifier,
                                  builder: (context, customList, _) {
                                    return Text(
                                      customList.isEmpty
                                          ? 'View all styled words & AI ChatGPT import'
                                          : '${customList.length} custom rules • Tap to view & import',
                                      style: const TextStyle(
                                        fontFamily: AppFonts.sfProText,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF8E8E93),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            CupertinoIcons.chevron_forward,
                            size: 18,
                            color: Color(0xFF8E8E93),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── 4. Suggest Add Timestamp in Editor ──
                  ValueListenableBuilder<bool>(
                    valueListenable: NotesService.instance.suggestAddTimestampNotifier,
                    builder: (context, suggestAddTimestamp, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141416).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Suggest Add Timestamp',
                                    style: TextStyle(
                                      fontFamily: AppFonts.sfProDisplay,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFEDEDED),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    suggestAddTimestamp
                                        ? 'Shows "+ Add timestamp" button while editing'
                                        : 'Never prompts to add timestamp',
                                    style: const TextStyle(
                                      fontFamily: AppFonts.sfProText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                NotesService.instance.setSuggestAddTimestamp(!suggestAddTimestamp);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                width: 50,
                                height: 30,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  color: suggestAddTimestamp
                                      ? const Color(0xFFEDEDED)
                                      : const Color(0xFF2C2C2E),
                                ),
                                alignment: suggestAddTimestamp
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: suggestAddTimestamp
                                        ? const Color(0xFF000000)
                                        : const Color(0xFF8E8E93),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 38),

                  // ── 5. Developer & Craft Section ──
                  const Text(
                    'DEVELOPER',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProDisplay,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: Color(0xFF636366),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Developer Header (Avatar + Name + Role)
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1.2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  fontFamily: AppFonts.sfProDisplay,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gaurav Gadhari',
                                    style: TextStyle(
                                      fontFamily: AppFonts.sfProDisplay,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFEDEDED),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Software Craftsman & Designer',
                                    style: TextStyle(
                                      fontFamily: AppFonts.sfProText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          height: 1.0,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),

                        const SizedBox(height: 14),

                        // Interactive Social / Link Chips
                        Row(
                          children: [
                            Expanded(
                              child: _buildDevActionChip(
                                icon: CupertinoIcons.link,
                                label: 'GitHub',
                                onTap: () => _openUrl('https://github.com/GauravGadhari'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildDevActionChip(
                                icon: CupertinoIcons.globe,
                                label: 'Portfolio',
                                onTap: () => _openUrl('https://this-is-gaurav.vercel.app'),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Footer Note
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '100% Offline & Private',
                              style: TextStyle(
                                fontFamily: AppFonts.sfProText,
                                fontSize: 11,
                                color: Color(0xFF636366),
                              ),
                            ),
                            Text(
                              'Null v1.0.2',
                              style: TextStyle(
                                fontFamily: AppFonts.sfProText,
                                fontSize: 11,
                                color: Color(0xFF48484A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.09),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppFonts.sfProText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEDEDED),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
