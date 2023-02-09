#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/

threshold=$1
echo "threshold:${threshold}"

probtrackX_labels_='all_subject_collect_probtrackX_results'
i=0
LINE_COUNT=0
SUBJECT_PROBX_FILE="${DTI_DIR}/${probtrackX_labels_}.txt"
rm -f $SUBJECT_PROBX_FILE
touch $SUBJECT_PROBX_FILE
printf "%s,%s,%s,%s,%s,%s\n" "row" "subject_name" "hemi" "file_loc" "save_loc" "thr"   >> $SUBJECT_PROBX_FILE

echo "looking at ${DTI_DIR} "

mkdir -p "${DTI_DIR}/probtrackX_results_lang_glasser_thr_${threshold}"
SUBJ_LINE=0
overwrite=false
while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      lh_file="${DTI_DIR}/probtrackX_results_lang_glasser_thr_${threshold}/${subject_name}_LH_fdt_network.mat"
      lh_path_file="${DTI_DIR}/probtrackX_results_lang_glasser_thr_${threshold}/${subject_name}_LH_fdt_paths.nii.gz"
      rh_file="${DTI_DIR}/probtrackX_results_lang_glasser_thr_${threshold}/${subject_name}_RH_fdt_network.mat"
      rh_path_file="${DTI_DIR}/probtrackX_results_lang_glasser_thr_${threshold}/${subject_name}_RH_fdt_paths.nii.gz"
      if [ "$overwrite" = true ]
      then
        echo "overwriting ${lh_file}"
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        lh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_LH_thr_${threshold}/fdt_network_matrix"
        printf "%d,%s,%s,%s,%s,%d\n" "$LINE_COUNT" "$subject_name" "LH" "$lh_tr_file" "$lh_file" "$threshold" >> $SUBJECT_PROBX_FILE
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        rh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_RH_thr_${threshold}/fdt_network_matrix"
        printf "%d,%s,%s,%s,%s,%d\n" "$LINE_COUNT" "$subject_name" "RH" "$rh_tr_file" "$rh_file" "$threshold" >> $SUBJECT_PROBX_FILE
      else
        if [ ! -f "$lh_file" ]
        then
          LINE_COUNT=$(expr ${LINE_COUNT} + 1)
          # folder to find the file
          lh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_LH_thr_${threshold}/fdt_network_matrix"
          printf "%d,%s,%s,%s,%s,%d\n" "$LINE_COUNT" "$subject_name" "LH" "$lh_tr_file" "$lh_file" "$threshold" >> $SUBJECT_PROBX_FILE
        fi
        if [ ! -f "$rh_file" ]
        then
          LINE_COUNT=$(expr ${LINE_COUNT} + 1)
          rh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_RH_thr_${threshold}/fdt_network_matrix"
          printf "%d,%s,%s,%s,%s,%d\n" "$LINE_COUNT" "$subject_name" "RH" "$rh_tr_file" "$rh_file" "$threshold" >> $SUBJECT_PROBX_FILE
        fi
      fi
done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")

run_val=0
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "running  ${LINE_COUNT} jobs"
  if [ "$LINE_COUNT" -lt 100 ] ; then
    echo "less than 100 jobs:  ${LINE_COUNT} jobs"
    nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT "$LINE_COUNT" "$LINE_COUNT" 0 collect_probtrackX_result_on_subject.sh  $SUBJECT_PROBX_FILE
  else
    echo "more than 100 jobs:  ${LINE_COUNT} jobs"
    #nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 collect_probtrackX_result_on_subject.sh  $SUBJECT_PROBX_FILE
    nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 75 100 25 collect_probtrackX_result_on_subject.sh  $SUBJECT_PROBX_FILE &
  fi
  else
    echo $LINE_COUNT
fi