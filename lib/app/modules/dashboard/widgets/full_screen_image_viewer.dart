import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  final TransformationController _transformationController =
      TransformationController();

  double _currentScale = 1;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _setScale(double scale) {
    final clampedScale = scale.clamp(1.0, 4.0);
    _transformationController.value = Matrix4.diagonal3Values(
      clampedScale,
      clampedScale,
      1,
    );
    setState(() {
      _currentScale = clampedScale;
    });
  }

  void _zoomIn() => _setScale(_currentScale + 0.5);

  void _zoomOut() => _setScale(_currentScale - 0.5);

  void _resetZoom() => _setScale(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Hero(
                    tag: widget.heroTag,
                    child: CustomNetworkImage(
                      image: widget.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.45),
                ),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 24,
              child: Column(
                children: [
                  _ZoomButton(
                    icon: Icons.add,
                    onTap: _zoomIn,
                  ),
                  const SizedBox(height: 12),
                  _ZoomButton(
                    icon: Icons.remove,
                    onTap: _zoomOut,
                  ),
                  const SizedBox(height: 12),
                  _ZoomButton(
                    icon: Icons.refresh,
                    onTap: _resetZoom,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              bottom: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_currentScale.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    color: ColorResource.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(14),
      ),
      icon: Icon(icon),
    );
  }
}
