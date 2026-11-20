# KikoMart Customer App

The **customer** app of the KikoMart platform (Flutter, Android, iOS, Web).
Customers browse the catalog, search, add to cart and favorites, apply coupons,
check out with cash on delivery, wallet or card (Stripe), track their orders,
leave reviews and collect loyalty points. It supports **Food**, **Ecommerce**,
or both, depending on what the store has switched on.

It is one of three apps that share **one Appwrite backend**:

| App | Folder | Who uses it |
|---|---|---|
| Store admin panel | `appWrite_store_app` | Store owner — **set this up first**, it creates the database |
| Customer app | `appwrite_user_app` (this one) | Customers |
| Delivery app | `appWrite_delivery_app` | Delivery riders |

Set up the store app first (its README, steps 2–4: Appwrite ids, seed script,
backend function), then come back here.

---

## 1. Requirements

- Flutter **3.27** or newer, Dart SDK `^3.10.1`
- An [Appwrite](https://appwrite.io) project — the **same one** the store app uses
- A [Firebase](https://console.firebase.google.com) project, for push notifications
- A [Stripe](https://stripe.com) account, only if you take card payments
- Android Studio / Xcode for mobile builds

```bash
flutter pub get
flutter run            # or: flutter run -d chrome   (web storefront)
```

The app compiles and runs as shipped, but it points at the demo backend.
Complete steps 2–4 before you use it.

---

## 2. Appwrite setup

Everything lives in **one block** at the top of
[`lib/app/resources/constants.dart`](lib/app/resources/constants.dart).
Replace each value with the id from your own Appwrite Console — use **the
same values as in the store app**:

| Constant | Where to find it | Store app name |
|---|---|---|
| `projectId` | Settings → Project ID | `projectId` |
| `endpoint` | Settings → API Endpoint (e.g. `https://fra.cloud.appwrite.io/v1`) | `apiEndpoint` |
| `databaseId` | Databases → your database → Database ID | `databaseId` |
| `postsBucketId` | Storage → your bucket → Bucket ID | `postsBucketId` |
| `messagingProviderId` | Messaging → Providers → your FCM provider | `messagingProviderId` |
| `notificationFunctionId` | Functions → the backend function | `notificationFunctionId` |
| `topicId` | Messaging → Topics (customer promotions) | `broadCastTopicId` |
| `storeAdminTopicId` | Messaging → Topics (new-order alerts to the store) | `storeAdminTopicId` |
| `stripePaymentFunctionId` | Functions → the Stripe function (step 4) | — |
| `webBaseUrl` | The domain where you host the web build | — |

Also add a **platform** for every target you build (Overview → Platforms):
Android `com.kikomart.user`, iOS bundle id, and your web domain.

There is deliberately **no API key in this app.** It only ever acts as the
signed-in customer; prices, orders, payments and wallet changes are done by
the backend function with the server key.

You do not need to create any tables here — the store app's seed script
creates them for all three apps.

---

## 3. Firebase setup (push notifications)

Three places, all of which must point at **your** Firebase project:

1. **`android/app/google-services.json`** — download it from Firebase Console
   → Project settings → your Android app and replace the file. The package
   name must match `applicationId` in `android/app/build.gradle.kts`
   (`com.kikomart.user` by default).
2. **`ios/Runner/GoogleService-Info.plist`** — the same, for the iOS app.
3. **`lib/global.dart`** — the four values (`apiKey`, `appId`,
   `messagingSenderId`, `projectId`) in the `FirebaseOptions` block.

Use the same Firebase project for all three apps. Customers subscribe to
`topicId` for promotions and receive order-status pushes from the backend.

---

## 4. Card payments (Stripe)

Cash on delivery and wallet work without this step. For card payments:

1. Deploy `kikomart-stripe-function` following its README (environment
   variables, scopes, execute access and the Stripe webhook).
2. Put its function id in `stripePaymentFunctionId`.
3. Set the function's `PAYMENT_SUCCESS_URL` / `PAYMENT_CANCEL_URL` to
   `<webBaseUrl>/payment/success` and `<webBaseUrl>/payment/cancel`. They
   **must** match `webBaseUrl` here, or the customer is stranded after paying.
4. Set the backend function's `STORE_CURRENCY` to the store's currency.

The charge amount is always calculated on the server from the stored order,
never from the app. Test with a Stripe test card before switching to live keys.

---

## 5. Maps

Address picking and order tracking use free OpenStreetMap tiles until the
store owner saves a **LocationIQ** key in the store panel (**Business Setup →
Web App Settings**). The app picks it up on its next start — no new build.
OpenStreetMap forbids heavy or commercial use of its free servers, so add the
key before going live. The fallback map centre is `mapDefaultLatitude` /
`mapDefaultLongitude` in `constants.dart`.

---

## 6. Branding

| What | Where |
|---|---|
| App name | `Constants.appName`, `android/app/src/main/AndroidManifest.xml` (`android:label`), `ios/Runner/Info.plist` (`CFBundleDisplayName`), `web/index.html`, `web/manifest.json` |
| Package / bundle id | `applicationId` in `android/app/build.gradle.kts`, `PRODUCT_BUNDLE_IDENTIFIER` in Xcode, `Constants.packageName` |
| Brand colour | `Constants.primaryColorValue` — one line; the theme is derived from it in light and dark mode |
| Font | `lib/app/resources/text_style.dart` |
| Logo & icons | `assets/images/`, `web/icons/`, platform launcher icons |
| Languages | `assets/language/{en,bn,ar}.json` — Arabic is right-to-left and the layout mirrors itself |

Store name, logo, currency, delivery charges and the active modules come from
the store panel's **Business Setup**, not from this app.

---

## 7. Release builds

```bash
# Android: one APK per architecture
flutter build apk --release --split-per-abi

# Android App Bundle, for Google Play
flutter build appbundle --release

# iOS
flutter build ipa --release

# Web storefront — stamps the version so returning visitors get the new build
./tool/build_web.sh
# then upload build/web to your host (e.g. Appwrite Sites)
```

For a signed Android release, create `android/key.properties`:

```properties
storePassword=…
keyPassword=…
keyAlias=…
storeFile=/absolute/path/to/keystore.jks
```

The build uses it when present and falls back to debug signing when it is
not.

The web build must be live at `webBaseUrl` for card payments on web and for
password-reset links (`webBaseUrl/reset-password`).

---

## 8. Project layout

```
lib/
  main.dart                  app bootstrap (GetMaterialApp.router)
  global.dart                Firebase, notifications, DI
  app/
    appwrite/                AppwriteService + AppwriteConfig (ids)
    controllers/             business logic and state (GetX)
    models/                  data models
    modules/<feature>/       screens/, widgets/, domain/repository/
    common/                  shared widgets and utils
    helper/                  DI, routing
    resources/               constants, colors, text styles, theme
assets/language/             en, bn, ar translations
tool/build_web.sh            web release build
test/                        widget and controller tests
```

Data flows one way: **view → controller → repository interface → repository
→ AppwriteService**. Views never call Appwrite directly.

### Coding conventions

- Every user-facing string is a translation key (`'key'.tr`) present in each
  file under `assets/language/`.
- State and business logic live in controllers (`GetxController`, rebuilt with
  `GetBuilder`); screens and widgets only render and forward taps.
- Appwrite calls live only in repositories, behind the interface the controller
  depends on.
- A widget used by one feature lives in that feature's `widgets/` folder; shared
  ones live in `common/widgets/`.
- Spacing, font sizes and corner radii come from `Constants`; colours come from
  the theme, so light and dark mode both work.

```bash
flutter analyze
flutter test
```

---

## 9. Troubleshooting

| Symptom | Cause |
|---|---|
| Home screen is empty | The store app's seed script has not been run, or the store has no products in the active module |
| "Unknown attribute" / "Table not found" errors | The seed script has not been run against this project, or the ids here differ from the store app's |
| Web app: "Invalid origin" / CORS error | Your web domain is not added as a Web platform in Appwrite (step 2) |
| Placing an order fails | The backend function is not deployed or `notificationFunctionId` is wrong |
| `price_changed` at checkout | A price changed since the cart loaded — the cart refreshes; place the order again |
| Card payment does not open, or `Unknown action` | The Stripe function or the backend function is missing or out of date (step 4) |
| Paid, but stuck on the payment page | `PAYMENT_SUCCESS_URL` on the Stripe function does not match `webBaseUrl` |
| No push notifications | Firebase config not replaced (step 3), or notification permission denied |
| Map shows no tiles in production | OpenStreetMap blocked heavy use — add a LocationIQ key in the store panel |
