#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# export PYTHONPATH="${PYTHONPATH:-${ROOT_DIR}}"
# export NUPLAN_MAP_VERSION="${NUPLAN_MAP_VERSION:-nuplan-maps-v1.0}"
# export NUPLAN_MAPS_ROOT="${NUPLAN_MAPS_ROOT:-${ROOT_DIR}/dataset/maps}"
# export NAVSIM_EXP_ROOT="${NAVSIM_EXP_ROOT:-${ROOT_DIR}/exp}"
# export NAVSIM_DEVKIT_ROOT="${NAVSIM_DEVKIT_ROOT:-${ROOT_DIR}}"
# export OPENSCENE_DATA_ROOT="${OPENSCENE_DATA_ROOT:-${ROOT_DIR}/dataset}"

CONFIG_NAME=default

# evaluation, change the checkpoint_path
python "${ROOT_DIR}/navsim/planning/script/run_pdm_score.py" \
agent=WoTE_agent \
'agent.checkpoint_path="'"${ROOT_DIR}"'/ckpts/epoch=29-step=19950.ckpt"' \
agent.config._target_=navsim.agents.WoTE.configs.${CONFIG_NAME}.WoTEConfig \
experiment_name=eval/WoTE/${CONFIG_NAME}/ \
split=test \
scene_filter=navtest \
