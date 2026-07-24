# CLAUDE.md

Guidance for working in this repository. Follow these conventions exactly — they reflect the existing architecture, not a greenfield ideal.

## Project

`appwrite_store_app` — a Flutter **store-admin** panel (multi-module: Food / Ecommerce) backed by **Appwrite**. Companion customer app lives in the sibling repo `appwrite_user_app`.

- **State management + DI:** GetX (`get`)
- **Routing:** `go_router` mounted via `GetMaterialApp.router`
- **Backend:** Appwrite (`appwrite` SDK) through a single `AppwriteService`
- **Push:** Firebase Messaging + `flutter_local_notifications`

## Commands

```bash
flutter pub get
flutter run
flutter analyze                       # keep this clean (only pre-existing info lints allowed)
flutter analyze lib/path/to/file.dart # analyze a single file after editing
flutter build apk --release
```

There is no test suite. Verify changes with `flutter analyze` and by running the app.

## Architecture — layered, feature-first

```
lib/
  main.dart                      # GetMaterialApp.router bootstrap
  global.dart                    # Global.init(): Firebase, notifications, DI, loads languages
  app/
    appwrite/                    # AppwriteService (DB/auth/storage wrapper) + AppwriteConfig (ids)
    controllers/                 # ALL controllers (global, GetxController) — business logic + state
    models/                      # data models with fromJson/toJson (snake_case keys = Appwrite attrs)
    modules/<feature>/
      screens/                   # pages (views)
      widgets/                   # widgets used by THIS feature's screens
      domain/repository/         # <feature>_repo_interface.dart + <feature>_repository.dart
      domain/services/           # optional pure helpers (e.g. parsers)
    common/
      widgets/                   # cross-module reusable widgets (ResponsiveScaffold, StoreDrawer, …)
      utils/                     # ResponsiveData, etc.
    helper/
      dependencies.dart          # DI wiring (repos + controllers)
      routes/app_router.dart     # GoRouter + path constants
    resources/                   # constants, colors, text_style, theme, route_names, messages, images
  scripts/seed_database.dart     # Appwrite schema/seed helper
assets/language/{en,bn}.json     # translation key/value maps
```

**Data flow:** `View (screen/widget)` → `Controller` (business logic, state) → `RepoInterface` → `Repository` (Appwrite calls) → `AppwriteService`. Views never touch repositories or `AppwriteService` directly.

### Data fetch flow — worked example (`getSpecialProducts`)

Every list fetch follows the same four hops. **A view must only call a
controller method and read the controller's exposed state — never call the
repository / `AppwriteService`, and never import a `*_repo_interface.dart` or
`*_repository.dart` from a screen/widget.**

1. **Repository** (`modules/products/domain/repository/product_repository.dart`) — the *only* layer that talks to Appwrite. Returns models; throws on failure:
   ```dart
   @override
   Future<List<ProductModel>> getSpecialProducts() async {
     final res = await appwriteService.listTable(
       tableId: AppwriteConfig.productsCollection,
       queries: [Query.equal('module_type', ModuleController.current), /* … */],
     );
     return res.rows.map((r) => ProductModel.fromJson(r.data)).toList();
   }
   ```
2. **Interface** (`product_repo_interface.dart`) — the controller depends on this abstraction, never the concrete class: `Future<List<ProductModel>> getSpecialProducts();`
3. **Controller** (`controllers/product_controller.dart`) — owns the loading / error / data state, calls the interface, then `update()`:
   ```dart
   Future<void> getSpecialProducts({bool reload = false}) async {
     _isLoadingSpecials = true; if (!reload) update();
     try {
       _specialProducts = await productRepoInterface.getSpecialProducts();
     } catch (e) {
       _specialsErrorMessage = 'Failed to load special products: $e';
     }
     _isLoadingSpecials = false; update();
   }
   ```
4. **View** (`modules/dashboard/section_widget/todays_specials_widget.dart`) — inside a `GetBuilder<ProductController>`, triggers the controller method (from `initState` / pull-to-refresh / a retry button) and renders `controller.specialProducts`, `controller.isLoadingSpecials`, `controller.specialsErrorMessage`. It imports the controller only.

When several lists load on one screen, orchestrate them from the view's load
method by `await`-ing the **controller** methods (e.g. `_loadData()` →
`Future.wait([controller.getSpecialProducts(), controller.getPopularProducts(), …])`)
— never by calling repositories from the view.

## MANDATORY rules

### 1. Translate every user-facing string
Never hardcode raw display text in screens/widgets. Add the key to **both** `assets/language/en.json` and `assets/language/bn.json`, then use the GetX `.tr` extension:

```dart
Text('store_setup'.tr)
```

Keys are `snake_case`. Languages are loaded in `dependencies.dart` into GetX `Translations` (`Messages`). If a string is genuinely a proper noun/debug-only `log()`, it may stay literal — everything shown to the user must be translated.

### 2. Business logic lives in controllers
All state, validation, orchestration, and decision logic go in a `controllers/<x>_controller.dart` (`extends GetxController implements GetxService`). Expose state via getters; mutate then call `update()` (this codebase uses `GetBuilder`, not `Obx`). No business logic in views.

### 3. API / Appwrite calls live in repositories only
Every backend call goes in `modules/<feature>/domain/repository/<feature>_repository.dart`, behind an abstract `<feature>_repo_interface.dart`. Controllers depend on the **interface**, never the implementation or `AppwriteService`. Repositories use `appwriteService.listTable / createRow / updateTable / getDocument / deleteRow / uploadImage` with `Query.*` filters and collection ids from `AppwriteConfig`.

### 4. Widgets go in the feature's `widgets/` folder
When a screen needs an extracted widget, put it in that module's `widgets/` folder. Only truly cross-module widgets belong in `common/widgets/`. Keep screens thin — compose from widgets.

### 5. Use `Constants` for all design values — never hardcode
Every design value in a screen/widget — **padding, margin, font size, border radius**, and section spacing — must come from `resources/constants.dart` (`Constants`). Never hardcode raw numbers for these.

```dart
// ✅ do
padding: const EdgeInsets.all(Constants.paddingSizeDefault),
borderRadius: BorderRadius.circular(Constants.radiusLarge),
fontSize: Constants.fontSizeLarge,

// ❌ don't
padding: const EdgeInsets.all(15),
borderRadius: BorderRadius.circular(15),
fontSize: 16,
```

Available tokens: font sizes `fontSizeExtraSmall`…`fontSizeOverLarge`; padding/margin `paddingSizeExtraSmall`…`paddingSizeExtraLarge`; radius `radiusSmall`…`radiusExtraLarge`; spacing `spaceSection`, `bottomNavSpace`. If a needed value is missing, add a new token to `Constants` rather than hardcoding at the call site.

### 6. Use theme-aware colors — never hardcode a static color
The app ships **light and dark** themes, so a screen/widget must never paint with a raw `Color`/`Colors.*` that looks right in only one mode. Pull every color from the theme so it recolors automatically when the mode changes.

- Prefer the reactive `context.<color>` extension (`AppColorsX` in `resources/colors.dart`) wherever a `BuildContext` is available — reading it registers a `Theme` dependency, so the widget rebuilds on theme change:
  ```dart
  color: context.textPrimary,          // text
  color: context.textSecondary,        // muted text
  color: context.scaffoldBackground,   // page background
  color: Theme.of(context).cardColor,  // surfaces/cards
  ```
- Use `ColorResource.<color>` only where there is **no** `BuildContext` (it resolves via `Get.isDarkMode` but is not reactive).
- When light/dark need genuinely different values at a call site, branch on `Theme.of(context).brightness == Brightness.dark` (see the existing `isDark` pattern in screens) rather than committing to one hardcoded color.
- Brand/semantic constants that are intentionally identical in both modes (`ColorResource.primaryDark`, `primaryGradient`, `error`, `textWhite`, …) are fine to use as-is.

```dart
// ✅ do
Text('hi', style: poppinsMedium.copyWith(color: context.textPrimary));
Container(color: Theme.of(context).cardColor);

// ❌ don't
Text('hi', style: poppinsMedium.copyWith(color: Colors.black));
Container(color: const Color(0xFFFFFFFF));
```

If a needed theme color is missing, add it to the `_c*` constants + both `AppColorsX` and the static getters in `resources/colors.dart` rather than hardcoding at the call site.

## Conventions

- **DI registration:** add new repos/controllers in `helper/dependencies.dart` with `Get.lazyPut`. Pattern: build the `RepoInterface = Repository(appwriteService: Get.find())`, `Get.lazyPut(() => thatInterface)`, then `Get.lazyPut(() => Controller(repoInterface: Get.find()))`. Resolve with `Get.find<T>()` (guard optional ones with `Get.isRegistered<T>()`).
- **Routing:** add a `GoRoute` in `app_router.dart`, a path constant in `AppRouter`, and an identifier in `RouteNames`. Navigate with `AppRouter.go(context, AppRouter.x)` — `context.go` is the reliable primitive under `GetMaterialApp.router` (prefer it over `context.push` / `Get.to` for full pages). Wrap pages in `ResponsiveScaffold(currentRoute: RouteNames.x, appBarTitle: 'x'.tr, body: ...)` to get the drawer + app bar.
- **Responsiveness:** use `ResponsiveBuilder` / `ResponsiveData` (`isMobile` = width ≤ 600). Standard pattern: **mobile = infinite scroll**, **tablet/web = numbered pagination** via `common/widgets/pagination_bar.dart`. Constrain wide content with `maxContentWidth`.
- **Text styles:** use `poppinsRegular` / `poppinsMedium` / `poppinsBold` from `resources/text_style.dart` (currently `GoogleFonts.inter`). Colors/theme from `resources/`.
- **Models:** `fromJson` / `toJson` with `snake_case` JSON keys matching Appwrite attributes; provide a `copyWith`. Appwrite system fields are `$id`, `$createdAt`.
- **Toasts:** `customToster('msg'.tr, isSuccess: bool)` from `common/widgets/custom_toster.dart`.
- **Modules:** the store can run Food, Ecommerce, or both. `ModuleController` holds the active module; products/categories carry `module_type` and module-scoped lists filter by it via `Query.equal('module_type', activeModule)`. Module-specific admin entries should be gated on `isFoodEnabled` / `isEcommerceEnabled`.

## Adding a feature (recipe)

1. `models/<x>_model.dart` — with `fromJson`/`toJson`/`copyWith`.
2. `modules/<x>/domain/repository/<x>_repo_interface.dart` + `<x>_repository.dart` (Appwrite calls).
3. `controllers/<x>_controller.dart` — business logic, depends on the interface.
4. `modules/<x>/screens/` + `modules/<x>/widgets/` — views (translated strings, `ResponsiveScaffold`).
5. Register repo + controller in `helper/dependencies.dart`.
6. Add route to `app_router.dart` / `RouteNames` if it's a navigable page.
7. Add any new strings to `assets/language/en.json` **and** `bn.json`.
8. `flutter analyze` the touched files.
