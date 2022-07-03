#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/


probtrackX_labels_='all_subject_collect_probtrackX_select_tracts_results'
i=0
LINE_COUNT=0
SUBJECT_PROBX_FILE="${DTI_DIR}/${probtrackX_labels_}.txt"
rm -f $SUBJECT_PROBX_FILE
touch $SUBJECT_PROBX_FILE


SOURCES=("IFG_top_90" "PostTemp_top_90")
TARGETS=("IFG_top_90" "PostTemp_top_90")
#EXCLUDES=("MFG_top_90" "IFGorb_top_90")
#EXCLUDES=("IFGorb_top_90")
EXCLUDES=("MFG_top_90")
SOURCEJoin=$(IFS=- ; echo "${SOURCES[*]}")
TARGETSJoin=$(IFS=- ; echo "${TARGETS[*]}")
EXCLUDEJoin=$(IFS=- ; echo "${EXCLUDES[*]}")

printf "%s,%s,%s,%s,%s,%s\n" "row" "subject_name" "hemi" "file_loc" "segment_file" "save_loc"   >> $SUBJECT_PROBX_FILE

echo "looking at ${DTI_DIR} "
SUBJ_LINE=0
while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      lh_file="${DTI_DIR}/probtrackX_results_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/${subject_name}_LH_fdt_network.mat"
      rh_file="${DTI_DIR}/probtrackX_results_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/${subject_name}_RH_fdt_network.mat"





      if [ ! -f "$lh_file" ]
      then
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        # folder to find the file
        lh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_LH_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/fdt_network_matrix"
        SUBJECT_SOURCE_FILE="${DTI_DIR}/${subject_name}/sources_lang_glasser_LH_${SOURCEJoin}_EX_${EXCLUDEJoin}.txt"
        printf "%d,%s,%s,%s,%s,%s\n" "$LINE_COUNT" "$subject_name" "LH" "$lh_tr_file" "$SUBJECT_SOURCE_FILE" "$lh_file" >> $SUBJECT_PROBX_FILE

      fi
      if [ ! -f "$rh_file" ]
      then
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        rh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_RH_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/fdt_network_matrix"
        SUBJECT_SOURCE_FILE="${DTI_DIR}/${subject_name}/sources_lang_glasser_RH_${SOURCEJoin}_EX_${EXCLUDEJoin}.txt"
        printf "%d,%s,%s,%s,%s,%s\n" "$LINE_COUNT" "$subject_name" "RH" "$rh_tr_file" "$SUBJECT_SOURCE_FILE" "$rh_file" >> $SUBJECT_PROBX_FILE
      fi
done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")

run_val=0
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "running  ${LINE_COUNT} jobs"
   nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 collect_probtrackX_result_on_subject.sh  $SUBJECT_PROBX_FILE &
   #nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 75 100 25 collect_probtrackX_result_on_select_tracts.sh  $SUBJECT_PROBX_FILE &
  else
    echo $LINE_COUNT
fi