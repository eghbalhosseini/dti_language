#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
FS_DIR=/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/

threshold=$1
echo "threshold:${threshold}"

#threshold=20
probtrackX_labels_="all_subject_probtrackX_thr_${threshold}"
i=0
LINE_COUNT=0
SUBJECT_PROBX_FILE="${DTI_DIR}/${probtrackX_labels_}.txt"
rm -f $SUBJECT_PROBX_FILE
touch $SUBJECT_PROBX_FILE
printf "%s,%s,%s,%s,%s\n" "row" "subject_name" "segment_name" "hemi" "thr"   >> $SUBJECT_PROBX_FILE

echo "looking at ${DTI_DIR} "
SUBJ_LINE=0
overwrite= false
bad_sub=(sub072 sub106 sub124 sub126 sub135 sub136 sub138 sub148 sub159 sub163 sub171 sub172 sub190 sub195 sub199 sub202 sub210 sub234 sub254 sub311 sub540 sub541)

while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      if [[ " ${bad_sub[@]} " =~ " ${subject_name} " ]]; then
        echo "skipping ${subject_name}"
        continue
      else
        lh_folder="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_LH_thr_${threshold}/fdt_paths.nii.gz"
        #rm $lh_folder
        rh_folder="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_RH_thr_${threshold}/fdt_paths.nii.gz"
        #rm $rh_folder
        if [ "$overwrite" = true ]
        then
          echo "overwriting ${lh_folder}"
          LINE_COUNT=$(expr ${LINE_COUNT} + 1)
          printf "%d,%s,%s,%s,%d\n" "$LINE_COUNT" "$subject_name" "lang_glasser_LH_thr_${threshold}" "LH" "$threshold" >> $SUBJECT_PROBX_FILE
          echo "overwriting ${rh_folder}"
          LINE_COUNT=$(expr ${LINE_COUNT} + 1)
          printf "%d,%s,%s,%s,%d\n" "$LINE_COUNT" "$subject_name" "lang_glasser_RH_thr_${threshold}" "RH" "$threshold">> $SUBJECT_PROBX_FILE
        else
          if [ ! -f "$lh_folder" ]
          then
            echo "missing ${lh_folder}"
            LINE_COUNT=$(expr ${LINE_COUNT} + 1)
            printf "%d,%s,%s,%s,%d\n" "$LINE_COUNT" "$subject_name" "lang_glasser_LH_thr_${threshold}" "LH" "$threshold" >> $SUBJECT_PROBX_FILE

          fi

          if [ ! -f "$rh_folder" ]
          then
            echo "missing ${rh_folder}"
            LINE_COUNT=$(expr ${LINE_COUNT} + 1)
            printf "%d,%s,%s,%s,%d\n" "$LINE_COUNT" "$subject_name" "lang_glasser_RH_thr_${threshold}" "RH" "$threshold">> $SUBJECT_PROBX_FILE
          fi

        fi
      fi
done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")

run_val=0
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "running  ${LINE_COUNT} jobs"
  if [ "$LINE_COUNT" -lt 200 ] ; then
     echo "less than 200 jobs:  ${LINE_COUNT} jobs"
     nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT "$LINE_COUNT" "$LINE_COUNT" 0 probtrackX_on_subject.sh  $SUBJECT_PROBX_FILE
     else
      #nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 probtrackX_on_subject.sh  $SUBJECT_PROBX_FILE
      nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 175 200 25 probtrackX_on_subject.sh  $SUBJECT_PROBX_FILE
    fi
  else
    echo $LINE_COUNT
fi