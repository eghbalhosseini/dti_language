#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
FS_DIR=/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/

analyze_glasser='subject_for_glasser'

i=0
LINE_COUNT=0
SUBJECT_GLASSER_FILE="${DTI_DIR}/${analyze_glasser}.txt"
rm -f $SUBJECT_GLASSER_FILE
touch $SUBJECT_GLASSER_FILE
echo "looking at ${DTI_DIR} "
      SUBJ_LINE=0
      while read x; do
      # check if file already exist in glasser dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      possible_file="${DTI_DIR/$subject_name/glasser/HCPMMP1.nii.gz}"
      if [ -f "$possible_file" ]
      then
        true
      else
        echo "$possible_file dosent exists adding it"
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        printf "%d, %s %s \n" "$LINE_COUNT" "$subject_name" "$x" >> $GRAND_MFTMA_FILE
      fi
    done < <(find $DTI_DIR -type d -maxdepth 1 -name "sub*")
