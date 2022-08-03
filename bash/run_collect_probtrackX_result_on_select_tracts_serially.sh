#!/bin/bash
#SBATCH --job-name=MISTRAL
#SBATCH --array=0
#SBATCH --time=6-23:00:00
#SBATCH --mem=80G
#SBATCH --exclude node017,node018
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ehoseini@mit.edu

DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/

threshold=20
probtrackX_labels_='all_subject_collect_probtrackX_select_tracts_results'
i=0
LINE_COUNT=0
SUBJECT_PROBX_FILE="${DTI_DIR}/${probtrackX_labels_}.txt"
rm -f $SUBJECT_PROBX_FILE
touch $SUBJECT_PROBX_FILE


SOURCES=("IFGorb_top_${threshold}" "AntTemp_top_${threshold}")
TARGETS=("IFGorb_top_${threshold}" "AntTemp_top_${threshold}")
#EXCLUDES=("MFG_top_90" "IFG_top_90")
EXCLUDES=("MFG_top_${threshold}")
#EXCLUDES=("IFG_top_90")

#SOURCES=("IFG_top_${threshold}" "PostTemp_top_${threshold}")
#TARGETS=("IFG_top_${threshold}" "PostTemp_top_${threshold}")
#EXCLUDES=("MFG_top_90" "IFGorb_top_90")
#EXCLUDES=("IFGorb_top_90")
#EXCLUDES=("MFG_top_${threshold}")

SOURCEJoin=$(IFS=- ; echo "${SOURCES[*]}")
TARGETSJoin=$(IFS=- ; echo "${TARGETS[*]}")
EXCLUDEJoin=$(IFS=- ; echo "${EXCLUDES[*]}")

printf "%s,%s,%s,%s,%s,%s\n" "row" "subject_name" "hemi" "file_loc" "segment_file" "save_loc"   >> $SUBJECT_PROBX_FILE

echo "looking at ${DTI_DIR} "
SUBJ_LINE=0
mkdir -p "${DTI_DIR}/probtrackX_results_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}"
overwrite=false
while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      lh_file="${DTI_DIR}/probtrackX_results_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/${subject_name}_LH_fdt_network.mat"
      rh_file="${DTI_DIR}/probtrackX_results_${SOURCEJoin}_TO_${TARGETSJoin}_EX_${EXCLUDEJoin}/${subject_name}_RH_fdt_network.mat"

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
done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")

echo $LINE_COUNT


#module load mit/matlab/2020b
matlab -nosplash -nojvm -r "addpath('/om2/user/ehoseini/dti_language/');\
cd('/om2/user/ehoseini/dti_language/');\
A=readtable('$SUBJECT_PROBX_FILE','Headerlines',0);\
%for i=1:size(A,1),\
%  disp(A(i,:).file_loc{1});\
%  transform_probtrackX_output('file_id',A(i,:).file_loc{1},'target_mask_file',A(i,:).segment_file{1},'save_dir',A(i,:).save_loc{1},'hemi',A(i,:).hemi{1});\
%end;\
exit"