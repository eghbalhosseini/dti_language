#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
FS_DIR=/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/

GLASSER_LOC='GLASSER'

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
      possible_folder="${DTI_DIR}/${subject_name}/glasser"
      possible_file="${possible_folder}/HCPMMP1.nii.gz"
      if [ -f "$possible_file" ]
      then
        true
      else
        echo "$possible_file dosent exists adding it"
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        IND_GLASSER_FILE="${DTI_DIR}/${subject_name}/sub_list_for_glasser.txt"
        rm -f $IND_GLASSER_FILE
        touch $IND_GLASSER_FILE
        printf "%s \n" "$subject_name" >> $IND_GLASSER_FILE
        mkdir $possible_folder
        printf "%d, %s, %s, %s, %s, %s, %s \n" "$LINE_COUNT" "$subject_name" "$x" "$FS_DIR" "$IND_GLASSER_FILE" "$GLASSER_LOC" "$possible_folder"  >> $SUBJECT_GLASSER_FILE
      fi
    done < <(find $DTI_DIR -type d -maxdepth 1 -name "sub*")

#echo $LINE_COUNT
#run_val=0
#if [ "$LINE_COUNT" -gt "$run_val" ]; then
#  echo "running  ${LINE_COUNT} "
#   #nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 150 200 50 manifold_capacity_script.sh $GRAND_MFTMA_FILE &
#   nohup /cm/shared/admin/bin/submit-many-jobs 20 15 20 5 manifold_capacity_script.sh $GRAND_MFTMA_FILE &
#  else
#    echo $LINE_COUNT
#fi