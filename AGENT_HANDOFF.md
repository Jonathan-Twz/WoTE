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

## Current blocker — TEST SENSOR DATA INCOMPLETE

**Root cause of eval failure:**
- WoTE inference requires 3 cameras (`CAM_F0`, `CAM_L0`, `CAM_R0`) + LiDAR (`MergedPointCloud`).
- See `build_tfu_sensors` in `navsim/common/dataclasses.py`: only loads these 3 cameras + LiDAR.
- Scenes missing camera data throw `FileNotFoundError` and are marked `valid=False`.

**Download script updated:**
- `download/download_test.sh` is now parameterized: `bash download/download_test.sh <NUM_SPLITS>`
  - Default downloads all 32 splits; pass a number for partial (e.g. `bash download/download_test.sh 5`).
  - Supports resume via marker files (`.camera_split_X_done` / `.lidar_split_X_done`).
  - Downloads one split at a time: download → extract → rsync merge → delete tgz to minimize disk usage.
  - Uses `pigz` (parallel gzip) for extraction instead of single-threaded `gzip` — leverages all 96 CPUs.
  - Data merges directly into `dataset/navsim_logs/test/` and `dataset/sensor_blobs/test/`.

**Current download status (2026-03-22):**
- User deleted old `dataset/sensor_blobs/test/` (LiDAR-only), freeing ~150GB.
- Ran `bash download/download_test.sh 5` to download first 5 splits (camera + lidar).
- `openscene-v1.1/` may still contain partial data (41GB, from split 3).
- Disk space: ~245GB available.

**Partial-data eval in progress:**
- Eval running in terminal 6 (`bash ./scripts/evaluation/eval_wote.sh`).
- Progress ~68% (65/96 Ray objects).
- Scenes with camera data process normally; missing ones fail with `FileNotFoundError`.
- Check `exp/eval/WoTE/default/*.csv` after completion for partial results.

## Required next actions
1. **Wait for current eval to finish**: check `exp/eval/WoTE/default/*.csv` for results.
2. **Download full test data**: `bash download/download_test.sh` (no args = all 32 splits).
3. **Re-run full evaluation**: `conda run -n wote bash scripts/evaluation/eval_wote.sh`
4. **Verify final scores**: compare against paper results PDMS=88.3.

## Eval run history
- **2026-03-21 (run 1)**: Metric cache OK, found 12146 scenarios, 11500 failed (no camera data), no CSV generated.
- **2026-03-22 (run 2, in progress)**: Downloaded 5/32 splits, partial scenes have data. Running in terminal 6.

## Verify after rerun
- `exp/eval/WoTE/default/*.csv` — final PDM scores
- `exp/eval/WoTE/default/run_pdm_score.log` — should end with "Finished running evaluation"
- `exp/eval/WoTE/default/log.txt`

## Known caveat
- Repository may contain other unrelated changed files or large generated artifacts; do not assume they are part of this fix scope.
- `dataset/metric_cache/` (251 entries) is separate from `exp/metric_cache/` (69711 entries) — eval uses `exp/metric_cache/`.
