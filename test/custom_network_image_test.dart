import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The point of these tests is the one thing that is invisible at the call
/// site: whether the decoder is actually told how big to decode.
///
/// On web `CachedNetworkImage` computes `memCacheWidth` and then throws it away
/// — its `HtmlImage` loader takes only a URL and drops the `decode` callback
/// that `ResizeImage` resizes through. `Image.network` keeps that callback, so
/// the web branch exists to get the size all the way to the decoder. A
/// regression here is silent: images still render, just at full resolution.
void main() {
  const double dpr = 2.0;

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(400, 800),
  }) {
    return tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: dpr),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: SizedBox.fromSize(size: size, child: child)),
        ),
      ),
    );
  }

  /// The network image in the tree, ignoring the placeholder asset.
  Image networkImage(WidgetTester tester) => tester.widget<Image>(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is ResizeImage &&
              (w.image as ResizeImage).imageProvider is NetworkImage,
        ),
      );

  group('web path', () {
    testWidgets('decodes to the box width when the box is landscape',
        (tester) async {
      await pump(
        tester,
        const CustomNetworkImage(
          image: 'https://example.com/a.jpg',
          width: 200,
          height: 100,
          useWebPath: true,
        ),
      );

      final resize = networkImage(tester).image as ResizeImage;
      // Longer side wins, scaled by the device pixel ratio.
      expect(resize.width, (200 * dpr).round());
      // The other axis stays free — constraining both would decode to the
      // box's aspect ratio and leave BoxFit.cover nothing to crop.
      expect(resize.height, isNull);
    });

    testWidgets('decodes to the box height when the box is portrait',
        (tester) async {
      await pump(
        tester,
        const CustomNetworkImage(
          image: 'https://example.com/a.jpg',
          width: 100,
          height: 200,
          useWebPath: true,
        ),
      );

      final resize = networkImage(tester).image as ResizeImage;
      expect(resize.height, (200 * dpr).round());
      expect(resize.width, isNull);
    });

    testWidgets('falls back to layout constraints when no size is given',
        (tester) async {
      await pump(
        tester,
        const CustomNetworkImage(
          image: 'https://example.com/a.jpg',
          useWebPath: true,
        ),
        size: const Size(300, 150),
      );

      final resize = networkImage(tester).image as ResizeImage;
      expect(resize.width, (300 * dpr).round());
    });

    testWidgets('fit overrides the longer-side rule', (tester) async {
      await pump(
        tester,
        const CustomNetworkImage(
          image: 'https://example.com/a.jpg',
          width: 200,
          height: 100,
          fit: BoxFit.fitHeight,
          useWebPath: true,
        ),
      );

      final resize = networkImage(tester).image as ResizeImage;
      expect(resize.height, (100 * dpr).round());
      expect(resize.width, isNull);
    });

    testWidgets('renders the placeholder instead of requesting an empty URL',
        (tester) async {
      await pump(
        tester,
        const CustomNetworkImage(image: '   ', useWebPath: true),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is Image && w.image is NetworkImage,
        ),
        findsNothing,
      );
      expect(find.byType(Image), findsOneWidget); // the placeholder asset
    });
  });

  group('mobile path', () {
    testWidgets('still uses CachedNetworkImage with the same decode size',
        (tester) async {
      await pump(
        tester,
        const CustomNetworkImage(
          image: 'https://example.com/a.jpg',
          width: 200,
          height: 100,
          useWebPath: false,
        ),
      );

      final cached = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(cached.memCacheWidth, (200 * dpr).round());
      expect(cached.memCacheHeight, isNull);
    });
  });
}
