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

while IFS=, read -r line_count subj_name segment_name sourceJoin targetJoin excludeJoin hemi ; do
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

source_array=(`echo $SOURCES | sed 's/-/\n/g'`)
target_array=(`echo $TARGETS | sed 's/-/\n/g'`)
exclude_array=(`echo $EXCLUDES | sed 's/-/\n/g'`)


# step 1 check if segment text files exist.
SUBJECT_SOURCE_FILE="${DTI_DIR}/${SUB}/sources_${SEGNAME}_${SOURCES}_EX_${EXCLUDES}.txt"
SUBJECT_TARGET_FILE="${DTI_DIR}/${SUB}/targets_${SEGNAME}_${TARGETS}_EX_${EXCLUDES}.txt"
SUBJECT_MASK_FILE="${DTI_DIR}/${SUB}/masks_${SEGNAME}_${EXCLUDES}.txt"
#
#SEARCH_DIR=${DTI_DIR}/${SUB}/indti/Labels/${SEGNAME}
rm -f $SUBJECT_SOURCE_FILE
rm -f $SUBJECT_TARGET_FILE
rm -f $SUBJECT_MASK_FILE
#
touch $SUBJECT_SOURCE_FILE
for x in "${source_array[@]}"; do
  source_file="${DTI_DIR}/${SUB}/indti/Labels/${SEGNAME}/${HEMI}_${x}.nii.gz"
  if [ -f "$source_file" ]
  then
	  printf "%s\n" "${source_file}" >> $SUBJECT_SOURCE_FILE
	fi
done

touch $SUBJECT_TARGET_FILE
for x in "${target_array[@]}"; do
  target_file="${DTI_DIR}/${SUB}/indti/Labels/${SEGNAME}/${HEMI}_${x}.nii.gz"
  if [ -f "$target_file" ]
   then
     printf "%s\n" "${target_file}" >> $SUBJECT_TARGET_FILE
  fi

done

touch $SUBJECT_MASK_FILE
for x in "${exclude_array[@]}"; do
  mask_file="${DTI_DIR}/${SUB}/indti/Labels/${SEGNAME}/${HEMI}_${x}.nii.gz"
  if [ -f "$mask_file" ]
  then
	  printf "%s\n" "${mask_file}" >> $SUBJECT_MASK_FILE
	fi
done

probtrackx2 -x "${SUBJECT_SOURCE_FILE}" \
  -l --pd -c  0.2 -S 2000 --steplength=0.5 -P 5000 --forcedir --opd \
  -s "${DTI_DIR}/${SUB}/dti.bedpostX/merged" \
  -m "${DTI_DIR}/${SUB}/indti/Labels/${SEGNAME}/all-whitematter+gray.nii.gz" \
  --dir="${DTI_DIR}/${SUB}/dti.probtrackx/${SEGNAME}_${SOURCES}_TO_${TARGETS}_EX_${EXCLUDES}/" \
  --targetmasks="${SUBJECT_TARGET_FILE}" \
  --stop="${SUBJECT_MASK_FILE}" \
  --network

