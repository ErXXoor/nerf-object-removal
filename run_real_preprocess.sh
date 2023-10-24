#!/bin/bash

if [ -z "${ROOT_DIR}" ]; then
    echo "Error, need \${ROOT_DIR} to be set!"
    echo "E.g. ROOT_DIR=\"$(pwd)/data/object-removal-custom\""
    exit 1
fi

if [ -z "${OUTPUT_DIR}" ]; then
    echo "Error, need \${OUTPUT_DIR} to be set!"
    echo "E.g. OUTPUT_DIR=\"$(pwd)/experiments/object-removal-custom/real\""
    exit 1
fi

sed -i.bak \
  -E "s@Config.data_dir = \".*@Config.data_dir = \"${ROOT_DIR}\"@1" \
  model/configs/custom/default.gin
sed -i.bak \
  -E "s@Config.checkpoint_dir = \".*@Config.checkpoint_dir = \"${OUTPUT_DIR}/default\"@1" \
  model/configs/custom/default.gin

CONFIG="$1"
SCENE="$2"
NAME="$3"
# ROOT_DIR=/mnt/res_nas/silvanweder/datasets/object-removal-custom-clean
# OUTPUT_DIR="$(pwd)"/tests
HOME_DIR="$(pwd)"

# make sure this works with an absolute path
# OUTPUT_DIR=/home/ext_silvan_weder_gmail_com/experiments

# setup experiment folder and symlink raw data
mkdir -p "${OUTPUT_DIR}/${SCENE}/data"
cd "${OUTPUT_DIR}/${SCENE}/data"
find "${ROOT_DIR}/${SCENE}" -maxdepth 1 ! -name "$(basename ${ROOT_DIR}/${SCENE})" -exec ln -s {} \;
cd "${HOME_DIR}"

# compute transforms files
python preprocessing/convert_colmap_to_nerf.py \
        --data_path "${OUTPUT_DIR}/${SCENE}/data/" \
        --out ../transforms.json \
        --split

# run lama inpainting
# we assume we have the following folders in the dataset
cd external/lama
bash run.sh "${OUTPUT_DIR}/${SCENE}/data" "${OUTPUT_DIR}" "${SCENE}" '_real'
cd ../..