[Read COOKIEGAME_CONTEXT.md first — it has full project state, architecture rules, and prior fixes. Then proceed.]

[CONSTRAINT: Zero narration. Output = root-cause diagnosis (brief) + diff/full files + verdict + Studio test checklist. No code echoes.]

## BATCH 2 — Critical regression + broken features + UX polish

### P0 — CRITICAL: Currency resets to 0 mid-session + intermittent click stall
Symptom 1: Player accumulates cookies (observed near 10k), balance snaps back to 0 automatically without any reset/purchase action.
Symptom 2: Manual clicks intermittently stop registering for a few hundred ms, then resume — suspected correlation with the 5s GetBalance reconcile tick added in the last passive-income fix.

Investigate (most likely self-inflicted by ServerPassiveSystem/reconcile, added last session):
1. Race at join: does the reconcile loop (ClientEntry, every BALANCE_RECONCILE_INTERVAL) fire before DataService's profile has finished loading for that player? If GetBalance returns 0/nil during that window, client SetCurrency(0) would zero a legitimate optimistic balance.
2. ServerPassiveSystem.lastAccrual: confirm it's correctly scoped per player (no shared/leaked state) and that no code path sets data.currency directly to 0 outside of intentional resets.
3. Click stall: check if the reconcile InvokeServer call or its callback blocks/yields the click input pipeline (ClickSystem/BatchedClicks) on the client, or if Heartbeat-based accrual on the server causes any throttling correlating with the ~5s cadence.

Diagnose AND fix in this response (not diagnosis-only) — currency loss is severe.

### P1 — Achievements completely broken (no achievement registers)
Regression. Investigate whether AchievementService's progress-check trigger is still wired to a live signal/event after the StatsChanged → _refreshStats refactor (Item 3a) — confirm the exact event AchievementService listens to still fires with the same semantics post-refactor. Fix the wiring if broken.

### P1 — Golden Cookie never spawns
Never confirmed working. Investigate GoldenCookieController's server-side spawn loop: is it initialized in ServerEntry? Check RNG/spawn-interval values and any guard condition that might never evaluate true. Fix if found.

### P2 — Daily Reward: no claimed-day indicator
After claiming, no visual confirmation (e.g., green checkmark) that today's reward was collected. Add a per-day claimed-state visual in DailyRewardPanel, driven by the server's claimed-days record. Must persist across reopens.

### P2 — Menu exclusivity (new feature)
If any panel is open and the player clicks a button to open a different panel, the currently open panel must close and the newly requested one opens — single active panel at all times.
Must be robust against:
  - Autoclicker spam (rapid repeated open requests must not break state or stack panels).
  - Duplicate-open race conditions (two open requests resolving concurrently must never show 2+ panels at once).
Implement via a single-active-panel guard in UISystem, using a generation-token/in-flight-request lock (same pattern as fast-buy).

### P2 — "Claim Reward" button font is blurry
Investigate Font/FontFace and TextScaled configuration on the Daily Reward panel's Claim Reward button — likely a resolution/scaling mismatch.

---


Proceed with 6.1 → 6.2 → 6.3 → 6.4. For 6.5, ask Gabriel (no code change without decision).

## Test checklist (Gabriel runs after this batch)
1. Let passive income run to 10k+ without any purchase — confirm balance does NOT reset to 0.
2. Rapid-click for 30+ seconds — confirm no stall/pause in click registration.
3. Trigger an achievement condition — confirm it registers and shows in the Achievements panel.
4. Wait for Golden Cookie spawn — confirm it appears and is clickable.
5. Claim Daily Reward — confirm a checkmark/claimed indicator appears, persists after closing/reopening panel.
6. Open Achievements, then click Daily without closing Achievements — confirm Achievements closes, Daily opens, never both visible. Repeat rapidly — confirm no duplicate panels.
7. Open Daily Reward panel — confirm "Claim Reward" text is crisp, not blurry.

Proceed with diagnosis + fix for all items above. No narration.