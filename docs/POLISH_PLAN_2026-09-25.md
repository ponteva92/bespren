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
| P0 | Gameplay-zoom tour capture gate, added to the runner | `tests/gameplay_tour_render_validation` | `GAMEPLAY TOUR RENDER OK \| zoom=0.38 \| captures=20` (25 once the pass added stops) |
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

Everything in sections 2 and 3 shipped. Nothing in section 4 did, because the hosts stayed closed. All of it is on `claude/fervent-brown-73kgeq`.

### 5.1 What shipped

| ID | Commit | What changed at 1× | Gate evidence |
|---|---|---|---|
| P0 | `fff172b` | New `gameplay_tour_render_validation`: stops at exactly `zoom = 0.38`, a baked Heikki at a fixed offset for scale, no HUD, stops resolved from live nodes. Grew from 20 to 25 stops as the pass added places (camp spur, east rest plot, east hamlet, Metsä near the camp, forest edge track). | `GAMEPLAY TOUR RENDER OK \| zoom=0.38 \| captures=25`, in the runner |
| P1 | `05fc122` | The Ostari footprint is a lot, not a panel. It is drawn on a behind-parent child that wears the road grain shader pointed at the terrain atlas's concrete cell, so it has the urban ground's slab structure and follows the night grade. It is broken up by expansion joints, stains, weeds at seam crossings, fallen beams and rubble mounds, and a three-row berm of broken chunks straddles the collision edge. No frame, no inner stroke. | local environment 48 (+1: every Ostari footprint draws on that child with that material) |
| P2 | `3dc19a7`, `c5d28fd` | Two shared languages in the `GroundShadow` pattern. `GroundFissure` is a groove that meanders, tapers to hairline tips and has a lit lip down-right of the core (a stick's shadow would fall the other way). `GroundRubble` is an irregular piece with a drop shadow, a darker broken side and a lit top. Decor cracks, the road's transverse and longitudinal cracks and the procedural-building fallback all draw through `GroundFissure`. Decor cracks meander in four legs and fork near a tip. Decor rubble is a heap of one piece plus two or three satellites. `build_crack_courses` is the one builder that both the chunk and the published envelopes read. | Placement, RNG draws, counts, collision and flow unchanged: world map 169, smoke 207 at the time. Closure 204 → 206 |
| P3 | `895e376` | `WorldForestUnderstory2D` adds saplings, shrubs (the two dense firs cropped above the bole), ferns, stumps, moss rocks and deadfall at 70–330 units, one hashed candidate per 230-unit cell. It leaves an empty bowl inside 1,180 units of the camp, builds a wall out to 2,150, scales the forest fill by the biome mask and thins out in far wilderness. `WorldCampClearing2D` lays trodden earth and worn paths to each satellite. Both are visual-only, on their own seed streams, and configured after the canonical pipeline. | World map: 2,572 elements; 143 on the rim; forest gameplay frames average 7.8 understory subjects over 31 frames, none under 3; no overlap with any footprint or road verge; identical rebuild. Placement 62 ms |
| P4 | `38b4669` | East Kylät is its own layout: a three-house hamlet west of its dirt road, a caretaker's house to the north-east, a three-pole line with a gap, and a walled grave plot east of the road. The plot has six wall runs, every one stopping 150 units short of its neighbour. `WorldGraveyard2D` draws rows of headstones and crosses over sunken mounds, some fallen or missing, with a path down the middle. | World map: 0 translated and 0 mirrored matches with the west; plot openings and interior walkable; 121 markers inside. Flow-mask pin and dressing positions re-pinned on purpose |
| P5 | `5d1e50a` | `GameSettings` (typed, no autoload) stores four quarter-step scales (camera shake, damage flash, weather, glow pulse) in `user://settings.cfg`. An OPTIONS button on the StartMenu opens an opaque sheet with 44 × 44 steppers; zero reads OFF and each step saves immediately. `GameWorld` applies the scales to `WeatherOverlay` (damage wash plus a new `intensity_scale`), the local `CameraShake2D`, `CorePulseDriver.pulse_scale`, and a `bespren_pulse_amount` global shader uniform read by the toon outline, the aura and the scale glow. At zero a pulse holds at its own mean, so turning it off stops motion without dimming. | New `settings_lifecycle_validation` (35) measures each effect at zero rather than reading the property back. Start-menu layout 212, start-menu capture `captures=4` |
| P6 | `5d1e50a` | Application-paused or focus-out releases every held touch and zeroes movement in all modes. Solo also pauses the tree and resumes on return. Leaving the world never leaves its own pause behind. | Same gate, lifecycle half |
| Phase 2 | `f85a5eb`, `b45780d` | `res://data/world/world_composition.tres` (`WorldCompositionContract`) holds the camp seat and satellites, nine road routes with grades and names, biome paint, five shout nouns and thirteen pocket tables. `BesprenWorldMap2D` preloads it, validates it at build and paints from it. Every camp literal and pocket table now resolves through it. The contract's dirt spur (route 9, `camp_spur`) runs from the camp's open ring, 465 units from the refuge, to the east-west spine: 2,229 units, and the one road allowed inside the 1,600-unit seclusion ring. The clearing moved to the ground layer, under the roads, so the spur can be seen leaving it. | World map: composition consumed and internally consistent; no world script still authors a pocket table or the camp literal; spur checks. Refactor proven output-identical: stable captures byte-identical, flow and understory hashes held. Closure 212 |
| Phase 3 | `dde2d55` | Three grades read apart. The perimeter track is a 230-unit bed (88 screen pixels, against dirt's 137 and the spine's 160) with a soft verge and a grass crown between two ruts. It keeps the dirt corridor for every clearance rule, so nothing seeded moves. Every shoulder is drawn before any bed, so junctions read as one surface, and paint lines and dashes stop inside it. Free ends taper over 300 units into a ragged, fading half-ellipse cap. | World map 226: three grades with bed widths stepping 420 / 360 / 230; 61 + 61 two-pass chunks; the spur's camp end is free and capped; the closed loop has no free ends; exactly five capped ends |

### 5.2 Gates at the head of the pass

Linux, lavapipe, `tools/ci/run_gates.sh`: **import clean, 22/22 headless, 6/6 ENet, 18/18 capture: 47/47.** Against the baseline: `settings_lifecycle_validation` (35) and `gameplay_tour_render_validation` (25 captures) are new. World map 169 → 226, local environment 47 → 48, start-menu layout 188 → 212, start-menu capture 3 → 4. The export closure is 204 → 212 resources, with 213 dependencies. Every other count is unchanged.

### 5.3 Before and after at the gameplay zoom

Occupancy is measured as in section 1.3. "Before" is the baseline tour at `db06241` and "after" is the tour at `dde2d55`. Occupancy counts detail, not quality: the camp and the road junction went *down* because the fixes removed noise (a mottled bowl, a shoulder band laid over the carriageway). Each verdict below is taken off the frame.

| Stop | Before | After | Frame verdict |
|---|---:|---:|---|
| camp_day | 17.6 % | 13.4 % | The refuge sits on trodden earth, not uniform mud, with the rim wall entering at the top edge. The frame is quieter, which is the point of a bowl. Mean luma 52.0 → 56.4 |
| camp_outskirts | 6.5 % | 9.6 % | The rim wall is in frame instead of bare mud |
| forest_interior | 12.4 % | 34.6 % | Reads as forest. The stop moved from (-12000, 3000) to (-10500, 2400) to sit inside the belt rather than on its edge |
| mall_shell_edge | 18.5 % | 20.1 % | A bermed concrete lot instead of a framed teal panel. Mean 58.3 → 65.7 |
| mall_pylon | 35.4 % | 34.1 % | The framed teal case is gone. The bake stands on slab inside a rubble berm. The bake itself still reads as a brown box, which is Phase 6 set-piece work |
| road_junction | 17.5 % | 12.9 % | One surface. The north-south shoulder no longer crosses the east-west bed |
| perimeter_track | 12.8 % | 9.1 % | The narrow grassy ride reads as the lowest grade |
| dirt_branch | 13.9 % | 13.2 % | Cracks read as grooves, not sticks |
| east_village_yard | 12.3 % | 9.1 % | A different place from the west yard (hamlet, not a translated copy) |
| west_village_yard | 14.2 % | 14.2 % | Unchanged, as intended |
| city_block / city_choke | 5.3 / 6.8 % | 5.3 / 7.0 % | Unchanged. Kaupunki's emptiness is Phase 4 work |
| wilderness | 4.8 % | 4.8 % | Unchanged. The far wilderness is left as "the quieter empty" on purpose |
| east_rest_plot / east_hamlet / camp_spur / metsa_near_camp | – | 6.6 / 17.5 / 14.6 / 19.5 % | New stops |

**Noise floor.** Run twice on the same code, 12 to 13 of the 25 world captures differ: the camp's light and aura, resource pulses, actor frames, the overview, the long Ostari shell, the west village, and sometimes wilderness density. Every "output-identical" claim above was judged against that floor, not against a single run.

### 5.4 Not done, and why

- **FIR-01, TINT-01, D-15 fence.** Rechecked at the end of the pass: `download.blender.org`, `api.polyhaven.com` and `dl.polyhaven.org` still return `403` on CONNECT from the environment proxy, and the Blender MCP has no Blender instance to attach to. The shrub half of the forest problem was covered without a bake by reusing the approved fir frames. The canopy mass, the pine hue and the fence silhouette still need Blender.
- **LAN host pause.** A backgrounded host releases touches but does not pause, because pausing would stall its client's snapshots. A grace window is a protocol change, and it stays with device certification.
- **Kaupunki and the far wilderness** are still sparse at 1×. That is Phase 4's district-job work, and the contract wants the wilderness quiet.


## 6. Follow-up: roadmap Phase 4, district jobs

Requested after section 5 as "implement". The Blender and Poly Haven hosts were still refused (403 on CONNECT), so the next unblocked item was roadmap Phase 4 (DIST-01): each district's job readable at 1× without a label.

### 6.1 What shipped

| District | What changed at 1× | Gate evidence |
|---|---|---|
| Kaupunki: city choke | 15 `CityStreetWall_*` shells line the asphalt spine with faces on a kerb line 420 units off the centreline, broken by alleys. A shallow storefront stands in front of each set-back ruin. The `city_choke` landmark moves onto the spine at (-8192, -8950), where both frontages step in to 360 and run unbroken for the landmark's 1,200-unit diameter. Built after every other obstacle, so no stable seed moved. | World map: frontage in frame along 79.3 % of the spine (was 0.0 %), both sides ≥ 45 %, the choke unbroken and square, no wall on a road or another footprint, and neither spine flow column blocked. Flow hash re-pinned on purpose |
| Kaupunki: street fabric | `WorldUrbanFabric2D` adds pavements with slab joints, broken slabs, weeds and drains, a lit kerb over a gutter shadow, and a rubble spill across the west pavement at the choke. Visual only, at z -20 after the roads. | World map: pavement between bed and kerb line, spill off the carriageway, no physics |
| Ostari: mall salvage | Two rows of 17 parking bays either side of the mall road, with worn paint, wheel stops, oil stains and an asphalt wash; five abandoned cars stand askew across them, always drawn as cars. | World map: 34 bays, rows off the road and clear of every shell, pylon and ruin, 5 cars in bays with the car frame |
| Kylät: village quiet | `WorldVillageYards2D` gives 7 of 8 village houses a yard: trodden apron, worn trail, woodpile with chopping block, fenced furrow plot, washing line. Every item is placed on open ground only. | World map: 7 of 8 yards, 6 woodpiles, 2 plots, every item clear of footprints and roads, no physics |
| Metsä: forest threat | No change in this phase: the understory and canopy wall from P3 already carry it. | – |

Two couplings were fixed at their source. The ambient scenery now seeds each zone on its own (with one shared stream, the city walls had re-dealt the forest and camp dress). The wild-atlas context gate now tests building-class obstacles against `WorldObstacle2D.get_visual_bounds()`, because pocket 2 briefly passed with its card hidden behind an Ostari chain-link panel. The tour gate clears its old captures before writing. Details are in `docs/art-log/16-world.md`.

Gates: **47/47**. World map 226 → 252; tour 25 → 29 captures (new stops: city frontage, city choke at night, mall car park, west homestead); wild-atlas context unchanged at `pockets=9 | unhostable=1 | captures=36`. Every other count is unchanged.

### 6.2 Before and after at the gameplay zoom

"Before" is the tour at `bef4a27`. `city_choke` moved with its landmark, so its "before" is the old seat at (-9200, -6000).

| Stop | Before | After | Frame verdict |
|---|---:|---:|---|
| city_street | 10.5 % | 22.7 % | Pavements, kerbs and drains on both sides, a building on each kerb |
| city_choke | 7.0 % | 35.3 % | The street pinched between two unbroken frontages, debris across the west pavement |
| city_choke_night | – | 18.2 % | Pavement, kerb and spill fall to the blue hour with the ground |
| city_frontage | – | 20.5 % | Walls on both sides broken by an alley |
| city_block | 5.3 % | 5.3 % | Unchanged: the large blocks are still oversized single bakes (Phase 6/9) |
| mall_car_park | – | 22.8 % | Reads as a car park: bays, wheel stops, oil stains, an abandoned pickup askew |
| mall_corridor | 22.7 % | 19.0 % | The mall road with the bay mouths at the frame edges; the asphalt wash lowers local contrast |
| west_homestead | – | 8.6 % | Woodpile with chopping block and a fenced furrow plot. Low occupancy, because furrows are low-contrast detail |
| east_hamlet | 17.5 % | 18.9 % | Woodpile, chopping block and washing line beside the hamlet house |

Rendered with and without the street walls against a second same-code run, stops outside Kaupunki change within the tour's same-code floor (0 to 0.4 %, camp frames 4 to 5 % from the light pulse).

### 6.3 Not done, and why

- **Ostari's narrow approach** exists only in collision: two gaps of about 1,000 units round the west pylon. The contract's reading of it, the missing-tooth mall gate, is a hero set piece and is carried to Phase 6 (SETP-01).
- **Kaupunki's six large blocks** still draw as single oversized bakes that read as dark slabs at 1× from the back lots.
- **Bakes**: FIR-01, TINT-01 and the D-15 fence are still blocked on the network policy.
