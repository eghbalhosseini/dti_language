#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/

threshold=$1
echo "threshold:${threshold}"

SRC_TRG_INDEX=$2
echo "source target index:${SRC_TRG_INDEX}"

probtrackX_labels_='all_subject_collect_probtrackX_group_tracts_results'
i=0
LINE_COUNT=0
SUBJECT_PROBX_FILE="${DTI_DIR}/${probtrackX_labels_}.txt"
rm -f $SUBJECT_PROBX_FILE
touch $SUBJECT_PROBX_FILE

if [ "$SRC_TRG_INDEX" -eq 1 ] ; then

  # AntTemp Targets
  SOURCES=("AntTemp_top_${threshold}" "IFGorb_top_${threshold}" "IFG_top_${threshold}" "MFG_top_${threshold}")
  TARGETS=("AntTemp_top_${threshold}" "IFGorb_top_${threshold}" "IFG_top_${threshold}" "MFG_top_${threshold}")
  EXCLUDES=("PostTemp_top_${threshold}" "AngG_top_${threshold}" )

elif [ "$SRC_TRG_INDEX" -eq 2 ] ; then
  # postTemp Targets
  SOURCES=("PostTemp_top_${threshold}" "IFGorb_top_${threshold}" "IFG_top_${threshold}" "MFG_top_${threshold}")
  TARGETS=("PostTemp_top_${threshold}" "IFGorb_top_${threshold}" "IFG_top_${threshold}" "MFG_top_${threshold}")
  EXCLUDES=("AntTemp_top_${threshold}" "AngG_top_${threshold}" )

elif [ "$SRC_TRG_INDEX" -eq 3 ] ; then
######################################
  # AngG Targets
  SOURCES=("IFGorb_top_${threshold}" "IFG_top_${threshold}" "AngG_top_${threshold}" "MFG_top_${threshold}")
  TARGETS=("AngG_top_${threshold}" "IFGorb_top_${threshold}" "IFG_top_${threshold}" "MFG_top_${threshold}")
  EXCLUDES=("AntTemp_top_${threshold}" "PostTemp_top_${threshold}" )


elif [ "$SRC_TRG_INDEX" -eq 4 ] ; then
  # IFG targets
  SOURCES=("PostTemp_top_${threshold}" "AntTemp_top_${threshold}" "AngG_top_${threshold}" "IFG_top_${threshold}")
  TARGETS=("PostTemp_top_${threshold}" "AntTemp_top_${threshold}" "AngG_top_${threshold}" "IFG_top_${threshold}")

  EXCLUDES=("IFGorb_top_${threshold}" "MFG_top_${threshold}")

####################################
elif [ "$SRC_TRG_INDEX" -eq 5 ] ; then
  # IFGorb Targets
  SOURCES=("PostTemp_top_${threshold}" "AntTemp_top_${threshold}" "AngG_top_${threshold}" "IFGorb_top_${threshold}")
  TARGETS=("PostTemp_top_${threshold}" "AntTemp_top_${threshold}"  "AngG_top_${threshold}" "IFGorb_top_${threshold}")

  EXCLUDES=("IFG_top_${threshold}" "MFG_top_${threshold}")

elif [ "$SRC_TRG_INDEX" -eq 6 ] ; then
  # MFG Targets
  SOURCES=("PostTemp_top_${threshold}" "AntTemp_top_${threshold}" "AngG_top_${threshold}" "MFG_top_${threshold}")
  TARGETS=("PostTemp_top_${threshold}" "AntTemp_top_${threshold}" "AngG_top_${threshold}" "MFG_top_${threshold}")

  EXCLUDES=("IFG_top_${threshold}" "IFGorb_top_${threshold}")
else
  printf '%s\n' "no source target pair is defined" >&2  # write error message to stderr
  exit 1
fi
SOURCEJoin=$(IFS=- ; echo "${SOURCES[*]}")
TARGETSJoin=$(IFS=- ; echo "${TARGETS[*]}")
EXCLUDEJoin=$(IFS=- ; echo "${EXCLUDES[*]}")

printf "%s,%s,%s,%s,%s,%s\n" "row" "subject_name" "hemi" "file_loc" "segment_file" "save_loc"   >> $SUBJECT_PROBX_FILE

bad_sub=(sub072 sub106 sub124 sub126 sub135 sub136 sub138 sub148 sub159 sub163 sub171 sub172 sub190 sub195 sub199 sub202 sub210 sub234 sub254 sub311 sub540 sub541)

echo "looking at ${DTI_DIR} "
SUBJ_LINE=0
mkdir -p "${DTI_DIR}/probtrackX_group_results_${SOURCEJoin}_TO_${TARGETSJoin}_TO_${EXCLUDEJoin}"
overwrite=false
while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      if [[ " ${bad_sub[@]} " =~ " ${subject_name} " ]]; then
        echo "skipping ${subject_name}"
        continue
      else
        lh_file="${DTI_DIR}/probtrackX_group_results_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/${subject_name}_LH_fdt_network.mat"
        rh_file="${DTI_DIR}/probtrackX_group_results_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/${subject_name}_RH_fdt_network.mat"

        if [ "$overwrite" = true ]
        then
          echo "overwriting ${lh_file}"
          LINE_COUNT=$(expr ${LINE_COUNT} + 1)
          # folder to find the file
          lh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_LH_thr_${threshold}_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/fdt_network_matrix"
          SUBJECT_SOURCE_FILE="${DTI_DIR}/${subject_name}/sources_lang_glasser_LH_thr_${threshold}_${SOURCEJoin}_EX_${EXCLUDEJoin}.txt"
          printf "%d,%s,%s,%s,%s,%s\n" "$LINE_COUNT" "$subject_name" "LH" "$lh_tr_file" "$SUBJECT_SOURCE_FILE" "$lh_file" >> $SUBJECT_PROBX_FILE
        else
          if [ ! -f "$lh_file" ]
            then
              echo "missing ${lh_file}"
              LINE_COUNT=$(expr ${LINE_COUNT} + 1)
              # folder to find the file
              lh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_LH_thr_${threshold}_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/fdt_network_matrix"
              SUBJECT_SOURCE_FILE="${DTI_DIR}/${subject_name}/sources_lang_glasser_LH_thr_${threshold}_${SOURCEJoin}_EX_${EXCLUDEJoin}.txt"
              printf "%d,%s,%s,%s,%s,%s\n" "$LINE_COUNT" "$subject_name" "LH" "$lh_tr_file" "$SUBJECT_SOURCE_FILE" "$lh_file" >> $SUBJECT_PROBX_FILE
          fi
        fi

        if [ "$overwrite" = true ]
        then
          echo "overwriting ${rh_file}"
          LINE_COUNT=$(expr ${LINE_COUNT} + 1)
          rh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_RH_thr_${threshold}_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/fdt_network_matrix"
          SUBJECT_SOURCE_FILE="${DTI_DIR}/${subject_name}/sources_lang_glasser_RH_thr_${threshold}_${SOURCEJoin}_EX_${EXCLUDEJoin}.txt"
          printf "%d,%s,%s,%s,%s,%s\n" "$LINE_COUNT" "$subject_name" "RH" "$rh_tr_file" "$SUBJECT_SOURCE_FILE" "$rh_file" >> $SUBJECT_PROBX_FILE
        else
          if [ ! -f "$rh_file" ]
          then
            echo "missing ${rh_file}"
            LINE_COUNT=$(expr ${LINE_COUNT} + 1)
            rh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_RH_thr_${threshold}_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/fdt_network_matrix"
            SUBJECT_SOURCE_FILE="${DTI_DIR}/${subject_name}/sources_lang_glasser_RH_thr_${threshold}_${SOURCEJoin}_EX_${EXCLUDEJoin}.txt"
            printf "%d,%s,%s,%s,%s,%s\n" "$LINE_COUNT" "$subject_name" "RH" "$rh_tr_file" "$SUBJECT_SOURCE_FILE" "$rh_file" >> $SUBJECT_PROBX_FILE
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
    nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT "$LINE_COUNT" "$LINE_COUNT" 0 collect_probtrackX_result_on_group_tracts.sh  $SUBJECT_PROBX_FILE
    else
      echo "more than 300 jobs:  ${LINE_COUNT} jobs"
      #nohup /cm/shared/admin/bin/submit-many-jobs 3 2 3 1 collect_probtrackX_result_on_select_tracts.sh  $SUBJECT_PROBX_FILE &
      nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT 275 300 25 collect_probtrackX_result_on_group_tracts.sh  $SUBJECT_PROBX_FILE &
  fi
  else
    echo $LINE_COUNT
fi