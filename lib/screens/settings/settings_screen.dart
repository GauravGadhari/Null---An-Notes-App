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
                left: 24.0,
                right: 24.0,
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
                      fontSize: 44,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -1.2,
                      color: Color(0xFFEDEDED),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'pure dark.\nzero friction.\njust your thoughts.',
                    style: TextStyle(
                      fontFamily: AppFonts.sfProDisplay,
                      fontSize: 19,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF55555A),
                      height: 1.35,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 38),

                  // ── SECTION 1: GENERAL GROUP ──
                  _buildSectionHeader('GENERAL'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416).withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Open to New Note
                        ValueListenableBuilder<bool>(
                          valueListenable: NotesService.instance.openOnNewNoteNotifier,
                          builder: (context, openOnNewNote, _) {
                            return _buildSettingToggleRow(
                              title: 'Open to New Note',
                              subtitle: openOnNewNote
                                  ? 'Opens clean draft on launch'
                                  : 'Resumes where you left off',
                              icon: CupertinoIcons.plus_app,
                              value: openOnNewNote,
                              onChanged: (val) => NotesService.instance.setOpenOnNewNote(val),
                            );
                          },
                        ),
                        _buildDivider(),
                        // Suggest Add Timestamp
                        ValueListenableBuilder<bool>(
                          valueListenable: NotesService.instance.suggestAddTimestampNotifier,
                          builder: (context, suggestAddTimestamp, _) {
                            return _buildSettingToggleRow(
                              title: 'Suggest Add Timestamp',
                              subtitle: suggestAddTimestamp
                                  ? 'Shows "+ add timestamp" while editing'
                                  : 'Never prompts timestamp button',
                              icon: CupertinoIcons.clock,
                              value: suggestAddTimestamp,
                              onChanged: (val) => NotesService.instance.setSuggestAddTimestamp(val),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── SECTION 2: TYPOGRAPHY & SMART WORDS GROUP ──
                  _buildSectionHeader('TYPOGRAPHY & INTELLIGENCE'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416).withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Smart Words Styling Toggle
                        ValueListenableBuilder<bool>(
                          valueListenable: NotesService.instance.smartWordsEnabledNotifier,
                          builder: (context, smartWordsEnabled, _) {
                            return _buildSettingToggleRow(
                              title: 'Smart Words Styling',
                              subtitle: smartWordsEnabled
                                  ? 'Expressive styles for emotions & slang'
                                  : 'Pure unformatted text baseline',
                              icon: CupertinoIcons.textformat_alt,
                              value: smartWordsEnabled,
                              onChanged: (val) => NotesService.instance.setSmartWordsEnabled(val),
                            );
                          },
                        ),
                        _buildDivider(),
                        // Smart Words Studio Navigation
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
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.sparkles,
                                    size: 16,
                                    color: Color(0xFFEDEDED),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Smart Words Catalog',
                                        style: TextStyle(
                                          fontFamily: AppFonts.sfProDisplay,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFFEDEDED),
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      ValueListenableBuilder<List<CustomSmartWord>>(
                                        valueListenable: NotesService.instance.customSmartWordsNotifier,
                                        builder: (context, customList, _) {
                                          return Text(
                                            customList.isEmpty
                                                ? 'View full catalog & AI ChatGPT generator'
                                                : '${customList.length} custom rules • Tap to view & edit',
                                            style: const TextStyle(
                                              fontFamily: AppFonts.sfProText,
                                              fontSize: 12,
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
                                  size: 16,
                                  color: Color(0xFF8E8E93),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── SECTION 3: DEVELOPER GROUP ──
                  _buildSectionHeader('DEVELOPER'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416).withValues(alpha: 0.90),
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

                        const SizedBox(height: 18),

                        // Action Buttons: GitHub & Portfolio
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: CupertinoIcons.chevron_left_slash_chevron_right,
                                label: 'GitHub',
                                onTap: () => _openUrl('https://github.com/GauravGadhari'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildActionButton(
                                icon: CupertinoIcons.globe,
                                label: 'Portfolio',
                                onTap: () => _openUrl('https://gauravgadhari.dev'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Subtle Footer Brand mark
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'NULL v1.2.0',
                          style: TextStyle(
                            fontFamily: AppFonts.sfProText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Crafted with obsessive precision',
                          style: TextStyle(
                            fontFamily: AppFonts.sfProText,
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: AppFonts.sfProText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: Color(0xFF636366),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1.0,
      margin: const EdgeInsets.symmetric(horizontal: 18),
      color: Colors.white.withValues(alpha: 0.07),
    );
  }

  Widget _buildSettingToggleRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFFEDEDED),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppFonts.sfProDisplay,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEDEDED),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: AppFonts.sfProText,
                    fontSize: 12,
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
              HapticFeedback.lightImpact();
              onChanged(!value);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: value
                    ? const Color(0xFFEDEDED)
                    : const Color(0xFF2C2C2E),
              ),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? const Color(0xFF000000) : const Color(0xFF8E8E93),
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
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: const Color(0xFFEDEDED),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppFonts.sfProText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFEDEDED),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
