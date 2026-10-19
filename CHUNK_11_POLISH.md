# Chunk 11 polish queue

Items deferred from chunk 10-C. Group by V1-blocking vs nice-to-have.

---

## V1-BLOCKING

### Order create idempotency

Today's `POST /orders` has no client-side idempotency key. If
Flutter retries after a network blip, two orders are created
(duplicate rows + double stock decrement). The stock-side
idempotency guard in 10-D-1 Task 4 (`existingMovements` check by
`referenceId`) only fires if upstream sends the same `order.id` —
which never happens today because `tx.order.create` always generates
a new id.

Fix:
- Add `idempotency_key VARCHAR(100)` to `orders` with `UNIQUE
  (boutique_id, idempotency_key)`
- Add `idempotencyKey` to `CreateOrderInput` in Flutter, generate as
  `${microsecondsSinceEpoch}_${Random().nextInt(0x7FFFFFFF)}` on
  order draft init
- Backend `orders.service.create`: look up by `(boutiqueId,
  idempotencyKey)` first; if found, return existing order; else
  proceed with create flow

Estimated: ~1 hour. V1-blocking — the stock guard from 10-D-1 only
becomes effective once this lands.

Audit ref: chunk 10-D-1 Task 4 review.

### History tab pagination

The variant history tab shows only the first 50 movements from a
single API call. No infinite scroll, no "load more", no UI signal
that older data exists.

For active boutiques (frequent restocks/orders/adjustments), 50
movements covers ~2-4 weeks. Past that, sellers lose access to
older history silently.

Backend already supports pagination correctly (returns
`{data, nextCursor, hasMore}`). Only UI/provider wiring is missing.

Fix scope (~80 lines across 2 files):
1. Convert `stockMovementsProvider` from `FutureProvider.family` to
   `AsyncNotifier` (or `StateNotifier`) that accumulates pages
2. Add `ScrollController` to `product_history_tab` with bottom-trigger
   that calls `loadMore()` when within ~200px of the end
3. Handle per-batch loading state (separate from initial load)
4. On `ref.invalidate` (after restock/adjust mutations), reset to
   page 1 — don't accidentally show stale appended pages

Affected files:
- `lib/features/stock/presentation/providers/stock_provider.dart`
- `lib/features/products/presentation/widgets/product_history_tab.dart`

This must ship before V1 launch. Cannot ship with sellers unable
to view stock history past the most recent 50 movements.

Audit ref: chunk 10-C TASK 4b verification.

---

## Nice-to-have (non-blocking)

### Return uniqueness — duplicate PENDING returns possible

`Return` has no `@@unique` constraint on `(order_id, order_item_id)`.
Two concurrent return-creation requests for the same order item can
both succeed (each sees `availableToReturn` based on stale
`returnedQuantity`, which only increments on APPROVAL). After Task
7a's transaction-boundary change, this also means: if a SHIPPED-
return's auto-cancel via `OrderService.updateStatus` fails after the
Return row was already created, a seller retrying the return
creation will produce a second PENDING return rather than recovering
the original.

Fix:
- Add migration: `CREATE UNIQUE INDEX ON returns (order_id, order_item_id) WHERE status = 'PENDING' AND deleted_at IS NULL`
  (partial unique — one open return per item; APPROVED/REJECTED are
  historical and don't conflict)
- Backend `createReturn` translates the Prisma unique-violation into
  a French message: `Une demande de retour est déjà en cours pour cet article.`

Affected files:
- `prisma/schema.prisma` + migration
- `src/modules/orders/returns/returns.service.ts`

Audit ref: chunk 10-D-1 Task 7a/7b review.

### Integration test pattern (post-V1 expansion)

Project has zero integration tests outside `prisma-tenant-guard`
(which is unit-style, no DB writes). Chunk 10-D-1 establishes the
pattern via `src/test-helpers/db-fixtures.ts` + FK-cascade cleanup.

Post-V1: extend to all modules — auth, products, customers, ai.
Each module gets its own `__tests__/<module>-integration.test.ts`.

- Strengthen the unique-email suffix in `createTestUser` from
  `Date.now() + 6-char rand` to UUIDv4 or 12–16 random chars
  once the suite grows past ~100 tests across multiple files in
  parallel. At current scale (29 tests, single file) the
  collision probability is negligible.

Affected files (post-V1 expansion):
- `src/test-helpers/db-fixtures.ts` (extend with module-specific
  helpers; widen unique suffix)
- New `src/modules/<module>/__tests__/<module>-integration.test.ts`
  per module

Audit ref: chunk 10-D-1 Task 8.

### Rename `BundleComponent.quantity` to `qtyPerBundle`

The schema field is `quantity Int @default(1)` on `BundleComponent`,
but in code-reading context the name is ambiguous — it could mean
"how many of this component" (correct) or "how many bundles"
(wrong). 10-D-2 Tasks 5–7 call out the per-component math
explicitly (`item.quantity * c.quantity`) which is read-twice to
parse. Renaming to `qtyPerBundle` makes the call sites read
clearly: `item.quantity * c.qtyPerBundle`.

Affected files:
- `prisma/schema.prisma` (rename field, run `prisma migrate dev`)
- `src/modules/orders/orders.service.ts` (3 read sites in 10-D-2:
  create bundle path, cancel bundle path, deliver bundle path)
- Anywhere else that reads `bundleComponent.quantity`

Audit ref: chunk 10-D-2 Task 5.

### Concurrent oversell race — in-stock path can throw when backorder fall-through would succeed

The order create per-item dispatch (chunk 10-D-2 Task 3) uses a
read-time pre-fetch to decide between in-stock and backorder paths.
The atomic UPDATE re-validates write-time stock state via
`WHERE on_hand - committed >= qty`. If a concurrent order commits
between the pre-fetch and our UPDATE, the in-stock UPDATE returns
0 rows and we throw `Stock insuffisant pour ${name} (disponible: N)`
— even when `variant.backorderEnabled = true` and the seller would
have been happy to take the backorder path.

V1 ships with this behavior (correct semantics, retryable — seller
re-tries and the next pre-fetch sees the new state). v1.x
improvement: in the 0-row UPDATE branch, when
`variant.backorderEnabled = true`, retry the line as backorder
inside the same transaction rather than throwing.

Affected files (when implementing):
- `src/modules/orders/orders.service.ts` (per-item loop)

Audit ref: chunk 10-D-2 Task 3.

### Prisma partial-index limitation tracking

Chunk 10-D-2 created `idx_order_items_is_backorder` as a partial
index (`WHERE is_backorder = true`) via raw migration SQL.
`prisma/schema.prisma` intentionally omits the corresponding
`@@index` declaration because Prisma can't express partial
predicates today — declaring a full index in the schema would
cause `migrate dev` shadow-db diffs to drop the partial index and
replace it with an unfiltered one, silently regressing the
optimization.

When Prisma adds partial-index schema support (track via Prisma
release notes), revisit:
- Add `@@index([isBackorder], map: "idx_order_items_is_backorder", where: ...)`
  to `OrderItem` in `prisma/schema.prisma`
- Drop the inline comment that flags this gap

Affected files:
- `prisma/schema.prisma` (OrderItem)

Audit ref: chunk 10-D-2 Task 1.

### French translations for orders.service.ts concurrent-update errors

The `'Order status was updated by another request.'` message and
similar status-conflict English strings need French equivalents.
Pattern: `'Le statut de la commande a été modifié entre-temps.'`

Affected file:
- `src/modules/orders/orders.service.ts`

Audit ref: chunk 10-D-1 Task 6 review.

### Backorder fulfillment workflow — not implemented

`backordered_quantity` is incremented at order create (10-D-2) and
decremented at cancel, but there is no flow for fulfilling a backorder
when restock arrives: no endpoint to convert a backordered `order_item`
line into a confirmed/shipped sale, no notification to the seller, no
mechanism to decrement `backordered_quantity` and simultaneously
decrement `on_hand` + increment `committed`.

Current seller workaround: cancel the backorder order and re-create it
once stock arrives (losing the original order number and customer
history link).

Fix scope:
- Backend: `POST /orders/:orderId/fulfill-backorder` — validates
  sufficient on-hand, atomically decrements `on_hand`, increments
  `committed`, clears `backordered_quantity` for the line, sets
  `is_backorder = false` on `order_items`, writes a `SALE` movement
  with `quantityChange = −qty`.
- Flutter: surface a "Fulfil backorder" action on the order detail
  screen when `order.status = PENDING` and any item has `isBackorder=true`.

Affected files:
- `src/modules/orders/orders.service.ts`
- `src/modules/orders/orders.routes.ts`
- Flutter order detail screen

Audit ref: chunk 10-D-2 Task 9 (test #11 proves cancel path; fulfil path
is the missing symmetric counterpart).

### Bundle return path blocked in v1

Returns on bundle order items throw a French ConflictError
(`"Impossible de retourner un article de pack. Annuler la commande à la
place."`) in both SHIPPED and DELIVERED states. This is intentional for
v1 (Decision 6/10 in 10-D-2 locked design). The seller workaround is to
cancel the order (which triggers the full component fan-out restore).

The block causes a UX gap for DELIVERED bundles: the seller cannot
partially return one item from a delivered bundle order without cancelling
the entire order. This is acceptable for Gen-Z/small-boutique v1 volumes
but needs addressing in v1.x.

Fix scope:
- `returns.service.ts`: replace the isBundle guard with a component
  fan-out restore (mirrors the cancel branch in `orders.service.ts`)
- On RETURN approval: for each `BundleComponent`, `on_hand += qty * c.quantity`
  + 1 `RETURN` movement per component (`referenceType=RETURN, referenceId=return.id`)
- Test: extend integration suite with bundle return scenario

Affected files:
- `src/modules/orders/returns/returns.service.ts`
- `src/modules/orders/__tests__/order-stock-integration.test.ts`

Audit ref: chunk 10-D-2 Task 8 (block placed), Task 9 test #16 (verifies block).

### PRD reconciliation — backorder returns

The PRD implies backorder lines can be returned (no explicit carve-out).
10-D-2 blocks returns on backorder lines entirely (Decision 10) because
there is no physical unit to restore — the goods never left the supplier.

This creates a PRD divergence: if a seller wants to record a "backorder
cancellation with refund" (customer changed mind before goods arrived),
the current UX forces them to cancel the order (which correctly
decrements `backordered_quantity`) but does not surface a `Return` record,
meaning no refund tracking in the returns tab and no `reason` field.

Resolution options for v1.x:
1. Allow return creation on backorder lines with `quantityReturned > 0`
   but explicitly skip all stock mutations (no on_hand change). Record
   the return purely as a financial/CRM artefact.
2. On backorder cancel, accept an optional `refundAmount` + `reason`
   query param and create a `Return` record in APPROVED state
   atomically with the cancel.

Affected files (when implementing):
- `src/modules/orders/returns/returns.service.ts`
- `src/modules/orders/orders.service.ts` (option 2 path)

Audit ref: chunk 10-D-2 locked Decision 10 + Task 8.

### Add SALE_CANCELLED to Flutter `StockMovementType`

Backend introduced `SALE_CANCELLED` movement type in 10-D-1 (cancel-
restore is recorded separately from RETURN for clean reporting
buckets). Flutter `StockMovementType` enum and the `displayLabel`
extension don't know about it yet — `fromApi` will throw on a
`SALE_CANCELLED` value.

Fix: add `saleCancelled('SALE_CANCELLED')` to the enum, French
label `'Vente annulée'`, and assign it to
`StockHistoryDisplayKind.broken` (same bucket as adjustments).

Affected files:
- `lib/features/stock/domain/stock_enums.dart`

Audit ref: chunk 10-D-1 TASK 3.



### Bundle stock UI gap

`product_stock_tab.dart` renders 4-state stock cards for bundle
products. Bundles don't have direct stock — availability is computed
from components.

Fix: in `product_detail_screen.dart`, when `product.effectiveIsBundle`
is true, replace the "Stock" tab with a "Composants" tab that
reuses `BundleComponentsSection` to show component availability
read-only.

Affected files:
- `lib/features/products/presentation/screens/product_detail_screen.dart`
- `lib/features/products/presentation/widgets/product_stock_tab.dart`

Audit ref: chunk 10-C TASK 3.

### committedOrders breakdown lost

`StockState.committedOrders` is rendered in `stock_state_sheet`
under the RÉSERVÉ row. Backend's `/stock-state` endpoint returns
only `committedQuantity` (count), so the list will be empty after
real repo activation.

Fix: add backend endpoint `GET /variants/:id/committed-orders`
returning `[{orderId, orderNumber, customerName, qty}]`. Lazy-load
from Flutter when the user expands the RÉSERVÉ row.

Affected files:
- Backend: `src/modules/stock/stock.routes.ts` (new endpoint)
- Backend: `src/modules/stock/stock.service.ts` (new method)
- Flutter: `lib/features/stock/data/real_stock_repository.dart`
  (new method `getCommittedOrders`)
- Flutter: `lib/features/stock/presentation/sheets/stock_state_sheet.dart`
  (lazy-load on expand)

Audit ref: chunk 10-C TASK 3.

### CategoryInput widening

`CategoryInput` only carries `name`. Backend accepts `color`, `icon`,
`sortOrder`. UI cannot set them today.

Fix: widen `CategoryInput`, add color picker + icon picker + sort-order
field to the create/edit category dialog.

Affected files:
- `lib/features/stock/domain/stock_inputs.dart`
- `lib/features/stock/presentation/screens/categories_management_screen.dart`

Audit ref: chunk 10-C TASK 4.

### deleteCategory `moveProductsToId` restoration

Repository signature accepts `moveProductsToId` for reassignment-on-delete,
but backend only soft-deletes (products keep their `categoryId` pointing
to a soft-deleted row).

Fix for V1: hide the target-category dropdown in the delete dialog;
copy reads "Les produits resteront dans cette catégorie supprimée
jusqu'à ce que tu les déplaces individuellement."

Long-term: backend endpoint accepts `targetCategoryId` query param
and runs `UPDATE products SET category_id = $target WHERE category_id = $current`
inside the soft-delete transaction.

Affected files:
- `lib/features/stock/presentation/screens/categories_management_screen.dart`
- Long-term: `src/modules/stock/categories.service.ts`

Audit ref: chunk 10-C TASK 4.

### Bundle component thumbnails

`getBundle` returns components without thumbnail URLs. Backend
select doesn't join to product_images.

Fix: extend `bundle.service.ts` `getComponents` select to include
`product.images` (where `isPrimary = true`, `take: 1`). Map to
`BundleComponent.componentThumbnailUrl` in real repo.

Affected files:
- `src/modules/stock/bundle.service.ts`
- `lib/features/stock/data/real_stock_repository.dart`

Audit ref: chunk 10-C TASK 4.

### BoutiqueStockSettings field gap

Flutter `BoutiqueStockSettings` carries 3 push-notification flags
(`pushNotifLowStock`, `pushNotifRupture`, `pushNotifRestockConfirmed`)
that the backend `boutique_stock_settings` table does not store. The
real repo defaults them all to `false` and ignores them on PATCH.

Fix: extend `boutique_stock_settings` schema with the three boolean
columns (migration), update service select+update, surface in real
repo.

Affected files:
- `prisma/schema.prisma` + new migration
- `src/modules/stock/stock.service.ts` (`getStockSettings` /
  `updateStockSettings`)
- `lib/features/stock/data/real_stock_repository.dart`

Audit ref: chunk 10-C TASK 4c.

### Report endpoints — missing fields for richer cards

Backend reports return scalar/text fields. Flutter cards expect
optional thumbnails, color tags, cost/value figures. Real repo
fills with `null`/`0` where backend doesn't supply.

Specifically:
- `/stock/value` topProducts: missing `thumbnailUrl`, `thumbnailColor`
- `/stock/dead`: missing `value` (units × WAC), `category`, thumbnails
- `/stock/low`: missing `productId`, `variantLabel`, `currentWacMillimes`,
  thumbnails
- `/stock/best-sellers` + `/stock/slow-movers`: missing thumbnails
- `/stock/shrinkage` + `/stock/off-sale-outflow` byProduct: missing
  thumbnails

Fix: per endpoint, extend SELECT to include primary image join
(LATERAL pg pattern) and any computed values needed (e.g. `value =
SUM(on_hand × current_avg_cost_millimes)` for dead stock).

Affected files:
- `src/modules/stock/stock.service.ts` (one extension per query)
- `lib/features/stock/data/real_stock_repository.dart` (drop the TODO
  fallbacks)

Audit ref: chunk 10-C TASK 4c.
