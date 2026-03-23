# WoTE Agent Handoff

This document captures the current implementation status, verified fixes, run commands, and next actions so a new agent can continue immediately.

## Fast start (for another agent)
1. `cd /home/wenzhe/wm_ws/WoTE`
2. Prefer Python work in conda env `wote`:
   - `conda run -n wote bash scripts/evaluation/eval_wote.sh`
3. Read first:
   - `.github/skills/README.md`
   - `.github/skills/wote-evaluation/SKILL.md`
   - `.github/skills/wote-evaluation/SESSION_STATUS.md`

## User constraints to preserve
- Use conda environment `wote` for Python tasks.
- Do not modify user dataset location manually; fix script/config paths instead.
- Keep README-based execution flow.

## What has been fixed (across all sessions)
- Removed machine-specific absolute paths and made scripts root-relative:
  - `scripts/evaluation/eval_wote.sh`
  - `scripts/evaluation/run_metric_caching.sh`
  - `scripts/miscs/gen_pdm_score.sh`
  - `scripts/miscs/gen_multi_trajs_pdm_score.py`
  - `scripts/miscs/k_means_trajs.py`
  - `navsim/agents/WoTE/configs/default.py`
- Added metric cache loading fallback when metadata csv is missing:
  - `navsim/common/dataloader.py`
- Added reusable agent skill:
  - `.github/skills/wote-evaluation/SKILL.md`

## Data artifacts already produced
- `dataset/extra_data/planning_vb/future_trajectories_list_trainval_navtrain.npy`
- `dataset/extra_data/planning_vb/trajectory_anchors_256.npy`
- `dataset/extra_data/planning_vb/trajectory_anchors_256_no_grid.png`
- `dataset/extra_data/planning_vb/formatted_pdm_score_256.npy`

## Completed milestones
- **Metric cache**: Fully generated — 69711 features across 138 log files, metadata CSV at `exp/metric_cache/metadata/metric_cache_metadata_node_0.csv`.
- **Checkpoint**: Downloaded — `ckpts/epoch=29-step=19950.ckpt` (767MB) + `ckpts/resnet34.pth` (87MB).
- **Dataset structure**: navsim_logs (test: 147 logs, trainval), sensor_blobs, maps all in place.
- **Environment**: conda env `wote`, env vars in `~/.bashrc`, 3× NVIDIA RTX 6000 Ada (48GB each), 96 CPUs.

## Evaluation — FULLY REPRODUCED

**Final results (2026-03-22, full 32/32 splits, 12146/12146 scenarios):**

| Metric | Score | Paper | Match |
|---|---|---|---|
| No Collision (NC) | 98.5 | 98.5 | Exact |
| Drivable Area (DAC) | 96.8 | 96.8 | Exact |
| Ego Progress (EP) | 81.9 | 81.9 | Exact |
| TTC | 94.9 | 94.9 | Exact |
| Comfort | 100.0 | 99.9 | ~match |
| **PDMS** | **88.3** | **88.3** | **Exact** |

Result CSV: `exp/eval/WoTE/default/2026.03.22.20.55.30.csv`

**Download script:**
- `download/download_test.sh` is parameterized: `bash download/download_test.sh <NUM_SPLITS>`
  - Default downloads all 32 splits; pass a number for partial (e.g. `bash download/download_test.sh 5`).
  - Supports resume via marker files (`.camera_split_X_done` / `.lidar_split_X_done`).
  - Uses `pigz` (parallel gzip) for extraction — leverages all 96 CPUs.
  - Data merges directly into `dataset/sensor_blobs/test/`.

## Eval run history
- **2026-03-21 (run 1)**: Metric cache OK, 12146 scenarios, 11500 failed (no camera data), no CSV.
- **2026-03-22 (run 2)**: 5/32 splits, 2252 valid, PDMS=88.1 (partial).
- **2026-03-22 (run 3)**: 32/32 splits, 12146 valid, **PDMS=88.3** (exact match).

---

## Next goal — Latent World Model BEV Visualization

Compare the world model's predicted BEV semantic map against the ground truth BEV.

### BEV architecture summary

- **GT BEV**: Built in `WoTE_targets.py` via `_compute_bev_semantic_map` — rasterizes HD map polygons, annotation boxes, and ego box using OpenCV onto a `(128, 256)` integer label grid (8 classes).
- **Predicted BEV (current)**: Model outputs `bev_semantic_map` logits `(B, 8, 128, 256)` via `_process_map` in `WoTE_model.py` — BEV latent 8x8 upsampled through `BEVUpsampleHead` + `bev_semantic_head`.
- **Predicted BEV (future)**: After `latent_world_model` (TransformerEncoder) updates BEV + ego tokens, decoded through the same head → `fut_bev_semantic_map` logits `(B, 8, 128, 256)`.
- **Future GT BEV**: Same rasterization but with future annotations transformed to current ego frame, plus ego box at trajectory anchor pose.

### 8 BEV semantic classes (`configs/default.py`)

| Label | Meaning |
|---|---|
| 0 | Background |
| 1 | Road (lane + intersection) |
| 2 | Walkways |
| 3 | Centerline |
| 4 | Static objects (barrier, cone, sign) |
| 5 | Vehicles |
| 6 | Pedestrians |
| 7 | Ego vehicle |

### Key files for visualization

| File | What to use |
|---|---|
| `navsim/agents/WoTE/WoTE_model.py` | `_process_map`, `_process_future_map`, `latent_world_model` |
| `navsim/agents/WoTE/WoTE_targets.py` | `_compute_bev_semantic_map`, `_add_ego_box_to_bev_map` |
| `navsim/agents/transfuser/transfuser_callback.py` | `semantic_map_to_rgb` (lines 145-165) — reusable colormap |
| `navsim/visualization/bev.py` | Scene-level BEV plotting utilities |

### Visualization plan

1. Write a script that loads a scene via `SceneLoader`, builds features/targets via `WoTEFeatureBuilder`/`WoTETargetBuilder`.
2. Load the checkpoint, run `forward_train` (needed to get both current and future BEV predictions; `forward_test` skips future BEV).
3. Extract from predictions: `bev_semantic_map` (current) and `fut_bev_semantic_map` (future) — apply `argmax(dim=1)`.
4. Extract from targets: `bev_semantic_map` and `fut_bev_semantic_map` (already integer labels).
5. Convert to RGB using `semantic_map_to_rgb` or a custom colormap.
6. Plot side-by-side: GT current vs predicted current, GT future vs predicted future.

## Known caveat
- Repository may contain other unrelated changed files or large generated artifacts; do not assume they are part of this fix scope.
- `dataset/metric_cache/` (251 entries) is separate from `exp/metric_cache/` (69711 entries) — eval uses `exp/metric_cache/`.
