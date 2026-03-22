#!/usr/bin/env bash
set -euo pipefail

NUM_SPLITS=${1:-32}    # 下载的 split 数量 (0..NUM_SPLITS-1)，默认全部 32 个
MAX_SPLIT=$((NUM_SPLITS - 1))

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

DEST_LOGS="${ROOT_DIR}/dataset/navsim_logs"
DEST_SENSOR="${ROOT_DIR}/dataset/sensor_blobs"
STAGING="openscene-v1.1"
HF_BASE="https://huggingface.co/datasets/OpenDriveLab/OpenScene/resolve/main/openscene-v1.1"

mkdir -p "${DEST_LOGS}" "${DEST_SENSOR}"

echo "==> Will download ${NUM_SPLITS}/32 splits (split 0..${MAX_SPLIT})"

if [ ! -d "${DEST_LOGS}/test" ] || [ -z "$(ls -A "${DEST_LOGS}/test" 2>/dev/null)" ]; then
    echo "==> Downloading test metadata..."
    wget -q --show-progress "${HF_BASE}/openscene_metadata_test.tgz"
    tar -xzf openscene_metadata_test.tgz
    rm openscene_metadata_test.tgz
    rsync -a "${STAGING}/meta_datas/test/" "${DEST_LOGS}/test/"
    echo "    Metadata done."
else
    echo "==> Test metadata already exists, skipping."
fi

echo "==> Downloading test camera data (${NUM_SPLITS} splits)..."
for split in $(seq 0 "${MAX_SPLIT}"); do
    marker="${DEST_SENSOR}/test/.camera_split_${split}_done"
    if [ -f "${marker}" ]; then
        echo "    Camera split ${split}/${MAX_SPLIT} already done, skipping."
        continue
    fi
    echo "    Downloading camera split ${split}/${MAX_SPLIT}..."
    wget -q --show-progress "${HF_BASE}/openscene_sensor_test_camera/openscene_sensor_test_camera_${split}.tgz"
    tar -xzf "openscene_sensor_test_camera_${split}.tgz"
    rm "openscene_sensor_test_camera_${split}.tgz"
    rsync -a "${STAGING}/sensor_blobs/test/" "${DEST_SENSOR}/test/"
    rm -rf "${STAGING}/sensor_blobs/test"
    touch "${marker}"
    echo "    Camera split ${split}/${MAX_SPLIT} merged."
done

echo "==> Downloading test lidar data (${NUM_SPLITS} splits)..."
for split in $(seq 0 "${MAX_SPLIT}"); do
    marker="${DEST_SENSOR}/test/.lidar_split_${split}_done"
    if [ -f "${marker}" ]; then
        echo "    Lidar split ${split}/${MAX_SPLIT} already done, skipping."
        continue
    fi
    echo "    Downloading lidar split ${split}/${MAX_SPLIT}..."
    wget -q --show-progress "${HF_BASE}/openscene_sensor_test_lidar/openscene_sensor_test_lidar_${split}.tgz"
    tar -xzf "openscene_sensor_test_lidar_${split}.tgz"
    rm "openscene_sensor_test_lidar_${split}.tgz"
    rsync -a "${STAGING}/sensor_blobs/test/" "${DEST_SENSOR}/test/"
    rm -rf "${STAGING}/sensor_blobs/test"
    touch "${marker}"
    echo "    Lidar split ${split}/${MAX_SPLIT} merged."
done

rm -rf "${STAGING}"
echo "==> Done. Downloaded ${NUM_SPLITS} splits to ${DEST_SENSOR}/test/"
