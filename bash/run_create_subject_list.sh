#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/


probtrackX_labels_='all_subjects'
i=0
LINE_COUNT=0
SUBJECT_PROBX_FILE="${DTI_DIR}/${probtrackX_labels_}.txt"
rm -f $SUBJECT_PROBX_FILE
touch $SUBJECT_PROBX_FILE
#printf "%s,%s,%s,%s\n" "row" "subject_name" "segment_name" "hemi"   >> $SUBJECT_PROBX_FILE

echo "looking at ${DTI_DIR} "
SUBJ_LINE=0
while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      LINE_COUNT=$(expr ${LINE_COUNT} + 1)
      printf "%s\n" "$subject_name" >> $SUBJECT_PROBX_FILE
done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")
