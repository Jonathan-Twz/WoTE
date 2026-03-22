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
- Updated `download/download_test.sh` with parameterized split count, resume support, correct target paths, and `pigz` parallel decompression.

## Runtime status snapshot
- `k_means_trajs.py` was debugged and successfully produced 256-anchor outputs.
- Evaluation launch path issues were fixed.
- Metric cache generation completed successfully (2026-03-21, ~12.5 hours).
- Evaluation found 12146 test scenarios (cache/split mismatch resolved).
- User deleted old LiDAR-only `dataset/sensor_blobs/test/`, freeing ~150GB (now ~245GB free).
- Downloaded 5/32 test splits (camera + lidar) via `bash download/download_test.sh 5`.
- Partial-data eval running in terminal 6 (~68% progress). Most scenes still fail due to missing camera data.

## Root cause: Missing test camera data
- WoTE only needs `CAM_F0`, `CAM_L0`, `CAM_R0` + `MergedPointCloud` (see `build_tfu_sensors` in `navsim/common/dataclasses.py`).
- Scenes missing camera files throw `FileNotFoundError` at `dataclasses.py:68` and are marked `valid=False`.

## Required continuation
1. Wait for current partial eval to finish; check `exp/eval/WoTE/default/*.csv`.
2. Download full test data: `bash download/download_test.sh` (all 32 splits, resumes from split 5).
3. Re-run full evaluation: `conda run -n wote bash scripts/evaluation/eval_wote.sh`
4. Verify final scores against paper (PDMS=88.3).

## Canonical commands
```bash
cd /home/wenzhe/wm_ws/WoTE

# Download test data (parameterized, resumes automatically)
bash download/download_test.sh        # all 32 splits
bash download/download_test.sh 5      # first 5 splits only

# Run evaluation
conda run -n wote bash scripts/evaluation/eval_wote.sh
```

## Logs to inspect
- `exp/metric_cache/metadata/run_metric_caching.log` — metric cache (completed)
- `exp/eval/WoTE/default/run_pdm_score.log` — eval main log
- `exp/eval/WoTE/default/log.txt` — eval detailed log
- `exp/eval/WoTE/default/*.csv` — final result (not yet generated)
- `exp/eval/WoTE/default/logs/` — per-worker logs

## Hardware
- 3× NVIDIA RTX 6000 Ada Generation (48GB VRAM each)
- 96 CPUs
- Disk: 3.5TB total, ~245GB free (after deleting old test LiDAR data)

## Decision notes
- Keep script-level path fixes (root-relative + env fallback), do not hardcode host paths.
- Prefer fixing orchestration scripts over editing dataset locations.
- Download splits one-at-a-time (download → extract → merge → delete tgz) to manage disk space.
- Use `pigz` (`tar -I pigz -xf`) for extraction to leverage all CPU cores; `pigz` is installed at `/usr/bin/pigz`.
