#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DATASET_ROOT="${ROOT_DIR}/dataset"
NAVSIM_LOG_PATH="${DATASET_ROOT}/navsim_logs/trainval"
if [[ -d "${NAVSIM_LOG_PATH}/trainval" ]]; then
	NAVSIM_LOG_PATH="${NAVSIM_LOG_PATH}/trainval"
fi
SENSOR_BLOBS_PATH="${DATASET_ROOT}/sensor_blobs/trainval"
METRIC_CACHE_PATH="${DATASET_ROOT}/metric_cache/trainval"

if [[ ! -d "${METRIC_CACHE_PATH}" ]]; then
	echo "Missing metric cache path: ${METRIC_CACHE_PATH}"
	echo "Run: bash scripts/evaluation/run_metric_caching.sh"
	exit 1
fi

python "${ROOT_DIR}/scripts/miscs/gen_multi_trajs_pdm_score.py" \
agent=WoTE_agent \
'agent.checkpoint_path="'"${ROOT_DIR}"'/exp/WoTE/default/lightning_logs/version_0/checkpoints/epoch=29-step=9990.ckpt"' \
agent.config._target_=navsim.agents.WoTE.configs.default.WoTEConfig \
experiment_name=eval/gen_data \
navsim_log_path="${NAVSIM_LOG_PATH}" \
sensor_blobs_path="${SENSOR_BLOBS_PATH}" \
metric_cache_path="${METRIC_CACHE_PATH}" \
split=trainval \
scene_filter=navtrain \