---
name: wote-evaluation
description: "Run WoTE metric caching and PDM evaluation from README using workspace-relative paths; use base if dependencies exist, otherwise fallback to conda env wote."
---

# WoTE Evaluation Skill

Use this workflow to run evaluation reliably in this repository.

## Companion files (read first for handoff)
- `.github/skills/README.md`
- `.github/skills/wote-evaluation/SESSION_STATUS.md`
- `AGENT_HANDOFF.md`

## When to use
- User asks to run README evaluation steps.
- Metric cache/evaluation fails due path issues.
- Environment variables are already in `~/.bashrc` but scripts still need robust path behavior.

## Preconditions
- Workspace root: `WoTE/`
- Checkpoint exists: `ckpts/epoch=29-step=19950.ckpt`
- Dataset exists under `dataset/`
- Environment variables are set in `~/.bashrc` (preferred), or script fallbacks are used.

## Environment policy
1. Try default environment first.
2. If missing required packages (e.g., `pandas`), rerun in `conda` env `wote`.

## Commands
From workspace root:

### 1) Precompute metric cache (README Step C)
```bash
bash scripts/evaluation/run_metric_caching.sh
```

Optional split selection:
```bash
bash scripts/evaluation/run_metric_caching.sh test
bash scripts/evaluation/run_metric_caching.sh trainval
```

### 2) Run evaluation (README Section 4)
```bash
bash scripts/evaluation/eval_wote.sh
```

If default environment is missing dependencies:
```bash
conda run -n wote bash scripts/evaluation/eval_wote.sh
```

## Path behavior in this repo
- `scripts/evaluation/eval_wote.sh` resolves `ROOT_DIR` automatically.
- It sets env-var fallbacks if missing:
  - `NUPLAN_MAPS_ROOT=${ROOT_DIR}/dataset/maps`
  - `NAVSIM_EXP_ROOT=${ROOT_DIR}/exp`
  - `NAVSIM_DEVKIT_ROOT=${ROOT_DIR}`
  - `OPENSCENE_DATA_ROOT=${ROOT_DIR}/dataset`
- Checkpoint path is root-relative:
  - `${ROOT_DIR}/ckpts/epoch=29-step=19950.ckpt`

## Metric cache loader note
If `exp/metric_cache/metadata/*.csv` is missing, loader falls back to recursively discovering `metric_cache.pkl` files.
This avoids hard failure at evaluation startup.

## Verification
- Evaluation logs:
  - `exp/eval/WoTE/default/run_pdm_score.log`
  - `exp/eval/WoTE/default/log.txt`
- Metric cache tree:
  - `exp/metric_cache/`

## Typical failure mapping
- `ModuleNotFoundError: pandas`:
  - use `conda run -n wote ...`
- `IndexError` in `MetricCacheLoader` on metadata csv:
  - ensure metric caching ran, or rely on recursive fallback loader.
- Dataset split path mismatches:
  - use scripts that resolve paths from `ROOT_DIR` and avoid machine-specific absolute paths.
