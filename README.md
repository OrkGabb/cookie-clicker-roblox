# Cookie Clicker (Roblox)

Production-tested Roblox idle-clicker with server-authoritative economy.

Built in Luau on Rojo, with an ECS-lite client architecture, ProfileService-backed
persistence, and a full idle-game feature set: click income, upgrades, a secondary
"Cupcake" (CPK) currency, achievements, daily rewards, Golden Cookie events, and
gamepass monetization. Every system that touches currency or progression follows one
rule: **the client requests, the server decides.**

This README is written as a portfolio artifact, not marketing copy — the "Technical
Highlights" section below documents real bugs this project hit in development, their
root causes, and the fixes actually shipped in this codebase (file references included
so you can verify against the source).

## Architecture

- **Rojo tree**: `src/Shared` → `ReplicatedStorage.Shared`, `src/Server` →
  `ServerScriptService.Server`, `src/Client` → `StarterPlayerScripts.Client`.
- **Client**: a small ECS world (`Shared/ECS/World.luau`) binds systems
  (`ClickSystem`, `VFXSystem`, `UISystem`, `PassiveSystem`) to `RenderStepped`. UI is
  hand-rolled declarative components (`Client/UI/Declare.luau`) over a centralized
  `Theme`/`AssetIds`/`NumberFormat` SSoT.
- **Server**: `ValidationSystem` is the single entry point for click income (manual
  batched clicks and the Auto-Clicker gamepass both funnel through
  `ProcessClicks`, so simulated clicks can never diverge from the payout math a real
  click gets). `ServerPassiveSystem`, `PurchaseSystem`, `ShopService`,
  `AchievementService`, `QuestService`, `DailyRewardService`, and `GoldenCookieService`
  each own one concern; all currency mutation funnels through `DataService`'s
  `AddCurrency`/`DeductCurrency` choke point, backed by ProfileService (merge-based
  persistence, never a full-record overwrite).
- **Client/server balance model**: the client predicts optimistically (clicks feel
  instant) while a periodic reconcile pulls the server's authoritative balance — see
  Highlight #2 below for why that reconcile is more subtle than it looks.

## Technical Highlights

Real bugs from this project's history — symptom, root cause, and the fix that's in
the code today.

### 1. CPK ("Cupcake") double-credit — delta-tracking vs. accumulator carry-forward

**File:** `src/Server/Systems/ValidationSystem.luau`

The original design tracked a `cupcakesAwarded` counter and compared it against a
separately-updated `totalClicks` field, crediting the difference each time. Whenever
the two fields were read and written out of step — trivially possible across the
batched-click network boundary, where clicks arrive in bursts rather than one at a
time — the diff was recomputed against stale state and cupcakes were minted twice for
the same batch of clicks.

**Fix:** replaced both fields with a single running `clickAccumulator` integer. Each
batch adds its click count to the accumulator, mints `floor(accumulator /
CLICKS_PER_CUPCAKE)`, and carries the remainder (`accumulator % CLICKS_PER_CUPCAKE`).
There is no second value for the accumulator to drift against, so the balance is
always a concrete integer with no prediction or stale-read surface. The cupcake
multiplier (gamepass ×2/×4 stacking) scales the *minted* amount, never the click
ratio, so mints stay whole integers regardless of which multipliers are active.

### 2. Currency snap-to-zero + backward-jumping display — the reconcile race

**File:** `src/Client/ClientEntry.client.luau`

Two symptoms traced back to one root cause. The client predicts currency locally the
instant a click happens (for responsiveness), then a periodic tick
(`Constants.BALANCE_RECONCILE_INTERVAL`) calls `GetBalance` and hard-sets the display
to the server's authoritative number to squash drift.

- **Backward jump under fast clicking (5 → 4 → 6):** the server lags the client by up
  to the click-batch window (0.5s) plus round-trip latency. A naive hard-set to
  "whatever the server says right now" pulls the display *down* to a momentarily
  stale total, then back up once the server catches up — visible stutter on every
  reconcile tick during active clicking.
- **Balance resets to 0 mid-session:** if the reconcile fires before `DataService` has
  finished loading that player's profile, `GetBalance` returns a zeroed placeholder
  (`{ currency = 0, cupcake = 0, cookieMultiplier = 1 }`), and a naive hard-set would
  zero a legitimate, already-accumulated optimistic balance.

**Fix:** `pullAuthoritative()` only ratchets the displayed currency **upward**
(`authoritative.currency > state:GetCurrency()`), never down. Spends are applied
directly through `Deduct*` at the moment a purchase is confirmed, so suppressing the
downward reconcile can never strand a spend at a stale-high value — and a zeroed
placeholder from an unloaded profile is, by construction, never greater than the
player's real optimistic balance, so it's silently ignored instead of nuking progress.
The same fix also closes a related desync: the server-resolved gamepass Cookie
multiplier is fed back into the client's optimistic math (`ApplyPassMultiplier`) on
every reconcile, so the "+N" popup and running total reflect the ×2/×4 multiplied
value the server will actually credit, not the un-multiplied base.

### 3. Golden Cookie double-claim + stale-spawn cleanup

**File:** `src/Server/Systems/GoldenCookieService.luau`

A golden cookie is offered via `RemoteEvent` and claimed via `RemoteFunction`. A
naive "validate, then reward, then mark claimed" sequence leaves a window where a
second concurrent claim invocation for the same GUID can also pass validation before
the first claim finishes writing its "already claimed" flag — a double-reward race.

**Fix:** the GUID is deleted from the player's pending-claim table **the instant** a
claim passes validation, before the expiry check even runs — so a second call with
the same GUID fails structurally, not probabilistically. A 1-second sweep tick
(riding the same spawn-interval loop) expires any GUID older than
`DescentDuration + DescentTolerance` so a missed cookie doesn't linger in memory for
the rest of the session. Reward tiers are weighted-random and scale with the player's
current passive income (`floor` dominates only for near-zero-CpS new players), and the
payout respects the same gamepass Cookie multiplier a normal click would.

### 4. Idempotent receipt processing — the double-grant class, at the monetization layer

**File:** `src/Server/Systems/ShopService.luau`

`MarketplaceService.ProcessReceipt` is not guaranteed to be called exactly once —
Roblox retries until the callback returns `PurchaseGranted`, which means the same
receipt can arrive again while (or after) a previous call already granted the reward.
Naively granting on every call double-credits the purchase.

**Fix:** processed `PurchaseId`s are persisted per-profile (`data.processedReceipts`)
and checked before granting; a receipt already in that table is acknowledged as
granted without re-running the grant logic. The flag is written **after** the reward
is actually applied (mark-first would silently eat the purchase if granting the
reward errors partway through) — so a crash mid-grant results in a retry, not a lost
purchase, and a legitimate retry after success is a no-op instead of a double-credit.

### 5. Achievement progress decoupled from the UI's stats-changed signal chain

**File:** `src/Server/Systems/AchievementService.luau`

Progress tracking (`AchievementService.RecordStat`) is called directly from every
server-validated action that should count toward an achievement (clicks, quests,
purchases) rather than being derived from a `StatsChanged`-style UI signal. `UISystem`
has a expensive full-`Render()` path that fires on `StatsChanged`/`SkinChanged` and a
cheap targeted path for everything else — achievement unlocking does not ride either
of those paths, so a client-side rendering refactor can change signal wiring or
timing without silently breaking which achievements fire. Unlocks are announced
immediately (`AchievementUnlocked`) and the reward is credited after a short delay so
the client can show an "unlocked" toast before a separate "reward" toast — sequencing
the two remotes rather than firing both in the same frame.

## Known open items

Carried forward honestly rather than scrubbed from history:

- Panel-open buttons (Settings/Achievements/Daily Reward) had a period of
  unresponsiveness under static review with no confirmed root cause; suspected but
  unconfirmed culprit was a `UIScale` pop-in tween starting before the panel was
  parented.
- Single-active-panel exclusivity (closing any open panel when a different one is
  requested, robust against autoclicker-speed open spam) was specified as a
  generation-token/in-flight-request guard but is not yet implemented in
  `UISystem.luau`.

## Getting started

```bash
rojo build -o "WORKV3.rbxlx"
```

Open `WORKV3.rbxlx` in Roblox Studio, then `rojo serve` for live sync during
development.
