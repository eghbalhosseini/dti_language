#!/bin/bash
#SBATCH -c 8
#SBATCH --exclude node[017-018,094]
#SBATCH -t 96:00:00
#SBATCH --mem=64G
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

while IFS=, read -r line_count subj_name hemi fdt_file ; do
  #echo "line_count ${model}"
  if [ $JID == $line_count ]
    then
      echo "found the right match ${line_count}"
      SUB=$subj_name
      SEGNAME=$segment_name
      HEMI=$hemi
      FILE_NAME=$fdt_file
      do_run=true
      break
    else
      do_run=false
  fi

done <"${GRAND_FILE}"
echo "subj:${SUB}"
echo "segment :${SEGNAME}"
echo "hemi :${HEMI}"

# step 1 check if segment text files exist.
SUBJECT_SEGMENT_FILE="${DTI_DIR}/${SUB}/targets_${SEGNAME}.txt"
SEARCH_DIR=${DTI_DIR}/${SUB}/indti/Labels/${SEGNAME}
if [ ! -f "${SUBJECT_SEGMENT_FILE}" ]
      then
        touch $SUBJECT_SEGMENT_FILE
        while read x ; do
          printf "%s\n" "${x}" >> $SUBJECT_SEGMENT_FILE
        done < <(find "${SEARCH_DIR}" -maxdepth 1 -type f -name "${HEMI}*" )
      else
          true
fi

probtrackx2 -x "${SUBJECT_SEGMENT_FILE}" \
  -l --pd -c  0.2 -S 2000 --steplength=0.5 -P 5000 --forcedir --opd \
  -s "${DTI_DIR}/${SUB}/dti.bedpostX/merged" \
  -m "${DTI_DIR}/${SUB}/indti/Labels/${SEGNAME}/all-whitematter+gray.nii.gz" \
  --dir="${DTI_DIR}/${SUB}/dti.probtrackx/${SEGNAME}/" \
  --targetmasks="${DTI_DIR}/${SUB}/targets_lang_glasser_${HEMI}.txt" --network

