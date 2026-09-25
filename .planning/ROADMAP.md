# Roadmap: Bespren Visual AAA+ & Map Redesign

## Overview

Brownfield visual + map-composition milestone. Core value: at 480×270 the world reads as authored places with a visible salvage loop — never as generated scatter on a grid. Phase 1 is audit and a written redesign contract only; no world-authoring code. Later phases consume that contract as composition data, fill districts and pockets, place unique set pieces, prove the 30s loop in captures, then lift remaining surfaces on the skeleton that already reads. Gameplay systems, 14×14 extents, 480×270 `canvas_items`, one weather overlay, HDR 2D off, and no runtime 3D stay frozen the whole way.

**Locked across every phase:** no new gameplay systems; no HDR 2D; no extra fullscreen passes; no runtime 3D / GLTF / Node3D; no shadow-casting 2D lights; no shrinking or growing ±14,336; no world-space district nameplates; wild non-tree frames stay unpromoted until a hosted-pocket 1× veto.

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [x] **Phase 1: Map Audit + Redesign Contract** - Census the 14×14 map and write the contract; zero world-authoring code (completed 2026-09-19)
- [x] **Phase 1.1: Repo and Gate Hygiene** (INSERTED) - Clone-reproducible gates, CI, legacy archive, HUD chip fix, lean CLAUDE.md (completed 2026-09-25)
- [x] **Phase 2: Authored Skeleton** - Consume composition data for paths, edges, districts, nodes, landmarks inside locked extents (completed 2026-09-25; resource nodes stay seeded until Phase 5)
- [x] **Phase 3: Readable Road Hierarchy** - Asphalt spine, dirt branch, and wilderness perimeter read as the loop's path at 1× (completed 2026-09-25)
- [x] **Phase 4: District Jobs** - Kaupunki choke, Ostari salvage, Kylät quiet, Metsä threat read without labels (completed 2026-09-25; Ostari's missing-tooth approach carried to Phase 6)
- [ ] **Phase 5: Camp Clearing + Salvage Pockets** - Camp is a clearing; 87 IDs sit in co-authored pockets
- [ ] **Phase 6: Hero Set Pieces** - Unique silhouettes at nodes; adjacent variety by construction, not `index % 8`
- [ ] **Phase 7: Capture Cameras + Canonical Gates** - Cameras on loop beats; noise floor measured; simulation untouched
- [ ] **Phase 8: 1× Loop, Named Places, Way-Home** - Stranger-point proves the 30s loop and way home with minimap hidden
- [ ] **Phase 9: Visual Lift on the Skeleton** - Remaining surfaces lifted on places that already read, still on the mobile bar

## Phase Details

### Phase 1: Map Audit + Redesign Contract

**Goal**: Team has a written redesign contract for the 14×14 world, grounded in a live audit, before anyone edits world layout
**Mode:** mvp
**Depends on**: Nothing (first phase)
**Requirements**: CONT-01
**Success Criteria** (what must be TRUE):

  1. Reviewer can open a `docs/` redesign contract that names camp, roads, district jobs, landmarks, salvage/threat pockets, 30s-loop beats, way-home language that is not the minimap, exclusion volumes, and capture cameras that will prove the loop
  2. Reviewer can read an audit of the current map — captures, density, pocket/obstacle overlaps, 1× unreadables — quoting live counts, not stale foundation docs
  3. Phase 1 diff contains no `src/world/` layout edits, no new atlas regions in `src/world/`, and no scenery/cover/resource count changes

**Plans:** 3/3 plans complete

Plans:
**Wave 1**

- [x] 01-01-PLAN.md — Live 14×14 census in docs/WORLD_MAP_AUDIT.md (seed, camp, eight routes, density, pocket 2, 1× unreadables, 25 captures)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 01-02-PLAN.md — Locked redesign contract in docs/WORLD_MAP_REDESIGN_CONTRACT.md (camp, roads, shout nouns, 30s beats, exclusions, named cameras)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 01-03-PLAN.md — CONT-01 proof: heading checklist, live-constant table vs RESEARCH census, empty src/world/ git path filter

### Phase 1.1: Repo and Gate Hygiene (INSERTED)

**Goal**: Every gate runs green from a fresh clone and on every push, before Phase 2 starts moving the world
**Depends on**: Phase 1
**Requirements**: none new (supports PROOF-01, PROOF-02)
**Success Criteria** (all met 2026-09-25):

  1. `scenes/build/runtime_export_dependencies.tscn` is committed and generated from `data/runtime_export_closure.json`; the unanchored `build/` ignore rule no longer swallows it
  2. `tools/ci/run_gates.sh` and `.github/workflows/gates.yml` run import, 21 headless gates, 3 ENet probes, and 17 Mobile/Vulkan capture gates; capture gates must report the Mobile renderer
  3. The unused legacy 2D catalog is archived under `tools/legacy/` with no deletion; vault-dependent hash checks skip by name without `Addons/`
  4. The wave chip no longer clips or contradicts itself, and the HUD gate measures chip text fit
  5. CLAUDE.md sections 7-9 live verbatim in `docs/art-log/`; stale gate counts are refreshed

**Plans**: executed directly on request (no PLAN files)

### Phase 2: Authored Skeleton

**Goal**: Player traverses an authored skeleton stored as composition data, still inside 14×14 / ±14,336
**Mode:** mvp
**Depends on**: Phase 1
**Requirements**: CONT-02, SKEL-01
**Success Criteria** (what must be TRUE):

  1. Player can move the existing 14×14 / ±14,336 playable world whose paths, edges, districts, nodes, and landmarks come from composition data — not biome cell IDs or seeded scatter
  2. Camp, roads, and colliding landmarks sit at contract positions; extents are unchanged
  3. Reviewer can inspect a shipped composition Resource that `BesprenWorldMap2D` consumes; GameWorld, CoopSession, gather rules, and the peer-one RPC surface stay the same

**Plans**: executed directly on request (no PLAN files); record in `docs/POLISH_PLAN_2026-09-25.md` section 5 (commits `f85a5eb`, `b45780d`)

**Outcome (2026-09-25):** `res://data/world/world_composition.tres` holds the camp seat and satellites, nine graded road routes including the D-02 `camp_spur`, biome paint, the five shout nouns (the Metsä weenie a reserved seat), and thirteen pocket tables, and `BesprenWorldMap2D` validates and consumes it. The three pocket tables and both camp literals now resolve through it. The refactor is output-identical against the capture noise floor. Extents, seeds, the 87 IDs, gather rules and RPC are unchanged. The 87 resource nodes still come from the 84-sector scatter, because moving them into authored pockets is Phase 5's SLVG-01.

### Phase 3: Readable Road Hierarchy

**Goal**: Player can read the road hierarchy at 1× as the salvage loop's path
**Mode:** mvp
**Depends on**: Phase 2
**Requirements**: ROAD-01
**Success Criteria** (what must be TRUE):

  1. Player can tell asphalt spine from dirt branch from wilderness perimeter at 1× without a label and without the minimap
  2. A 480×270 frame of the home road shows "this is the way" through width, edge, and negative space — not only as polylines in code
  3. Roads remain ground-layer presentation; collision and flow stay canonical

**Plans**: executed directly on request (no PLAN files); record in `docs/POLISH_PLAN_2026-09-25.md` section 5 (commit `dde2d55`)

**Outcome (2026-09-25):** Three grades with bed widths of 420 / 360 / 230 units (160 / 137 / 88 screen pixels at 0.38). The perimeter has a verge and a grass crown between ruts and keeps the dirt corridor for every clearance rule. All shoulders are drawn before any bed, so junctions read as one surface. Free ends taper and wear out. The gameplay tour's `camp_spur`, `road_junction`, `dirt_branch` and `perimeter_track` stops are the 1× evidence. The flow-mask pin is unchanged.

### Phase 4: District Jobs

**Goal**: Player can tell each district's job at 1× without a label
**Mode:** mvp
**Depends on**: Phase 3
**Requirements**: DIST-01
**Success Criteria** (what must be TRUE):

  1. Player entering Kaupunki can tell it is a city choke (dense shells, sightline breaks) without a label
  2. Player entering Ostari can tell it is mall salvage (collapsed commercial place, narrow approach) without a label
  3. Player entering Kylät can tell it is village quiet (yards, timber, rest rhythm) without a label
  4. Player entering Metsä can tell it is forest threat (canopy wall, sparse mass, camp as the clearing) without a label

**Plans**: executed directly on request (no PLAN files); record in `docs/POLISH_PLAN_2026-09-25.md` section 6.

**Outcome (2026-09-25):**

1. Kaupunki: 15 street-wall shells put a building face in frame along 79.3 % of the spine (was 0.0 %). The `city_choke` landmark on the spine is an unbroken, square pinch at 360 units. Pavements, kerbs, drains and a choke rubble spill are drawn by `WorldUrbanFabric2D`. The tour's `city_street` goes from 10.5 % to 22.7 % occupancy, and the choke frame reads 35.3 %.
2. Ostari: a 34-bay car park with five abandoned cars reads as mall salvage at 1×. The narrow approach exists only in collision (two gaps of about 1,000 units round the west pylon). Its missing-tooth reading is the mall gate, carried to Phase 6 (SETP-01).
3. Kylät: East has its own job (hamlet and grave plot, `38b4669`). `WorldVillageYards2D` gives 7 of 8 houses a yard with apron, trail, woodpile, plot and washing, while the west yard's middle stays negative space. The fence silhouette (D-15) still needs a bake.
4. Metsä: the understory and canopy wall from the polish pass carry it. Canopy mass (FIR-01) still needs a bake.

### Phase 5: Camp Clearing + Salvage Pockets

**Goal**: Camp reads as a clearing and the 87 gather nodes live in authored salvage pockets
**Mode:** mvp
**Depends on**: Phase 4
**Requirements**: SLVG-01, CAMP-01
**Success Criteria** (what must be TRUE):

  1. Player still gathers the same 87 IDs with unchanged 3–5 step / one-unit rules, but nodes sit in authored salvage pockets instead of uniform 84-sector scatter
  2. Camp reads as a clearing: negative space and landmark exclusion are visible; the refuge is not a stamp in the forest
  3. Pocket tables and obstacle tables match in the same change — no new pocket/shell overlap beyond the recorded unhostable tripwire

**Plans**: TBD

**Progress (2026-09-25 polish pass):** Criterion 2 is largely met. `WorldCampClearing2D` lays the bowl's trodden earth and satellite paths, and the understory keeps 1,180 units empty inside a canopy wall. The pocket tables now live in the composition Resource, which is where SLVG-01 will author salvage pockets. Criterion 1 (nodes in pockets) has not started.

### Phase 6: Hero Set Pieces

**Goal**: Nodes and landmarks read as unique places a co-op partner can name, not repeating wallpaper
**Mode:** mvp
**Depends on**: Phase 5
**Requirements**: SETP-01
**Success Criteria** (what must be TRUE):

  1. Player can call out distinct hero set pieces at nodes and landmarks (mall gate, city choke, village yard, forest satellites) without world-space nameplates
  2. Adjacent dress does not read as `index % 8` wallpaper; neighboring instances differ by construction, not a per-instance coin
  3. Forbidden wild non-tree frames stay out of the shipping world

**Plans**: TBD

### Phase 7: Capture Cameras + Canonical Gates

**Goal**: Capture cameras sit on the 30s-loop beats, noise is measured, and presentation has not written simulation
**Mode:** mvp
**Depends on**: Phase 6
**Requirements**: PROOF-01, PROOF-02
**Success Criteria** (what must be TRUE):

  1. World-render cameras look at the contract's camp, home-road, landmarks, salvage pockets, and threat approaches — not leftover hardcoded scrap piles
  2. Two identical capture runs exist as the noise floor before any visual diff is blamed on art
  3. Headless world-map and smoke gates are green after layout changes; collision, flow, gather, and RPC stay canonical
  4. A visual veto can fail a numeric pass; on-disk captures match live camp position

**Plans**: TBD

### Phase 8: 1× Loop, Named Places, Way-Home

**Goal**: A stranger can point at the 30s loop, named places, and the way home at 480×270 with the minimap hidden
**Mode:** mvp
**Depends on**: Phase 7
**Requirements**: LOOP-01, READ-01, READ-02
**Success Criteria** (what must be TRUE):

  1. A stranger looking at 480×270 captures can point the 30s loop in order: camp → readable road → named landmark → salvage pocket → threat → back
  2. A stranger can point at camp, road, landmark, salvage pocket, and threat as named places with no world-space labels
  3. From each district, the way home reads from roads, silhouettes, and the camp Amber Gold weenie with the minimap hidden

**Plans**: TBD

### Phase 9: Visual Lift on the Skeleton

**Goal**: Every remaining visual surface is lifted on the skeleton that already reads, still on the 480×270 mobile bar
**Mode:** mvp
**Depends on**: Phase 8
**Requirements**: VISL-01
**Success Criteria** (what must be TRUE):

  1. Reviewer at 1× can see a lift of terrain, props, foliage, structures, lighting, actors, camp, dashboard/HUD, VFX, and shaders on Phase 8 camera beats — authored places plus unique set pieces, not a prettier stamp grid
  2. Mobile contract still holds: one fullscreen pass, HDR 2D off, no runtime 3D, no extra custom fullscreen pass, Base Core remains the only dominant Amber Gold
  3. Existing focused visual gates still pass on the new places

**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 1.1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9. The 2026-09-25 polish pass (`docs/POLISH_PLAN_2026-09-25.md`) ran before Phase 2, on request, and some of its world work counts as early evidence for Phases 4 and 5.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Map Audit + Redesign Contract | 3/3 | Complete    | 2026-09-19 |
| 1.1 Repo and Gate Hygiene (INSERTED) | - | Complete | 2026-09-25 |
| 2. Authored Skeleton | - | Complete | 2026-09-25 |
| 3. Readable Road Hierarchy | - | Complete | 2026-09-25 |
| 4. District Jobs | - | Complete (Ostari approach → Phase 6) | 2026-09-25 |
| 5. Camp Clearing + Salvage Pockets | 0/TBD | Partial evidence (camp clearing) | - |
| 6. Hero Set Pieces | 0/TBD | Not started | - |
| 7. Capture Cameras + Canonical Gates | 0/TBD | Not started | - |
| 8. 1× Loop, Named Places, Way-Home | 0/TBD | Not started | - |
| 9. Visual Lift on the Skeleton | 0/TBD | Not started | - |
