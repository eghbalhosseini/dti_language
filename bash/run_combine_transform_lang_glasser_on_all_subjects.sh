#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
FS_DIR=/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/


network_id="lang"
threshold="20"

#

combine_fmri_glasser='all_subject_for_combine_fmri_glasser'
i=0
LINE_COUNT=0
SUBJECT_COMBINED_FILE="${DTI_DIR}/${combine_fmri_glasser}.txt"
rm -f $SUBJECT_COMBINED_FILE
touch $SUBJECT_COMBINED_FILE
printf "%s,%s,%s,%s\n" "row" "subject_name" "network_id" "threshold"    >> $SUBJECT_COMBINED_FILE

echo "looking at ${DTI_DIR} "
SUBJ_LINE=0
overwrite=true
while read x; do
      # check if file already exist in fmri dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      possible_folder="${DTI_DIR}/${subject_name}/indti"
      possible_file="${possible_folder}/lang_glasser_BOTH_thr_${threshold}_indti.nii.gz"
      # find previous files and delete them

      if [ -f "$possible_file" ] && [ ! $overwrite ]
      then
        true
      else
        echo "$possible_file dosent exists adding it"
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        mkdir -p $possible_folder
        printf "%d,%s,%s,%s\n" "$LINE_COUNT" "$subject_name" "$network_id" "$threshold"  >> $SUBJECT_COMBINED_FILE
      fi
done < <(find $DTI_DIR -type d -maxdepth 1 -name "sub*")

run_val=0
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "running  ${LINE_COUNT} jobs"
   #nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 combine_lang_glasser_on_subject.sh  $SUBJECT_COMBINED_FILE
   if [ "$LINE_COUNT" -lt 100 ]; then
     nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT "$LINE_COUNT" "$LINE_COUNT" 0 combine_lang_glasser_on_subject.sh  $SUBJECT_COMBINED_FILE
  else
   nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 75 100 25 combine_lang_glasser_on_subject.sh  $SUBJECT_COMBINED_FILE
   fi
  else
    echo $LINE_COUNT
fi