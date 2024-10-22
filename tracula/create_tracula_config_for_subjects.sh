#!/bin/bash

# Define the base directory where the subject folders are located
BASE_DIR="/mindhive/evlab/Shared/diffusionzeynep"

# Template content of the configuration file, where {subj} will be replaced with actual subject ID
TEMPLATE_CONTENT='
# FreeSurfer SUBJECTS_DIR
# T1 images and FreeSurfer segmentations are expected to be found here
setenv SUBJECTS_DIR //mindhive/evlab/u/Shared/SUBJECTS_FS/FS
# Output directory where trac-all results will be saved
#
set dtroot = /mindhive/evlab/Shared/diffusionzeynep/{subj}/trc
set bedpdir = /mindhive/evlab/Shared/diffusionzeynep/{subj}/dti.bedpostX
cp -r /mindhive/evlab/Shared/diffusionzeynep/{subj}/dti.bedpostX/* /mindhive/evlab/Shared/diffusionzeynep/{subj}/trc/{subj}/dmri.bedpostX/
# Subject IDs
#
set subjlist = ({subj})
# Input DWI volumes (file names relative to dcmroot)
#
set dcmroot = (/mindhive/evlab/Shared/diffusionzeynep/)
set dcmlist = ({subj}/dti/data.nii.gz )
# Input gradient tables (file names relative to dcmroot)
#
set bveclist = (/mindhive/evlab/Shared/diffusionzeynep/{subj}/dti/bvecs)
#set bveclist = ({subj}/dti/bvecs)
# Input b-value tables (file names relative to dcmroot)
set bvallist = (/mindhive/evlab/Shared/diffusionzeynep/{subj}/dti/bvals)
#set bvallist = ({subj}/dti/bvals)
'

# Find all directories matching the pattern "sub###"
SUBJECTS=$(find "$BASE_DIR" -maxdepth 1 -type d -name 'sub[0-9][0-9][0-9]' -printf '%f\n')

# Iterate over each subject directory
for subj in $SUBJECTS; do
    # Define the subject's directory and output file path
    SUBJECT_DIR="$BASE_DIR/$subj"
    OUTPUT_FILE="$SUBJECT_DIR/tracula_config_${subj}.csh"

    # Replace {subj} in the template content with the actual subject ID
    FILE_CONTENT=$(echo "$TEMPLATE_CONTENT" | sed "s/{subj}/$subj/g")

    # Write the content to the output file
    echo "$FILE_CONTENT" > "$OUTPUT_FILE"

    # Print a message for confirmation
    echo "Created file $OUTPUT_FILE for subject $subj"
done