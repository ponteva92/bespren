# World Map Redesign Contract — Locked Target Anatomy

Contract date: 2026-09-19
Scope root: `C:\Users\heikk\Desktop\Claude\gpt_peli`
Runtime target: Godot 4.7.1 Mobile, 2D, 480×270 landscape
Requirement: CONT-01 (docs-only). Sibling census: `docs/WORLD_MAP_AUDIT.md`.

This is the to-be walking-skeleton half of CONT-01. Phase 2 consumes it as composition intent. It is not layout code, not a camera scene, not a `WorldCompositionContract` Resource, and not a pixel proof. Live constants quoted here are current implementation facts from the audit; they are not frozen-at-pixel camp seats.

## Banner

Phase 1 is documents, not world-authoring (D-25, D-28). Reviewer opens this file and the audit. `git diff --name-only -- src/world/` must print nothing for this slice.

**Frozen this phase (do not bump, do not edit `.gd`):**

- Playable extents stay a centered `14 × 14` macro-grid, `2048`-unit cells, exact `PLAYABLE_HALF_EXTENT` ±14,336 (`Rect2(-14336, -14336, 28672, 28672)`). Shrinking or growing the world is out of scope.
- No `src/world/` layout edits, no new atlas `Rect2`, no scenery / cover / resource count changes in this slice.
- `BesprenResourceScatter2D.LAYOUT_VERSION` stays `2`.
- `BesprenWorldMap2D.WORLD_BUILD_SEED` stays `0xB35E7E`.
- Gather rules stay 87 deterministic IDs, 3–5 host-validated interactions, one-unit yield on completion only. `DEFAULT_SCATTER_SEED` stays `0x5CA77E2`.
- Peer-one RPC stays canonical. Clients submit movement intent or the existing `interact` command; they never submit a trusted final position, resource ID, harvest amount, collision result, or world-layout mutation.
- Presentation never writes simulation. Collision, flow-field raster, spawn rejection, and host motion stay on `WorldObstacle2D` / `BesprenWorldMap2D`. Dress layers (`WorldBackgroundDecor2D`, `WorldAmbientScenery2D`, `WorldWildernessAccent2D`, `WorldGroundCover2D`) remain visual-only.

Camp *job* is locked (secluded Metsä, dirt spur, hero clearing, three satellites as furniture). Camp *coordinates* are not frozen-at-pixel: D-22 allows the refuge to slide inside Metsä in Phase 2. Do not treat audit `STARTING_CAMP_POSITION = Vector2(9950, 2400)` as the target pin.

**Non-negotiable production contract** (from `docs/AAA_VISUAL_REDESIGN_AUDIT_2026-09-16.md`; item 3 is a later-phase promotion pipeline and is not copied here):

1. Runtime remains 2D: no raw GLTF, Blend, PBR graph, Node3D, or source-vault reference enters the export closure.
2. Existing host authority, ordered snapshots, collision, flow field, placement grid, 480×270 logical layout, and 44 px touch contracts are preserved.
4. A green headless or desktop-GPU test is not Android, touch, thermal, audio, lifecycle, or two-device LAN certification.
5. A visual veto overrides a numeric pass.

Phase 1 restates the veto and forbids new atlas `Rect2` / wild non-tree promotion. It does not run a provenance-import-capture promotion pipeline.

Proof of this slice: heading completeness against the fifteen-section outline, live-constant quotes grounded in the audit, empty `src/world/` path filter. Not Godot. Not Android.

## Camp

Base Core stays a secluded Metsä refuge, not a road-junction camp (D-01). The player does not spawn on asphalt. The forest wall is the edge of the bowl; the road is outside it.

**Dirt spur (D-02).** Player leaves camp on a dirt spur that meets the asphalt spine. The spur is the readable exit. The audit eight-route table records **no spur today**: eight polylines, none terminate at the current camp. This contract **adds** the spur as a Phase 2 route, not as an existing polyline. Do not write a new `Vector2` for the spur join. Relative language: spur from the clearing bowl to the nearest asphalt spine, length short enough that the 30s loop remains a tight Metsä circuit (D-24), not a commute.

**Hero clearing (D-03, D-04).** One empty bowl holds: Base Core, three camp satellites as furniture (bedding, supply cache, medical cache), and the nearby teaching salvage pocket. Satellites stay inside the bowl; they are not distant stamps in the trees. Forest wall reads as the rim. Amber Gold (`#FFB52E` PointLight2D + aura) is the only dominant warm weenie. No second Amber Gold competitor (D-10).

**Slide inside Metsä (D-22).** Camp may move inside Metsä in Phase 2. It remains secluded, remains on a dirt spur, remains a hero clearing. Extents stay ±14,336. Phase 2 greps every camp-position consumer, including the duplicate `WorldBackgroundDecor2D.CAMP_POSITION` literal the audit names as a grep trap. This file does not pick the new seat.

## Natures

Metsä's job is canopy wall plus sparse interior (D-05). Camp is the one true clearing. The wall is threat mass at the rim; the interior is walkable sparse, not a fifth urban district.

**Two natures, not a fifth district (D-06, D-07).**

| Nature | Job | On the 30s loop? |
|--------|-----|------------------|
| Metsä (near camp / roads) | Threat canopy, sparse interior, camp clearing, dirt spur, teaching pocket, Metsä threat weenie | Yes — the whole 30s circuit lives here |
| Far wilderness | Quieter empty; the 10-minute empty beyond the circuit | No. The 30s loop does not enter far wilderness |

The 30s loop stays in Metsä (D-07). Far wilderness is the long empty a 10-minute Ostari commute may skim; it is not a named district and it is not a shout noun.

**FIR-01 named, not solved (D-08).** Sparse fir still reads as a stalk with branch tiers rather than a conifer mass at 1×. Geometry clip removed the hexagonal mound; canopy density is a subject problem a clip cannot address. This contract cites the 1× veto. It does **not** require a mass language now. Do not promote wild non-tree frames. Five shipped tree yaws in `WILD_TREE_REGIONS` only. Salvage atlas has no `src/` consumer.

## Roads

Three readable grades at 1× (D-20). The look is the contract; a third `dirt_flags` enum is Phase 3 (ROAD-01), not this file.

| Grade | Job | 30s path? |
|-------|-----|-----------|
| Asphalt spine | Way-home. Every district exit hits it. Follow it to the dirt spur and camp (D-23) | Short readable segment only — not a commute |
| Dirt | Camp spur (new) + village paths | Spur is beat 2 of the 30s circuit |
| Wilderness perimeter | Exists; closes the far belt | No. Not the 30s path |

**Current graph (audit, not target).** `BesprenWorldMap2D._build_road_network` authors eight polylines. `dirt_flags` is `PackedByteArray([0, 0, 0, 0, 1, 1, 1, 1])` — four asphalt, four dirt. Perimeter (route 6) is dirt like the villages. Widths today: asphalt outer 540 / inner 420; dirt outer 480 / inner 360. Three visual grades at 1× are the target look; code today has two flag values. Do not add a ninth live route in this census sense — the dirt spur is the Phase 2 invention (audit: "What the contract must invent" item 1).

**Asphalt always leads home (D-23).** District weenies are local nouns, not compasses. Silhouettes plus Amber Gold confirm near camp. The minimap is not the way-home. Shipping HUD keeps the `72 × 54` minimap; review captures hide it.

Roads remain ground-layer presentation at `z_index = -20`. Collision and flow stay canonical. Phase 1 does not retune widths.

## District jobs and topology

Keep both Kaupunki and Ostari. Keep two geographically separate villages. Seats may rearrange on the locked 14×14 grid (D-21). Compass seats (NW city / NE mall / south villages / Metsä wrap) are **not** frozen. Sketch relative topology — named places and connections — not GDScript cell coordinates.

Neither Kaupunki nor Ostari sits on the 30s Metsä loop (D-16). Ostari owns 10-minute salvage density (D-17). Metsä's 30s pocket is teaching / nearby only. City and villages may hold sparse nodes but not the salvage identity.

| Place | Job | Topology (relative) | Shout noun |
|-------|-----|---------------------|------------|
| Camp | Secluded Metsä hero clearing | Inside Metsä, off the asphalt, dirt spur to nearest spine | Amber Gold (only dominant warm) |
| Metsä (near) | Canopy wall + sparse interior + 30s circuit | Wraps camp; threat weenie and teaching pocket stay near the spur / short asphalt read | Metsä threat weenie |
| Far wilderness | Quieter empty (10-minute empty) | Beyond the Metsä circuit; not a fifth district | none |
| Kaupunki | Dense urban choke | Hits the asphalt spine; dense shells, sightline breaks | city choke |
| Ostari | Mall salvage behind mall gate | Hits the asphalt spine; 10-minute commute through the missing-tooth gap | mall gate |
| West Kylät | Quiet yards | Separate dirt path to asphalt; not collapsed onto east | west yard |
| East Kylät | Graveyard / abandoned rest | Separate dirt path to asphalt; same quiet family, different job | **none** |

**Villages (D-13, D-14).** Two different jobs in the same quiet family. West = quiet yards (named west yard). East = graveyard / abandoned rest (unnamed). East does not steal Ostari salvage. Do not collapse into one cluster with two yards.

**Mall gate (D-18).** Gap in a long shell (missing tooth), not a glowing vertical prop. Hero dressing later only if the gap already reads.

Fence vs house projection mismatch is named, not solved (D-15). West yard reads by silhouette and negative space, not fence-as-hero.

## Five shout nouns

Sparse list of **exactly five** (D-09, D-11). Silhouette first, hue secondary (D-10). No world-space nameplates. No second Amber Gold competitor. East village has no shout noun. Salvage pocket is a place, not a fifth weenie (D-12). Landmark table has five rows, not six.

| # | Noun | District | Role | Silhouette language |
|---|------|----------|------|---------------------|
| 1 | camp Amber Gold | Camp / Metsä | Refuge weenie; 30s beat 1 | Warm pulse + camp mass. Only dominant Amber Gold in the world |
| 2 | mall gate | Ostari | Wayfinding, not a 30s beat | Gap in a long shell (missing tooth). Not a glow mast (D-18) |
| 3 | west yard | West Kylät | Wayfinding, not a 30s beat | Negative space + homestead silhouette. Not fence-as-hero (D-15) |
| 4 | city choke | Kaupunki | Wayfinding, not a 30s beat | Dense urban mass that breaks the sightline |
| 5 | Metsä threat weenie | Metsä | **30s named landmark** (D-12) | One colliding Metsä mass readable at gameplay zoom 0.38. Not Amber Gold. Not a tree stamp. Do not pick `VisualKind` or atlas `Rect2` |

Mall gate / west yard / city choke are wayfinding nouns. The 30s-loop named-landmark beat is only the Metsä threat weenie. `WorldObstacle2D` remains the single obstacle class; a later weenie adds `VisualKind` + crop, never a second class.

## 30s loop beats

Tight Metsä circuit (D-24). All beats stay near camp inside Metsä. Asphalt appears as a short readable segment, not a commute. Ostari is not on this loop.

1. Camp hero clearing (Amber Gold weenie)
2. Dirt spur (readable exit, D-02)
3. Short asphalt read (not a commute)
4. Metsä threat weenie (D-12 named landmark)
5. Nearby teaching salvage pocket (not Ostari)
6. Threat approach then back along spur

A stranger at 480×270 should be able to point this order with the minimap hidden (LOOP-01 / READ-01 land in Phases 7–8). Phase 1 only names the beats.

## 10-minute loop

Asphalt spine commute to Ostari mall salvage through the mall-gate gap. Ostari owns salvage density (D-17). Player leaves the Metsä circuit, follows asphalt, reads the missing-tooth gate, salvages inside the mall, and follows asphalt home to the dirt spur. Far wilderness may be empty along the way; it is not a salvage identity and not a 30s beat.

## Salvage and threat pockets

Stub for Task 2: pocket jobs only (teaching near camp; Ostari 10-minute density; city/villages sparse); 87 IDs / 3–5 / one-unit frozen; no node coordinates.

## Exclusion volumes

Stub for Task 2: name camp radii, road-edge, landmark discs, satellite bowl, and which layer owns which (D-27); presentation never writes collision or flow.

## Way-home language

Stub for Task 2: follow asphalt to the dirt spur; Amber Gold confirms near camp; district weenies are local nouns; proof frames hide the minimap (D-23).

## Capture cameras

Stub for Task 2: specified IDs only (`cam_loop_01_camp_clearing` through `cam_job_metsa_canopy_wall`); not implemented; no nodes in `tests/world_render_validation.gd` (D-27).

## Co-authorship and tripwires

Stub for Task 2: pocket 2 vs `OstariSouthShell` recorded not moved; `MAXIMUM_UNHOSTABLE_POCKETS = 1`; wild veto; no nameplates; no second Amber Gold (D-19, D-08, D-10, D-28).

## Phase 2 consumer list

Stub for Task 2: grep table when camp slides inside Metsä (D-22), including duplicate `WorldBackgroundDecor2D.CAMP_POSITION`; `WorldCompositionContract` is Phase 2, not this file's runtime.

## Out of scope

Stub for Task 2: FIR-01, SALV-01, fence vs house projection, TINT-01, PLACE-01, pocket-2 move, Resource `.tres`, extra stamps, Android / LAN, mechanics, HDR 2D, extra fullscreen pass, runtime 3D, shrinking ±14,336.
