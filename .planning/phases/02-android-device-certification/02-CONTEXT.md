# Phase 2: Android Device Certification - Context

**Gathered:** 2026-09-25
**Status:** Ready for planning
**Source:** Manual discuss-phase session (the GSD `/gsd-discuss-phase` command was not installed; decisions were taken interactively and recorded in its format)

<domain>
## Phase Boundary

Take the current vertical slice described in `CLAUDE.md` (sections 1 to 16) from "passing on desktop" to
"certified on physical Android hardware". That covers the release gate that `CLAUDE.md` 12, 14 and 15 leave open:
on-device readability, frame time, thermals, touch/safe areas, lifecycle behaviour, and real two-device LAN
tactical play.

This phase does **not** add gameplay (Base deposit, persistent inventory, progression, shared camera). New
capability is allowed only where a certification gate needs it: the perf logger, the host-IP display and entry,
and host-background pause handling.

**Repository note:** the GitHub repo currently holds only `CLAUDE.md`, `project.godot` and `export_presets.cfg`.
The Godot sources, tests and assets live in the local Windows project (`C:\Users\heikk\Desktop\Claude\gpt_peli`).
Every build, ADB and device step runs there. Planning should either push the sources to this repo first or scope
every task to the local checkout.
</domain>

<decisions>
## Implementation Decisions

### Target hardware
- Certify on **the two Android phones the user owns**. Together they are the certification matrix and the two-device LAN pair.
- Record for each device: model, SoC/GPU, Android version, native resolution, refresh rate, and display cutout geometry. Findings are claimed only for these two devices.
- The export stays `arm64-v8a` only. A device that is not arm64 is out of scope, not a finding.

### Performance and thermal bar
- **Pass = p95 frame time ≤ 33.3 ms (30 FPS floor) sustained over a 20-minute session** that includes at least one full night horde wave, on both devices.
- 60 FPS (16.67 ms) results are logged and reported but are not required to pass.
- Thermal pass = no throttling collapse inside the 20 minutes. The p95 of the last 5 minutes must still meet the 30 FPS floor. Battery temperature is logged wherever the platform exposes it.
- Frame pacing matters, not only the average. Report p50/p95/p99 and the count of frames over 50 ms.

### Fix policy
- **Fix until green.** The phase is not complete until every gate passes on both devices.
- Fixes must respect the existing contracts. The fallback order for performance follows `CLAUDE.md` 10: first reduce weather and light energy through a quality tier, then light overlap and visibility culling. Never add a second full-screen pass or HDR 2D.
- A fix that would change the authority or protocol contract (`CLAUDE.md` 6) is escalated to the user before it is implemented.
- After any fix, the desktop gates must still pass (`SMOKE OK`, the focused gates, and the world render gate at `captures=25`).

### Performance telemetry
- Build an **in-game, debug-only performance logger**: an optional overlay plus a CSV written to `user://`, pulled with `adb pull`.
- Minimum columns: timestamp, frame time, FPS, draw calls, object/node count, game phase (day/night), and battery temperature when available.
- Stripped or disabled in non-debug builds. It must cost nothing measurable when off, and it may not run a second full-screen pass.
- A small host-side script (Python, under `tools/`) turns a CSV into the p50/p95/p99 summary, so a soak run's pass/fail is reproducible rather than eyeballed.

### Two-device LAN join
- **Manual IP entry.** When hosting, the host shows its LAN IPv4 on screen. Join LAN takes a typed IP. UDP port 8791 is unchanged.
- No discovery or broadcast, and no new Wi-Fi/multicast permissions. `permissions/internet=true` is expected to be enough, and this phase verifies that on real Wi-Fi.
- The certification run covers movement, gather/deplete, shared resource pool, build/place, towers and traps, auto-aim fire, and a full night wave across both devices. Every broadcast must be seen to stay consistent on both screens.

### Lifecycle
- **Host backgrounded:** the host pauses its simulation on `NOTIFICATION_APPLICATION_PAUSED`/focus loss. The client shows a "host paused" state. If the host has not resumed within a **~30 s grace window**, the client falls back to Solo through the existing `OfflineMultiplayerPeer` path. The exact constant is at Claude's discretion.
- Other required lifecycle cases (from `CLAUDE.md` 11): pause, background/resume on both host and client, controller disconnect, and late Player 2 join. Each is certified on device with an observed outcome recorded.
- **Client backgrounded:** at Claude's discretion. The default is that the host keeps simulating and the client's avatar idles. On resume the client picks up authoritative snapshots, or re-registers if the host dropped it.

### Readability judgement
- **Fixed checklist plus native-resolution screenshots** from `adb exec-out screencap -p`, committed as evidence and captured by day and by night on both devices.
- The checklist includes at least:
  - Heikki and Shane are distinguishable in greyscale.
  - Wood, Metal and Tech are identifiable.
  - The Base Core is the dominant warm focal point.
  - HUD counts, command plates and the build deck are legible.
  - Night play is readable.
  - Health bars read.
  - No control sits under a cutout, and every touch target is at least 44×44 logical.
- The user gives the final visual sign-off on each checklist item.

### Build under test
- A **fresh signed debug APK** rebuilt from the current export closure. The last APK predates the feedback stack.
- Before any device run, rerun the closure/export gates (201 resources / 202 dependencies, isolated closure load, inventory gate with zero forbidden entries, and APK v2/v3 signature verification).
- Release signing is out of scope for this phase.

### Claude's Discretion
- Grace-window constant, the "host paused" UI treatment, and client-background behaviour (within the defaults above).
- Perf logger sampling interval, file rotation, and overlay layout (it must not cover the HUD dashboard, minimap or controls).
- Structure of the certification report and evidence folder.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Contracts
- `CLAUDE.md` §6: authority boundary, ENet/UDP 8791, Offline fallback, `MobileControls` finger ownership and safe-area conversion
- `CLAUDE.md` §10: Mobile renderer budgets, the 1 full-screen pass rule, the quality-tier escalation rule
- `CLAUDE.md` §11: Android UX/accessibility contract, 44×44 targets, required lifecycle cases
- `CLAUDE.md` §12: headless/GPU gates, export closure and dependency counts, the last-APK status
- `CLAUDE.md` §14 and §15: completion matrix rows marked "device validation required" (the full list of gates this phase closes)

### Config
- `project.godot`: 480×270 `canvas_items` stretch, Mobile renderer, `emulate_mouse_from_touch=false`
- `export_presets.cfg`: Android preset, arm64-v8a, signed debug, immersive mode, `permissions/internet=true`

### External
- Godot 4.7 docs: exporting for Android, `NOTIFICATION_APPLICATION_PAUSED`/`RESUMED`, `DisplayServer.get_display_safe_area`, `Performance` monitors
</canonical_refs>

<specifics>
## Specific Ideas

- Every "Passing desktop; device validation required" row in the `CLAUDE.md` §14 matrix should end this phase as "Device-validated on <device A>, <device B>", with a pointer to evidence.
- `CLAUDE.md` records a desktop 1× capture as a worst-case bound for texture minification (§8). Device screenshots at native resolution are the first real test of that claim, so compare the resource icon anchors on device against the recorded 1× and simulated-4× figures.
- The soak run should be scripted where possible: a fixed route, a forced night start via the host command, and a fixed build set, so that runs before and after a fix are comparable.
</specifics>

<deferred>
## Deferred Ideas

- UDP LAN host discovery (needs multicast permissions and a host list UI) goes to a later networking/UX phase.
- Release keystore and release-signed certification go to the release phase.
- A 60 FPS requirement or a 30/60 quality-tier selector as a player setting goes after the baseline numbers exist.
- Wider device-matrix coverage (low-tier Mali, tablets, foldables) goes after this phase.
- Base Core deposit, shared co-op camera, persistent inventory, and progression are the next gameplay slices (`CLAUDE.md` §15).
</deferred>

---

*Phase: 02-android-device-certification*
*Context gathered: 2026-09-25 via manual discuss-phase*
