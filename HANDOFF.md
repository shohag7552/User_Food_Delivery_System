# Handoff: server-side Stripe pricing (delete this file and payment_patches/ when done)

Goal (user's words): "make server-side pricing the only behaviour and calculate the Stripe
amount from the stored order on the server", without breaking any other feature,
CodeCanyon-ready. **Do not commit or deploy; the user deploys.**

All four projects are in `~/flutter projects/kikomart/` (the `~/Go projects` copies are empty):
`appwrite_user_app`, `appWrite_store_app`, `kikomart-notificaiton-function` (backend, deployed as
`notification_function1`), `kikomart-stripe-function`. Each app has its own CLAUDE.md; follow it.

## Status (2026-11-13)
- `appwrite_user_app`: DONE, uncommitted. `flutter analyze` = baseline 35 infos, no warnings.
- Other three repos: changes are written and tested but NOT applied. They are patches in
  `appwrite_user_app/payment_patches/` (all three were checked to apply cleanly on 2026-11-13):
  - `backend.patch` → `kikomart-notificaiton-function` (`git apply`); `go test` passed
  - `store_seed.patch` → `appWrite_store_app` (`git apply`)
  - `stripe.patch` → run from `kikomart/` with `patch -p0`; `go test` passed. The Stripe repo
    already holds earlier uncommitted work (order lookup, verify check, webhook); the patch goes on top.
- The user deployed the OLD Stripe function and ran the new app → `Unknown action:
  start_online_order`. Expected: the backend patch was not applied or deployed yet.

## Next steps
1. Apply the three patches; run `go test ./...` in both Go repos; `flutter analyze` the store
   app's `lib/scripts/seed_database.dart` and `lib/app/appwrite/appwrite_config.dart`
   (only new infos should be the file's usual `avoid_print`).
2. Walk the user through deploying (they do it):
   a. Store app: `dart lib/scripts/seed_database.dart` → creates `pending_orders`; check its columns
      are "available" in the console.
   b. Stripe function: env `DATABASE_ID`, `ALLOW_LEGACY_CLIENT_AMOUNT=true` (until old app versions
      are gone); scopes `rows.read`, `rows.write`; execute access `users` + `any`; Stripe webhook
      `<FUNCTION_URL>/stripe/webhook` with checkout.session.completed / async_payment_succeeded /
      async_payment_failed / expired. Redeploy.
   c. Backend: env `STORE_CURRENCY` (ISO code, default USD; must match the store's currency); add
      event `databases.<DATABASE_ID>.tables.pending_orders.rows.*.update`; timeout 30 s;
      `APPWRITE_API_KEY` needs `messages.write`. Redeploy.
3. Test with a Stripe test card: normal pay → one order + one push; pay then kill the app →
   order still appears (webhook path); cancel → no order.
4. Then CodeCanyon clean-up (see below).

## How the new flow works
1. App → backend `start_online_order` (`pending.go`): server prices the cart (`loadPricing` +
   `computeTotals`, always binding), 409 `price_changed` if the app's `expected_total` differs,
   else writes a `pending_orders` row (server-only perms) with total, `currency_code`
   (env STORE_CURRENCY) and payload JSON = checkout fields + cart snapshot + totals.
2. App → Stripe function `/stripe/create {orderId: pendingId}`: reads the amount from the row
   (`gateways/orders.go`, table `pending_orders`). A client amount is ignored.
3. Stripe webhook marks the row `confirmed` + `paid` (or `cancelled`).
4. The order is written by whichever comes first:
   - the app's `place_order {pending_order_id, payment_session_id}`, or
   - the backend event handler `convertPaidPending` on the pending_orders update.
   `place_order` with a pending id uses only the stored row (cart snapshot, paid totals) and
   requires the Stripe session to match exactly (`paidInFull`). The idempotency key is the
   pending id, so only one order is written. The webhook path retries `order_in_progress`
   4×3 s; the app retries it 5×2 s. The row is then marked `converted`.
5. For card orders the backend sends the pushes (`announceOrder`, English only); the app skips
   `notifyOrderPlaced` when `pendingOrderId` is set.
- Legacy `temp_` ids still use the old client-amount path until `ALLOW_LEGACY_CLIENT_AMOUNT=false`.

## Known gaps
- Customer deletes the delivery address while paying → `place_order` fails after the charge.
- No end-to-end test for the app and the webhook arriving at the same moment (relies on `claimKey`).
- The store app has no screen for `pending_orders` (only matters if the webhook conversion fails,
  which logs `PAID PENDING ORDER ... NOT CONVERTED`).

## CodeCanyon blockers found (not payment-related)
- URGENT: an Appwrite server key is hard-coded in `appWrite_store_app/lib/app/resources/constants.dart:45`
  and is in git history (commit abe1a7b). The user must rotate it; then make the scripts in
  `lib/scripts/` read the key from an env var or argument.
- `google-services.json` / `GoogleService-Info.plist` are committed in all three apps → ship placeholders.
- `.idea/` folders, `.DS_Store` files (one committed in the backend), the `<YEAR> <COPYRIGHT HOLDER>`
  placeholders in the Stripe function's LICENSE, this HANDOFF.md and `payment_patches/`.
