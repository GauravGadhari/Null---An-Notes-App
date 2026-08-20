import 'package:flutter/material.dart';
import '../../core/fonts/app_fonts.dart';
import '../../core/services/notes_service.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback? onSleepRequested;

  const SettingsScreen({
    super.key,
    this.onSleepRequested,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF000000),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'settings',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProDisplay,
                      fontSize: 44,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1.0,
                      color: Color(0xFFEDEDED),
                    ),
                  ),
                  const SizedBox(height: 8),
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

                  const SizedBox(height: 48),

                  // --- Launch Behavior Toggle: Open to New Note vs Last Note ---
                  ValueListenableBuilder<bool>(
                    valueListenable: NotesService.instance.openOnNewNoteNotifier,
                    builder: (context, openOnNewNote, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141416).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(22),
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
                                  const SizedBox(height: 4),
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

                  // --- Smart Words Styling Toggle ---
                  ValueListenableBuilder<bool>(
                    valueListenable: NotesService.instance.smartWordsEnabledNotifier,
                    builder: (context, smartWordsEnabled, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141416).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(22),
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
                                  const SizedBox(height: 4),
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

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
