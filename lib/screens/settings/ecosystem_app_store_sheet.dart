import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/fonts/app_fonts.dart';

/// Renders an authentic Apple App Store-style Product Page bottom sheet for
/// cross-promoting "My 21 Days of Habit" from the Light Ecosystem with live CDN images.
void show21DaysAppStoreSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (context) => const _AppStoreProductSheet(),
  );
}

class _AppStoreProductSheet extends StatelessWidget {
  const _AppStoreProductSheet();

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.light_computers.daysofhabbit';

  static const String _iconUrl =
      'https://play-lh.googleusercontent.com/06RZZwjcaJDy_NtNYrJzlP7WgHSxoL7SuqdxGuPOdLBps2TKItVsoIy0z-ablDK3hKJ_C7FzHWbZv-2N01nebZQ=w240-h480';

  static const List<String> _screenshotUrls = [
    'https://play-lh.googleusercontent.com/HbwXUwb5h_YZYJcuzGg8l940d_Sk7cYh91PXjPvHBusWdwILS1QcwCd8rnuG5ZD8DNIZuMSLTMwDGa8d7JBbQQ=w1080-h2424',
    'https://play-lh.googleusercontent.com/ehx-h4WFAHF8330yKg2FgA7obfacRtuVlIr8UmXc9-4qnoEIqJDLkR-lrHauPkkiPirGZ1mW1DHKH-YAC7zP=w1080-h2424',
    'https://play-lh.googleusercontent.com/nKilctbM4dgaE2g6RfNRxHnBE65CZNlI74xCYZK974KHaY8Qsk8JJGJNnk0DU6_VNvHrfpLQ3Gr0AYGxHamz1Q=w1080-h2424',
    'https://play-lh.googleusercontent.com/ZH2LeXmTMbv3lJXzmf6sCglLpYL_EBnCPgqjg0NOO6RdHVRNeNzhoLcjJe2XEYQ5XM9vIfuL6JyfV31Eq5LB8o4=w1080-h2424',
    'https://play-lh.googleusercontent.com/uc9vv0rO6XpQ0Fv7dSYMvogFuNcb6gOr_6K7dhwtdBzUQ9UFWT1UBBJohxMsAcWWTFe5wBNh9ScmrG3q9kkMm9c=w1080-h2424',
    'https://play-lh.googleusercontent.com/0mtk7X1UCg7kfVoCksfxEvPtmDsPe4XD5FP92BxFn5tVUdHU1pr_3G3MEkvs3oVgDKlcgraMcNs93uP1IcEv2A=w1080-h2424',
    'https://play-lh.googleusercontent.com/UuVgVC4znIMMGoElGT-q5F6udZiOC40B950v7Wz02aVUc4DEDliwlqRGM3eNdhavTCnWGe6Om2Y01yJQeuPe=w1080-h2424',
  ];

  static const List<String> _fallbackAssetScreenshots = [
    'assets/ecosystem/21days/screen_1.png',
    'assets/ecosystem/21days/screen_2.png',
    'assets/ecosystem/21days/screen_3.png',
    'assets/ecosystem/21days/screen_4.png',
    'assets/ecosystem/21days/screen_5.png',
    'assets/ecosystem/21days/screen_6.png',
  ];

  Future<void> _launchStore(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse(_playStoreUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _openFullscreenScreenshot(
    BuildContext context,
    String networkUrl,
    String? fallbackAsset,
  ) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.90),
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      networkUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        if (fallbackAsset != null) {
                          return Image.asset(
                            fallbackAsset,
                            fit: BoxFit.contain,
                          );
                        }
                        return const Icon(
                          CupertinoIcons.photo,
                          size: 48,
                          color: Color(0xFF8E8E93),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetHeight = screenHeight * 0.86;

    return Container(
      height: sheetHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF121214),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.0,
          ),
          left: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 36,
            spreadRadius: 8,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Top Apple Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Scrollable App Store Content Body
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Apple App Store Header (Icon + Titles + GET Action) ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 74x74 Rounded Squircle Icon
                        Container(
                          width: 74,
                          height: 74,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            _iconUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              'assets/ecosystem/21days/icon.png',
                              fit: BoxFit.cover,
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Image.asset(
                                'assets/ecosystem/21days/icon.png',
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Titles + Get Button
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My 21 Days of Habit',
                                style: TextStyle(
                                  fontFamily: AppFonts.sfProDisplay,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEDEDED),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Build lasting habits & routines',
                                style: TextStyle(
                                  fontFamily: AppFonts.sfProText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Light Ecosystem',
                                style: TextStyle(
                                  fontFamily: AppFonts.sfProText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF636366),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Action Row: Apple-Style "GET" Pill + Share
                              Row(
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _launchStore(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDEDED),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'GET',
                                        style: TextStyle(
                                          fontFamily: AppFonts.sfProDisplay,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF000000),
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _launchStore(context),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.08),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        CupertinoIcons.share,
                                        size: 15,
                                        color: Color(0xFFEDEDED),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 18),

                    // --- Apple App Store Metric Ribbon ---
                    _buildAppStoreMetricsRibbon(),

                    const SizedBox(height: 18),
                    _buildDivider(),
                    const SizedBox(height: 24),

                    // --- App Store Screenshots Section ---
                    const Text(
                      'PREVIEW',
                      style: TextStyle(
                        fontFamily: AppFonts.sfProText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF636366),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Horizontal Screenshots Carousel
                    SizedBox(
                      height: 280,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _screenshotUrls.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final networkUrl = _screenshotUrls[index];
                          final fallbackAsset = index < _fallbackAssetScreenshots.length
                              ? _fallbackAssetScreenshots[index]
                              : null;

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _openFullscreenScreenshot(
                              context,
                              networkUrl,
                              fallbackAsset,
                            ),
                            child: Container(
                              width: 136,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.network(
                                networkUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  if (fallbackAsset != null) {
                                    return Image.asset(
                                      fallbackAsset,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return Container(
                                    color: const Color(0xFF1C1C1E),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      CupertinoIcons.photo,
                                      size: 24,
                                      color: Color(0xFF636366),
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  if (fallbackAsset != null) {
                                    return Image.asset(
                                      fallbackAsset,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return Container(
                                    color: const Color(0xFF1C1C1E),
                                    alignment: Alignment.center,
                                    child: const CupertinoActivityIndicator(radius: 12),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 28),
                    _buildDivider(),
                    const SizedBox(height: 20),

                    // --- Description & Highlights ---
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontFamily: AppFonts.sfProDisplay,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEDEDED),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Science proves it takes 21 days to form a neural pathway. My 21 Days of Habit combines ultra-clean visual progress, streak recovery shields, and zero-distraction focus to turn your ambitions into daily discipline.',
                      style: TextStyle(
                        fontFamily: AppFonts.sfProText,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFA0A0A5),
                        height: 1.45,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildFeaturePill(
                      icon: CupertinoIcons.shield_lefthalf_fill,
                      title: 'Streak Shields',
                      description: 'Protect hard-earned streaks when life gets busy',
                    ),
                    const SizedBox(height: 10),
                    _buildFeaturePill(
                      icon: CupertinoIcons.square_grid_2x2_fill,
                      title: 'Glanceable Widgets',
                      description: 'Track and check habits directly from your Home Screen',
                    ),
                    const SizedBox(height: 10),
                    _buildFeaturePill(
                      icon: CupertinoIcons.sparkles,
                      title: 'Light Ecosystem Sync',
                      description: 'Synchronize seamlessly across Light apps with cloud backup',
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Sticky Action Button
          Container(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 14,
              bottom: MediaQuery.of(context).padding.bottom + 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1.0,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _launchStore(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEDED),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.18),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.cloud_download,
                        size: 18,
                        color: Color(0xFF000000),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Get My 21 Days of Habit',
                        style: TextStyle(
                          fontFamily: AppFonts.sfProDisplay,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF000000),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 1.0,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _buildAppStoreMetricsRibbon() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetricColumn(
          header: '4.9 ★',
          sub: '1.4K RATINGS',
        ),
        _buildVerticalDivider(),
        _buildMetricColumn(
          header: '#1',
          sub: 'HABIT APP',
        ),
        _buildVerticalDivider(),
        _buildMetricColumn(
          header: '4+',
          sub: 'AGE',
        ),
        _buildVerticalDivider(),
        _buildMetricColumn(
          header: 'EN',
          sub: 'LANGUAGE',
        ),
      ],
    );
  }

  Widget _buildMetricColumn({required String header, required String sub}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          header,
          style: const TextStyle(
            fontFamily: AppFonts.sfProDisplay,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFFEDEDED),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          sub,
          style: const TextStyle(
            fontFamily: AppFonts.sfProText,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF636366),
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1.0,
      height: 28,
      color: Colors.white.withValues(alpha: 0.10),
    );
  }

  Widget _buildFeaturePill({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFFEDEDED),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: AppFonts.sfProDisplay,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEDEDED),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
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
        ],
      ),
    );
  }
}
