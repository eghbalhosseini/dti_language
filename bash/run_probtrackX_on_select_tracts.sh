#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
probtrackX_labels_='all_subject_probtrackX_select_tracts'
LINE_COUNT=0
SOURCES=("IFGorb_top_90" "AntTemp_top_90")
TARGETS=("IFGorb_top_90" "AntTemp_top_90")
EXCLUDES=("MFG_top_90" "IFG_top_90")

#SOURCES=("IFG_top_90" "PostTemp_top_90")
#TARGETS=("IFG_top_90" "PostTemp_top_90")
#EXCLUDES=("MFG_top_90" "IFGorb_top_90")
#EXCLUDES=("IFGorb_top_90")
#EXCLUDES=("MFG_top_90")



SOURCEJoin=$(IFS=- ; echo "${SOURCES[*]}")
#echo $SOURCEJoin

TARGETSJoin=$(IFS=- ; echo "${TARGETS[*]}")
#echo $TARGETSJoin

EXCLUDEJoin=$(IFS=- ; echo "${EXCLUDES[*]}")
#echo $EXCLUDEJoin


SUBJECT_PROBX_FILE="${DTI_DIR}/${probtrackX_labels_}.txt"
rm -f $SUBJECT_PROBX_FILE
touch $SUBJECT_PROBX_FILE
printf "%s,%s,%s,%s,%s,%s,%s\n" "row" "subject_name" "segment_name" "source_name" "target_name" "exclude_name" "hemi"   >> $SUBJECT_PROBX_FILE

echo "looking at ${DTI_DIR} "
while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      lh_folder="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_LH_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/fdt_paths.nii.gz"
      #rm $lh_folder
      rh_folder="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_RH_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/fdt_paths.nii.gz"
      #rm $rh_folder
      if [ ! -f "$lh_folder" ]
      then
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        printf "%d,%s,%s,%s,%s,%s,%s\n" "$LINE_COUNT" "$subject_name" "lang_glasser_LH" "$SOURCEJoin" "$TARGETSJoin" "$EXCLUDEJoin" "LH" >> $SUBJECT_PROBX_FILE
      fi
      if [ ! -f "$rh_folder" ]
      then
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        printf "%d,%s,%s,%s,%s,%s,%s\n" "$LINE_COUNT" "$subject_name" "lang_glasser_RH" "$SOURCEJoin" "$TARGETSJoin" "$EXCLUDEJoin" "RH">> $SUBJECT_PROBX_FILE
      fi
done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")

run_val=0
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "running  ${LINE_COUNT} jobs"
   #nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 probtrackX_on_select_tracts.sh  $SUBJECT_PROBX_FILE
   nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 75 100 25 probtrackX_on_select_tracts.sh  $SUBJECT_PROBX_FILE &
  else
    echo $LINE_COUNT
fi