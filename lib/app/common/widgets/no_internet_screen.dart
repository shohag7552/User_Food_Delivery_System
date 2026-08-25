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
/// The verdict goes to the top and everything actionable to the bottom, with
/// the aquarium filling the space between them: what is wrong is read once, and
/// the two things a person might do about it — wait, or retry — sit under the
/// thumb.
///
/// Two layouts, because one cannot serve both:
///
/// * **Phone / tablet** — the aquarium *is* the screen, and the copy sits over
///   it on scrims. There is nothing else to do on this page, so handing the
///   whole display to the one thing that answers a touch is the point of it.
/// * **Desktop web** — the same scene stretched across a 1600px window would be
///   absurd, and text floating over a browser-wide animation is hard to read.
///   There it becomes a contained hero with the copy above and below it.
class NoInternetScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isReloading;

  const NoInternetScreen({
    super.key,
    required this.onRetry,
    this.isReloading = false,
  });

  /// Matches `WebTopNav.isEnabled` and the order pages, so the app changes to
  /// its desktop shape at one width rather than a different one per screen.
  static const double _wideBreakpoint = 900;

  /// Desktop only: the hero's bounds, and the column the copy reads in.
  static const double _stageWidth = 720;
  static const double _maxStageHeight = 420;
  static const double _minStageHeight = 240;
  static const double _maxContentWidth = 460;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.scaffoldBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth >= _wideBreakpoint
              ? _buildWideLayout(context, constraints)
              : _buildImmersiveLayout(context);
        },
      ),
    );
  }

  // ── Phone / tablet: the aquarium takes the whole screen ──────────────────

  Widget _buildImmersiveLayout(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Edge to edge, behind the status bar and the home indicator alike.
        // `cover` crops the wide scene to the middle of the phone rather than
        // letterboxing it, which is what makes it read as a window.
        RiveArtwork(
          asset: RiveAssets.interactiveAquarium,
          fit: Fit.cover,
          isInteractive: true,
          fallback: _buildFallbackArtwork(),
        ),
        // Both scrims and all the text are painted boxes, not gesture targets,
        // so a touch that lands between them falls straight through to the
        // aquarium underneath. Only the button actually consumes one, which
        // leaves nearly the whole screen usable for feeding fish.
        Align(alignment: Alignment.topCenter, child: _buildTopBar(context)),
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildBottomBar(context),
        ),
      ],
    );
  }

  /// The verdict, at the top, on a scrim that fades downward into the water.
  Widget _buildTopBar(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xB3000000), Color(0x00000000)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Constants.paddingSizeLarge,
            Constants.paddingSizeDefault,
            Constants.paddingSizeLarge,
            Constants.paddingSizeExtraLarge * 2,
          ),
          child: _buildTitle(context, onScrim: true),
        ),
      ),
    );
  }

  /// What to do about it, at the bottom, under the thumb.
  Widget _buildBottomBar(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Fades in slowly, so the water still shows through the top of it
          // and the copy still has something solid to sit on.
          colors: [Color(0x00000000), Color(0x99000000), Color(0xD9000000)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Constants.paddingSizeLarge,
            Constants.paddingSizeExtraLarge * 2,
            Constants.paddingSizeLarge,
            Constants.paddingSizeLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (RiveAssets.isAvailable) ...[
                _buildHint(context, onScrim: true),
                const SizedBox(height: Constants.paddingSizeSmall),
              ],
              _buildSubtitle(context, onScrim: true),
              const SizedBox(height: Constants.paddingSizeLarge),
              _buildRetryButton(onScrim: true),
            ],
          ),
        ),
      ),
    );
  }

  // ── Desktop web: a contained hero with the copy around it ────────────────

  Widget _buildWideLayout(BuildContext context, BoxConstraints constraints) {
    final stageHeight = math.max(
      math.min(constraints.maxHeight * 0.45, _maxStageHeight),
      _minStageHeight,
    );

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.paddingSizeLarge,
              vertical: Constants.paddingSizeExtraLarge,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Same reading order as the phone: verdict, scene, then the
                // things to do about it.
                _buildTitle(context, onScrim: false),
                const SizedBox(height: Constants.paddingSizeLarge),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Constants.radiusExtraLarge,
                  ),
                  child: SizedBox(
                    width: _stageWidth,
                    height: stageHeight,
                    child: RiveArtwork(
                      asset: RiveAssets.interactiveAquarium,
                      fit: Fit.cover,
                      isInteractive: true,
                      fallback: _buildFallbackArtwork(),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _maxContentWidth,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (RiveAssets.isAvailable) ...[
                        const SizedBox(height: Constants.paddingSizeDefault),
                        _buildHint(context, onScrim: false),
                      ],
                      const SizedBox(height: Constants.paddingSizeSmall),
                      _buildSubtitle(context, onScrim: false),
                      const SizedBox(height: Constants.paddingSizeLarge),
                      _buildRetryButton(onScrim: false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared pieces ────────────────────────────────────────────────────────
  //
  // `onScrim` switches every one of these to a white-on-dark palette. Over the
  // artwork the theme's own colours are unusable: the scene looks the same in
  // light and dark mode, so anything that followed the theme would disappear
  // into the water in one of the two.

  Widget _buildTitle(BuildContext context, {required bool onScrim}) {
    return Text(
      'no_internet_title'.tr,
      textAlign: TextAlign.center,
      style: poppinsBold.copyWith(
        fontSize: Constants.fontSizeExtraLarge,
        color: onScrim ? ColorResource.textWhite : context.textPrimary,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, {required bool onScrim}) {
    return Text(
      isReloading
          ? 'reconnecting_data'.tr
          : 'we_will_reconnect_automatically'.tr,
      textAlign: TextAlign.center,
      style: poppinsRegular.copyWith(
        fontSize: Constants.fontSizeLarge,
        color: onScrim
            ? ColorResource.textWhite.withValues(alpha: 0.8)
            : context.textSecondary,
      ),
    );
  }

  /// Caption for the artwork, offered only when there is something to interact
  /// with — inviting a tap on a static icon would be a lie.
  Widget _buildHint(BuildContext context, {required bool onScrim}) {
    return Text(
      'tap_the_water_to_feed_the_fish'.tr,
      textAlign: TextAlign.center,
      style: poppinsMedium.copyWith(
        fontSize: Constants.fontSizeSmall,
        color: onScrim
            ? ColorResource.textWhite.withValues(alpha: 0.75)
            : context.textLight,
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

  /// A pill, in one shape on both layouts and two palettes.
  ///
  /// The brand's filled red sat badly on blue water and competed with the
  /// artwork for attention. Over the scrim the button instead borrows the white
  /// the copy already uses, which reads as one piece of overlay rather than a
  /// control dropped on top of a picture. The stadium shape distinguishes it
  /// from the app's ordinary rounded-rectangle buttons: this is the only thing
  /// on the screen worth pressing, so it should not look like a form field.
  Widget _buildRetryButton({required bool onScrim}) {
    final background = onScrim
        ? ColorResource.textWhite
        : ColorResource.primaryDark;
    final foreground = onScrim
        ? ColorResource.primaryDark
        : ColorResource.textWhite;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isReloading ? null : onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          // Dimmed rather than greyed: a grey pill on the scrim would read as
          // broken, where a faded one reads as busy.
          disabledBackgroundColor: background.withValues(alpha: 0.6),
          disabledForegroundColor: foreground,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        icon: isReloading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: foreground,
                ),
              )
            : const Icon(Icons.refresh_rounded, size: 20),
        label: Text(
          isReloading ? 'reconnecting'.tr : 'check_connection'.tr,
          style: poppinsBold.copyWith(
            fontSize: Constants.fontSizeDefault,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
