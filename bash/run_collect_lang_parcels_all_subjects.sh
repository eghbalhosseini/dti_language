#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/

threshold=$1
echo "threshold:${threshold}"

probtrackX_labels_='all_subject_collect_for_glasser_results'
i=0
LINE_COUNT=0
SUBJECT_PROBX_FILE="${DTI_DIR}/${probtrackX_labels_}.txt"
rm -f $SUBJECT_PROBX_FILE
touch $SUBJECT_PROBX_FILE
printf "%s,%s,%s,%s,%s,%s\n" "row" "subject_name" "hemi" "file_loc" "save_loc" "thr"   >> $SUBJECT_PROBX_FILE

echo "looking at ${DTI_DIR} "

mkdir -p "${DTI_DIR}/lang_glasser_parcels_thr_${threshold}"
SUBJ_LINE=0
overwrite=false
while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      src_file="${DTI_DIR}/${subject_name}/indti/lang_glasser_BOTH_thr_${threshold}_indti.nii.gz"
      target_file="${DTI_DIR}/lang_glasser_parcels_thr_${threshold}/${subject_name}_lang_glasser_BOTH_thr_${threshold}_indti.nii.gz"
      cp ${src_file} ${target_file}
      src_file="${DTI_DIR}/${subject_name}/indti/lang_glasser_LH_thr_${threshold}_indti.nii.gz"
      target_file="${DTI_DIR}/lang_glasser_parcels_thr_${threshold}/${subject_name}_lang_glasser_LH_thr_${threshold}_indti.nii.gz"
      cp ${src_file} ${target_file}
      src_file="${DTI_DIR}/${subject_name}/indti/lang_glasser_RH_thr_${threshold}_indti.nii.gz"
      target_file="${DTI_DIR}/lang_glasser_parcels_thr_${threshold}/${subject_name}_lang_glasser_RH_thr_${threshold}_indti.nii.gz"
      cp ${src_file} ${target_file}
done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")

