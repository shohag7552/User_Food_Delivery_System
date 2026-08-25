import 'dart:math' as math;

import 'package:appwrite_user_app/app/common/widgets/rating_stars.dart';
import 'package:appwrite_user_app/app/helper/rive_assets.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// The five-star rating control used in the review sheets, drawn by Rive.
///
/// A drop-in replacement for [InteractiveRatingStars] — same `rating` /
/// `onRatingChanged` contract — which it also falls back to whenever the Rive
/// runtime or the file is unavailable. The sheets ship today; an animation that
/// cannot load must cost polish, not the ability to leave a review.
///
/// The artwork has no pointer listeners of its own: it is a display animation
/// driven by a single number input, so every tap and drag is handled here in
/// Flutter and pushed into the state machine.
class RiveRatingStars extends StatefulWidget {
  const RiveRatingStars({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.maxWidth = 300,
  });

  /// Current score, 0 (nothing chosen) to [_starCount].
  final int rating;

  final ValueChanged<int> onRatingChanged;

  /// Upper bound on the drawn width. The stars scale with the widget, so
  /// without a cap a wide sheet on tablet or web would render them enormous.
  final double maxWidth;

  @override
  State<RiveRatingStars> createState() => _RiveRatingStarsState();
}

class _RiveRatingStarsState extends State<RiveRatingStars> {
  static const String _stateMachine = 'State Machine 1';
  static const String _ratingInput = 'rating';
  static const int _starCount = 5;

  /// Fallback aspect ratio, used only if the artboard reports nothing usable.
  static const double _fallbackAspect = 214 / 60;

  RiveWidgetController? _controller;

  bool get _isReady => _controller != null;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant RiveRatingStars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      _pushRating(widget.rating);
    }
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

    final cached = RiveAssets.fileOrNull(RiveAssets.ratingAnimation);
    if (cached != null) {
      _createController(cached);
      return;
    }

    // Not warmed yet (a failed preload, or a hot reload). Load it now and swap
    // the fallback out when it arrives.
    RiveAssets.preload(RiveAssets.ratingAnimation).then((file) {
      if (!mounted || file == null) return;
      setState(() => _createController(file));
    });
  }

  void _createController(File file) {
    try {
      final controller = RiveWidgetController(
        file,
        stateMachineSelector: StateMachineSelector.byName(_stateMachine),
      );
      _controller = controller;
      _pushRating(widget.rating);
    } catch (_) {
      // A renamed artboard or state machine in a re-exported file lands here.
      // Falling back is the right answer: the sheet still works.
      _controller = null;
    }
  }

  void _pushRating(int rating) {
    // Rive marks state-machine inputs deprecated in favour of data binding,
    // but this artwork exposes no view model — the number input is the only
    // handle it gives us.
    // ignore: deprecated_member_use
    _controller?.stateMachine.number(_ratingInput)?.value = rating.toDouble();
  }

  /// Aspect ratio of the loaded artboard.
  ///
  /// Read from the file rather than hardcoded: the artwork has already been
  /// re-exported once (500x500 down to a 214x60 crop of just the star row),
  /// and a constant here would have silently mis-placed every tap target.
  double get _aspectRatio {
    final bounds = _controller?.artboard.bounds;
    if (bounds == null || bounds.width <= 0 || bounds.height <= 0) {
      return _fallbackAspect;
    }
    return bounds.width / bounds.height;
  }

  /// Which star a touch at [dx] falls on, in a control [width] wide.
  ///
  /// The artboard is cropped tight to the star row, so the five stars divide
  /// its width evenly and the hit test is a straight division.
  int _ratingForOffset(double dx, double width) {
    final index = (dx / (width / _starCount)).floor() + 1;
    return index.clamp(1, _starCount);
  }

  void _selectAt(double dx, double width) {
    final rating = _ratingForOffset(dx, width);
    if (rating != widget.rating) {
      widget.onRatingChanged(rating);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return InteractiveRatingStars(
        rating: widget.rating,
        onRatingChanged: widget.onRatingChanged,
        size: 42,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : widget.maxWidth,
          widget.maxWidth,
        );
        final height = width / _aspectRatio;

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  // Pointers are ignored here: the artwork has no listeners of
                  // its own, so every hit belongs to the layer above.
                  child: IgnorePointer(
                    child: RiveWidget(
                      controller: _controller!,
                      fit: Fit.contain,
                      hitTestBehavior: RiveHitTestBehavior.none,
                    ),
                  ),
                ),
                Positioned.fill(child: _buildTouchLayer(width)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tap targets over the drawn stars, plus drag-to-scrub across them.
  ///
  /// The per-star zones are separate widgets rather than one big hit area so
  /// each keeps its own [Semantics] node — replacing five tappable icons with a
  /// single canvas would otherwise erase the control from the accessibility
  /// tree entirely.
  Widget _buildTouchLayer(double width) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Scrubbing is the reason an animated rating feels better than five
      // buttons: the stars light up as the finger crosses them.
      onHorizontalDragStart: (details) =>
          _selectAt(details.localPosition.dx, width),
      onHorizontalDragUpdate: (details) =>
          _selectAt(details.localPosition.dx, width),
      child: Row(
        children: List.generate(_starCount, (index) {
          final star = index + 1;
          return Expanded(
            child: Semantics(
              button: true,
              selected: widget.rating >= star,
              label: '$star',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onRatingChanged(star),
                child: const SizedBox.expand(),
              ),
            ),
          );
        }),
      ),
    );
  }
}
