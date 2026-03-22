SPLIT=test
# SPLIT=trainval

nice -n 0 python -u $NAVSIM_DEVKIT_ROOT/navsim/planning/script/run_metric_caching.py \
    split=$SPLIT \
    cache.cache_path="${NAVSIM_EXP_ROOT}/metric_cache" \
    scene_filter.frame_interval=1 \
    worker.threads_per_node=48


# #!/usr/bin/env bash
# set -euo pipefail # Exit on errors, unset variables, and pipeline failures.

# SPLIT=${1:-trainval}  # Default to trainval, allow override via argument, e.g. test

# ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# CACHE_PATH="${NAVSIM_EXP_ROOT}/metric_cache"

# echo "Running metric caching for split: ${SPLIT}"
# echo "Cache output path: ${CACHE_PATH}"

# mkdir -p "${CACHE_PATH}"

# python -u "${ROOT_DIR}/navsim/planning/script/run_metric_caching.py" \
#     --info all \
#     split=$SPLIT \
#     cache.cache_path="${CACHE_PATH}" \
#     scene_filter.frame_interval=1 \
#     worker.threads_per_node=16