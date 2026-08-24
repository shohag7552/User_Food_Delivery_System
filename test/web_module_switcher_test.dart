import 'package:appwrite_user_app/app/common/widgets/web_module_switcher.dart';
import 'package:appwrite_user_app/app/controllers/module_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store running both storefronts.
///
/// The real flags are resolved from business setup at bootstrap, which would
/// drag the settings graph into a test about a two-button control. Only the
/// answers the control asks for are overridden; switching still goes through
/// the real [ModuleController.switchModule].
class _BothModulesController extends ModuleController {
  _BothModulesController(SharedPreferences prefs)
    : super(sharedPreferences: prefs);

  @override
  bool get bothEnabled => true;

  @override
  bool get isFoodEnabled => true;

  @override
  bool get isEcommerceEnabled => true;

  @override
  bool isModuleEnabled(String module) => true;

  String _active = ModuleController.food;

  @override
  String get activeModule => _active;

  @override
  bool get isFood => _active == ModuleController.food;

  @override
  bool get isEcommerce => _active == ModuleController.ecommerce;

  @override
  Future<bool> switchModule(String module) async {
    if (module == _active) return false;
    _active = module;
    update();
    return true;
  }
}

/// A store with only one storefront — the control has nothing to offer.
class _FoodOnlyController extends _BothModulesController {
  _FoodOnlyController(super.prefs);

  @override
  bool get bothEnabled => false;
}

void main() {
  late _BothModulesController module;

  Future<void> pumpSwitcher(
    WidgetTester tester, {
    ModuleController? controller,
    Future<void> Function(String target)? onSwitch,
    TextDirection direction = TextDirection.ltr,
  }) async {
    Get.put<ModuleController>(controller ?? module);
    await tester.pumpWidget(
      GetMaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(child: WebModuleSwitcher(onSwitch: onSwitch)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Where the rail actually landed, and how tall against how wide.
  Rect railRect(WidgetTester tester) => tester.getRect(
    find.ancestor(of: find.text('food'), matching: find.byType(Container)).last,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    module = _BothModulesController(await SharedPreferences.getInstance());
  });

  tearDown(Get.reset);

  testWidgets('states both storefronts without being opened first', (
    tester,
  ) async {
    await pumpSwitcher(tester);

    // The point of the web control: neither label is behind a click.
    expect(find.text('food'), findsOneWidget);
    expect(find.text('shop'), findsOneWidget);
  });

  testWidgets('one click switches to the other storefront', (tester) async {
    final switched = <String>[];
    await pumpSwitcher(
      tester,
      onSwitch: (target) async {
        switched.add(target);
        await module.switchModule(target);
      },
    );

    await tester.tap(find.text('shop'));
    await tester.pumpAndSettle();

    expect(switched, [ModuleController.ecommerce]);
    expect(module.activeModule, ModuleController.ecommerce);
  });

  testWidgets('clicking the storefront already open does nothing', (
    tester,
  ) async {
    final switched = <String>[];
    await pumpSwitcher(
      tester,
      onSwitch: (target) async => switched.add(target),
    );

    await tester.tap(find.text('food'));
    await tester.pumpAndSettle();

    expect(switched, isEmpty);
  });

  testWidgets('refuses a second click while a switch is in flight', (
    tester,
  ) async {
    // Switching clears every cached list and refetches; two of those queued
    // back to back is the thing an impatient double-click causes.
    final switched = <String>[];
    await pumpSwitcher(
      tester,
      onSwitch: (target) async {
        switched.add(target);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
    );

    await tester.tap(find.text('shop'));
    await tester.pump();
    await tester.tap(find.text('shop'), warnIfMissed: false);
    await tester.pump();

    expect(switched, hasLength(1));

    await tester.pumpAndSettle();
  });

  testWidgets('stacks vertically rather than spreading across the page', (
    tester,
  ) async {
    await pumpSwitcher(tester);

    final food = tester.getCenter(find.text('food'));
    final shop = tester.getCenter(find.text('shop'));

    // Shop sits below Food, and they share a column.
    expect(shop.dy, greaterThan(food.dy));
    expect(shop.dx, moreOrLessEquals(food.dx, epsilon: 0.5));
  });

  testWidgets('tucks against the right edge in English', (tester) async {
    await pumpSwitcher(tester);

    final screen = tester.getSize(find.byType(Scaffold)).width;
    // Flush: the rail's trailing edge is the window's.
    expect(railRect(tester).right, moreOrLessEquals(screen, epsilon: 0.5));
  });

  testWidgets('tucks against the left edge in Arabic', (tester) async {
    await pumpSwitcher(tester, direction: TextDirection.rtl);

    expect(railRect(tester).left, moreOrLessEquals(0, epsilon: 0.5));
  });

  testWidgets('shows nothing when the store runs one storefront', (
    tester,
  ) async {
    await pumpSwitcher(
      tester,
      controller: _FoodOnlyController(await SharedPreferences.getInstance()),
    );

    expect(find.text('food'), findsNothing);
    expect(find.text('shop'), findsNothing);
  });
}
