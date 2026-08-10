# `.well-known` — App Link / Universal Link association files

These files let the Appwrite password-recovery link
(`https://food-app-c2fe8.web.app/reset-password?userId=…&secret=…`) open the
installed app instead of the browser. Without them the link still works — it
just always lands in the browser on the deployed web build.

## Files

- **`assetlinks.json`** — Android App Links. Lists the SHA-256 fingerprints
  allowed to claim links for `com.mehedi.food`.
- **`apple-app-site-association`** — iOS Universal Links. **No file extension**
  by design; `firebase.json` pins its `Content-Type` to `application/json`
  because Firebase would otherwise serve it as `application/octet-stream`,
  which iOS rejects.

## ⚠️ `firebase.json` must not ignore dotfiles

`.well-known` is a dot-directory. The hosting config previously carried
`"ignore": ["**/.*"]`, which silently excluded these files from every deploy —
the deploy succeeds, the URL returns 200 (the SPA rewrite serves `index.html`),
and link verification fails with no error anywhere. That pattern has been
removed; do not reintroduce it. Firebase `ignore` has no negation syntax.

Verify after every hosting change:

```bash
curl -sI https://food-app-c2fe8.web.app/.well-known/assetlinks.json
curl -sI https://food-app-c2fe8.web.app/.well-known/apple-app-site-association
```

Both must return **200** with **`content-type: application/json`**. `text/html`
means the rewrite is answering and the files were not deployed.

## Fingerprints still to add to `assetlinks.json`

The single entry present today is the **local debug key**
(`~/.android/debug.keystore`), which is also what release builds are signed with
right now — `android/app/build.gradle.kts:35-38` still points release at the
debug signing config.

Before publishing, add:

1. The **release keystore** SHA-256, once a real one exists.
2. The **Play App Signing** SHA-256 from Play Console → Setup → App integrity.
   Google re-signs uploaded bundles, so the fingerprint users' devices actually
   see is Google's, not yours. Omitting it means App Links silently stop
   verifying for every Play install.

Multiple fingerprints in the array is supported and is how debug, release and
Play-signed builds are covered simultaneously.

## iOS: blocked on two values

`apple-app-site-association` currently contains placeholders. It needs:

- The **Apple Team ID** (`DEVELOPMENT_TEAM = U7VLRFHZG7` is already in
  `ios/Runner.xcodeproj/project.pbxproj` — confirm it owns the App ID).
- The **real bundle id**. It is still the placeholder
  `com.example.foodUserApp`; this must change before the App ID can be
  registered with the Associated Domains capability.

Until both are filled in, iOS Universal Links will not verify. Android is
unaffected.

## Changing the hosting domain

The host appears in six places. All must move together, and Android only
re-verifies on install/update:

1. `AppwriteConfig.webAppBaseUrl`
2. `assetlinks.json` (served from the new host)
3. `apple-app-site-association` (served from the new host)
4. `<data android:host>` in `android/app/src/main/AndroidManifest.xml`
5. `applinks:` in `ios/Runner/Runner.entitlements`
6. A new **Web platform** entry on the Appwrite project
