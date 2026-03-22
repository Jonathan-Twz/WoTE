# WoTE Evaluation Session Status

Last updated: 2026-03-22

## Scope completed
- Path portability fixes applied for eval/caching/misc scripts.
- Config absolute paths removed and replaced with project-root based paths.
- Metric cache loader now supports fallback discovery when metadata CSV is missing.
- Skill documentation created.
- Metric cache fully generated: 69711 features, metadata CSV at `exp/metric_cache/metadata/metric_cache_metadata_node_0.csv`.
- K-means anchors (256) and formatted PDM scores generated.
- Diagnosed eval failure root cause: missing test camera sensor data.

## Runtime status snapshot
- `k_means_trajs.py` was debugged and successfully produced 256-anchor outputs.
- Evaluation launch path issues were fixed.
- Metric cache generation completed successfully (2026-03-21, ~12.5 hours).
- Evaluation found 12146 test scenarios (cache/split mismatch resolved).
- **11500/12146 scenarios failed** due to missing camera images in `dataset/sensor_blobs/test/`.
- No CSV result file generated — eval did not finish successfully.

## Root cause: Missing test camera data
- `dataset/sensor_blobs/test/` only contains `MergedPointCloud/` (LiDAR), no camera directories.
- WoTE needs `CAM_F0`, `CAM_B0`, `CAM_L0`, `CAM_L1`, `CAM_L2`, `CAM_R0`, `CAM_R1`, `CAM_R2`.
- Partial download exists: `openscene-v1.1/sensor_blobs/test/` has 31 scenes with camera data (from split 3).
- Download script: `download/download_test_missing.sh` (splits 0-31, only 1 completed).
- Disk space constraint: only ~102GB free; full camera data ~150GB+.

## Required continuation
1. Merge partial camera data: `rsync -av openscene-v1.1/sensor_blobs/test/* dataset/sensor_blobs/test/ && rm -rf openscene-v1.1`
2. Download remaining test camera splits (0-2, 4-31) one at a time to conserve disk space.
3. Re-run evaluation: `conda run -n wote bash scripts/evaluation/eval_wote.sh`
4. Confirm non-zero scenario scoring and CSV result generation.

## Canonical commands
```bash
cd /home/wenzhe/wm_ws/WoTE

# Step 1: merge existing partial camera data
rsync -av openscene-v1.1/sensor_blobs/test/* dataset/sensor_blobs/test/
rm -rf openscene-v1.1

# Step 2: download remaining camera data (modifies download_test_missing.sh as needed)
bash download/download_test_missing.sh

# Step 3: run evaluation
conda run -n wote bash scripts/evaluation/eval_wote.sh
```

## Logs to inspect
- `exp/metric_cache/metadata/run_metric_caching.log` — metric cache (completed)
- `exp/eval/WoTE/default/run_pdm_score.log` — eval main log
- `exp/eval/WoTE/default/log.txt` — eval detailed log
- `exp/eval/WoTE/default/*.csv` — final result (not yet generated)
- `exp/eval/WoTE/default/logs/` — 475 per-worker logs from last run

## Hardware
- 3× NVIDIA RTX 6000 Ada Generation (48GB VRAM each)
- 96 CPUs
- Disk: 3.5TB total, ~102GB free (97% used)

## Decision notes
- Keep script-level path fixes (root-relative + env fallback), do not hardcode host paths.
- Prefer fixing orchestration scripts over editing dataset locations.
- Download camera splits one-at-a-time (download→extract→merge→delete tgz) to manage disk space.
