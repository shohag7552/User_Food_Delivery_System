import 'package:appwrite_user_app/app/common/widgets/hover_arrow_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Autoplay is a timer moving a scroll controller, which is exactly the kind
/// of thing that fails silently in a browser and leaves nothing to look at.
/// These drive it directly.

const double kCardWidth = 100;
const double kGap = 20;
const double kStride = kCardWidth + kGap;
const double kViewport = 300;
const Duration kInterval = Duration(seconds: 3);

/// Long enough for a step's animation to finish on top of the interval.
const Duration kSettle = Duration(milliseconds: 600);

ScrollController? capturedController;

Widget _harness({
  required int itemCount,
  Duration? interval = kInterval,
  double? itemExtent = kStride,
  bool disableAnimations = false,
}) {
  capturedController = null;
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(kViewport, 600),
        disableAnimations: disableAnimations,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: kViewport,
            child: HoverArrowCarousel(
              height: 120,
              itemExtent: itemExtent,
              autoScrollInterval: interval,
              builder: (context, controller) {
                capturedController = controller;
                return ListView.separated(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: itemCount,
                  separatorBuilder: (_, _) => const SizedBox(width: kGap),
                  itemBuilder: (_, _) =>
                      const SizedBox(width: kCardWidth, height: 120),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('HoverArrowCarousel autoplay', () {
    testWidgets('steps one card per interval', (tester) async {
      await tester.pumpWidget(_harness(itemCount: 10));
      await tester.pump();
      expect(capturedController!.offset, 0);

      await tester.pump(kInterval);
      await tester.pump(kSettle);
      expect(capturedController!.offset, moreOrLessEquals(kStride));

      await tester.pump(kInterval);
      await tester.pump(kSettle);
      expect(capturedController!.offset, moreOrLessEquals(kStride * 2));

      // Leave nothing ticking behind the test.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('re-aligns to the card grid from an off-grid offset', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(itemCount: 10));
      await tester.pump();

      // As an arrow tap or a half-finished drag would leave it.
      capturedController!.jumpTo(kStride * 2 + 37);
      await tester.pump();

      await tester.pump(kInterval);
      await tester.pump(kSettle);
      // Rounded back onto the grid, then one card on — not offset + stride.
      expect(capturedController!.offset, moreOrLessEquals(kStride * 3));

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('wraps back to the first card at the end', (tester) async {
      await tester.pumpWidget(_harness(itemCount: 10));
      await tester.pump();

      capturedController!.jumpTo(capturedController!.position.maxScrollExtent);
      await tester.pump();

      await tester.pump(kInterval);
      await tester.pump(const Duration(seconds: 2));
      expect(capturedController!.offset, 0);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('stays put when every card already fits', (tester) async {
      // Two cards in a 300px viewport: nothing to reveal.
      await tester.pumpWidget(_harness(itemCount: 2));
      await tester.pump();
      expect(capturedController!.position.maxScrollExtent, 0);

      await tester.pump(kInterval);
      await tester.pump(kSettle);
      expect(capturedController!.offset, 0);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('stays put without an interval — the manual default', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(itemCount: 10, interval: null));
      await tester.pump();

      await tester.pump(kInterval);
      await tester.pump(kSettle);
      expect(capturedController!.offset, 0);
    });

    testWidgets('stays put without an item extent', (tester) async {
      await tester.pumpWidget(_harness(itemCount: 10, itemExtent: null));
      await tester.pump();

      await tester.pump(kInterval);
      await tester.pump(kSettle);
      expect(capturedController!.offset, 0);
    });

    testWidgets('stays put when the platform asks for reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(itemCount: 10, disableAnimations: true),
      );
      await tester.pump();

      await tester.pump(kInterval);
      await tester.pump(kSettle);
      expect(capturedController!.offset, 0);
    });

    testWidgets('stands down after the reader drags the strip', (
      tester,
    ) async {
      await tester.pumpWidget(_harness(itemCount: 10));
      await tester.pump();

      await tester.drag(find.byType(ListView), const Offset(-40, 0));
      await tester.pumpAndSettle();
      final afterDrag = capturedController!.offset;

      // The interval passes, but the strip is the reader's for now.
      await tester.pump(kInterval);
      await tester.pump(kSettle);
      expect(capturedController!.offset, moreOrLessEquals(afterDrag));

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
