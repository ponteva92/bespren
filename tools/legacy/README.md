# Legacy archive

Everything under `tools/legacy/` is excluded from Godot by `.gdignore`. It is
kept for provenance, not shipped, imported, or gated.

## `asset_catalog_2d/`

The first 2D asset pipeline: pixel-art props, enemies, bosses and environment
animations extracted from the `Addons/` vault by `build_2d_asset_pipeline.py`
and wrapped as scenes by `build_2d_resources.gd`, with
`asset_pipeline_validation.gd` as its gate.

Archived 2026-09-25 because:

- Nothing at runtime used it. No script, scene, UID, export closure entry or
  export preset referenced any of its 9,513 asset files; the shipping game uses
  the baked `assets/2d/actors/` family and the Poly Haven / local atlases.
- It could not load from a clone. Every scene pointed into
  `assets/2d/_source_imports/`, which is gitignored, so its gate failed 19,086
  of 38,450 checks on any machine without the vault and every Godot import paid for
  ~54 MB of broken resources.

The original relative layout is preserved, so restoring is a move back:

```sh
git mv tools/legacy/asset_catalog_2d/assets/2d/<dir> assets/2d/<dir>
```

Restore the matching gate and tools from `asset_catalog_2d/tests/` and
`asset_catalog_2d/tools/asset_pipeline/` at the same time, and re-add the
catalog to the Android export `exclude_filter`. Nothing here was deleted.
