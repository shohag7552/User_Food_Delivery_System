import 'dart:math' as math;

import 'package:appwrite_user_app/app/common/widgets/rive_artwork.dart';
import 'package:appwrite_user_app/app/helper/rive_assets.dart';
import 'package:appwrite_user_app/app/resources/colors.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rive/rive.dart' show Fit;

/// Shown whenever the app has no usable connection.
///
/// Everything sits in the upper part of the screen — artwork, then the two
/// lines worth reading, then the one button worth pressing — with the slack
/// left underneath. A dead-end screen that spreads its content to the far
/// corners makes the eye travel for no reason; keeping it together at the top
/// means it is read in one glance.
///
/// The fish is the only thing here a person can act on, so it leads.
class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isReloading;

  const NoInternetScreen({
    super.key,
    required this.onRetry,
    this.isReloading = false,
  });

  /// Text column width on tablet and desktop. Without it the copy and the
  /// button run the full width of a browser window.
  static const double _maxContentWidth = 460;

  /// Share of the viewport the tank claims, and the bounds it stays inside.
  ///
  /// Height-driven rather than aspect-driven: a 16:9 box sized off a phone's
  /// width is only ~210px tall, which reads as a banner rather than a window
  /// you are looking through. Filling half the screen and cropping the scene
  /// horizontally is what makes it feel like an aquarium.
  static const double _stageHeightFactor = 0.52;
  static const double _minStageHeight = 200;
  static const double _maxStageHeight = 480;

  /// Vertical room the copy and the button need. The tank gives way to it on a
  /// short window so the retry button stays reachable without scrolling.
  static const double _actionsReserve = 260;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.scaffoldBackground,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Scrollable so a short window (desktop split-screen, landscape
            // phone) can still reach the retry button instead of overflowing.
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                // Centred now that the tank claims half the viewport: the
                // block is tall enough that the leftover space reads better
                // split above and below it than all pooled underneath.
                child: Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Outside the padded column on purpose: the tank runs to
                      // the screen edges on a phone, which is what makes it
                      // read as a window rather than a picture of one.
                      _buildStage(constraints),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Constants.paddingSizeLarge,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _maxContentWidth,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (RiveAssets.isAvailable) ...[
                                const SizedBox(
                                  height: Constants.paddingSizeDefault,
                                ),
                                _buildHint(context),
                              ],
                              const SizedBox(height: Constants.paddingSizeLarge),
                              _buildCopy(context),
                              const SizedBox(height: Constants.paddingSizeLarge),
                              _buildRetryButton(),
                              // The slack lives here, below everything, rather
                              // than being shared out between the blocks above.
                              const SizedBox(height: Constants.paddingSizeLarge),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The tank. Full-bleed width, half the viewport tall, and every pointer
  /// inside it goes to the aquarium's own listeners.
  ///
  /// `Fit.cover` fills the box completely, so the scene is zoomed in and
  /// cropped at the sides rather than letterboxed. That also means there is no
  /// dead margin inside the tank where a tap would land on nothing.
  Widget _buildStage(BoxConstraints constraints) {
    final preferred = (constraints.maxHeight * _stageHeightFactor).clamp(
      _minStageHeight,
      _maxStageHeight,
    );
    final roomLeft = math.max(
      constraints.maxHeight - _actionsReserve,
      _minStageHeight,
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(Constants.radiusExtraLarge),
      ),
      child: SizedBox(
        width: constraints.maxWidth,
        height: math.min(preferred, roomLeft),
        child: RiveArtwork(
          asset: RiveAssets.interactiveAquarium,
          fit: Fit.cover,
          // The whole point of the screen: tap the water, feed the fish.
          isInteractive: true,
          fallback: _buildFallbackArtwork(),
        ),
      ),
    );
  }

  /// What the stage shows when Rive is unavailable — a real possibility here of
  /// all places, since on web the runtime is fetched over the very network that
  /// just went away.
  Widget _buildFallbackArtwork() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ColorResource.primaryDark.withValues(alpha: 0.06),
      ),
      child: const Center(
        child: Icon(
          Icons.wifi_off_rounded,
          size: 64,
          color: ColorResource.primaryDark,
        ),
      ),
    );
  }

  /// Caption for the artwork, offered only when there is something to interact
  /// with — inviting a tap on a static icon would be a lie.
  Widget _buildHint(BuildContext context) {
    return Text(
      'tap_the_water_to_feed_the_fish'.tr,
      textAlign: TextAlign.center,
      style: poppinsRegular.copyWith(
        fontSize: Constants.fontSizeSmall,
        color: context.textLight,
      ),
    );
  }

  Widget _buildCopy(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'no_internet_title'.tr,
          textAlign: TextAlign.center,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeExtraLarge,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: Constants.paddingSizeExtraSmall),
        Text(
          isReloading
              ? 'reconnecting_data'.tr
              : 'we_will_reconnect_automatically'.tr,
          textAlign: TextAlign.center,
          style: poppinsRegular.copyWith(
            fontSize: Constants.fontSizeSmall,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRetryButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isReloading ? null : onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorResource.primaryDark,
          foregroundColor: ColorResource.textWhite,
          disabledBackgroundColor: ColorResource.primaryDark.withValues(
            alpha: 0.5,
          ),
          disabledForegroundColor: ColorResource.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.radiusLarge),
          ),
          elevation: 0,
        ),
        icon: isReloading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: ColorResource.textWhite,
                ),
              )
            : const Icon(Icons.refresh_rounded, size: 20),
        label: Text(
          isReloading ? 'reconnecting'.tr : 'check_connection'.tr,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: ColorResource.textWhite,
          ),
        ),
      ),
    );
  }
}
