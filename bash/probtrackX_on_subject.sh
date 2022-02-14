#!/bin/bash
#SBATCH -c 8
#SBATCH --exclude node[017-018]
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

while IFS=, read -r line_count subj_name segment_name hemi ; do
  #echo "line_count ${model}"
  if [ $JID == $line_count ]
    then
      echo "found the right match ${line_count}"
      SUB=$subj_name
      SEGNAME=$segment_name
      HEMI=$hemi
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
if [ ! -f "$SUBJECT_SEGMENT_FILE" ]
      then
        touch $SUBJECT_SEGMENT_FILE
        while read x ; do
          printf "%s\n" "${x}" >> $SUBJECT_SEGMENT_FILE
        done < <(find "${SEARCH_DIR}" -maxdepth 1 -type f -name "${HEMI}*" )
      else
          true
fi

