#!/bin/bash
set -e

VERSION=1.2.10
# Configuration for HTR mode selection
HTRLOGHI=1

# Model configuration
HTRLOGHIMODELHEIGHT=64
HTRBASEMODEL=/proj/berzelius-2024-46/users/x_zhyan/loghi/generic-2023-02-15
#set to 1 to actually use basemodel, 0 to not use basemodel
USEBASEMODEL=1

# Define a VGSL model
HTRNEWMODEL="None,64,None,3 Cr3,3,24 Bn Mp2,2,2,2 Cr3,3,48 Bn Mp2,2,2,2 Cr3,3,96 Bn Cr3,3,96 Bn Mp2,2,2,2 Rc Bl256 Bl256 Bl256 Bl256 Bl256 O1s92"
# Set channels to 1 to process input as grayscale, 3 for color, 4 for color and mask
channels=4

GPU=0

# Dataset and training configuration
# These should be generated automatically by the apptainer-create-new.sh script
listdir=/proj/berzelius-2024-46/users/x_zhyan/All_training
trainlist=$listdir/training_all_train.txt
validationlist=$listdir/training_all_val.txt


datadir=./scratch/republicprint

# Set to the charlist file in the model folder
charlist=/proj/berzelius-2024-46/users/x_zhyan/loghi/generic-2023-02-15/charlist.txt

# Training configuration
epochs=10
height=$HTRLOGHIMODELHEIGHT
multiply=1

# Output directory
outdir=/proj/berzelius-2024-46/users/x_zhyan/models

# 64/128/256 are easy for A100.
batch_size=64
model_name=myfirstmodel
learning_rate=0.0003

# Create output directory, change the name if needed.
mkdir -p $outdir/output_freeze_recurrent_dense

# DO NOT EDIT BELOW THIS LINE
tmpdir=$(mktemp -d)

BASEMODEL=""
BASEMODELDIR=""
if [[ $USEBASEMODEL -eq 1 ]]; then
    BASEMODEL=" --existing_model "$HTRBASEMODEL
    BASEMODELDIR="-B $(dirname "${HTRBASEMODEL}"):$(dirname "${HTRBASEMODEL}")"

fi

# LoghiHTR option

        # Initialize Loghi-HTR
        # Some of the arguments are not listed here, but they might be useful.

        # --optimizer: Optimizer to use, default is adam
        # --decay_steps and --decay_rate: Learning rate decay, default is 0.99 and -1 (no decay). These are in beta stage.
        # --use_float32: Use float32 instead of float16, default is float16 for training.
        # --replace_recurrent_layer: Use this to replace the recurrent layers in a newly defined model with new ones.
        # --freeze_conv(dense/recurrent)_layers: Freeze the conv/dense/recurrent layers of the model. This is useful for transfer learning.


if [[ $HTRLOGHI -eq 1 ]]; then
    echo "Starting Loghi HTR"

    apptainer exec --nv\
	$BASEMODELDIR \
        --bind $outdir:$outdir \
        --bind $listdir:$listdir \
        htr.sif python3 /src/loghi-htr/src/main.py \
        --do_train \
        --train_list $trainlist \
        --do_validate \
        --validation_list $validationlist \
        --learning_rate $learning_rate \
        --channels $channels \
        --batch_size $batch_size \
        --epochs $epochs \
        --gpu $GPU \
        --height $height \
        --use_mask \
        --seed 1 \
        --beam_width 1 \
        --model "$HTRNEWMODEL" \
        --multiply $multiply \
        --output $listdir \
        --model_name $model_name \
        --output_charlist $outdir/output_charlist.charlist \
        --output $outdir/output_freeze_recurrent_dense $BASEMODEL
fi

echo "Results can be found at:"
echo $outdir

