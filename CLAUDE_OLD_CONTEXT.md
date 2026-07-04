# CookieGame — Project Context for Claude Code

Roblox idle-clicker, built fresh (not on the P.S.U. framework, per YAGNI), Luau, server-authoritative.
Built with Rojo 7.7.0-rc.1. Tree mapping (`default.project.json`):
- `src/Shared` → `ReplicatedStorage.Shared`
- `src/Server` → `ServerScriptService.Server`
- `src/Client` → `StarterPlayerScripts.Client`

Full feature spec/roadmap: see `docs/Implementation_Prompts.md` (Prompts 0–4: shared infra, Settings,
Achievements, Daily Rewards, Upgrades panel). Read it before starting work on any of those systems.

## Hard rules — no exceptions

- `--!strict` on every file touched.
- Currency, progression, and reward state are server-authoritative. The client only requests — it never
  decides whether something is awarded.
- Persistence goes through ProfileService (`src/Server/Services/DataService.luau`) — never `SetAsync`,
  never a full-record overwrite. `:Reconcile()` handles merging new default fields into old saves.
- Never hand out the same default-data table reference to two players — always a fresh table per player
  (`createDefaultData()` is a function, not a shared constant, for exactly this reason).
- One source of truth per asset ID, per formula, per config value. Example: upgrade cost lives ONLY in
  `EconomyMath.ComputeUpgradeCost` (`src/Shared/Util/EconomyMath.luau`), called identically from
  `PurchaseSystem.luau` (server) and `MainGui.luau`/`UISystem.luau` (client). Never reimplement it inline.
- Deliverable is real file diffs / real files. A prose "done" summary is not an acceptable deliverable
  and will be rejected on review.

## Standing process rule

**No task is marked done without Gabriel personally confirming a clean Roblox Studio boot** (zero errors
in both server and client Output) AND exercising the actual feature path that changed. Do not declare
something fixed based on code reading alone — this project's history has multiple cases of Luau parse
errors (unbalanced `end`, ambiguous statement breaks across line boundaries) and undefined-variable bugs
that were claimed "resolved" but were never actually run. If `luau-analyze` / `luau-lsp` is set up, run
it before claiming anything is done — but treat it as a pre-check, not a substitute for the Studio test.

## Confirmed real API surface — verify against source before adding new fields, don't assume

- **`Theme.luau`** (`src/Shared/UI/Theme.luau`):
  - `Theme.Colors`: `Cream, Blush, Lavender, Cocoa, Gold, Mint, Rose, Peach, Dusk, HeaderPink,
    BackgroundCream, PanelLavender, TextPrimary, TextSecondary, Success, Warning, Danger`.
    **There is no `AccentMint`** — this exact typo has recurred at least 4 times across the codebase.
    Always use `Mint`.
  - `Theme.Fonts`: only `Display` and `Body`. **No `Header`.**
  - `Theme.Padding`: `Standard`, `Small`, `Large` — these are raw `UDim` values, not tables. Use
    `.Offset` for the pixel number (e.g. `Theme.Padding.Standard.Offset`). Never `.Unaligned` or similar.
  - `Theme.Corners`: used as `Theme.Corners.Standard` / `Theme.Corners.Large` elsewhere in the codebase
    (same UDim-shaped pattern as Padding) — re-verify against source if you touch this.
- **`AssetIds.luau`** (`src/Shared/AssetIds.luau`): `CookieMain, CookieMini, Cupcake, Golden_Cookie,
  Achievements, DailyReward, Settings, WindowShadow, CloseButtonEgg`.
- **`Declare.luau`** (`src/Client/UI/Declare.luau`): named shortcuts only exist for `Frame, TextLabel,
  TextButton, ImageLabel, ImageButton, ScrollingFrame, UIListLayout, UICorner, UIPadding, UIStroke,
  UIGradient, UIAspectRatioConstraint, UIFlexItem, UISizeConstraint, UITextSizeConstraint`. Anything else
  (e.g. `UIGridLayout`) has no shortcut — use `Declare.New("ClassName")({...})`.

## Architecture notes

- `GameState.luau` (`src/Shared/State/GameState.luau`) wraps ECS-style components (`self.Currency`,
  `self.Upgrades`, `self.ClickerInput`) plus raw private fields (`self._stats`,
  `self._unlockedAchievements`, etc.). Client-side, it's used for optimistic prediction so clicks/currency
  feel instant — the server (`DataService` + `ProfileService`) remains the actual source of truth.
- `UISystem.luau` has two re-render paths: the `Changed` signal triggers a cheap, targeted update
  (`FastUpdateCurrency`-style); `StatsChanged`/`SkinChanged` trigger a full `Render()` that destroys and
  rebuilds the entire `MainGui` ScreenGui, including any currently open panel. Be careful firing
  `StatsChanged` casually — it's the expensive path.

## Open issues (as of last review)

- **Unresponsive panel buttons** (Settings / Achievements / Daily Reward): root cause not yet confirmed.
  Static review of `Declare.luau`, `CloseButton.luau`, `WindowPanel.luau`, and all three panel files found
  no code-level defect — the event-wiring pattern is identical to `Sidebar.luau`'s buttons, which are
  confirmed working in Studio. Suspected but unconfirmed: the `UIScale` pop-in tween in `WindowPanel.luau`
  starts playing before the panel instance is parented to the ScreenGui, which may leave `Scale` stuck at
  0. Don't attempt a fix until Gabriel reports back: (1) does the close button grow on hover, (2) does
  clicking the dark overlay outside the panel close it, (3) is anything printed in Output when a panel
  opens or its close button is clicked.

## Don't

- Don't read, search, or analyze anything under `/graphify-out/` — it's a cache for a different
  code-navigation tool (Graphify), in a custom format meant for that tool's own consumption. Reading it
  costs tokens with no benefit. Treat it as out of scope entirely (see `.claude/settings.json`).
