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
