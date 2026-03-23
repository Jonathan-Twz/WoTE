# WoTE Evaluation Session Status

Last updated: 2026-03-22

## Evaluation — FULLY REPRODUCED

PDMS = **88.3** (exact match with paper). All 12146 test scenarios successful.

Result CSV: `exp/eval/WoTE/default/2026.03.22.20.55.30.csv`

| Metric | Score | Paper |
|---|---|---|
| No Collision | 98.5 | 98.5 |
| Drivable Area Compliance | 96.8 | 96.8 |
| Ego Progress | 81.9 | 81.9 |
| TTC | 94.9 | 94.9 |
| Comfort | 100.0 | 99.9 |
| **PDMS** | **88.3** | **88.3** |

## Scope completed
- Path portability fixes applied for eval/caching/misc scripts.
- Config absolute paths removed and replaced with project-root based paths.
- Metric cache loader now supports fallback discovery when metadata CSV is missing.
- Skill documentation created.
- Metric cache fully generated: 69711 features.
- K-means anchors (256) and formatted PDM scores generated.
- Diagnosed and resolved eval failure (missing test camera data).
- Updated `download/download_test.sh` with parameterized split count, resume support, correct target paths, and `pigz` parallel decompression.
- Full test data downloaded (32/32 splits, camera + lidar).
- Full evaluation completed and paper results reproduced.

## Next goal — Latent World Model BEV Visualization

Compare predicted BEV semantic maps from the latent world model against ground truth.

### Key code locations
- **GT BEV construction**: `navsim/agents/WoTE/WoTE_targets.py` — `_compute_bev_semantic_map`, rasterizes HD map + annotation boxes + ego box → `(128, 256)` int labels.
- **Predicted BEV (current)**: `navsim/agents/WoTE/WoTE_model.py` — `_process_map` → BEV latent 8x8 → `BEVUpsampleHead` → `bev_semantic_head` → `(B, 8, 128, 256)` logits.
- **Predicted BEV (future)**: Same model, `_process_future_map` after `latent_world_model` TransformerEncoder updates BEV tokens.
- **Colormap utility**: `navsim/agents/transfuser/transfuser_callback.py` — `semantic_map_to_rgb` (lines 145-165).

### BEV classes (8 total)
0=background, 1=road, 2=walkway, 3=centerline, 4=static objects, 5=vehicles, 6=pedestrians, 7=ego.

### Visualization plan
1. Load scene via `SceneLoader`, build features/targets via `WoTEFeatureBuilder`/`WoTETargetBuilder`.
2. Load checkpoint, run `forward_train` (produces both current and future BEV; `forward_test` skips future).
3. `argmax(dim=1)` on predicted logits to get class labels.
4. Convert GT + predicted to RGB via `semantic_map_to_rgb`.
5. Plot side-by-side: GT current vs predicted current, GT future vs predicted future.

## Canonical commands
```bash
cd /home/wenzhe/wm_ws/WoTE

# Download test data
bash download/download_test.sh        # all 32 splits
bash download/download_test.sh 5      # first 5 splits only

# Run evaluation
conda run -n wote bash scripts/evaluation/eval_wote.sh
```

## Hardware
- 3× NVIDIA RTX 6000 Ada Generation (48GB VRAM each)
- 96 CPUs
- Disk: 3.5TB total

## Decision notes
- Keep script-level path fixes (root-relative + env fallback), do not hardcode host paths.
- Prefer fixing orchestration scripts over editing dataset locations.
- Use `pigz` (`tar -I pigz -xf`) for extraction; installed at `/usr/bin/pigz`.
