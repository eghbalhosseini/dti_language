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

while IFS=, read -r line_count subj_name segment_name target exclude hemi ; do
  #echo "line_count ${model}"
  if [ $JID == $line_count ]
    then
      echo "found the right match ${line_count}"
      SUB=$subj_name
      SEGNAME=$segment_name
      HEMI=$hemi
      TARGET=$target
      EXLUDE=$exclude
      do_run=true
      break
    else
      do_run=false
  fi

done <"${GRAND_FILE}"
echo "subj:${SUB}"
echo "segment :${SEGNAME}"
echo "target : ${TARGET}"
echo "exclude : ${EXLUDE}"
echo "hemi :${HEMI}"

# step 1 check if segment text files exist.
SUBJECT_SEGMENT_FILE="${DTI_DIR}/${SUB}/targets_${SEGNAME}_${TARGET}.txt"
SUBJECT_MASK_FILE="${DTI_DIR}/${SUB}/masks_${SEGNAME}_${TARGET}.txt"

SEARCH_DIR=${DTI_DIR}/${SUB}/indti/Labels/${SEGNAME}
rm -f $SUBJECT_SEGMENT_FILE
rm -f $SUBJECT_MASK_FILE

if [ ! -f "${SUBJECT_SEGMENT_FILE}" ]
      then
        touch $SUBJECT_SEGMENT_FILE
        while read x ; do
          if [[ $x == *"$EXLUDE"* ]]; then
           echo "excluding ${EXLUDE}!"
           else
             printf "%s\n" "${x}" >> $SUBJECT_SEGMENT_FILE
          fi
        done < <(find "${SEARCH_DIR}" -maxdepth 1 -type f -name "${HEMI}*" )
        # remove the target
        #line_to_rm=$(find "${SEARCH_DIR}" -maxdepth 1 -type f -name "${HEMI}_${TARGET}*")
        #echo $line_to_rm
        #sed "/^$line_to_rm/d" $SUBJECT_SEGMENT_FILE
      else
          true
fi

if [ ! -f "${SUBJECT_MASK_FILE}" ]
      then
        touch $SUBJECT_MASK_FILE
        while read x ; do
          if [[ $x == *"$TARGET"* ]]; then
           echo "It's there!"
           printf "%s\n" "${x}" >> $SUBJECT_MASK_FILE
           else
             true
          fi
        done < <(find "${SEARCH_DIR}" -maxdepth 1 -type f -name "${HEMI}*" )
      else
          true
fi


probtrackx2 -x "${SUBJECT_SEGMENT_FILE}" \
  -l --pd -c  0.2 -S 2000 --steplength=0.5 -P 5000 --forcedir --opd \
  -s "${DTI_DIR}/${SUB}/dti.bedpostX/merged" \
  -m "${DTI_DIR}/${SUB}/indti/Labels/${SEGNAME}/all-whitematter+gray.nii.gz" \
  --dir="${DTI_DIR}/${SUB}/dti.probtrackx/${SEGNAME}/" \
  --targetmasks="${DTI_DIR}/${SUB}/targets_lang_glasser_${HEMI}_{$TARGET}.txt" \
  --wtstop="${DTI_DIR}/${SUB}/masks_lang_glasser_${HEMI}_{$TARGET}.txt" \
  --network

