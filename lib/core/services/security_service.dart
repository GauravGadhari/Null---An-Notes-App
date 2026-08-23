import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import '../models/note.dart';
import 'notes_service.dart';

class SecurityService {
  static final SecurityService instance = SecurityService._();
  SecurityService._();

  final LocalAuthentication _auth = LocalAuthentication();
  late Box _securityBox;

  final ValueNotifier<bool> isBiometricsAvailableNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isAppLockEnabledNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isAppUnlockedNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<Set<String>> unlockedNoteIdsNotifier = ValueNotifier<Set<String>>({});

  bool get isBiometricsAvailable => isBiometricsAvailableNotifier.value;
  bool get isAppLockEnabled => isAppLockEnabledNotifier.value;
  bool get isAppUnlocked => isAppUnlockedNotifier.value;

  Future<void> init() async {
    _securityBox = await Hive.openBox('null_security');
    final available = await canCheckBiometrics();
    isBiometricsAvailableNotifier.value = available;

    final enabled = _securityBox.get('app_lock_enabled', defaultValue: false) as bool;
    isAppLockEnabledNotifier.value = enabled;

    // If master app lock is enabled and biometrics available, start locked until biometrics pass
    if (enabled && available) {
      isAppUnlockedNotifier.value = false;
    } else {
      isAppUnlockedNotifier.value = true;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({required String localizedReason}) async {
    try {
      final isSupported = await canCheckBiometrics();
      if (!isSupported) {
        // If device has no biometric or screen lock hardware, allow to prevent locking user out
        return true;
      }
      return await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setAppLockEnabled(bool enable) async {
    final reason = enable
        ? 'Authenticate with Biometrics to enable App Lock'
        : 'Authenticate with Biometrics to disable App Lock';

    final authenticated = await authenticate(localizedReason: reason);
    if (authenticated) {
      await _securityBox.put('app_lock_enabled', enable);
      isAppLockEnabledNotifier.value = enable;
      isAppUnlockedNotifier.value = true;
      HapticFeedback.mediumImpact();
      return true;
    } else {
      HapticFeedback.heavyImpact();
      return false;
    }
  }

  Future<bool> unlockApp() async {
    final authenticated = await authenticate(localizedReason: 'Authenticate to unlock Null');
    if (authenticated) {
      isAppUnlockedNotifier.value = true;
      HapticFeedback.lightImpact();
      return true;
    } else {
      HapticFeedback.heavyImpact();
      return false;
    }
  }

  void lockApp() {
    if (isAppLockEnabled && isBiometricsAvailable) {
      isAppUnlockedNotifier.value = false;
    }
    // Re-lock all individual notes on background/sleep
    unlockedNoteIdsNotifier.value = {};
  }

  void relockAllNotes() {
    if (unlockedNoteIdsNotifier.value.isNotEmpty) {
      unlockedNoteIdsNotifier.value = {};
    }
  }

  bool isNoteUnlocked(Note note) {
    if (!note.isLocked) return true;
    return unlockedNoteIdsNotifier.value.contains(note.id);
  }

  Future<bool> unlockNote(String noteId) async {
    final authenticated = await authenticate(localizedReason: 'Authenticate with Biometrics to view locked note');
    if (authenticated) {
      final updated = Set<String>.from(unlockedNoteIdsNotifier.value)..add(noteId);
      unlockedNoteIdsNotifier.value = updated;
      HapticFeedback.lightImpact();
      return true;
    } else {
      HapticFeedback.heavyImpact();
      return false;
    }
  }

  Future<bool> toggleNoteLock(int pageIndex, Note note) async {
    final willLock = !note.isLocked;
    final reason = willLock
        ? 'Authenticate with Biometrics to lock this note'
        : 'Authenticate with Biometrics to unlock this note';

    final authenticated = await authenticate(localizedReason: reason);
    if (authenticated) {
      note.isLocked = willLock;
      if (willLock) {
        // Keep unlocked for the immediate current session
        final updated = Set<String>.from(unlockedNoteIdsNotifier.value)..add(note.id);
        unlockedNoteIdsNotifier.value = updated;
      }
      NotesService.instance.updateNoteLock(pageIndex, willLock);
      HapticFeedback.mediumImpact();
      return true;
    } else {
      HapticFeedback.heavyImpact();
      return false;
    }
  }
}
