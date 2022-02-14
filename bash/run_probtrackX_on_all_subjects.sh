#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
FS_DIR=/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/

probtrackX_labels_='all_subject_probtrackX'
i=0
LINE_COUNT=0
SUBJECT_PROBX_FILE="${DTI_DIR}/${probtrackX_labels_}.txt"
rm -f $SUBJECT_PROBX_FILE
touch $SUBJECT_PROBX_FILE
printf "%s,%s,%s\n" "row" "subject_name" "segment_name"   >> $SUBJECT_PROBX_FILE

echo "looking at ${DTI_DIR} "
SUBJ_LINE=0
while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"

      lh_folder="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_LH"
      rh_folder="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_RH"

      if [ ! -d "$lh_folder" ]
      then
        printf "%d,%s,%s\n" "$LINE_COUNT" "$subject_name" "lang_glasser_LH" >> $SUBJECT_PROBX_FILE
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
      fi
      if [ ! -d "$rh_folder" ]
      then
        printf "%d,%s,%s\n" "$LINE_COUNT" "$subject_name" "lang_glasser_RH" >> $SUBJECT_PROBX_FILE
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
      fi
done < <(find $DTI_DIR -type d -maxdepth 1 -name "sub*")

run_val=0
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "running  ${LINE_COUNT} jobs"
   #nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 aparc_aseg_on_subject.sh  $SUBJECT_LABEL_FILE
   #nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 75 100 25 aparc_aseg_on_subject.sh  $SUBJECT_LABEL_FILE
  else
    echo $LINE_COUNT
fi