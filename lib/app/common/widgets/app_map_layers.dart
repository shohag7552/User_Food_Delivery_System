import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:appwrite_user_app/app/resources/text_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

/// The tile layer every map in the app uses, so the provider is configured in
/// one place ([Constants.mapTileUrl]).
class AppTileLayer extends StatelessWidget {
  const AppTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: Constants.mapTileUrl,
      // Identifies the app to the tile server — OpenStreetMap's usage policy
      // blocks requests without it.
      userAgentPackageName: Constants.packageName,
      maxNativeZoom: Constants.mapMaxNativeZoom,
    );
  }
}

/// Licence credit for the map data ([Constants.mapAttribution]); tapping it
/// opens the provider's copyright page. Must stay visible on every map.
///
/// Map tiles are always light, so the chip is deliberately light in both
/// themes (same as the other chips drawn over the map).
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(Constants.radiusSmall),
      child: InkWell(
        borderRadius: BorderRadius.circular(Constants.radiusSmall),
        onTap: () => launchUrl(
          Uri.parse(Constants.mapAttributionUrl),
          mode: LaunchMode.externalApplication,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Constants.paddingSizeExtraSmall,
            vertical: Constants.paddingSizeExtraSmall / 2,
          ),
          child: Text(
            Constants.mapAttribution,
            style: poppinsRegular.copyWith(
              fontSize: Constants.fontSizeExtraSmall,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
