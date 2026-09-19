# World Map Audit — Live 14×14 Census

Audit date: 2026-09-19  
Scope root: `C:\Users\heikk\Desktop\Claude\gpt_peli`  
Runtime target: Godot 4.7.1 Mobile, 2D, 480×270 landscape

This census greps live `const` values in `src/world/` and `tests/` as they stand on 2026-09-19. It does not re-run GPU or headless world-map gates. It does not trust scenery, capture, or gate-count prose in `docs/WORLD_MAP_FOUNDATION.md`. This document is not pixel proof. On-disk `artifacts/world_*` freshness versus camp `(9950, 2400)` is not verified this session (RESEARCH A2). Filename inventory is not a claim that those PNGs match the live camera.

Phase 1 is docs-only (CONT-01, D-25, D-28). This file does not bump `LAYOUT_VERSION` or `WORLD_BUILD_SEED`. It does not edit `src/world/`.

## Method

Method is grep of live identifiers, not a render pass and not a foundation-doc paraphrase.

1. Read `const` and authored tables in `src/world/world_map_2d.gd`, `world_road_network_2d.gd`, dress/scatter scripts, and matching `tests/*validation*.gd`.
2. Quote the identifier, the numeric value, and the source path beside each row (D-26).
3. Do not re-run Godot GPU or `--headless` world-map gates. Those gates prove the *old* map; they are not this census.
4. Do not copy scenery 576 / forest 172 / captures 23 / `WORLD MAP VALIDATION OK (150)` from `docs/WORLD_MAP_FOUNDATION.md`. Those counts lag live code. Drift is Task 2.
5. Do not treat on-disk `artifacts/world_*` PNGs as proof that the camp camera sits at `(9950, 2400)`. Capture-gate freshness versus camp is not verified this session (RESEARCH A2).
6. Comment figures that no live gate pins this session — for example the `461` obstacle remark on `OBSTACLE_BROADPHASE_CELL` — stay comments, not census pins (RESEARCH A3).

What this document is not: pixel proof, a redesign contract, a camera implementation, a wild-atlas promotion, or a `LAYOUT_VERSION` / `WORLD_BUILD_SEED` bump.

## Extents, seed, camp, cell

Locked playable world. Seed and layout version are frozen this phase (D-28). Camp coordinates are current-state, not a Phase 2 target.

| Constant | Value | File |
|----------|-------|------|
| `BesprenWorldMap2D.GRID_SIZE` | 14 | `src/world/world_map_2d.gd` |
| `BesprenWorldMap2D.CELL_SIZE` | 2048.0 | `src/world/world_map_2d.gd` |
| `BesprenWorldMap2D.PLAYABLE_HALF_EXTENT` | 14336.0 | `src/world/world_map_2d.gd` |
| `BesprenWorldMap2D.WORLD_SIZE` | 28672.0 (`PLAYABLE_HALF_EXTENT * 2.0`) | `src/world/world_map_2d.gd` |
| `BesprenWorldMap2D.WORLD_BUILD_SEED` | `0xB35E7E` — freeze; this plan does not change the `.gd` (D-28) | `src/world/world_map_2d.gd` |
| `BesprenWorldMap2D.STARTING_CAMP_POSITION` | `Vector2(9950, 2400)` | `src/world/world_map_2d.gd` |
| `BesprenWorldMap2D.STARTING_CAMP_REQUIRED_ROAD_EDGE_CLEARANCE` | 1600 | `src/world/world_map_2d.gd` |
| Comment-measured nearest road edge | 2098 | `src/world/world_map_2d.gd` comment on `STARTING_CAMP_POSITION`; gate pin `EXPECTED_STARTING_CAMP_ROAD_EDGE_DISTANCE` in `tests/world_map_validation.gd` |
| `BesprenWorldMap2D.STARTING_CAMP_OPEN_RADIUS` | 520 | `src/world/world_map_2d.gd` |
| `BesprenWorldMap2D.STARTING_CAMP_SATELLITE_COUNT` | 3 | `src/world/world_map_2d.gd` |
| Satellite Bedding offset | `Vector2(-650, -300)` (`StartingCampBedding`) | `src/world/world_map_2d.gd` `_build_starting_camp_satellites`; `tests/world_map_validation.gd` `EXPECTED_CAMP_SATELLITE_OFFSETS` |
| Satellite Supply offset | `Vector2(350, 650)` (`StartingCampSupplyCache`) | same |
| Satellite Medical offset | `Vector2(0, 720)` (`StartingCampMedicalCache`) | same |
| Derived camp cell | `(11, 8)` east-forest: `floor((9950+14336)/2048)=11`, `floor((2400+14336)/2048)=8` | derived from live constants; biome rule `column >= 10 and row <= 8` is `FOREST` |
| `BesprenResourceScatter2D.LAYOUT_VERSION` | 2 — freeze; do not bump (D-28) | `src/world/resource_scatter_2d.gd` |

Playable rect is `PLAYABLE_RECT`: origin `(-14336, -14336)`, size `(28672, 28672)`.

Camp is a secluded east-forest clearing, not a road-junction camp. Required road-edge clearance is 1600; the comment-measured nearest road edge is 2098. Three satellites sit as furniture offsets around the core. None of that is a dirt spur polyline — see Eight routes.

## Biome seats as-is

Current seats from `_build_biome_cells` / `get_biome_regions`. Not frozen. D-21 (districts may rearrange on the locked 14×14 grid) belongs to the redesign contract, not this census.

Fill order in `_build_biome_cells`: start `WILDERNESS`, then forest if perimeter or `(column >= 10 and row <= 8)` or `(column <= 2 and row >= 5)`, then overlay city / mall / west village / east village.

| Region key | Cells | Source |
|------------|-------|--------|
| `kaupunki` | `(1,1)–(5,5)` | `get_biome_regions` / `_build_biome_cells` (`Biome.CITY`) |
| `ostari` | `(7,2)–(10,5)` | `get_biome_regions` / `_build_biome_cells` (`Biome.MALL`) |
| `kyla_west` | `(1,9)–(4,12)` | `get_biome_regions` / `_build_biome_cells` (`Biome.VILLAGE_WEST`) |
| `kyla_east` | `(9,9)–(12,12)` | `get_biome_regions` / `_build_biome_cells` (`Biome.VILLAGE_EAST`) |
| `metsa_perimeter` | `PLAYABLE_RECT` | `get_biome_regions` |

Forest rule (Metsä wrap, not a fifth named region): `metsa_perimeter = PLAYABLE_RECT`; cell is `FOREST` when `column == 0 or row == 0 or column == GRID_SIZE - 1 or row == GRID_SIZE - 1` (perimeter) **or** `column >= 10 and row <= 8` **or** `column <= 2 and row >= 5`, unless a later district overlay wins. Camp cell `(11, 8)` is that east-forest belt.

Compass today: Kaupunki NW, Ostari NE interior, two Kylät south, Metsä wrapping the secluded camp. Those seats are current, not a lock.

## Eight routes and missing spur

`BesprenWorldMap2D._build_road_network` authors **eight** polylines. `dirt_flags` is `PackedByteArray([0, 0, 0, 0, 1, 1, 1, 1])` — four zeros then four ones. There is **no camp spur today**. Eight routes; none terminate at `(9950, 2400)`. D-02 is the *target* (dirt spur that meets asphalt). Live map has seclusion, not a spur polyline. Do not list a ninth route.

Widths from `src/world/world_road_network_2d.gd`: asphalt outer 540 / inner 420 (`ASPHALT_OUTER_WIDTH` / `ASPHALT_INNER_WIDTH`); dirt outer 480 / inner 360 (`DIRT_OUTER_WIDTH` / `DIRT_INNER_WIDTH`). Code today has two `dirt_flags` values. Three readable grades at 1× (D-20) are a contract invention, not a third flag in this census.

| i | dirt_flags | polyline | job today |
|---|------------|----------|-----------|
| 0 | 0 asphalt | `(-12288,0)`–origin–`(12288,0)` | EW spine |
| 1 | 0 asphalt | `(0,-12288)`–origin–`(0,12288)` | NS spine |
| 2 | 0 asphalt | `(-8192,-11264)`–`(-8192,0)`–origin | Kaupunki branch |
| 3 | 0 asphalt | `(0,-5500)`–`(9000,-5500)`–`(9000,0)` | Ostari branch |
| 4 | 1 dirt | `(0,4096)`–`(-8192,4096)`–`(-8192,11264)` | West village |
| 5 | 1 dirt | `(0,4096)`–`(8192,4096)`–`(8192,11264)` | East village |
| 6 | 1 dirt | closed ±12288 rectangle `(-12288,-12288)`–`(12288,-12288)`–`(12288,12288)`–`(-12288,12288)`–`(-12288,-12288)` | Wilderness perimeter — not the 30s path |
| 7 | 1 dirt | `(9000,-5500)`–`(11264,-5500)`–`(11264,-11264)` | Ostari east spur |

Nearest asphalt to camp is the EW spine (route 0) and the Ostari branch (route 3) at `y = 0` / `x = 9000`; camp sits at `(9950, 2400)` with 2098 units to the nearest physical road edge. No polyline walks that gap.

### Z matrix (absolute)

From CONVENTIONS / `tests/world_map_validation.gd` `EXPECTED_*_Z`:

| Pass | z | Owners |
|------|--:|--------|
| Ground tiles, terrain overlay, roads | -20 | `GroundTiles`, `TerrainMaterialOverlay`, `WorldRoadNetwork2D` (`EXPECTED_GROUND_Z`) |
| Non-colliding rubble / moss / cover / wilderness accent | -5 | `WorldBackgroundDecor2D`, `WorldGroundCover2D`, `WorldWildernessAccent2D` (`EXPECTED_DECOR_Z`, `EXPECTED_WILDERNESS_ACCENT_Z`) |
| Ambient silhouettes | -4 | `WorldAmbientScenery2D` (`EXPECTED_AMBIENT_SCENERY_Z`) |
| Gameplay / static occlusion | 5 | `WorldObstacle2D`, Base, scatter, avatars (`EXPECTED_ENTITY_Z`) |

## Density tables

Task 2 fills live dress/scatter counts (`TOTAL_SCENERY_COUNT` 640, decor 1100, `RESOURCE_COUNT` 87) against `.gd` constants, not foundation 576.

## Pocket versus obstacle overlaps

Task 2 records wilderness pocket 2 under `OstariSouthShell` (D-19). Do not move the pocket in this census.

## 1× unreadables

Task 2 names FIR-01, the wild-atlas veto, fence/house projection mismatch, and scatter-as-place. Numeric pass is not promotion.

## Capture inventory

Task 2 inventories the 25-capture set and TIME-stable class from `tests/world_render_validation.gd`. Filename inventory is not pixel proof.

## Foundation drift

Task 2 tables stale `docs/WORLD_MAP_FOUNDATION.md` claims (576 / 23 / 150) against live 640 / 25 / 169.

## What the contract must invent

Task 2 lists dirt spur (D-02), Metsä threat weenie, teaching salvage pocket as a place, and three-grade visual look — without GDScript coordinates.
