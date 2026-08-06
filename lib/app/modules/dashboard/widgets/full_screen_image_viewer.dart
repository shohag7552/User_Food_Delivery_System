import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full-screen photo viewer: swipe between images, pinch or double-tap to zoom,
/// tap to hide the chrome.
///
/// Deliberately dark in both themes — a photo viewer's job is to get out of the
/// way of the image, so the surround stays black and the chrome stays white
/// rather than following the app theme.
class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  /// Applied to the page at [initialIndex] only, so the flight matches the one
  /// thumbnail the user actually tapped.
  final String heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.heroTag,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  static const double _maxScale = 4;
  static const double _doubleTapScale = 2.5;

  /// How much one press of the zoom buttons moves the scale.
  static const double _zoomStep = 0.5;

  /// Anything above this counts as zoomed — guards against float drift leaving
  /// a "zoomed" state at an effective 1.0.
  static const double _zoomEpsilon = 1.01;

  static const double _thumbSize = 56;
  static const double _thumbStride = _thumbSize + Constants.paddingSizeSmall;

  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  final ScrollController _thumbController = ScrollController();

  /// One transform per page. Sharing a single controller would apply the
  /// current zoom to the neighbouring pages that a swipe reveals.
  final Map<int, TransformationController> _transformControllers = {};

  late int _currentIndex = widget.initialIndex;
  bool _isZoomed = false;
  double _currentScale = 1;
  bool _chromeVisible = true;

  /// Where the last double-tap landed, so zooming in centres on that point
  /// instead of the middle of the screen.
  Offset _doubleTapPosition = Offset.zero;

  bool get _hasMultiple => widget.images.length > 1;

  @override
  void initState() {
    super.initState();
    // Bring the opening image into view in the thumbnail strip.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncThumbnails());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _thumbController.dispose();
    for (final controller in _transformControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TransformationController _transformFor(int index) {
    return _transformControllers.putIfAbsent(index, () {
      final controller = TransformationController();
      controller.addListener(() => _onTransformChanged(index, controller));
      return controller;
    });
  }

  /// Single source of truth for the zoom readout and the pan/swipe gating —
  /// pinch, double-tap and the zoom buttons all land here through the
  /// controller, so none of them can drift out of sync with the UI.
  void _onTransformChanged(int index, TransformationController controller) {
    if (index != _currentIndex) return;
    final scale = controller.value.getMaxScaleOnAxis();
    final zoomed = scale > _zoomEpsilon;
    if (zoomed != _isZoomed || (scale - _currentScale).abs() > 0.005) {
      setState(() {
        _isZoomed = zoomed;
        _currentScale = scale;
      });
    }
  }

  void _onPageChanged(int index) {
    // Leaving a page resets its zoom, so coming back to it starts clean and the
    // swipe gesture is never blocked by a zoom the user has scrolled away from.
    _transformControllers[_currentIndex]?.value = Matrix4.identity();
    setState(() {
      _currentIndex = index;
      _isZoomed = false;
      _currentScale = 1;
    });
    _syncThumbnails();
  }

  /// Keeps the active thumbnail centred in the strip.
  void _syncThumbnails() {
    if (!_thumbController.hasClients || !_hasMultiple) return;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final target = (_currentIndex * _thumbStride) -
        (viewportWidth / 2) +
        (_thumbStride / 2);
    _thumbController.animateTo(
      target.clamp(0.0, _thumbController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _handleDoubleTap(int index) {
    final controller = _transformFor(index);

    if (controller.value.getMaxScaleOnAxis() > _zoomEpsilon) {
      controller.value = Matrix4.identity();
      return;
    }

    // Scale about the tapped point: a point p maps to s·p + t, so holding p
    // still means t = p·(1 − s).
    final dx = -_doubleTapPosition.dx * (_doubleTapScale - 1);
    final dy = -_doubleTapPosition.dy * (_doubleTapScale - 1);
    controller.value = Matrix4.identity()
      ..setEntry(0, 0, _doubleTapScale)
      ..setEntry(1, 1, _doubleTapScale)
      ..setEntry(0, 3, dx)
      ..setEntry(1, 3, dy);
  }

  void _zoomIn() => _zoomBy(_zoomStep);

  void _zoomOut() => _zoomBy(-_zoomStep);

  void _resetZoom() =>
      _transformFor(_currentIndex).value = Matrix4.identity();

  /// Steps the current page's zoom, keeping whatever is under the centre of
  /// the screen under the centre of the screen.
  ///
  /// The old viewer rebuilt the matrix with `Matrix4.diagonal3Values`, which
  /// scales about the top-left corner — pressing "+" pulled the photo down and
  /// to the right instead of magnifying what you were looking at.
  void _zoomBy(double delta) {
    final controller = _transformFor(_currentIndex);
    final matrix = controller.value;
    final scale = matrix.getMaxScaleOnAxis();
    final newScale = (scale + delta).clamp(1.0, _maxScale);
    if ((newScale - scale).abs() < 0.001) return;

    // At 1× the image fits exactly, so there is nothing to offset.
    if (newScale <= 1) {
      controller.value = Matrix4.identity();
      return;
    }

    final viewport = MediaQuery.sizeOf(context);
    final centre = Offset(viewport.width / 2, viewport.height / 2);
    final translation = matrix.getTranslation();

    // Scene point currently under the centre must stay under the centre:
    //   p = (c − t) / s   and   t' = c − s'·p
    double tx = centre.dx - newScale * (centre.dx - translation.x) / scale;
    double ty = centre.dy - newScale * (centre.dy - translation.y) / scale;

    // Programmatic matrices bypass InteractiveViewer's own boundary clamping,
    // so keep the scaled image covering the viewport — otherwise stepping the
    // zoom could leave black gutters the user cannot pan away.
    tx = tx.clamp(viewport.width * (1 - newScale), 0.0);
    ty = ty.clamp(viewport.height * (1 - newScale), 0.0);

    controller.value = Matrix4.identity()
      ..setEntry(0, 0, newScale)
      ..setEntry(1, 1, newScale)
      ..setEntry(0, 3, tx)
      ..setEntry(1, 3, ty);
  }

  void _toggleChrome() => setState(() => _chromeVisible = !_chromeVisible);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPages(),
          _buildTopBar(),
          _buildZoomControls(),
          if (_hasMultiple) _buildThumbnailStrip(),
        ],
      ),
    );
  }

  Widget _buildPages() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.images.length,
      onPageChanged: _onPageChanged,
      // While zoomed, the drag belongs to the image — otherwise panning across
      // a magnified photo would flip to the next one instead.
      physics: _isZoomed
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final image = CustomNetworkImage(
          image: widget.images[index],
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
        );

        return GestureDetector(
          onTap: _toggleChrome,
          onDoubleTapDown: (details) =>
              _doubleTapPosition = details.localPosition,
          onDoubleTap: () => _handleDoubleTap(index),
          child: InteractiveViewer(
            transformationController: _transformFor(index),
            minScale: 1,
            maxScale: _maxScale,
            // Panning is only enabled once there is something to pan. At 1×
            // the image already fits, so a drag has nowhere to go — leaving
            // pan on would let the viewer claim the horizontal drag and
            // swallow the page swipe.
            panEnabled: _isZoomed && index == _currentIndex,
            child: SizedBox.expand(
              child: index == widget.initialIndex
                  ? Hero(tag: widget.heroTag, child: image)
                  : image,
            ),
          ),
        );
      },
    );
  }

  /// Close button and the position counter, over a scrim so both stay legible
  /// on a bright photo. Fades out with the rest of the chrome.
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: _chrome(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Constants.paddingSizeSmall,
                Constants.paddingSizeSmall,
                Constants.paddingSizeDefault,
                Constants.paddingSizeLarge,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: ColorResource.textWhite,
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                  ),
                  const Spacer(),
                  if (_hasMultiple)
                    Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeDefault,
                        color: ColorResource.textWhite,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Thumbnail rail — turns "swipe and hope" into a visible set you can jump
  /// around in, which is the difference a multi-image viewer needs.
  Widget _buildThumbnailStrip() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: _chrome(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: _thumbSize + Constants.paddingSizeLarge,
              child: ListView.separated(
                controller: _thumbController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: Constants.paddingSizeDefault,
                  vertical: Constants.paddingSizeSmall,
                ),
                itemCount: widget.images.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: Constants.paddingSizeSmall),
                itemBuilder: (context, index) {
                  final selected = index == _currentIndex;
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _thumbSize,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(Constants.radiusDefault),
                        border: Border.all(
                          color: selected
                              ? ColorResource.textWhite
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Opacity(
                        opacity: selected ? 1 : 0.5,
                        child: CustomNetworkImage(
                          image: widget.images[index],
                          width: _thumbSize,
                          height: _thumbSize,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Zoom cluster: in / out around a live scale readout, with a reset that
  /// only appears once there is a zoom to undo.
  ///
  /// Anchored to the right edge and vertically centred, so it clears both the
  /// top bar and the thumbnail rail at any image count — the old viewer pinned
  /// its buttons to the bottom-right, where they would now sit on top of the
  /// thumbnails.
  Widget _buildZoomControls() {
    final canZoomIn = _currentScale < _maxScale - 0.001;
    final canZoomOut = _currentScale > 1.001;

    return Positioned.directional(
      textDirection: Directionality.of(context),
      end: Constants.paddingSizeSmall,
      top: 0,
      bottom: 0,
      child: _chrome(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius:
                      BorderRadius.circular(Constants.radiusExtraLarge),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ZoomButton(
                      icon: Icons.add_rounded,
                      onTap: canZoomIn ? _zoomIn : null,
                      tooltip: 'zoom_in'.tr,
                    ),
                    Text(
                      '${_currentScale.toStringAsFixed(1)}x',
                      style: poppinsMedium.copyWith(
                        fontSize: Constants.fontSizeExtraSmall,
                        color: ColorResource.textWhite,
                      ),
                    ),
                    _ZoomButton(
                      icon: Icons.remove_rounded,
                      onTap: canZoomOut ? _zoomOut : null,
                      tooltip: 'zoom_out'.tr,
                    ),
                  ],
                ),
              ),
              // Nothing to reset at 1×, so the button stays out of the way
              // until it means something.
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: canZoomOut
                    ? Padding(
                        padding: const EdgeInsets.only(
                          top: Constants.paddingSizeSmall,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: _ZoomButton(
                            icon: Icons.restart_alt_rounded,
                            onTap: _resetZoom,
                            tooltip: 'reset_zoom'.tr,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fades a chrome layer in and out, and stops it swallowing taps meant for
  /// the photo while hidden.
  Widget _chrome({required Widget child}) {
    return IgnorePointer(
      ignoring: !_chromeVisible,
      child: AnimatedOpacity(
        opacity: _chromeVisible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

/// A zoom-cluster button. A null [onTap] dims it in place rather than removing
/// it, so the cluster keeps its size as you reach either end of the range.
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: Constants.minTapTarget / 2,
        child: SizedBox.square(
          dimension: Constants.minTapTarget,
          child: Icon(
            icon,
            size: 20,
            color: ColorResource.textWhite.withValues(
              alpha: enabled ? 1 : 0.35,
            ),
          ),
        ),
      ),
    );
  }
}
