#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/

threshold=$1
echo "threshold:${threshold}"

SRC_TRG_INDEX=$2
echo "source target index:${SRC_TRG_INDEX}"

#threshold=20
probtrackX_labels_="all_subject_probtrackX_select_tracts_thr_${threshold}"
LINE_COUNT=0
#####################################
if [ "$SRC_TRG_INDEX" -eq 1 ] ; then

  # AntTemp Targets
  SOURCES=("IFGorb_top_${threshold}" "AntTemp_top_${threshold}")
  TARGETS=("IFGorb_top_${threshold}" "AntTemp_top_${threshold}")
  EXCLUDES=("IFG_top_${threshold}" "MFG_top_${threshold}")
elif [ "$SRC_TRG_INDEX" -eq 2 ] ; then

  SOURCES=("IFG_top_${threshold}" "AntTemp_top_${threshold}")
  TARGETS=("IFG_top_${threshold}" "AntTemp_top_${threshold}")
  EXCLUDES=("IFGorb_top_${threshold}" "MFG_top_${threshold}")

elif [ "$SRC_TRG_INDEX" -eq 3 ] ; then

  SOURCES=("MFG_top_${threshold}" "AntTemp_top_${threshold}")
  TARGETS=("MFG_top_${threshold}" "AntTemp_top_${threshold}")
  EXCLUDES=("IFG_top_${threshold}" "IFGorb_top_${threshold}")

####################################
elif [ "$SRC_TRG_INDEX" -eq 4 ] ; then
# PostTemp Targets
  SOURCES=("IFGorb_top_${threshold}" "PostTemp_top_${threshold}")
  TARGETS=("IFGorb_top_${threshold}" "PostTemp_top_${threshold}")
  EXCLUDES=("IFG_top_${threshold}" "MFG_top_${threshold}")
elif [ "$SRC_TRG_INDEX" -eq 5 ] ; then
  SOURCES=("IFG_top_${threshold}" "PostTemp_top_${threshold}")
  TARGETS=("IFG_top_${threshold}" "PostTemp_top_${threshold}")
  EXCLUDES=("IFGorb_top_${threshold}" "MFG_top_${threshold}")

elif [ "$SRC_TRG_INDEX" -eq 6 ] ; then
  SOURCES=("MFG_top_${threshold}" "PostTemp_top_${threshold}")
  TARGETS=("MFG_top_${threshold}" "PostTemp_top_${threshold}")
  EXCLUDES=("IFG_top_${threshold}" "IFGorb_top_${threshold}")

elif [ "$SRC_TRG_INDEX" -eq 7 ] ; then
######################################
# AngG Targets
  SOURCES=("IFGorb_top_${threshold}" "AngG_top_${threshold}")
  TARGETS=("IFGorb_top_${threshold}" "AngG_top_${threshold}")
  EXCLUDES=("IFG_top_${threshold}" "MFG_top_${threshold}")
elif [ "$SRC_TRG_INDEX" -eq 8 ] ; then
  SOURCES=("IFG_top_${threshold}" "AngG_top_${threshold}")
  TARGETS=("IFG_top_${threshold}" "AngG_top_${threshold}")
  EXCLUDES=("IFGorb_top_${threshold}" "MFG_top_${threshold}")

elif [ "$SRC_TRG_INDEX" -eq 9 ] ; then
  SOURCES=("MFG_top_${threshold}" "AngG_top_${threshold}")
  TARGETS=("MFG_top_${threshold}" "AngG_top_${threshold}")
  EXCLUDES=("IFG_top_${threshold}" "IFGorb_top_${threshold}")

else
  printf '%s\n' "no source target pair is defined" >&2  # write error message to stderr
  exit 1
fi

# 22 subjects are considered bacd
bad_sub=(sub072 sub106 sub124 sub126 sub135 sub136 sub138 sub148 sub159 sub163 sub171 sub172 sub190 sub195 sub199 sub202 sub210 sub234 sub254 sub311 sub540 sub541)


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
      # if subject_name is in bad_sub list, skip otherwise process subject
      if [[ " ${bad_sub[@]} " =~ " ${subject_name} " ]]; then
        echo "skipping ${subject_name}"
        continue
      else

      lh_folder="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_LH_thr_${threshold}_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/fdt_paths_in_orig.nii.gz"
      find "${DTI_DIR}/${subject_name}/dti.probtrackx/" -name "*90*"  -exec rm -rf {} +
      #rm $lh_folder
      rh_folder="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_RH_thr_${threshold}_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/fdt_paths_in_orig.nii.gz"
      #rm $rh_folder
      if [ "$overwrite" = true ]
      then
        echo "overwriting ${lh_folder}"
        rm -r $lh_folder
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        printf "%d,%s,%s,%s,%s,%s,%s,%d\n" "$LINE_COUNT" "$subject_name" "lang_glasser_LH_thr_${threshold}" "$SOURCEJoin" "$TARGETSJoin" "$EXCLUDEJoin" "LH" "$threshold" >> $SUBJECT_PROBX_FILE

        echo "overwriting ${rh_folder}"
        rm -r $rh_folder
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
      fi
done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")
echo $LINE_COUNT
run_val=0
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "running  ${LINE_COUNT} jobs"
  if [ "$LINE_COUNT" -lt 300 ] ; then
    echo "less than 300 jobs:  ${LINE_COUNT} jobs"
      nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT "$LINE_COUNT" "$LINE_COUNT" 0 probtrackX_vol_2_vol_on_select_tracts.sh  $SUBJECT_PROBX_FILE
  else
    echo "more than 300 jobs:  ${LINE_COUNT} jobs"
      #nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 probtrackX_on_select_tracts.sh  $SUBJECT_PROBX_FILE
      nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 275 300 25 probtrackX_vol_2_vol_on_select_tracts.sh  $SUBJECT_PROBX_FILE
  fi
  else
    echo $LINE_COUNT
fi