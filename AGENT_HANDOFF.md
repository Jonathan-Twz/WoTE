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
- Always respond in Chinese-simplified.

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

## Current blocker — MISSING TEST CAMERA DATA

**Root cause of eval failure (95% scenario failure rate):**
- `dataset/sensor_blobs/test/` 每个场景只有 `MergedPointCloud/`（LiDAR），缺少相机目录 (`CAM_F0`, `CAM_L0`, `CAM_R0` 等)。
- WoTE 模型推理需要相机图像，因此评估时绝大多数场景抛出异常。
- 对比 `dataset/sensor_blobs/trainval/` 有完整的 8 个相机目录 + LiDAR。

**部分下载状态：**
- `openscene-v1.1/sensor_blobs/test/` 已有 31 个场景的相机数据（来自 split 3），尚未合并到 `dataset/sensor_blobs/test/`。
- 下载脚本：`download/download_test_missing.sh`（循环下载 0-31 共 32 个 split 的 `openscene_sensor_test_camera_*.tgz`）。

**磁盘空间警告：**
- 磁盘总 3.5TB，已用 3.2TB，仅剩 ~102GB。
- 完整 test 相机数据预估 ~150GB+，空间可能不足。
- 策略：逐个 split 下载→提取→合并→删除 tgz，最小化临时空间需求。

## Required next actions
1. **合并已有的部分相机数据**：`rsync -av openscene-v1.1/sensor_blobs/test/* dataset/sensor_blobs/test/` 然后 `rm -rf openscene-v1.1`。
2. **下载剩余 test 相机 split（0-2, 4-31）**：修改 `download/download_test_missing.sh` 逐个下载、提取、合并、删除。
3. **重新运行评估**：`conda run -n wote bash scripts/evaluation/eval_wote.sh`
4. **确认最终分数**：检查 `exp/eval/WoTE/default/` 下是否生成 `.csv` 结果文件。

## Previous eval run details (2026-03-21)
- Metric cache: OK — 69711 cached, metadata CSV generated.
- Eval found 12146 test scenarios (not 0 anymore), but 11500 failed due to missing camera data.
- No CSV result file was generated (eval did not complete successfully).
- Worker logs at `exp/eval/WoTE/default/logs/` (475 files).

## Verify after rerun
- `exp/eval/WoTE/default/*.csv` — final PDM scores
- `exp/eval/WoTE/default/run_pdm_score.log` — should end with "Finished running evaluation"
- `exp/eval/WoTE/default/log.txt`

## Known caveat
- Repository may contain other unrelated changed files or large generated artifacts; do not assume they are part of this fix scope.
- `dataset/metric_cache/` (251 entries) is separate from `exp/metric_cache/` (69711 entries) — eval uses `exp/metric_cache/`.
