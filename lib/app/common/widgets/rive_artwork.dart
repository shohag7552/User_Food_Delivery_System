import 'dart:developer';

import 'package:appwrite_user_app/app/helper/rive_assets.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Renders a Rive file, falling back to a plain Flutter widget whenever the
/// runtime or the artwork is unavailable.
///
/// The fallback is not optional. `rive_native` is a platform binary, and on web
/// it fetches its runtime from a CDN — both can legitimately fail, and a screen
/// that has nothing to draw in that case is a screen that fails with it. That
/// matters most on the very screen this was written for: the offline screen,
/// which is by definition shown when the network is unreliable.
///
/// Use [RiveRatingStars] instead where a state-machine input has to be driven;
/// this widget is for artwork that plays itself.
class RiveArtwork extends StatefulWidget {
  const RiveArtwork({
    super.key,
    required this.asset,
    required this.fallback,
    this.stateMachine,
    this.fit = Fit.contain,
    this.alignment = Alignment.center,
    this.isInteractive = false,
    this.autoBind = true,
  });

  /// Asset key, e.g. [RiveAssets.interactiveAquarium].
  final String asset;

  /// Drawn whenever the artwork cannot be. Sized by the caller, so the layout
  /// around it does not shift when one is swapped for the other.
  final Widget fallback;

  /// Named state machine, or null for the artboard's default.
  final String? stateMachine;

  final Fit fit;

  /// Where the artboard sits when [fit] leaves spare room — `topCenter` to pin
  /// artwork to the top of its box rather than floating it in the middle.
  final Alignment alignment;

  /// Whether to bind the artboard's default view model instance.
  ///
  /// Artwork built with data binding — anything whose motion comes from view
  /// model properties rather than state-machine inputs — does nothing without
  /// it. Harmless on files that have no view models: the attempt is caught and
  /// the artwork still draws.
  final bool autoBind;

  /// Whether the artwork's own Rive listeners should receive pointer events.
  ///
  /// Off by default: most artwork is decoration, and a graphic that silently
  /// swallows touches is a bug that is hard to trace back to its cause.
  final bool isInteractive;

  @override
  State<RiveArtwork> createState() => _RiveArtworkState();
}

class _RiveArtworkState extends State<RiveArtwork> {
  RiveWidgetController? _controller;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void dispose() {
    // The controller is ours; the file belongs to the cache and is shared with
    // every other instance, so it is deliberately left alone.
    _controller?.dispose();
    super.dispose();
  }

  void _bind() {
    if (!RiveAssets.isAvailable) return;

    final cached = RiveAssets.fileOrNull(widget.asset);
    if (cached != null) {
      _createController(cached);
      return;
    }

    RiveAssets.preload(widget.asset).then((file) {
      if (!mounted || file == null) return;
      setState(() => _createController(file));
    });
  }

  void _createController(File file) {
    final RiveWidgetController controller;
    try {
      controller = RiveWidgetController(
        file,
        stateMachineSelector: widget.stateMachine == null
            ? const StateMachineDefault()
            : StateMachineSelector.byName(widget.stateMachine!),
      );
    } catch (e) {
      // A renamed artboard or state machine in a re-exported file lands here.
      log('Rive artwork could not be built (${widget.asset}): $e');
      _controller = null;
      return;
    }

    if (widget.autoBind) {
      try {
        controller.dataBind(DataBind.auto());
      } catch (e) {
        // The file has no exported default instance, or none at all. The scene
        // still draws — it just will not be driven — so this is worth a log but
        // not worth throwing the artwork away over.
        log('Rive artwork has no bindable view model (${widget.asset}): $e');
      }
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.fallback;

    return RiveWidget(
      controller: controller,
      fit: widget.fit,
      alignment: widget.alignment,
      // `translucent` lets the artwork's own hit areas respond while anything
      // it does not cover still reaches the widgets behind it.
      hitTestBehavior: widget.isInteractive
          ? RiveHitTestBehavior.translucent
          : RiveHitTestBehavior.none,
    );
  }
}
