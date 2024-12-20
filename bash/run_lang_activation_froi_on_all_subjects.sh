#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
FS_DIR=/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/


network_id="lang"
threshold="20"
#

analyze_fROI='all_subject_for_activation_fROI'
i=0
LINE_COUNT=0
SUBJECT_FROI_FILE="${DTI_DIR}/${analyze_fROI}.txt"
rm -f $SUBJECT_FROI_FILE
touch $SUBJECT_FROI_FILE
printf "%s,%s,%s,%s\n" "row" "subject_name" "network_id" "threshold"    >> $SUBJECT_FROI_FILE

echo "looking at ${DTI_DIR} "
SUBJ_LINE=0
while read x; do
      # check if file already exist in fmri dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      possible_folder="${DTI_DIR}/${subject_name}/indti"

      possible_top_file="${possible_folder}/${network_id}_act_BOTH_top_${threshold}_indti.nii.gz"
      possible_bottom_file="${possible_folder}/${network_id}_act_BOTH_bottom_${threshold}_indti.nii.gz"
      if [ -f "$possible_top_file" ] && [ -f "$possible_bottom_file" ]
      then
        true
      else
        echo "indti activation files dont exist, adding them"
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        mkdir -p $possible_folder
        printf "%d,%s,%s,%s\n" "$LINE_COUNT" "$subject_name" "$network_id" "$threshold"  >> $SUBJECT_FROI_FILE
      fi
done < <(find $DTI_DIR -type d -maxdepth 1 -name "sub*")

run_val=0
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "running  ${LINE_COUNT} jobs"
   #nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 lang_froi_act_on_subject.sh  $SUBJECT_FROI_FILE
   nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 150 200 50 lang_froi_act_on_subject.sh  $SUBJECT_FROI_FILE
  else
    echo $LINE_COUNT
fi