#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
FS_DIR=/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/


network_id="lang"
#

analyze_fROI='all_subject_for_parcels'
i=0
LINE_COUNT=0
SUBJECT_FROI_FILE="${DTI_DIR}/${analyze_fROI}.txt"
rm -f $SUBJECT_FROI_FILE
touch $SUBJECT_FROI_FILE
printf "%s,%s,%s\n" "row" "subject_name" "network_id"    >> $SUBJECT_FROI_FILE

echo "looking at ${DTI_DIR} "
SUBJ_LINE=0
while read x; do
      # check if file already exist in fmri dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      possible_folder="${DTI_DIR}/${subject_name}/fmri"
      possible_file="${possible_folder}/${subject_name}_${network_id}_parcels_indti.nii.gz"

      if [ -f "$possible_file" ]
      then
        true
      else
        echo "parcel files dont exist, adding them"
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        mkdir -p $possible_folder
        printf "%d,%s,%s\n" "$LINE_COUNT" "$subject_name" "$network_id"   >> $SUBJECT_FROI_FILE
      fi
done < <(find $DTI_DIR -type d -maxdepth 1 -name "sub*")

run_val=0
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "running  ${LINE_COUNT} jobs"
  if [ "$LINE_COUNT" -lt 300 ] ; then
    echo "less than 300 jobs:  ${LINE_COUNT} jobs"
    nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT "$LINE_COUNT" "$LINE_COUNT" 0 lang_parcel_on_subject.sh  $SUBJECT_FROI_FILE
    else
          echo "more than 300 jobs:  ${LINE_COUNT} jobs"
   #nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 lang_froi_on_subject.sh  $SUBJECT_FROI_FILE
   nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 275 300 25 lang_parcel_on_subject.sh  $SUBJECT_FROI_FILE
  fi
  else
    echo $LINE_COUNT
fi