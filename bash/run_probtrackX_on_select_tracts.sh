#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/

threshold=$1
echo "threshold:${threshold}"

#threshold=20
probtrackX_labels_="all_subject_probtrackX_select_tracts_thr_${threshold}"
LINE_COUNT=0
#####################################
# AntTemp Targets
#SOURCES=("IFGorb_top_${threshold}" "AntTemp_top_${threshold}")
#TARGETS=("IFGorb_top_${threshold}" "AntTemp_top_${threshold}")
#EXCLUDES=("IFG_top_${threshold}" "MFG_top_${threshold}")

#SOURCES=("IFG_top_${threshold}" "AntTemp_top_${threshold}")
#TARGETS=("IFG_top_${threshold}" "AntTemp_top_${threshold}")
#EXCLUDES=("IFGorb_top_${threshold}")


#SOURCES=("MFG_top_${threshold}" "AntTemp_top_${threshold}")
#TARGETS=("MFG_top_${threshold}" "AntTemp_top_${threshold}")
#EXCLUDES=("IFG_top_${threshold}")

####################################
# PostTemp Targets
#SOURCES=("IFGorb_top_${threshold}" "PostTemp_top_${threshold}")
#TARGETS=("IFGorb_top_${threshold}" "PostTemp_top_${threshold}")
#EXCLUDES=("IFG_top_${threshold}" "MFG_top_${threshold}")

SOURCES=("IFG_top_${threshold}" "PostTemp_top_${threshold}")
TARGETS=("IFG_top_${threshold}" "PostTemp_top_${threshold}")
EXCLUDES=("IFGorb_top_${threshold}")


#SOURCES=("MFG_top_${threshold}" "PostTemp_top_${threshold}")
#TARGETS=("MFG_top_${threshold}" "PostTemp_top_${threshold}")
#EXCLUDES=("IFG_top_${threshold}")

######################################
# AngG Targets
#SOURCES=("IFGorb_top_${threshold}" "AngG_top_${threshold}")
#TARGETS=("IFGorb_top_${threshold}" "AngG_top_${threshold}")
#EXCLUDES=("IFG_top_${threshold}" "MFG_top_${threshold}")


#SOURCES=("IFG_top_${threshold}" "AngG_top_${threshold}")
#TARGETS=("IFG_top_${threshold}" "AngG_top_${threshold}")
#EXCLUDES=("IFGorb_top_${threshold}")

#SOURCES=("MFG_top_${threshold}" "AngG_top_${threshold}")
#TARGETS=("MFG_top_${threshold}" "AngG_top_${threshold}")
#EXCLUDES=("IFG_top_${threshold}")

#SOURCES=("IFG_top_${threshold}" "AntTemp_top_${threshold}")


#SOURCES=("PostTemp_top_${threshold}" "MFG_top_${threshold}")
#TARGETS=("PostTemp_top_${threshold}" "MFG_top_${threshold}")
#EXCLUDES=("IFG_top_${threshold}")

#SOURCES=("PostTemp_top_${threshold}" "MFG_top_${threshold}")
#TARGETS=("PostTemp_top_${threshold}" "MFG_top_${threshold}")
#EXCLUDES=("IFG_top_${threshold}" "IFGorb_top_${threshold}")


#EXCLUDES=("MFG_top_${threshold}" "IFG_top_${threshold}")
#EXCLUDES=("MFG_top_${threshold}" "IFGorb_top_${threshold}")
#EXCLUDES=("IFG_top_${threshold}")

#SOURCES=("IFG_top_${threshold}" "PostTemp_top_${threshold}")
#TARGETS=("IFG_top_${threshold}" "PostTemp_top_${threshold}")
#EXCLUDES=("MFG_top_90" "IFGorb_top_90")
#EXCLUDES=("IFGorb_top_${threshold}")
#EXCLUDES=("MFG_top_${threshold}")

#bad_sub=(sub072 sub124 sub126 sub135 sub136 sub138 sub148 sub159 sub163 sub171 sub172 sub190 sub195 sub199 sub202 sub210 sub234 sub254 sub311 sub540 sub541)

SOURCEJoin=$(IFS=- ; echo "${SOURCES[*]}")
#echo $SOURCEJoin

TARGETSJoin=$(IFS=- ; echo "${TARGETS[*]}")
#echo $TARGETSJoin

EXCLUDEJoin=$(IFS=- ; echo "${EXCLUDES[*]}")
#echo $EXCLUDEJoin


SUBJECT_PROBX_FILE="${DTI_DIR}/${probtrackX_labels_}.txt"
rm -f $SUBJECT_PROBX_FILE
touch $SUBJECT_PROBX_FILE
printf "%s,%s,%s,%s,%s,%s,%s,%s\n" "row" "subject_name" "segment_name" "source_name" "target_name" "exclude_name" "hemi" "thr"   >> $SUBJECT_PROBX_FILE

echo "looking at ${DTI_DIR} "
overwrite=false
while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      lh_folder="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_LH_thr_${threshold}_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/fdt_paths.nii.gz"
      find "${DTI_DIR}/${subject_name}/dti.probtrackx/" -name "*90*"  -exec rm -rf {} +
      #rm $lh_folder
      rh_folder="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_RH_thr_${threshold}_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/fdt_paths.nii.gz"
      #rm $rh_folder
      if [ "$overwrite" = true ]
      then
        echo "overwriting ${lh_folder}"
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        printf "%d,%s,%s,%s,%s,%s,%s,%d\n" "$LINE_COUNT" "$subject_name" "lang_glasser_LH_thr_${threshold}" "$SOURCEJoin" "$TARGETSJoin" "$EXCLUDEJoin" "LH" "$threshold" >> $SUBJECT_PROBX_FILE

        echo "overwriting ${rh_folder}"
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        printf "%d,%s,%s,%s,%s,%s,%s,%d\n" "$LINE_COUNT" "$subject_name" "lang_glasser_RH_thr_${threshold}" "$SOURCEJoin" "$TARGETSJoin" "$EXCLUDEJoin" "RH" "$threshold" >> $SUBJECT_PROBX_FILE
      else
          if [ -f "$lh_folder" ]
          then
            true
          else
            echo "missing ${lh_folder}"
            LINE_COUNT=$(expr ${LINE_COUNT} + 1)
            printf "%d,%s,%s,%s,%s,%s,%s,%d\n" "$LINE_COUNT" "$subject_name" "lang_glasser_LH_thr_${threshold}" "$SOURCEJoin" "$TARGETSJoin" "$EXCLUDEJoin" "LH" "$threshold" >> $SUBJECT_PROBX_FILE
          fi
          if [ -f "$rh_folder" ]
          then
            true
          else
            echo "missing ${rh_folder}"
            LINE_COUNT=$(expr ${LINE_COUNT} + 1)
            printf "%d,%s,%s,%s,%s,%s,%s,%d\n" "$LINE_COUNT" "$subject_name" "lang_glasser_RH_thr_${threshold}" "$SOURCEJoin" "$TARGETSJoin" "$EXCLUDEJoin" "RH" "$threshold" >> $SUBJECT_PROBX_FILE
          fi
      fi
done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")
echo $LINE_COUNT
run_val=0
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "running  ${LINE_COUNT} jobs"
  if [ "$LINE_COUNT" -lt 300 ] ; then
    echo "less than 300 jobs:  ${LINE_COUNT} jobs"
      nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT "$LINE_COUNT" "$LINE_COUNT" 0 probtrackX_on_select_tracts.sh  $SUBJECT_PROBX_FILE
  else
    echo "more than 300 jobs:  ${LINE_COUNT} jobs"
      #nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 probtrackX_on_select_tracts.sh  $SUBJECT_PROBX_FILE
      nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 275 300 25 probtrackX_on_select_tracts.sh  $SUBJECT_PROBX_FILE
  fi
  else
    echo $LINE_COUNT
fi