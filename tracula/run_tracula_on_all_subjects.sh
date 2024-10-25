#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
FS_DIR=/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/

threshold=$1
echo "threshold:${threshold}"

#threshold=20
probtrackX_labels_="all_subject_tracula"
i=0
LINE_COUNT=0
SUBJECT_TRX_FILE="${DTI_DIR}/${probtrackX_labels_}.txt"
rm -f $SUBJECT_TRX_FILE
touch $SUBJECT_TRX_FILE
printf "%s,%s\n" "row" "subject_name" >> $SUBJECT_TRX_FILE

echo "looking at ${DTI_DIR} "
SUBJ_LINE=0
overwrite= true
bad_sub=(sub007 sub072 sub106 sub124 sub126 sub135 sub136 sub138 sub148 sub159 sub163 sub171 sub172 sub190 sub195 sub199 sub202 sub210 sub234 sub254 sub311 sub540 sub541)

while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      if [[ " ${bad_sub[@]} " =~ " ${subject_name} " ]]; then
        echo "skipping ${subject_name}"
        continue
      else
        # first remove this file if it exists
        file_to_remove="/mindhive/evlab/Shared/diffusionzeynep/${subject_name}/trc/${subject_name}/scripts/IsRunning.trac"
        if [ -f "$file_to_remove" ]; then
          echo "removing ${file_to_remove}"
          rm $file_to_remove
        fi

        trc_folder="${DTI_DIR}/${subject_name}/trc/${subject_name}"
        #rm $lh_folder
        #rm $rh_folder
        if [ "$overwrite" = true ]
        then
          echo "overwriting ${trc_folder}"
          LINE_COUNT=$(expr ${LINE_COUNT} + 1)
          printf "%d,%s\n" "$LINE_COUNT" "$subject_name" >> $SUBJECT_TRX_FILE
        else
          if [ ! -f "trc_folder" ]
          then
            echo "missing ${trc_folder}"
            LINE_COUNT=$(expr ${LINE_COUNT} + 1)
            printf "%d,%s\n" "$LINE_COUNT" "$subject_name" >> $SUBJECT_TRX_FILE

          fi
        fi
      fi
done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")

run_val=0
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "running  ${LINE_COUNT} jobs"
  if [ "$LINE_COUNT" -lt 200 ] ; then
     echo "less than 200 jobs:  ${LINE_COUNT} jobs"
     nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT "$LINE_COUNT" "$LINE_COUNT" 0 run_tracula_preproc_subject.sh  $SUBJECT_TRX_FILE
     else
      #nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 probtrackX_on_subject.sh  $SUBJECT_TRX_FILE
      nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 175 200 25 run_tracula_preproc_subject.sh  $SUBJECT_TRX_FILE
    fi
  else
    echo $LINE_COUNT
fi