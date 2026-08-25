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
  // ── Artboard geometry, read out of rating_animation.riv ─────────────────
  //
  // The artboard is 500x500 with the star row centred: the `Stars` group sits
  // at x=250, and the five stars at -140/-70/0/+70/+140 from it. So the row
  // spans x=75..425 in artboard units, 70 units per star.
  //
  // These are what map a touch position to a star. They are constants rather
  // than guesses precisely because they came out of the file — if the artwork
  // is ever re-exported with different spacing, they are the four numbers to
  // re-check.
  static const String _stateMachine = 'State Machine 1';
  static const String _ratingInput = 'rating';
  static const int _starCount = 5;
  static const double _artboardWidth = 500;
  static const double _starPitch = 70;
  static const double _bandLeft = 75;

  /// How much of the square artboard's height to actually show. The stars sit
  /// on the vertical centre line and occupy a shallow band, so the rest is
  /// empty canvas — showing all 500 units of it would leave the control
  /// swimming in whitespace.
  static const double _heightRatio = 0.36;

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

  /// Which star a touch at [dx] falls on, in a control [width] wide.
  ///
  /// `Fit.fitWidth` maps the artboard's full width onto the widget's, so the
  /// conversion is a single scale factor.
  int _ratingForOffset(double dx, double width) {
    final artboardX = dx * _artboardWidth / width;
    final index = ((artboardX - _bandLeft) / _starPitch).floor() + 1;
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
          constraints.maxWidth.isFinite ? constraints.maxWidth : widget.maxWidth,
          widget.maxWidth,
        );
        final height = width * _heightRatio;

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  // Clipped because the box is a slice of a taller artboard,
                  // and ignoring pointers because the artwork has no listeners
                  // — every hit belongs to the layer above.
                  child: ClipRect(
                    child: IgnorePointer(
                      child: RiveWidget(
                        controller: _controller!,
                        fit: Fit.fitWidth,
                        hitTestBehavior: RiveHitTestBehavior.none,
                      ),
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
    final scale = width / _artboardWidth;
    final starWidth = _starPitch * scale;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Scrubbing is the reason an animated rating feels better than five
      // buttons: the stars light up as the finger crosses them.
      onHorizontalDragStart: (details) =>
          _selectAt(details.localPosition.dx, width),
      onHorizontalDragUpdate: (details) =>
          _selectAt(details.localPosition.dx, width),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _bandLeft * scale),
        child: Row(
          children: List.generate(_starCount, (index) {
            final star = index + 1;
            return SizedBox(
              width: starWidth,
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
      ),
    );
  }
}

