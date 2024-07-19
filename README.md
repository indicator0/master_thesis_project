# Swedish HTR

## Setup
### To use this HTR pipeline, please set up Apptainer and NVDIA-related environments.

#### To create your own training/validation set, please use apptainer-create-new.sh. Type "sh PATH_TO_THIS_SHELL_SCRIPT PATH_TO_YOUR_IMAGES OUTPUT_DIRCTORY"
#### All your PageXML files should be stored in a folder called "page" under the PATH_TO_YOUR_IMAGES.

#### To train your own model, please use apptainer-train.sh. Type "sh PATH_TO_THIS_SHELL_SCRIPT"
#### Most of the arguments should be setup inside the shell script.

#### To make inference (test), please use apptainer-pipe.sh. Type "sh PATH_TO_THIS_SHELL_SCRIPT PATH_TO_YOUR_IMAGES"
#### All the predicted PageXML files should be stored in a folder called "page" under the PATH_TO_YOUR_IMAGES.


### Folder strcture
-Project_folder
        -laypa folder
        -HTR model folder (best_val_nov30)
                -charlist.txt
                -config.json
                -model.keras
        -apptainer-create-new.sh
        -apptainer-train.sh
        -apptainer-pipe.sh
        -htr.sif
        -laypa.sif
        -tool.sif
        -run.py
        -model_best_mIoU.pth (baseline detection model)
        -config.yaml (work with model_best_mIoU.pth)
