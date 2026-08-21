import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/fonts/app_fonts.dart';
import 'core/services/notes_service.dart';
import 'screens/editor/editor_screen.dart';
import 'screens/editor/editor_state.dart';
import 'screens/export/export_studio_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/glowing_ring.dart';
import 'widgets/null_bottom_dock.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await NotesService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const NullNotesApp());
}

class NullNotesApp extends StatelessWidget {
  const NullNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Null',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: Colors.white,
        fontFamily: AppFonts.sfProDisplay,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Color(0xFF000000),
          onSurface: Colors.white,
        ),
      ),
      home: const NullUniversalShell(),
    );
  }
}

class NullUniversalShell extends StatefulWidget {
  const NullUniversalShell({super.key});

  @override
  State<NullUniversalShell> createState() => _NullUniversalShellState();
}

class _NullUniversalShellState extends State<NullUniversalShell>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  EditorState _state = EditorState.sleep;
  late final PageController _pageController;

  // Controllers for silky-smooth transitions
  late final AnimationController _swipeUpWakeController;
  late final AnimationController _swipeDownWakeController;
  late final AnimationController _sleepTransitionController;

  // Controller for morphing circle into rectangular page indicator container
  late final AnimationController _morphController;
  // Controller for morphing bottom dock into floating toolbar when focused
  late final AnimationController _toolbarMorphController;
  Timer? _morphCollapseTimer;
  double _currentPage = 0.0;

  bool _isWakingUp = false;
  bool _isWakingDown = false;
  bool _isSleepingAnim = false;
  double _dragAccumulator = 0.0;

  static const double _sleepSize = 68.0;
  static const double _awakeSize = 32.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initialPage = NotesService.instance.getInitialPageIndex();
    _pageController = PageController(initialPage: initialPage);
    _currentPage = initialPage.toDouble();
    _pageController.addListener(_handlePageScroll);
    NotesService.instance.notesNotifier.addListener(_onNotesChanged);
    NotesService.instance.isEditorFocusedNotifier.addListener(_onEditorFocusChanged);

    _toolbarMorphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Automatically trigger smooth entrance wake animation on app open after 300ms delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _state == EditorState.sleep) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _state == EditorState.sleep) {
            _triggerSwipeDown();
          }
        });
      }
    });

    // 1. SWIPE UP WAKE: 1380ms trajectory
    _swipeUpWakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1380),
    );

    _swipeUpWakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isWakingUp = false;
          _state = EditorState.awake;
        });
        _swipeUpWakeController.reset();
      }
    });

    // 2. SWIPE DOWN WAKE: 780ms smooth descent
    _swipeDownWakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );

    _swipeDownWakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isWakingDown = false;
          _state = EditorState.awake;
        });
        _swipeDownWakeController.reset();
      }
    });

    // 3. SLEEP TRANSITION: 700ms smooth return to center with real-time fade-out
    _sleepTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _sleepTransitionController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSleepingAnim = false;
          _state = EditorState.sleep;
        });
        _sleepTransitionController.reset();
      }
    });

    // 4. MORPH CONTROLLER: Smoothly morphs between 32px circle and 88px rectangular indicator
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _handlePageScroll() {
    if (_pageController.hasClients && _pageController.page != null) {
      setState(() {
        _currentPage = _pageController.page!;
      });

      if (_state == EditorState.awake && !_isSleepingAnim) {
        // If user scrolls tabs while editor is active/focused -> make inactive and morph to page indicators
        if (NotesService.instance.isEditorFocusedNotifier.value) {
          NotesService.instance.onDismissKeyboard?.call();
          FocusManager.instance.primaryFocus?.unfocus();
        }

        // Expand/morph into rectangular container on tab scroll
        if (_morphController.value < 1.0 && !_morphController.isAnimating) {
          _morphController.animateTo(1.0, curve: Curves.easeOutCubic);
        }

        // Reset collapse timer so it stays open while user is scrolling
        _morphCollapseTimer?.cancel();
        _morphCollapseTimer = Timer(const Duration(milliseconds: 800), () {
          if (mounted && _state == EditorState.awake) {
            _morphController.animateTo(0.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _morphCollapseTimer?.cancel();
    NotesService.instance.notesNotifier.removeListener(_onNotesChanged);
    NotesService.instance.isEditorFocusedNotifier.removeListener(_onEditorFocusChanged);
    _pageController.removeListener(_handlePageScroll);
    _pageController.dispose();
    _swipeUpWakeController.dispose();
    _swipeDownWakeController.dispose();
    _sleepTransitionController.dispose();
    _morphController.dispose();
    _toolbarMorphController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      NotesService.instance.saveNow();
    }
  }

  void _onEditorFocusChanged() {
    if (!mounted) return;
    if (NotesService.instance.isEditorFocusedNotifier.value) {
      _toolbarMorphController.forward();
    } else {
      _toolbarMorphController.reverse();
    }
  }

  void _onNotesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 5th-order smootherstep polynomial (C^2 continuous: zero jerk, pure fluid motion)
  static double _smootherstep(double t) {
    final clamped = t.clamp(0.0, 1.0);
    return clamped * clamped * clamped * (clamped * (clamped * 6 - 15) + 10);
  }

  /// Velocity derivative of the smootherstep curve
  static double _smootherstepDerivative(double t) {
    final clamped = t.clamp(0.0, 1.0);
    return 30 * clamped * clamped * (clamped * (clamped - 2) + 1);
  }

  void _triggerSwipeUp() {
    if (_state == EditorState.sleep && !_isWakingUp && !_isWakingDown && !_isSleepingAnim) {
      // Swipe up refreshes the active template idea!
      NotesService.instance.refreshActiveDraftQuote();
      setState(() {
        _isWakingUp = true;
      });
      _swipeUpWakeController.forward(from: 0.0);
    }
  }

  void _triggerSwipeDown() {
    if (_state == EditorState.sleep && !_isWakingUp && !_isWakingDown && !_isSleepingAnim) {
      setState(() {
        _isWakingDown = true;
      });
      _swipeDownWakeController.forward(from: 0.0);
    }
  }

  void _putToSleep() {
    if (_state != EditorState.sleep && !_isSleepingAnim) {
      // Exit active editing mode, dismiss keyboard and collapse toolbar immediately
      if (NotesService.instance.isEditorFocusedNotifier.value) {
        NotesService.instance.onDismissKeyboard?.call();
        FocusManager.instance.primaryFocus?.unfocus();
      }
      if (_toolbarMorphController.value > 0.0) {
        _toolbarMorphController.animateTo(0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic);
      }

      _morphCollapseTimer?.cancel();
      if (_morphController.value > 0.0) {
        _morphController.animateTo(0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic);
      }

      if (_isWakingUp) {
        _swipeUpWakeController.stop();
        _swipeUpWakeController.reset();
        _isWakingUp = false;
      }
      if (_isWakingDown) {
        _swipeDownWakeController.stop();
        _swipeDownWakeController.reset();
        _isWakingDown = false;
      }

      setState(() {
        _isSleepingAnim = true;
      });
      _sleepTransitionController.forward(from: 0.0);
    }
  }

  void _triggerAwakeCircleTap() {
    final activeIndex = _currentPage.round();
    final totalNotes = NotesService.instance.count;
    if (activeIndex > totalNotes) {
      // If on settings page, navigate to draft editor page and focus
      _pageController.animateToPage(
        totalNotes,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      ).then((_) {
        NotesService.instance.requestEditorFocus(totalNotes);
      });
    } else {
      NotesService.instance.requestEditorFocus(activeIndex);
    }
  }

  void _openExportStudio() {
    final activeIndex = _currentPage.round().clamp(0, NotesService.instance.count > 0 ? NotesService.instance.count - 1 : 0);
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: ExportStudioScreen(initialPageIndex: activeIndex),
          );
        },
        transitionDuration: const Duration(milliseconds: 360),
      ),
    );
  }

  void _onDragStart(DragStartDetails details) {
    _dragAccumulator = 0.0;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragAccumulator += details.primaryDelta ?? 0.0;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0.0;

    if (_state == EditorState.sleep && !_isWakingUp && !_isWakingDown && !_isSleepingAnim) {
      if (_dragAccumulator < -20 || velocity < -100) {
        _triggerSwipeUp();
      } else if (_dragAccumulator > 20 || velocity > 100) {
        _triggerSwipeDown();
      }
    } else if (_state == EditorState.awake && !_isSleepingAnim) {
      if (_dragAccumulator < -20 || velocity < -120) {
        _putToSleep();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRestingAwake = _state == EditorState.awake &&
        !_isWakingUp &&
        !_isWakingDown &&
        !_isSleepingAnim;

    final totalNotes = NotesService.instance.count;
    final totalPages = totalNotes + 2;

    final leftOverscrollText = totalNotes == 0
        ? "recent notes here or create your first note"
        : (totalNotes % 2 == 0
            ? "aha no more stuff here"
            : "break the flow here bruhh you dont have any more");

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final isFocused = NotesService.instance.isEditorFocusedNotifier.value;
        final hasToolbar = _toolbarMorphController.value > 0.01;

        // 1. If in active editor mode, exit focus and dismiss toolbar
        if (isFocused || hasToolbar) {
          NotesService.instance.onDismissKeyboard?.call();
          FocusManager.instance.primaryFocus?.unfocus();
          _toolbarMorphController.reverse();
          return;
        }

        // 2. If in awake state, smoothly transition to sleep mode
        if (_state == EditorState.awake && !_isSleepingAnim) {
          _putToSleep();
          return;
        }

        // 3. If already in sleep mode, close / minimize the app
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (_state == EditorState.awake && !_isSleepingAnim) {
            // Unfocus active editor when horizontal tab swipe begins
            if (notification.metrics.axis == Axis.horizontal && notification is ScrollStartNotification) {
              if (NotesService.instance.isEditorFocusedNotifier.value) {
                NotesService.instance.onDismissKeyboard?.call();
                FocusManager.instance.primaryFocus?.unfocus();
              }
            }

            // Only respond to vertical overscroll at top edge
            if (notification.metrics.axis == Axis.vertical) {
              if (notification is OverscrollNotification && notification.overscroll < -6) {
                _putToSleep();
                return true;
              }
              if (notification is ScrollUpdateNotification && notification.metrics.pixels < -30) {
                _putToSleep();
                return true;
              }
            }
          }
          return false;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: _state == EditorState.sleep ? _onDragStart : null,
          onVerticalDragUpdate: _state == EditorState.sleep ? _onDragUpdate : null,
          onVerticalDragEnd: _state == EditorState.sleep ? _onDragEnd : null,
          onTap: (_state == EditorState.sleep && !_isWakingUp && !_isWakingDown && !_isSleepingAnim)
              ? _triggerSwipeDown
              : null,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _swipeUpWakeController,
              _swipeDownWakeController,
              _sleepTransitionController,
              _morphController,
              _toolbarMorphController,
            ]),
            child: RepaintBoundary(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: totalPages,
                onPageChanged: (index) {
                  NotesService.instance.setLastActivePage(index);
                  final note = NotesService.instance.getNote(index);
                  if (note != null) {
                    NotesService.instance.activeBackgroundColorNotifier.value =
                        note.quote.backgroundColorValue ?? 0xFF000000;
                    NotesService.instance.activeEditorFontNotifier.value =
                        note.quote.fontFamily;
                  } else {
                    final draft = NotesService.instance.activeDraftQuote;
                    NotesService.instance.activeBackgroundColorNotifier.value =
                        draft.backgroundColorValue ?? 0xFF000000;
                    NotesService.instance.activeEditorFontNotifier.value =
                        draft.fontFamily;
                  }
                },
                itemBuilder: (context, index) {
                  if (index <= totalNotes) {
                    return EditorScreen(
                      key: ValueKey('editor_page_$index'),
                      pageIndex: index,
                      state: _state,
                      onSleepRequested: _putToSleep,
                    );
                  } else {
                    return SettingsScreen(
                      key: const ValueKey('settings_page'),
                      onSleepRequested: _putToSleep,
                    );
                  }
                },
              ),
            ),
            builder: (context, staticPageView) {
              // --- 1. Compute Unified Real-Time Content Opacity ---
              double contentOpacity = 0.0;

              if (_isSleepingAnim) {
                final t = _sleepTransitionController.value.clamp(0.0, 1.0);
                contentOpacity = (1.0 - _smootherstep(t)).clamp(0.0, 1.0);
              } else if (_isWakingUp) {
                final t = _swipeUpWakeController.value;
                if (t >= 0.70) {
                  contentOpacity = ((t - 0.70) / 0.30).clamp(0.0, 1.0);
                }
              } else if (_isWakingDown) {
                final t = _swipeDownWakeController.value;
                if (t >= 0.50) {
                  contentOpacity = ((t - 0.50) / 0.50).clamp(0.0, 1.0);
                }
              } else if (_state == EditorState.awake) {
                contentOpacity = 1.0;
              }

              // --- 2. Unified Ring Geometry & Physics Engine ---
              double ringY = 0.0;
              double ringSize = _sleepSize;
              double ringStroke = 2.4;
              double ringOpacity = 0.35;
              double scaleX = 1.0;
              double scaleY = 1.0;
              double activeMorph = 0.0;

              final screenHeight = MediaQuery.of(context).size.height;
              final statusBarHeight = MediaQuery.of(context).padding.top;
              final bottomBarHeight = MediaQuery.of(context).padding.bottom;
              final targetBottomMargin = math.max(34.0, bottomBarHeight + 20.0);
              final awakeRingY = 1.0 - (targetBottomMargin * 2.0 / screenHeight);

              if (_isSleepingAnim) {
                final t = _sleepTransitionController.value.clamp(0.0, 1.0);
                final s = _smootherstep(t);
                ringY = awakeRingY * (1.0 - s);
                ringSize = _awakeSize + s * (_sleepSize - _awakeSize);
                ringStroke = 1.6 + s * 0.8;
                ringOpacity = 0.22 + s * 0.13;
                activeMorph = (1.0 - s) * _morphController.value;
              } else if (_isWakingUp) {
                final t = _swipeUpWakeController.value;
                if (t <= 0.40) {
                  final u = (t / 0.40).clamp(0.0, 1.0);
                  final s = _smootherstep(u);
                  ringY = -0.65 * s;
                  ringSize = _sleepSize - s * 14.0;
                  ringStroke = 2.4 - s * 0.4;
                  ringOpacity = 0.35 - s * 0.05;

                  final velocity = _smootherstepDerivative(u) * 0.65;
                  final stretch = (velocity * 0.05).clamp(0.0, 0.25);
                  scaleY = 1.0 + stretch;
                  scaleX = 1.0 / math.sqrt(scaleY);
                } else if (t <= 0.52) {
                  ringY = -0.65;
                  ringSize = _sleepSize - 14.0;
                  ringStroke = 2.0;
                  ringOpacity = 0.30;
                } else {
                  final u = ((t - 0.52) / 0.48).clamp(0.0, 1.0);
                  final s = _smootherstep(u);
                  ringY = -0.65 + s * (awakeRingY - (-0.65));
                  ringSize = (_sleepSize - 14.0) - s * ((_sleepSize - 14.0) - _awakeSize);
                  ringStroke = 2.0 - s * 0.4;
                  ringOpacity = 0.30 - s * 0.08;

                  final velocity = _smootherstepDerivative(u) * (awakeRingY - (-0.65));
                  final stretch = (velocity * 0.035).clamp(0.0, 0.22);
                  scaleY = 1.0 + stretch;
                  scaleX = 1.0 / math.sqrt(scaleY);
                }
              } else if (_isWakingDown) {
                final t = _swipeDownWakeController.value.clamp(0.0, 1.0);
                final s = _smootherstep(t);
                ringY = s * awakeRingY;
                ringSize = _sleepSize - s * (_sleepSize - _awakeSize);
                ringStroke = 2.4 - s * 0.8;
                ringOpacity = 0.35 - s * 0.13;

                final velocity = _smootherstepDerivative(t) * awakeRingY;
                final stretch = (velocity * 0.04).clamp(0.0, 0.18);
                scaleY = 1.0 + stretch;
                scaleX = 1.0 / math.sqrt(scaleY);
              } else if (_state == EditorState.awake) {
                ringY = awakeRingY;
                ringSize = _awakeSize;
                ringStroke = 1.6;
                ringOpacity = 0.22;
                activeMorph = _morphController.value;

                // Smoothly lift floating toolbar above keyboard when input is focused
                final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
                final tp = _toolbarMorphController.value;
                if (keyboardHeight > 0 && tp > 0.01) {
                  final targetKeyboardY = 1.0 - (keyboardHeight * 2.0 / screenHeight) - 0.06;
                  ringY = (1.0 - tp) * awakeRingY + tp * targetKeyboardY;
                }
              } else {
                ringY = 0.0;
                ringSize = _sleepSize;
                ringStroke = 2.4;
                ringOpacity = 0.35;
              }

              return Stack(
                children: [
                  // --- Left Overscroll Vertical Typographic Reveal (Oldest Note edge) ---
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Opacity(
                        opacity: contentOpacity,
                        child: RotatedBox(
                          quarterTurns: 3, // 270 degrees rotated along vertical spine
                          child: Text(
                            leftOverscrollText,
                            style: const TextStyle(
                              fontFamily: AppFonts.sfProDisplay,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: Color(0xFF38383B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- Right Overscroll Vertical Typographic Reveal (End of notes / settings edge) ---
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Opacity(
                        opacity: contentOpacity,
                        child: const RotatedBox(
                          quarterTurns: 3, // 270 degrees rotated along vertical spine
                          child: Text(
                            "the edge of thoughts",
                            style: TextStyle(
                              fontFamily: AppFonts.sfProDisplay,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: Color(0xFF38383B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // --- Swipeable Pages (Notes + New Editor + Settings) ---
                  Positioned.fill(
                    child: Opacity(
                      opacity: contentOpacity,
                      child: IgnorePointer(
                        ignoring: contentOpacity < 0.6,
                        child: staticPageView,
                      ),
                    ),
                  ),

                  // --- Universal Glowing Ring & Morphing Page Indicator / Toolbar Dock ---
                  Align(
                    alignment: Alignment(0, ringY),
                    child: (isRestingAwake || (_isSleepingAnim && activeMorph > 0.01))
                        ? ListenableBuilder(
                            listenable: Listenable.merge([
                              NotesService.instance.activeEditorFontNotifier,
                              NotesService.instance.activeBackgroundColorNotifier,
                            ]),
                            builder: (context, _) {
                              return NullBottomDock(
                                morphProgress: activeMorph,
                                toolbarProgress: _toolbarMorphController.value,
                                currentPage: _currentPage,
                                pageCount: totalPages,
                                baseSize: ringSize,
                                strokeWidth: ringStroke,
                                glowOpacity: ringOpacity,
                                activeFontFamily: NotesService.instance.activeEditorFontNotifier.value,
                                activeBackgroundColor: NotesService.instance.activeBackgroundColorNotifier.value,
                                onPageSelected: (index) {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOutCubic,
                                  );
                                },
                                onTap: _triggerAwakeCircleTap,
                                onUndo: () => NotesService.instance.onUndo?.call(),
                                onRedo: () => NotesService.instance.onRedo?.call(),
                                onFontTap: () => NotesService.instance.onCycleFont?.call(),
                                onSizeTap: () => NotesService.instance.onCycleFontSize?.call(),
                                onBackgroundTap: () => NotesService.instance.onCycleBackground?.call(),
                                onDismissKeyboard: () => NotesService.instance.onDismissKeyboard?.call(),
                              );
                            },
                          )
                        : Transform.scale(
                            scaleX: scaleX,
                            scaleY: scaleY,
                            child: SizedBox(
                              width: ringSize,
                              height: ringSize,
                              child: NullGlowingRing(
                                size: ringSize,
                                strokeWidth: ringStroke,
                                glowOpacity: ringOpacity,
                                onTap: () {
                                  if (_state == EditorState.sleep &&
                                      !_isWakingUp &&
                                      !_isWakingDown &&
                                      !_isSleepingAnim) {
                                    _triggerSwipeDown();
                                  } else if (_state == EditorState.awake &&
                                      !_isSleepingAnim) {
                                    _triggerAwakeCircleTap();
                                  }
                                },
                              ),
                            ),
                          ),
                  ),

                  // --- Top-Left Back Button (Smoothly appears/disappears on focus) ---
                  if (_toolbarMorphController.value > 0.01)
                    Positioned(
                      top: 16 + statusBarHeight,
                      left: 24,
                      child: Opacity(
                        opacity: _toolbarMorphController.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(-18.0 * (1.0 - _toolbarMorphController.value), 0),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              NotesService.instance.onDismissKeyboard?.call();
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF141416).withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                color: Color(0xFFEDEDED),
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // --- Top-Right Share / Export Studio Button (Smoothly appears/disappears on focus) ---
                  if (_toolbarMorphController.value > 0.01)
                    Positioned(
                      top: 16 + statusBarHeight,
                      right: 24,
                      child: Opacity(
                        opacity: _toolbarMorphController.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(18.0 * (1.0 - _toolbarMorphController.value), 0),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _openExportStudio();
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF141416).withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.ios_share_rounded,
                                color: Color(0xFFEDEDED),
                                size: 19,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
}
