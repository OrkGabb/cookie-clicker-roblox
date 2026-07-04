# CookieGame — Implementation Prompts (Settings / Achievements / Daily Rewards / Upgrades / Visual Integration)

**For:** AI coding agent (originally Gemini 3.1 Pro)
**Scope:** Code only. Image assets (Cookie_Main 2048px, Cookie_mini, egg close icon) are sourced
externally via Seedream — these prompts only reference asset IDs, they do not generate images.

---

## Non-negotiable engineering bar (applies to every prompt below)

> Hard requirements, no exceptions:
> - `--!strict` on every file you create or touch.
> - Currency, progression, and reward state are server-authoritative. The client never decides whether
>   something is awarded — it only requests, and the server validates.
> - DataStore writes use `UpdateAsync` with a merge against the existing record (in practice: ProfileService
>   + `:Reconcile()`). Never `SetAsync`, never overwrite the full player record.
> - Never construct a default/template data table once and hand out the same reference to multiple
>   players — always return a fresh table per player.
> - Single source of truth: one place for each asset ID, each formula, each config value. No
>   copy-pasted math, no duplicated constants across files.
> - At the end, return actual file diffs or full files for everything you touched. A prose summary
>   saying "done" is not an acceptable deliverable.

---

## PROMPT 0 — Shared infrastructure (do this first, everything else depends on it)

**1. `ReplicatedStorage/Shared/UI/Theme.luau`**
- Centralize the color palette: header pink, cream background, lavender panel accent, primary/secondary
  text, success/warning/danger.
- Centralize typography: `Theme.Fonts.Display` (rounded/friendly, headers/numbers) and `Theme.Fonts.Body`
  (readable, descriptions).
- Centralize standard corner radius and padding values.
- Every existing UI file with a hardcoded `Color3.fromRGB(...)` or `Enum.Font.X` migrates to this module.

**2. Asset IDs — `ReplicatedStorage/Shared/Constants/AssetIds.luau`**
- `AssetIds.CloseButtonEgg`, `AssetIds.CookieMain` (TODO comment for the 2048x2048 swap),
  `AssetIds.CookieMini` (placeholder until provided).

**3. `ReplicatedStorage/Shared/Util/NumberFormat.luau`**
- `NumberFormat.Format(n: number): string` — abbreviates large values (K, M, B, T, Qa, Qi, Sx, Sp, Oc...).
- Guards against NaN/infinity reaching the UI; clamps negative values to 0 before formatting.
- Replaces every raw `tostring(n)` used for currency/CPC/CPS display across the codebase.

**4. `src/Client/UI/Components/CloseButton.luau`**
- Reusable `ImageButton` using `AssetIds.CloseButtonEgg`, ~32x32, hover/press scale tween. The only close
  button implementation allowed across Settings, Achievements, Daily Rewards, and Upgrades.

**5. Cookie_Main — double the size**, keeping it centered and clear of the Sidebar (0.00–0.08 width) and
ShopPanel (0.70–1.00 width).

**6. Currency display** — add a `Cookie_mini` `ImageLabel` next to the counter; remove any emoji glyph
(unreliable across Roblox's font set).

**Bonus**: type `EconomyMath.ComputeLiveCPC(data: any)` with a real `PlayerData` type instead of `any`.

---

## PROMPT 1 — Settings

Trigger: the gear icon.

- `src/Client/UI/Panels/SettingsPanel.luau`: sliders (Master/Music/SFX volume, 0–100 step 5, routed
  through `SoundService` SoundGroups), toggles (Performance Mode, Notifications), a two-step "Reset Save"
  confirmation (two genuinely distinct confirmations, not two rapid clicks).
- Remotes: `UpdateSettings` (RemoteEvent, client-safe fields only). NOTE: an early design had a
  `RequestResetSave` RemoteEvent for a destructive full-profile reset — it was REMOVED in the Phase 1
  pre-beta audit (a wipe capability must never be reachable by a live client). Do not re-add it; if QA
  needs a reset, use a local Studio command-bar script.
- `src/Server/Systems/SettingsService.luau`: sanitizes/clamps settings server-side before persisting.
  The Settings panel's "Reset Settings" applies `DEFAULT_SETTINGS` client-side and persists via the
  settings-only `UpdateSettings` write — it never touches currency/progress.

---

## PROMPT 2 — Achievements

Trigger: the trophy icon.

- `ReplicatedStorage/Shared/Config/AchievementConfig.luau`: `{ id, title, description, icon, statKey,
  threshold, rewardType: "Currency" | "Cosmetic", rewardAmount }`. 12–15 entries (total clicks, lifetime
  cookies, golden cookies, upgrades purchased total + per-type, daily-streak length). SSoT — no threshold
  duplicated elsewhere.
- Player data schema: `stats = { totalClicks, lifetimeCookies, goldenCookiesCollected,
  upgradesPurchasedTotal, ... }`, `unlockedAchievements: { [id]: true }`.
- `src/Server/Systems/AchievementService.luau`: called from every server-validated event; unlocking is
  entirely server-side; rewards route through the existing currency-award path (no duplicated addition
  logic); persists via merge. `AchievementUnlocked` RemoteEvent (server → client) triggers a toast.
- Achievements UI: `src/Client/UI/Panels/AchievementsList.luau` (scrollable grid, icon/title/description/
  progress bar per card, locked vs unlocked state, `NumberFormat` for large values). Rendered as the
  "Achievements" tab inside `QuestPanel.luau` after the Quests/Achievements tab merge — there is no longer
  a standalone AchievementsPanel window.

---

## PROMPT 3 — Daily Rewards

Trigger: the gift icon.

- `ReplicatedStorage/Shared/Config/DailyRewardConfig.luau`: 7-day cycle, `{ day, rewardType,
  rewardAmount }`, day 7 meaningfully larger. SSoT.
- Player data: `lastClaimTimestamp: number` (server `os.time()` only, never client-supplied),
  streak tracked via the single SSoT stat (no separate `currentStreakDay` field — see CLAUDE.md).
- `src/Server/Systems/DailyRewardService.luau`: `ClaimDailyReward` RemoteFunction, eligibility computed
  entirely server-side from `os.time() - lastClaimTimestamp`; rate-limited like `ValidationSystem`; reward
  through the existing currency-award path; returns success/failure + new streak state.
- `src/Client/UI/Panels/DailyRewardsPanel.luau`: 7-day grid, current day highlighted, claimed days
  checked, future days dimmed; claim button state comes from the server response, never assumed
  client-side.

---

## PROMPT 4 — Upgrades panel (data binding only)

The right-side ScrollingFrame already exists visually — this is data-binding, not new UI.

- `src/Client/UI/Panels/UpgradesPanel.luau` (or wherever it lives): rows bound to `UpgradeConfig` +
  live owned-counts; icon, name, effect description, current cost (`NumberFormat`), owned count, buy
  button. Cost via the single SSoT `EconomyMath.ComputeUpgradeCost(def, ownedCount)` — never inline.
  Buy button disabled when currency < cost; fires the existing purchase remote; re-renders via
  `EconomyMath.ComputeLiveCPC` after server confirmation so CPC/CPS reflects the new state immediately.

---

## Acceptance checklist (applies to all prompts above)

- `--!strict` everywhere.
- Merge-based persistence — never `SetAsync`, never a full overwrite.
- No shared default-data table handed out by reference to multiple players.
- One source of truth per asset ID, per formula, per config value.
- Every action affecting currency/progression is server-validated; the client only requests.
- Deliverable is real file diffs, not a prose "all implemented successfully" summary.
