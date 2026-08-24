import 'dart:async';

import 'package:appwrite_user_app/app/common/widgets/web_top_nav.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:flutter/material.dart';

/// Overlays desktop-web hover-revealed scroll arrows on any carousel — the
/// same affordance as the ecommerce home's Top Products strip.
///
/// On mobile/tablet (or whenever [WebTopNav.isEnabled] is false) it renders
/// the bare [child]: no MouseRegion, no arrows, so touch layouts are
/// unaffected. The arrows are positioned overlays, so the stack keeps the
/// child's own size.
class HoverArrows extends StatefulWidget {
  final Widget child;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  /// Notified as the pointer enters and leaves the strip. Lets an owner react
  /// to hover — pausing an autoplay, say — without wrapping the whole thing in
  /// a second [MouseRegion]. Never fires off desktop web, where there is no
  /// [MouseRegion] to fire it.
  final ValueChanged<bool>? onHoverChanged;

  /// Whether the carousel actually has anything to scroll. Evaluated lazily
  /// on every build (hover triggers one), so implementations can inspect a
  /// laid-out ScrollController. When it returns false the arrows stay hidden —
  /// a strip whose items all fit needs no paging affordance.
  final bool Function()? canScroll;

  const HoverArrows({
    super.key,
    required this.child,
    required this.onLeft,
    required this.onRight,
    this.canScroll,
    this.onHoverChanged,
  });

  @override
  State<HoverArrows> createState() => _HoverArrowsState();
}

class _HoverArrowsState extends State<HoverArrows> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (!WebTopNav.isEnabled(context)) {
      return widget.child;
    }

    final bool showArrows = widget.canScroll?.call() ?? true;

    return MouseRegion(
      onEnter: (_) {
        if (_hovered) return;
        setState(() => _hovered = true);
        widget.onHoverChanged?.call(true);
      },
      onExit: (_) {
        if (!_hovered) return;
        setState(() => _hovered = false);
        widget.onHoverChanged?.call(false);
      },
      child: Stack(
        children: [
          widget.child,
          if (showArrows) ...[
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _animatedArrow(isLeft: true),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: _animatedArrow(isLeft: false),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Fades + slides the scroll arrow in while the strip is hovered, and out
  /// (non-interactive) otherwise.
  Widget _animatedArrow({required bool isLeft}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      opacity: _hovered ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        offset: _hovered ? Offset.zero : Offset(isLeft ? -0.4 : 0.4, 0),
        child: IgnorePointer(
          ignoring: !_hovered,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: context.cardBackground,
              shape: const CircleBorder(),
              elevation: 3,
              shadowColor: Colors.black.withValues(alpha: 0.2),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isLeft ? widget.onLeft : widget.onRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isLeft ? Icons.chevron_left : Icons.chevron_right,
                    color: ColorResource.primaryDark,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [HoverArrows] specialised for plain horizontal scrollables: owns the
/// [ScrollController], hands it to [builder] (wire it to the list), and pages
/// the list by [scrollDelta] per arrow tap.
///
/// ```dart
/// HoverArrowCarousel(
///   height: 250,
///   builder: (context, controller) => ListView.separated(
///     controller: controller,
///     scrollDirection: Axis.horizontal,
///     ...
///   ),
/// )
/// ```
///
/// Pass [itemExtent] and [autoScrollInterval] together to make the strip
/// advance on its own, one card at a time. See [autoScrollInterval] for the
/// rules that hold it back.
class HoverArrowCarousel extends StatefulWidget {
  final double height;
  final Widget Function(BuildContext context, ScrollController controller)
  builder;

  /// How far one arrow tap scrolls, in pixels.
  final double scrollDelta;

  /// The stride from one card to the next — card width *plus* the gap after
  /// it. Autoplay lands on multiples of this, which is what keeps cards
  /// aligned to the viewport edge instead of stopping half-cut.
  final double? itemExtent;

  /// How long each card rests before the strip steps to the next one. Null —
  /// the default — leaves the carousel entirely manual.
  ///
  /// **Pass null off desktop web.** Autoplay does not test the platform
  /// itself: the callers already know which shell they are in, and deciding it
  /// here would hide the rule from them and put [kIsWeb] between this logic
  /// and any test of it.
  ///
  /// Once on, it is deliberately easy to stop and hard to fight:
  ///
  ///  * never while the pointer is over the strip — a card being read is a
  ///    card about to be clicked;
  ///  * never for a while after the reader scrolls or pages it themselves;
  ///  * never while the page sits behind another route, or when the platform
  ///    asks for reduced motion;
  ///  * never when every card already fits, since there is nothing to reveal.
  final Duration? autoScrollInterval;

  const HoverArrowCarousel({
    super.key,
    required this.height,
    required this.builder,
    this.scrollDelta = 380,
    this.itemExtent,
    this.autoScrollInterval,
  });

  @override
  State<HoverArrowCarousel> createState() => _HoverArrowCarouselState();
}

class _HoverArrowCarouselState extends State<HoverArrowCarousel> {
  final ScrollController _controller = ScrollController();

  /// One step of autoplay. Long enough to read as a deliberate move rather
  /// than a jump, short enough not to feel like the page is loading.
  static const Duration _stepDuration = Duration(milliseconds: 450);

  /// The wrap back to the first card covers the whole strip, so its duration
  /// grows with the distance — capped, or a long strip would rewind as a blur.
  static const Duration _maxRewindDuration = Duration(milliseconds: 900);

  Timer? _autoScrollTimer;

  /// Cleared this long after the reader last moved the strip themselves.
  /// Scaled to the interval so a slow carousel waits proportionally longer.
  Timer? _interactionTimer;

  bool _hovered = false;
  bool _interacted = false;

  /// Both read from inherited widgets in [didChangeDependencies]: animations
  /// can be switched off platform-wide, and the ticker goes quiet whenever
  /// this page is covered by another route.
  bool _animationsEnabled = true;
  bool _tickerEnabled = true;

  bool get _autoScrollConfigured =>
      widget.autoScrollInterval != null && (widget.itemExtent ?? 0) > 0;

  /// Whether the timer should currently be running at all. Transient reasons
  /// to skip a single step (a fling still settling, a strip that all fits)
  /// live in [_step] instead, so they never tear the timer down.
  bool get _autoScrollActive =>
      _autoScrollConfigured &&
      _animationsEnabled &&
      _tickerEnabled &&
      !_hovered &&
      !_interacted;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animationsEnabled = !MediaQuery.disableAnimationsOf(context);
    _tickerEnabled = TickerMode.valuesOf(context).enabled;
    _syncAutoScroll();
  }

  @override
  void didUpdateWidget(covariant HoverArrowCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoScrollInterval != widget.autoScrollInterval ||
        oldWidget.itemExtent != widget.itemExtent) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
      _syncAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _interactionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Starts or stops the timer to match [_autoScrollActive].
  ///
  /// Stopping rather than letting a running timer skip its turn is the point:
  /// the reader gets a full interval to look at the card they stopped on,
  /// instead of the strip moving the instant their pointer leaves it.
  void _syncAutoScroll() {
    if (!_autoScrollActive) {
      _autoScrollTimer?.cancel();
      _autoScrollTimer = null;
      return;
    }
    _autoScrollTimer ??= Timer.periodic(widget.autoScrollInterval!, _step);
  }

  void _onHoverChanged(bool hovered) {
    if (_hovered == hovered) return;
    _hovered = hovered;
    _syncAutoScroll();
  }

  /// Hands the strip back to the reader for a few beats after they move it.
  void _pauseForInteraction() {
    _interacted = true;
    _syncAutoScroll();
    _interactionTimer?.cancel();
    _interactionTimer = Timer(widget.autoScrollInterval! * 2, () {
      if (!mounted) return;
      _interacted = false;
      _syncAutoScroll();
    });
  }

  void _step(Timer _) {
    if (!mounted || !_controller.hasClients) return;

    final maxExtent = _controller.position.maxScrollExtent;
    // Nothing to reveal — every card already fits.
    if (maxExtent <= 1) return;

    final stride = widget.itemExtent!;

    // Clamped, because a bouncing scrollable reports offsets past both ends
    // while it settles. Reading one of those raw would aim the next step at a
    // card that does not exist.
    final offset = _controller.offset.clamp(0.0, maxExtent);

    // At the end: wrap back to the first card rather than stalling there.
    if (offset >= maxExtent - 1) {
      _animateTo(0, duration: _rewindDuration(offset));
      return;
    }

    // Rounding off the current offset — not adding to it — is what re-aligns
    // the strip to the card grid after an arrow tap or a manual drag left it
    // part-way between two cards.
    final target = (((offset / stride).round() + 1) * stride).clamp(
      0.0,
      maxExtent,
    );
    _animateTo(target);
  }

  /// Long strips rewind for longer, up to [_maxRewindDuration].
  Duration _rewindDuration(double distance) {
    final scaled = Duration(milliseconds: (distance / 3).round());
    return scaled > _maxRewindDuration ? _maxRewindDuration : scaled;
  }

  void _animateTo(double target, {Duration duration = _stepDuration}) {
    _controller.animateTo(target, duration: duration, curve: Curves.easeInOut);
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    // Paging by hand is the reader taking over; autoplay stands down for a
    // while rather than fighting them for the strip.
    if (_autoScrollConfigured) _pauseForInteraction();
    final target = (_controller.offset + delta).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HoverArrows(
      onLeft: () => _scrollBy(-widget.scrollDelta),
      onRight: () => _scrollBy(widget.scrollDelta),
      // No arrows when every item already fits in the viewport.
      canScroll: () =>
          _controller.hasClients && _controller.position.maxScrollExtent > 1,
      onHoverChanged: _autoScrollConfigured ? _onHoverChanged : null,
      child: SizedBox(
        height: widget.height,
        child: _autoScrollConfigured
            ? NotificationListener<ScrollStartNotification>(
                // Only a drag counts as taking over. A wheel or trackpad
                // scroll needs the pointer on the strip, which hover has
                // already paused.
                onNotification: (notification) {
                  if (notification.dragDetails != null) _pauseForInteraction();
                  return false;
                },
                child: widget.builder(context, _controller),
              )
            : widget.builder(context, _controller),
      ),
    );
  }
}
