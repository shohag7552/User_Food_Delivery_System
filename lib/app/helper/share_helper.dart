import 'package:appwrite_user_app/app/common/widgets/custom_toster.dart';
import 'package:appwrite_user_app/app/helper/localization_extension_helper.dart';
import 'package:appwrite_user_app/app/helper/price_helper.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/resources/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

/// Hands a product out to whatever the platform uses for sharing.
///
/// The link points at the deployed web build rather than at a custom scheme:
/// a shared link has to open for the person receiving it, and most of them will
/// not have the app installed. `usePathUrlStrategy()` in `main.dart` keeps the
/// URL clean (`/product/<id>`, no `/#/`), and the same path is claimed by the
/// Android App Link / iOS Universal Link, so it opens the app where it *is*
/// installed and the browser everywhere else.
class ShareHelper {
  ShareHelper._();

  /// Public URL of one product page.
  static Uri productUrl(String productId) =>
      Uri.parse('${Constants.webBaseUrl}/product/$productId');

  /// Opens the share sheet for [product].
  ///
  /// Falls back to copying the link whenever sharing is unavailable — the
  /// desktop-web path when the browser has no Web Share API, and any platform
  /// where the sheet fails to open. A share button that silently does nothing
  /// is worse than one that quietly copies.
  ///
  /// [context] should belong to the widget that triggered the share: iPadOS
  /// anchors its share popover to a rect, and passing none makes UIKit throw.
  static Future<void> shareProduct(
    BuildContext context,
    ProductModel product,
  ) async {
    final url = productUrl(product.id);
    final name = product.nameMap.trLanguage;

    // Name, price, then the link on its own line — messaging apps that unfurl
    // links read the last URL in the body, and the price is the part that makes
    // the message worth opening.
    final message =
        '$name\n${PriceHelper.formatPrice(product.finalPrice)}\n\n$url';

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: name,
          sharePositionOrigin: _originOf(context),
        ),
      );

      if (result.status == ShareResultStatus.unavailable) {
        await _copyLink(url);
      }
    } catch (_) {
      await _copyLink(url);
    }
  }

  /// The triggering widget's rect in global coordinates, or null if it has not
  /// been laid out.
  static Rect? _originOf(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static Future<void> _copyLink(Uri url) async {
    await Clipboard.setData(ClipboardData(text: url.toString()));
    customToster('link_copied'.tr, isSuccess: true);
  }
}
