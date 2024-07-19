#!/bin/bash
set -e

VERSION=1.2.10
# Stop on error, if set to 1 will exit program if any of the docker commands fail
set -e
STOPONERROR=1

# set to 1 if you want to enable, 0 otherwise, select just one
BASELINELAYPA=1

# This is the baseline detection model (Laypa). You need to configure this to the correct path.
# The first one is laypa config file, the second one is the model weights

LAYPAMODEL=/home/x_zhyan/Desktop/x_zhyan/loghi/config.yaml
LAYPAMODELWEIGHTS=/home/x_zhyan/Desktop/x_zhyan/loghi/model_best_mIoU.pth

# Set to 1 to enable HTR process, 0 otherwise. If 0 it will skip HTR process, just do baseline detection.
HTRLOGHI=1

# This is the HTR model (Loghi-HTR). You need to configure this to the correct path (Only specify the model folder, not an exact model weights file in keras format).
HTRLOGHIMODEL=/proj/berzelius-2024-46/users/x_zhyan/models/output_all_with_finetune/best_val

# Set this to 1 for recalculating reading order, line clustering and cleaning.
RECALCULATEREADINGORDER=1
# If the edge of baseline is closer than x pixels...
RECALCULATEREADINGORDERBORDERMARGIN=50
# Clean if 1
RECALCULATEREADINGORDERCLEANBORDERS=0
# How many threads to use
RECALCULATEREADINGORDERTHREADS=4

# Detect language of pagexml, set to 1 to enable, disable otherwise (Not implemented yet)
DETECTLANGUAGE=0

# Interpolate word locations
SPLITWORDS=1

# Higher beamwidth makes results slightly better at the expense of lot of computation time. Six is a sweet spot.
# This is for CTC decoder.
BEAMWIDTH=6

# -1 for CPU, 0 for the first GPU, 1 for the second GPU, etc. Multiple-GPU is not supported.
GPU=0

# Docker images path (Deprecated)
DOCKERLOGHITOOLING=docker://loghi/docker.loghi-tooling:$VERSION
DOCKERLAYPA=docker://loghi/docker.laypa:$VERSION
DOCKERLOGHIHTR=docker://loghi/docker.htr:$VERSION
USE2013NAMESPACE=" -use_2013_namespace "

# DO NO EDIT BELOW THIS LINE
if [ -z $1 ]; then echo "Please provide path to images to be HTR-ed" && exit 1; fi;
tmpdir=$(mktemp -d)
echo $tmpdir

DOCKERGPUPARAMS=""
if [[ $GPU -gt -1 ]]; then
        DOCKERGPUPARAMS="--nv"
        echo "Using GPU ${GPU}"
fi

SRC=$1

mkdir $tmpdir/imagesnippets/
mkdir $tmpdir/linedetection
mkdir $tmpdir/output


find $SRC -name '*.done' -exec rm -f "{}" \;


if [[ $BASELINELAYPA -eq 1 ]]
then
        echo "Starting Laypa baseline detection"

        input_dir=$SRC
        output_dir=$SRC
	echo $output_dir
        LAYPADIR="$(dirname "${LAYPAMODEL}")"

        if [[ ! -d $input_dir ]]; then
                echo "Specified input dir (${input_dir}) does not exist, stopping program"
                exit 1
        fi

        if [[ ! -d $output_dir ]]; then
                echo "Could not find output dir (${output_dir}), creating one at specified location"
                mkdir -p $output_dir
        fi
#python laypa-c46490c8fbdb78795bddd9c192b8958d941b5e27/run.py \
# Run laypa in Apptainer, using GPU
        apptainer exec --nv laypa.sif \
	python laypa-1.2.10/run.py \
        -c $LAYPAMODEL \
        -i $input_dir \
        -o $output_dir \
        --opts MODEL.WEIGHTS "" TEST.WEIGHTS $LAYPAMODELWEIGHTS | tee -a $tmpdir/log.txt

        # > /dev/null

        if [[ $STOPONERROR && $? -ne 0 ]]; then
                echo "Laypa errored has errored, stopping program"
                exit 1
        fi
# Run Laypa tools in Apptainer, first extract baselines
        apptainer exec tool.sif /src/loghi-tooling/minions/target/appassembler/bin/MinionExtractBaselines \
        -input_path_png $output_dir/page/ \
        -input_path_page $output_dir/page/ \
        -output_path_page $output_dir/page/ \
        -as_single_region true \
        -laypaconfig $LAYPAMODEL $USE2013NAMESPACE | tee -a $tmpdir/log.txt


        if [[ $STOPONERROR && $? -ne 0 ]]; then
                echo "MinionExtractBaselines (Laypa) errored has errored, stopping program"
                exit 1
        fi
fi

# #HTR option 1 LoghiHTR
if [[ $HTRLOGHI -eq 1 ]]
then

        echo "starting Loghi HTR"
        # Then cut images into image snippets
       apptainer exec tool.sif /src/loghi-tooling/minions/target/appassembler/bin/MinionCutFromImageBasedOnPageXMLNew \
       -input_path $SRC \
       -outputbase $tmpdir/imagesnippets/ \
       -output_type png \
       -channels 4 \
       -threads 4 $USE2013NAMESPACE| tee -a $tmpdir/log.txt


        if [[ $STOPONERROR && $? -ne 0 ]]; then
                echo "MinionCutFromImageBasedOnPageXMLNew has errored, stopping program"
                exit 1
        fi

       find $tmpdir/imagesnippets/ -type f -name '*.png' > $tmpdir/lines.txt

	LOGHIDIR="$(dirname "${HTRLOGHIMODEL}")"
        # CUDA_VISIBLE_DEVICES=-1 python3 ~/src/htr/src/main.py --do_inference --channels 4 --height $HTR_LOGHI_MODEL_HEIGHT --existing_model ~/src/htr/$HTR_LOGHI_MODEL  --batch_size 32 --use_mask --inference_list $tmpdir/lines.txt --results_file $tmpdir/results.txt --charlist ~/src/htr/$HTR_LOGHI_MODEL.charlist --gpu $GPU
#        apptainer run $DOCKERGPUPARAMS --rm -m 32000m --shm-size 10240m -ti -v $tmpdir:$tmpdir docker.htr python3 /src/src/main.py --do_inference --channels 4 --height $HTRLOGHIMODELHEIGHT --existing_model /src/loghi-htr-models/$HTRLOGHIMODEL  --batch_size 10 --use_mask --inference_list $tmpdir/lines.txt --results_file $tmpdir/results.txt --charlist /src/loghi-htr-models/$HTRLOGHIMODEL.charlist --gpu $GPU --output $tmpdir/output/ --config_file_output $tmpdir/output/config.txt --beam_width 10
        # Initialize Loghi-HTR
        # Some of the arguments are not listed here, but they might be useful.

        # --optimizer: Optimizer to use, default is adam
        # --seed: Seed for random number generator, default is 42
        # --channels: Number of channels in the input image, default is 3. If set to 1, some other changes are required.
        # --decay_steps and --decay_rate: Learning rate decay, default is 0.99 and -1 (no decay). These are in beta stage.
        # --use_float32: Use float32 instead of float16, default is float16 for training.
        # --replace_recurrent_layer: Use this to replace the recurrent layers in a newly defined model with new ones.
        # --freeze_conv(dense/recurrent)_layers: Freeze the conv/dense/recurrent layers of the model. This is useful for transfer learning.

        apptainer run --nv htr.sif \
	bash -c "LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libtcmalloc_minimal.so.4 python3 /src/loghi-htr/src/main.py \
        --do_inference \
        --existing_model $HTRLOGHIMODEL  \
        --batch_size 64 \
        --use_mask \
        --inference_list $tmpdir/lines.txt \
        --results_file $tmpdir/results.txt \
        --charlist $HTRLOGHIMODEL/charlist.txt \
        --gpu $GPU \
        --output $tmpdir/output/ \
        --config_file_output $tmpdir/output/config.json \
        --beam_width $BEAMWIDTH " | tee -a $tmpdir/log.txt

        if [[ $STOPONERROR && $? -ne 0 ]]; then
                echo "Loghi-HTR has errored, stopping program"
                exit 1
        fi
        apptainer run tool.sif /src/loghi-tooling/minions/target/appassembler/bin/MinionLoghiHTRMergePageXML \
                -input_path $SRC/page \
                -results_file $tmpdir/results.txt \
                -config_file $tmpdir/output/config.json $USE2013NAMESPACE | tee -a $tmpdir/log.txt


        if [[ $STOPONERROR && $? -ne 0 ]]; then
                echo "MinionLoghiHTRMergePageXML has errored, stopping program"
                exit 1
        fi
fi

if [[ $RECALCULATEREADINGORDER -eq 1 ]]
then
        echo "recalculating reading order"
        if [[ $RECALCULATEREADINGORDERCLEANBORDERS -eq 1 ]]
        then
                echo "and cleaning"
                apptainer run tool.sif /src/loghi-tooling/minions/target/appassembler/bin/MinionRecalculateReadingOrderNew \
                        -input_dir $SRC/page/ \
			-border_margin $RECALCULATEREADINGORDERBORDERMARGIN \
			-clean_borders \
			-threads $RECALCULATEREADINGORDERTHREADS $USE2013NAMESPACE | tee -a $tmpdir/log.txt

                if [[ $STOPONERROR && $? -ne 0 ]]; then
                        echo "MinionRecalculateReadingOrderNew has errored, stopping program"
                        exit 1
                fi
        else
                apptainer run tool.sif /src/loghi-tooling/minions/target/appassembler/bin/MinionRecalculateReadingOrderNew \
                        -input_dir $SRC/page/ \
			-border_margin $RECALCULATEREADINGORDERBORDERMARGIN \
			-threads $RECALCULATEREADINGORDERTHREADS $USE2013NAMESPACE| tee -a $tmpdir/log.txt

                if [[ $STOPONERROR && $? -ne 0 ]]; then
                        echo "MinionRecalculateReadingOrderNew has errored, stopping program"
                        exit 1
                fi
        fi
fi
if [[ $DETECTLANGUAGE -eq 1 ]]
then
        echo "detecting language..."
        apptainer run tool.sif /src/loghi-tooling/minions/target/appassembler/bin/MinionDetectLanguageOfPageXml \
                -page $SRC/page/ $USE2013NAMESPACE | tee -a $tmpdir/log.txt


        if [[ $STOPONERROR && $? -ne 0 ]]; then
                echo "MinionDetectLanguageOfPageXml has errored, stopping program"
                exit 1
        fi
fi


if [[ $SPLITWORDS -eq 1 ]]
then
        echo "MinionSplitPageXMLTextLineIntoWords..."
        apptainer run tool.sif /src/loghi-tooling/minions/target/appassembler/bin/MinionSplitPageXMLTextLineIntoWords \
                -input_path $SRC/page/ $USE2013NAMESPACE | tee -a $tmpdir/log.txt

        if [[ $STOPONERROR && $? -ne 0 ]]; then
                echo "MinionSplitPageXMLTextLineIntoWords has errored, stopping program"
                exit 1
        fi
fi

# cleanup results
rm -rf $tmpdir

