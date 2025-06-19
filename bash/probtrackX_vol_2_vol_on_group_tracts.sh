#!/bin/bash
#SBATCH --exclude node[017-018,094]
#SBATCH -t 2:00:00
#SBATCH --mem=10G

GRAND_FILE=$1
OVERWRITE='false' # or 'true'
#
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
SUBJECT_FS_DIR="${DTI_DIR}/${SUBJ}/fs/" # Base freesurfer dir
SUBJECT_REG_DIR="${DTI_DIR}/${SUBJ}/lang_glasser/" # Base freesurfer dir

if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
  JID=$SLURM_ARRAY_TASK_ID    # Taking the task ID in a job array as an input parameter.
else
  JID=$2       # Taking the task ID as an input parameter.
fi
echo "${GRAND_FILE}"
echo $JID

while IFS=, read -r line_count subj_name segment_name sourceJoin targetJoin excludeJoin hemi threshold ; do
  #echo "line_count ${model}"
  if [ $JID == $line_count ]
    then
      echo "found the right match ${line_count}"
      SUB=$subj_name
      SEGNAME=$segment_name
      HEMI=$hemi
      SOURCES=$sourceJoin
      TARGETS=$targetJoin
      EXCLUDES=$excludeJoin
      THR=$threshold
      do_run=true
      break
    else
      do_run=false
  fi

done <"${GRAND_FILE}"
echo "subj:${SUB}"
echo "segment :${SEGNAME}"
echo "sources : ${SOURCES}"
echo "targets : ${TARGETS}"
echo "excludes : ${EXCLUDES}"
echo "hemi :${HEMI}"
echo "threshold :${THR}"



mov_file="${DTI_DIR}/${SUB}/dti.probtrackx/${SEGNAME}_${SOURCES}_TO_${TARGETS}_EX_${EXCLUDES}/fdt_paths.nii.gz"
output_file="${DTI_DIR}/${SUB}/dti.probtrackx/${SEGNAME}_${SOURCES}_TO_${TARGETS}_EX_${EXCLUDES}/fdt_paths_in_orig.nii.gz"
reg_file="${SUBJECT_REG_DIR}/reg_FS2nodif.dat"
FS_file="${SUBJECT_FS_DIR}/mri/brain.mgz"

mri_vol2vol \
--mov "$mov_file" \
--targ "$FS_file" \
--interp nearest \
--reg  "$reg_file" \
--o "$output_file"


