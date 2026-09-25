# Polish Pass + Skeleton Plan — 2026-09-25

Scope chosen by the owner: **polish pass first, then roadmap Phases 2–3**, with Blender / Poly Haven rebakes included if the cloud environment's network policy opens `download.blender.org`, `api.polyhaven.com` and `dl.polyhaven.org`.

This document is the audit behind that plan, the plan itself, and — as items land — the record of what shipped and how it was verified. It follows the measurement rules in `CLAUDE.md` 12: every claim is a gate verdict or a number off a capture, and every capture is judged at the size it delivers.

## 1. Audit

### 1.1 Gates (baseline, unchanged `master` at `db06241`)

Linux, Godot `4.7.1.stable.official.a13da4feb` (SHA-512 verified), Mesa lavapipe under Xvfb, through `tools/ci/run_gates.sh`: **import clean, 21/21 headless, 6/6 ENet (host + client × 3), 17/17 Mobile/Vulkan capture gates — 45/45 in 3 m 22 s.** Every count in `CLAUDE.md` 12 reproduced exactly (smoke 207, world map 169, health readability 76, VFX 154, start-menu layout 188, …). The repository is in excellent contractual health; the defects are in what the frame shows, not in what the gates assert.

### 1.2 The capture set does not show the player's view

`world_render_validation` frames 23 of its 25 captures between zoom 0.0092 and 0.45; only the two wilderness-ecology frames use the shipped `0.38`. That is right for reading layout and wrong for judging delivered pixels — the rule `CLAUDE.md` 9 states for bakes applies to the world too. So the first instrument this pass adds is **`tests/gameplay_tour_render_validation`**: twenty stops at exactly `zoom = 0.38`, a baked Heikki in every frame as the scale reference, no HUD or minimap, stops resolved from live obstacle nodes and `get_core_position()` so a layout change moves the camera instead of leaving a stale frame.

### 1.3 What the player sees (gameplay-zoom tour, day frames)

Occupancy = share of pixels departing more than 14 luma from their own 61-px neighbourhood mean — near zero on bare ground whatever its value.

| Stop | Occupied | Verdict at 1× |
|---|---:|---|
| camp_day | 17.6 % | Camp is a 70-px decal on uniform mud. No clearing reads: the ground under the bowl is the same as the ground outside it, and canopy exists only at the top edge. |
| camp_outskirts | 6.5 % | A full screen of nothing but mottled ground and one node. |
| city_block | 5.3 % | A full screen of flat grey with a building corner at the edge. |
| city_choke | 6.8 % | Tyre, barrel, two hydrants on flat grey. Not a choke. |
| mall_shell_edge | 18.5 % | **The long shell's "foundation" is a flat teal slab with a dark 26-unit frame and a pale inner stroke.** At 0.38 it fills two-thirds of the frame and reads as a UI panel, not a building. |
| mall_pylon | 35.4 % | A city-building bake standing on the same framed teal panel plus a "glass band" rectangle — a display case. |
| mall_corridor / road_* | 17–23 % | Road bed is good; **ground cracks are straight black T-shaped strokes** (18 units ≈ 7 px wide at 0.38) that read as dropped sticks or poles, not cracks. |
| road_junction | 17.5 % | The vertical road's dark outer band is drawn across the horizontal road's bed: the junction reads as two strips laid on top of each other. |
| west / east village | 12–15 % | East village is West village translated +16,100 in X (same pole run, same fence ring, same house corners). |
| forest_interior | 12.4 % | **No tree in frame.** Metsä places 3–4 colliding trees per 2,048-unit cell — about one per screen — so the forest does not read as forest at the player's zoom. |
| wilderness | 4.8 % | Mottled ground and three small rocks. |

Two consequences drive the plan. First, the single largest quality problem at 1× is **emptiness**: most stops are one or two subjects on a whole screen of ground. Second, the defects that *are* drawn are vector primitives whose authored unit (world units) never met the delivered one (screen pixels at 0.38) — the same species of mistake `CLAUDE.md` 8 records for outline widths, arriving on the mall foundation and the crack strokes.

### 1.4 Product gaps confirmed in source

- **Accessibility**: `CameraShake2D.intensity_scale`, `WeatherOverlay.damage_intensity_scale` and `WeatherOverlay.intensity` exist; nothing sets them, nothing persists them (`grep` for `ConfigFile` / `user://` over `src/` returns nothing), and there is no pulse-amplitude scale at all. `CLAUDE.md` 11 requires all four before content locks them in.
- **Lifecycle**: no handler for `NOTIFICATION_APPLICATION_PAUSED` / focus loss anywhere under `src/`. A backgrounded Solo session keeps simulating the horde against an absent player, and held touches are never released.
- **Duplicated literals** (Phase 2 grep traps, confirmed): the camp seat `Vector2(9950, 2400)` lives in `world_map_2d.gd`, `world_background_decor_2d.gd` and `tests/world_render_validation.tscn`; pocket tables live separately in `world_background_decor_2d.gd`, `world_ambient_scenery_2d.gd` and `world_wilderness_accent_2d.gd`.

### 1.5 Tooling in this environment

Godot runs (and the Godot MCP now resolves it through `/usr/bin/godot`). Blender cannot: no Blender instance for the Blender MCP to attach to, and the network policy returns 403 for `download.blender.org`, `api.polyhaven.com` and `dl.polyhaven.org`. Bake items are therefore listed in section 4 and are attempted only if those hosts become reachable.

## 2. Polish pass (presentation first; collision, flow, seeds and RPC unchanged unless stated)

| ID | Item | Owner | Proof |
|---|---|---|---|
| P0 | Gameplay-zoom tour capture gate, added to the runner | `tests/gameplay_tour_render_validation` | `GAMEPLAY TOUR RENDER OK \| zoom=0.38 \| captures=20` |
| P1 | Ostari foundation reads as a broken concrete apron on the ground, not a framed panel: no hard frame, no inner stroke, value within the urban ground band, weathered edge and rubble | `WorldObstacle2D._draw_mall_foundation` | tour `mall_shell_edge`, `mall_pylon`; foundation-to-ground luma ratio |
| P2 | Ground cracks become tapered, jagged, low-contrast fissures with a lit lip, sized in screen pixels at 0.38; positions and RNG draws unchanged | `WorldBackgroundDecorChunk2D` crack pass | tour road/mall frames; decor counts unchanged in `world_map_validation` |
| P3 | Metsä reads as forest: canopy-wall rim around the camp bowl and denser visual-only canopy in the forest belt; camp ground reads as a trodden clearing | `WorldAmbientScenery2D` / camp clearing ground layer | tour `camp_*`, `forest_interior`; occupancy; `forest_density` world frame |
| P4 | East Kylät gets its own composition (the contract's "abandoned rest": graveyard plot, different yard geometry), not West translated | `BesprenWorldMap2D._build_village_east` | tour `east_village_*`; `world_map_validation` updated deliberately |
| P5 | Accessibility settings — camera shake, damage flash, weather intensity, pulse amplitude — on a StartMenu panel with 44 × 44 targets, persisted to `user://settings.cfg`, applied by `GameWorld` | new `GameSettings` (static, no autoload), `StartMenu`, `GameWorld`, `CorePulseDriver`, `ResourceNodeView` | new headless gate; start-menu layout gate; a capture of the panel |
| P6 | Lifecycle: Solo pauses on background / focus loss and resumes; every session releases held touches on focus loss; LAN host-pause stays with the device-certification phase (protocol change) | `GameWorld` | headless lifecycle checks in the new gate |

## 3. Roadmap Phases 2–3 (after the polish pass)

- **Phase 2 — Authored Skeleton.** A shipped `WorldCompositionContract` Resource that `BesprenWorldMap2D` consumes: camp seat, road routes with grades, district regions, and one pocket table set that the three dress layers read instead of their own copies. Every duplicated camp literal resolves through it. Add the contract's dirt spur (camp bowl → nearest asphalt spine), exempted from the camp road-clearance rule as the one authored crossing. Extents, seeds, the 87 IDs and the gather rules stay as they are.
- **Phase 3 — Readable Road Hierarchy.** Three grades at 1× — asphalt spine, dirt branch/spur, wilderness perimeter track — through width, edge and negative space, and junctions drawn as one surface (all outer bands before any inner band).

## 4. Blender / Poly Haven items (only if the hosts become reachable)

FIR-01 fir canopy mass (two-clone clump or a denser CC0 conifer), TINT-01 pine rebake so `WILD_TREE_TINT` can be dropped, and the D-15 village fence (a timber fence bake to replace the hedgehog barricade). Each follows `CLAUDE.md` 9: rebake through the checked-in scripts, re-run the manifest writer, re-derive every `Rect2` copy by script, judge at delivered size.

## 5. Record

Filled in as each item lands.
