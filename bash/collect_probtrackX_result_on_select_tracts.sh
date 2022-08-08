#!/bin/bash

#SBATCH --exclude node[017-018,094]
#SBATCH -t 96:00:00
#SBATCH --mem=20G
GRAND_FILE=$1
OVERWRITE='false' # or 'true'
#
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
  JID=$SLURM_ARRAY_TASK_ID    # Taking the task ID in a job array as an input parameter.
else
  JID=$2       # Taking the task ID as an input parameter.
fi
echo "${GRAND_FILE}"
echo $JID

while IFS=, read -r line_count subj_name hemi fdt_file segment_file save_file ; do
  #echo "line_count ${model}"
  if [ $JID == $line_count ]
    then
      echo "found the right match ${line_count}"
      SUB=$subj_name
      HEMI=$hemi
      FILE_NAME=$fdt_file
      SEGMENT_NAME=$segment_file
      SAVE_NAME=$save_file
      do_run=true
      break
    else
      do_run=false
  fi

done <"${GRAND_FILE}"
echo "subj: ${SUB}"
echo "file: ${FILE_NAME}"
echo "segment file: ${SEGMENT_NAME}"
echo "save file: ${SAVE_NAME}"
echo "hemi: ${HEMI}"

# step 1 check if segment text files exist.

module load mit/matlab/2021a
matlab -nosplash -nojvm -r "addpath('/om2/user/ehoseini/dti_language/');\
cd('/om2/user/ehoseini/dti_language/');\
disp('running transformation');transform_probtrackX_output('file_id','${FILE_NAME}','target_mask_file','${SEGMENT_NAME}','save_dir','${SAVE_NAME}','hemi','${HEMI}');exit"


# copy nii files
x=$fdt_file
original='fdt_network_matrix'
correction='fdt_paths.nii.gz'
nii_src_file="${x/$original/$correction}"

x=$save_file
original='fdt_network'
correction='fdt_paths.nii.gz'
nii_targ_file="${x/$original/$correction}"

cp $nii_src_file $nii_targ_file