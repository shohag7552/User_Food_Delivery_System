import 'package:appwrite_user_app/app/common/widgets/custom_network_image.dart';
import 'package:appwrite_user_app/app/controllers/brand_controller.dart';
import 'package:appwrite_user_app/app/controllers/cart_controller.dart';
import 'package:appwrite_user_app/app/models/product_model.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/domain/services/hover_gallery.dart';
import 'package:appwrite_user_app/app/modules/brands/domain/repository/brand_repo_interface.dart';
import 'package:appwrite_user_app/app/controllers/favorites_controller.dart';
import 'package:appwrite_user_app/app/modules/cart/domain/repository/cart_repo_interface.dart';
import 'package:appwrite_user_app/app/modules/favorites/domain/repository/favorites_repo_interface.dart';
import 'package:appwrite_user_app/app/modules/ecommerce/widgets/ecommerce_product_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeBrandRepo implements BrandRepoInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeCartRepo implements CartRepoInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeFavoritesRepo implements FavoritesRepoInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ProductModel _product({
  String cover = 'cover.jpg',
  List<String> gallery = const [],
}) => ProductModel(
  id: 'p1',
  nameMap: const {'en': 'Shoe'},
  descriptionMap: const {'en': ''},
  price: 100,
  imageId: cover,
  isVeg: false,
  isAvailable: true,
  stock: 10,
  categoryId: 'c1',
  avgRating: 0,
  ratingCount: 0,
  variants: const [],
  moduleType: 'ecommerce',
  imageGallery: gallery,
);

void main() {
  /// An empty result is the switch that keeps every existing card exactly as
  /// it is, so these are as much about what does *not* scrub as what does.
  group('hoverGalleryImages', () {
    test('is empty for a product with no gallery', () {
      expect(hoverGalleryImages(_product()), isEmpty);
    });

    test('is empty when the gallery holds only the cover', () {
      expect(
        hoverGalleryImages(_product(gallery: ['cover.jpg'])),
        isEmpty,
      );
    });

    test('keeps the store app\'s order, cover already first', () {
      expect(
        hoverGalleryImages(
          _product(gallery: ['cover.jpg', 'b.jpg', 'c.jpg']),
        ),
        ['cover.jpg', 'b.jpg', 'c.jpg'],
      );
    });

    test('puts the cover first on a legacy row that disagrees', () {
      // The card must rest on the same photo it would have shown anyway.
      expect(
        hoverGalleryImages(_product(gallery: ['b.jpg', 'c.jpg'])),
        ['cover.jpg', 'b.jpg', 'c.jpg'],
      );
    });

    test('never shows the cover twice', () {
      expect(
        hoverGalleryImages(
          _product(gallery: ['b.jpg', 'cover.jpg', 'c.jpg']),
        ),
        ['cover.jpg', 'b.jpg', 'c.jpg'],
      );
    });

    test('drops blank entries', () {
      expect(
        hoverGalleryImages(_product(gallery: ['cover.jpg', '  ', 'c.jpg'])),
        ['cover.jpg', 'c.jpg'],
      );
    });

    test('caps a long gallery', () {
      final long = List.generate(12, (i) => 'img$i.jpg');
      final images = hoverGalleryImages(
        _product(cover: 'img0.jpg', gallery: long),
      );
      expect(images, hasLength(kMaxHoverGalleryImages));
      expect(images.first, 'img0.jpg');
    });
  });

  group('hoverIndexFor', () {
    int index(double dx, {int count = 4, double width = 200}) =>
        hoverIndexFor(localDx: dx, width: width, count: count);

    test('splits the band into equal slices', () {
      // 200px / 4 images = one image per 50px.
      expect(index(0), 0);
      expect(index(49), 0);
      expect(index(50), 1);
      expect(index(101), 2);
      expect(index(199), 3);
    });

    test('holds the end image at and past the right edge', () {
      // Both happen for real: exactly `width` on the frame a hover ends, and
      // a fraction beyond it while the pointer leaves.
      expect(index(200), 3);
      expect(index(260), 3);
    });

    test('holds the cover at and before the left edge', () {
      expect(index(-12), 0);
    });

    test('is always 0 when there is nothing to scrub', () {
      expect(index(180, count: 1), 0);
      expect(index(180, count: 0), 0);
    });

    test('survives a zero-width band', () {
      expect(hoverIndexFor(localDx: 10, width: 0, count: 4), 0);
    });
  });

  /// Drives the real thing with a real mouse: hover *is* reachable in a widget
  /// test, so the swap does not have to be taken on trust.
  group('EcommerceProductCard scrubbing', () {
    const double cardWidth = 300;

    /// The URL the card is currently painting.
    String shownImage(WidgetTester tester) {
      final images = tester
          .widgetList<CustomNetworkImage>(find.byType(CustomNetworkImage))
          .toList();
      return images.last.image;
    }

    /// One mouse for the whole test — adding a second pointer with the same
    /// device id throws, so hovering repeatedly means moving, not re-adding.
    Future<TestGesture> addMouse(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      return gesture;
    }

    Future<void> hoverAt(
      WidgetTester tester,
      TestGesture mouse,
      double dx,
    ) async {
      final card = tester.getTopLeft(find.byType(EcommerceProductCard));
      await mouse.moveTo(Offset(card.dx + dx, card.dy + 40));
      await tester.pumpAndSettle();
    }

    Future<void> pumpCard(
      WidgetTester tester, {
      required List<String> gallery,
      bool? enable = true,
    }) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: cardWidth,
                height: 400,
                child: EcommerceProductCard(
                  product: _product(gallery: gallery),
                  imageAspectRatio: 1,
                  enableHoverGallery: enable,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      // The card reads a brand label and a cart quantity; neither is what
      // these tests are about, so both resolve to nothing.
      Get.put<BrandController>(
        BrandController(brandRepoInterface: _FakeBrandRepo()),
      );
      Get.put<CartController>(
        CartController(cartRepoInterface: _FakeCartRepo()),
      );
      Get.put<FavoritesController>(
        FavoritesController(favoritesRepoInterface: _FakeFavoritesRepo()),
      );
    });

    tearDown(Get.reset);

    testWidgets('follows the pointer across the band', (tester) async {
      await pumpCard(
        tester,
        gallery: ['cover.jpg', 'b.jpg', 'c.jpg', 'd.jpg'],
      );
      expect(shownImage(tester), 'cover.jpg');

      final mouse = await addMouse(tester);

      // 300px / 4 images = one image per 75px slice.
      await hoverAt(tester, mouse, 100);
      expect(shownImage(tester), 'b.jpg');

      await hoverAt(tester, mouse, 280);
      expect(shownImage(tester), 'd.jpg');

      // And back the other way.
      await hoverAt(tester, mouse, 20);
      expect(shownImage(tester), 'cover.jpg');
    });

    testWidgets('rests back on the cover once the pointer leaves', (
      tester,
    ) async {
      await pumpCard(tester, gallery: ['cover.jpg', 'b.jpg', 'c.jpg']);

      final mouse = await addMouse(tester);
      await hoverAt(tester, mouse, 280);
      expect(shownImage(tester), 'c.jpg');

      await mouse.moveTo(const Offset(-100, -100));
      await tester.pumpAndSettle();
      expect(shownImage(tester), 'cover.jpg');
    });

    testWidgets('a single-photo product never leaves its cover', (
      tester,
    ) async {
      await pumpCard(tester, gallery: const []);

      final mouse = await addMouse(tester);
      await hoverAt(tester, mouse, 280);
      expect(shownImage(tester), 'cover.jpg');
    });

    testWidgets('off the web shell, hover changes nothing', (tester) async {
      await pumpCard(
        tester,
        gallery: ['cover.jpg', 'b.jpg', 'c.jpg'],
        enable: false,
      );

      final mouse = await addMouse(tester);
      await hoverAt(tester, mouse, 280);
      expect(shownImage(tester), 'cover.jpg');
    });
  });
}
