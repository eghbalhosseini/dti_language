#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
FS_DIR=/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/

aparc_aseg_labels_='all_subject_aparc_aseg_labels'
i=0
LINE_COUNT=0
SUBJECT_LABEL_FILE="${DTI_DIR}/${aparc_aseg_labels_}.txt"
rm -f $SUBJECT_LABEL_FILE
touch $SUBJECT_LABEL_FILE
printf "%s,%s\n" "row" "subject_name"    >> $SUBJECT_LABEL_FILE

echo "looking at ${DTI_DIR} "
SUBJ_LINE=0
while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"

      lh_folder="${DTI_DIR}/${subject_name}/indti/Labels/lang_glasser_LH"
      rh_folder="${DTI_DIR}/${subject_name}/indti/Labels/lang_glasser_RH"
      aparc_aseg_folder="${DTI_DIR}/${subject_name}/indti/Labels/aparc+aseg"

      if [ -d "$lh_folder" ] && [ -d "$rh_folder" ] && [ -d "$aparc_aseg_folder" ] && false
      then
        true
      else
        echo "${subject_name} folders dont exists adding them"
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        printf "%d,%s\n" "$LINE_COUNT" "$subject_name" >> $SUBJECT_LABEL_FILE
      fi
done < <(find $DTI_DIR -type d -maxdepth 1 -name "sub*")

run_val=0
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "running  ${LINE_COUNT} jobs"
   #nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 aparc_aseg_on_subject.sh  $SUBJECT_LABEL_FILE
   nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 75 100 25 aparc_aseg_on_subject.sh  $SUBJECT_LABEL_FILE
  else
    echo $LINE_COUNT
fi