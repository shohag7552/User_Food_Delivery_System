import 'dart:async';
import 'dart:developer';

import 'package:rive/rive.dart';

/// Loads and caches the app's Rive files, and records whether the Rive runtime
/// came up at all.
///
/// `rive` 0.14 runs on `rive_native`, a platform binary rather than pure Dart,
/// so initialising it can legitimately fail — an unsupported platform, a web
/// build that could not fetch the runtime. [isAvailable] is what every Rive
/// widget checks before trying to render, so a failure downgrades to the plain
/// Flutter fallback instead of taking a screen down with it.
///
/// Files are cached for the life of the app and never disposed: they are a few
/// KB each, several widgets build controllers from the same file, and a
/// disposed file would break every later open of the sheet that uses it.
class RiveAssets {
  RiveAssets._();

  /// Five stars driven by one number input; see [RiveRatingStars].
  static const String ratingAnimation =
      'assets/animations/rating_animation.riv';

  /// An interactive aquarium, shown while the app is offline.
  ///
  /// Its main artboard is 1920x1080 and carries `cursorTracker` / `hitbox` /
  /// `mouse` listeners, so it needs pointer events. Motion comes from view
  /// models (`VMMain`, `VMFish`, `VMFood`) rather than state-machine inputs,
  /// which is why it must be rendered with auto-binding on.
  static const String interactiveAquarium =
      'assets/animations/interactive-aquarium.riv';

  /// Everything warmed at startup. Both files are a few KB, and both appear on
  /// screens that must not wait on a disk read to draw.
  static const List<String> _warmupAssets = [
    ratingAnimation,
    interactiveAquarium,
  ];

  static bool _isAvailable = false;

  /// Whether the Rive runtime initialised successfully on this platform.
  static bool get isAvailable => _isAvailable;

  static final Map<String, File> _files = {};

  /// How long app start will wait for the runtime before giving up on it.
  ///
  /// On web `RiveNative.init()` appends a <script> that pulls the runtime from
  /// a CDN and awaits its load event — with no error listener, so an offline or
  /// blocked fetch never completes rather than failing. Since this runs inside
  /// `Global.init()`, an unbounded wait there is an app that never boots.
  static const Duration _bootTimeout = Duration(seconds: 5);

  /// Boots the runtime and warms every file the app uses.
  ///
  /// Called once from `Global.init()`. Preloading matters: the sheets open
  /// instantly, and loading on first build would show the fallback stars for a
  /// frame and then swap them for the animation mid-interaction.
  static Future<void> init() async {
    final Future<bool> boot;
    try {
      boot = RiveNative.init();
    } catch (e) {
      log('Rive runtime failed to initialise: $e');
      return;
    }

    final booted = await boot
        .timeout(_bootTimeout, onTimeout: () => false)
        .catchError((Object e) {
          log('Rive runtime failed to initialise: $e');
          return false;
        });

    if (booted) {
      _isAvailable = true;
      await _warmup();
      return;
    }

    log('Rive runtime not ready — animated widgets will use fallbacks.');

    // It may be slow rather than broken. Keep listening so a sheet opened later
    // in the session still gets the animation; anything built before then has
    // already fallen back, which is the correct behaviour either way.
    unawaited(_adoptLateBoot(boot));
  }

  static Future<void> _adoptLateBoot(Future<bool> boot) async {
    try {
      if (!await boot) return;
      _isAvailable = true;
      await _warmup();
    } catch (_) {
      // Already reported above; nothing further to do.
    }
  }

  static Future<void> _warmup() async {
    for (final asset in _warmupAssets) {
      await preload(asset);
    }
  }

  /// The cached file, or null if it has not been loaded (or failed to load).
  /// Synchronous so a widget can build its controller in `initState` without a
  /// frame of placeholder.
  static File? fileOrNull(String key) => _files[key];

  /// Loads [key] into the cache, returning the cached copy if it is already
  /// there. Never throws — a failure returns null and the caller falls back.
  static Future<File?> preload(String key) async {
    if (!_isAvailable) return null;

    final cached = _files[key];
    if (cached != null) return cached;

    try {
      // Factory.flutter renders through Skia/Impeller rather than Rive's own
      // renderer. This file is plain vector shapes, so it needs nothing the
      // Rive renderer adds — and on web every Factory.rive widget holds a live
      // WebGL context, which browsers cap.
      final file = await File.asset(key, riveFactory: Factory.flutter);
      if (file == null) {
        log('Rive file could not be decoded: $key');
        return null;
      }
      _files[key] = file;
      return file;
    } catch (e) {
      log('Rive file failed to load ($key): $e');
      return null;
    }
  }
}
