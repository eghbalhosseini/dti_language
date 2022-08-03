#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
FS_DIR=/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/
TEMP_DIR="${DTI_DIR}/GLASSER"

# change relative FS folder
SUBJECTS_DIR="${TEMP_DIR}"
export TEMP_DIR
#
GLASSER_LOC='glasser_output'
analyze_glasser='all_subject_for_glasser'
glasser_txt='all_subj_glasser_txt'
i=0
LINE_COUNT=0
SUBJECT_GLASSER_FILE="${TEMP_DIR}/${analyze_glasser}.txt"
GLASSER_TXT="${TEMP_DIR}/${glasser_txt}.txt"
rm -f $SUBJECT_GLASSER_FILE
touch $SUBJECT_GLASSER_FILE

rm -f $GLASSER_TXT
touch $GLASSER_TXT

printf "%s,%s,%s,%s,%s,%s,%s,%s\n" "row" "subject_name" "subject_dir" "subject_fs_dir" "sub_text_file_for_script" "loc_of_recons" "loc_of_recond_in_sub_dir" "glasser_run_dir"  >> $SUBJECT_GLASSER_FILE

echo "looking at ${DTI_DIR} "
overwrite=false
SUBJ_LINE=0
while read x; do
      # check if file already exist in glasser dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      possible_folder="${DTI_DIR}/${subject_name}/glasser"
      possible_file="${possible_folder}/HCPMMP1.nii.gz"
      if [ "$overwrite" = true ]
      then
         echo "overwriting ${possible_file}"
         LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        printf "%s\n" "$subject_name" >> $GLASSER_TXT
        mkdir -p $possible_folder
        printf "%d,%s,%s,%s,%s,%s,%s,%s\n" "$LINE_COUNT" "$subject_name" "$x" "$FS_DIR" "$GLASSER_TXT" "$GLASSER_LOC" "$possible_folder" "$TEMP_DIR"  >> $SUBJECT_GLASSER_FILE
      else
        if [ -f "$possible_file" ]
        then
          true
        else
          echo "$possible_file dosent exists adding it"
          LINE_COUNT=$(expr ${LINE_COUNT} + 1)
          #IND_GLASSER_FILE="${TEMP_DIR}/glasser_${subject_name}.txt"
          #rm -f $IND_GLASSER_FILE
          #touch $IND_GLASSER_FILE
          printf "%s\n" "$subject_name" >> $GLASSER_TXT
          mkdir -p $possible_folder
          # copy files from FS folder to GLASSER, this will be removed afterwards
          #cp -a "${DTI_DIR}/${subject_name}/fs/." "${TEMP_DIR}/${subject_name}/"
          printf "%d,%s,%s,%s,%s,%s,%s,%s\n" "$LINE_COUNT" "$subject_name" "$x" "$FS_DIR" "$GLASSER_TXT" "$GLASSER_LOC" "$possible_folder" "$TEMP_DIR"  >> $SUBJECT_GLASSER_FILE
        fi
      fi
done < <(find $DTI_DIR -type d -maxdepth 1 -name "sub*")

echo $LINE_COUNT
run_val=0
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "running  ${LINE_COUNT} jobs"
  if [ "$LINE_COUNT" -lt 100 ] ; then
    echo "less than 100 jobs:  ${LINE_COUNT} jobs"
    nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT "$LINE_COUNT" "$LINE_COUNT" 0 glasser_parcellation_on_subject.sh  $SUBJECT_GLASSER_FILE
  else
     echo "more than 100 jobs:  ${LINE_COUNT} jobs"
   #nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 glasser_parcellation_on_subject.sh  $SUBJECT_GLASSER_FILE
    nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 80 100 20 glasser_parcellation_on_subject.sh  $SUBJECT_GLASSER_FILE &
  fi
  else
    echo $LINE_COUNT
fi