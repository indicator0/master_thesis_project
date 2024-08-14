# Swedish HTR

## Setup
### To use this HTR pipeline, please set up Apptainer and NVDIA-related environments.

Clone this repo into your local machine, then download SIF files, PTH file and HTR models and put them into the repo root directory.
You may choose one of the models, and put the entire "best_val" folder into the root directory (The model named output_all_with_finetune is recommended to use).

### To create your own training/validation set, please use apptainer-create-new.sh. Type "sh PATH_TO_THIS_SHELL_SCRIPT PATH_TO_YOUR_IMAGES OUTPUT_DIRCTORY"
All your PageXML files should be stored in a folder called "page" under the PATH_TO_YOUR_IMAGES.

### To train your own model, please use apptainer-train.sh. Type "sh PATH_TO_THIS_SHELL_SCRIPT"
Most of the arguments should be setup inside the shell script.

### To make inference (test), please use apptainer-pipe.sh. Type "sh PATH_TO_THIS_SHELL_SCRIPT PATH_TO_YOUR_IMAGES"
All the predicted PageXML files should be stored in a folder called "page" under the PATH_TO_YOUR_IMAGES.
In config.yaml, you may find two entries MAX_SIZE_TEST and MIN_SIZE_TEST. When dealing with large images, you may need to adjust these two values to a higer value, and vice versa.
1536 for MAX_SIZE_TEST and 768 for MIN_SIZE_TEST are recommended for pictures taken by popular mobiles and cameras.


### Folder strcture
#### Project_folder
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

### There are some auxiliary files that are not directly related to the HTR pipeline, but are important for result analysis.
        -compare.py (for comparing the results between two HTR models)
        -flask_test (for running a web server to visualize the results)
                        -static
                        -templates
                        -app.py

### To visulize the result, please use flask. Type "python app.py" under the flask folder.
Image input and result xml input directory are hard coded in app.py. You may need to change the directory in the code.

#### .sif files, .pth file and HTR models are available to download at the following links.

##### SIF files: https://1drv.ms/f/s!AhLc1l9ln_Uug-5MWa5ElHAlSCzeaQ?e=MyU546
##### PTH file: https://1drv.ms/u/s!AhLc1l9ln_Uug9wag9FqW8u9h2HaIw?e=pdecqO
##### HTR models: https://1drv.ms/f/s!AhLc1l9ln_Uug9w4eeSPAcwlQqXiQQ?e=RBeIgl