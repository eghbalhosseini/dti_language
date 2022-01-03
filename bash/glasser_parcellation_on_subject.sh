#!/bin/bash
#SBATCH -c 8
#SBATCH --exclude node[017-018]
#SBATCH -t 5:00:00

GRAND_FILE=$1
OVERWRITE='false' # or 'true'
#

if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
  JID=$SLURM_ARRAY_TASK_ID    # Taking the task ID in a job array as an input parameter.
else
  JID=$2       # Taking the task ID as an input parameter.
fi
echo "${GRAND_FILE}"
echo $JID

while IFS=, read -r line_count subj_name sub_dti_dir fs_dir subj_glasser_txt glasser_rel_dir glasser_dest_dir temp_dir ; do
  #echo "line_count ${model}"
  if [ $JID == $line_count ]
    then
      echo "found the right match ${line_count}"
      run_subj_name=$subj_name
      run_sub_dti_dir=$sub_dti_dir
      run_fs_dir=$fs_dir
      run_subj_glasser_txt=$subj_glasser_txt
      run_glasser_rel_dir=$glasser_rel_dir
      run_glasser_dest_dir=$glasser_dest_dir
      run_temp_dir=$temp_dir
      do_run=true
      break
    else
      do_run=false
      #echo "didnt the right match"
  fi

done <"${GRAND_FILE}"

SUB_HCPMM_FILE_IN_FS="${run_fs_dir}/${run_glasser_rel_dir}/${run_subj_name}/HCPMMP1.nii.gz"
SUB_HCPMM_FILE_IN_DTI="${run_glasser_dest_dir}/"

echo "subj:${run_subj_name}"
echo "dti_dir:${run_sub_dti_dir}"
echo "fs_dir:${run_fs_dir}"
echo "txt file:${run_subj_glasser_txt}"

echo "glasser_relative:${run_glasser_rel_dir}"
echo "glasser destination:${run_glasser_dest_dir}"
echo "subject dir:${SUBJECTS_DIR}"

echo "copying FS files from ${run_fs_dir} to ${SUBJECTS_DIR}"
#cp -r "${run_fs_dir}/${run_subj_name}" $run_temp_dir
#echo "source file:${SUB_HCPMM_FILE_IN_FS}"
#echo "target dir:${SUB_HCPMM_FILE_IN_DTI}"
#echo "temp dir:${run_temp_dir}"

# copy folder to temp:
mkdir -p "${SUBJECTS_DIR}/${run_subj_name}"
#cp -vr "${run_fs_dir}/${run_subj_name}/." $run_temp_dir


#bash /om/user/ehoseini/dti_language/glasser_to_native/create_subj_volume_parcellation.sh -L $run_subj_glasser_txt -a HCPMMP1 -d $run_gsslasser_rel_dir
# copy files from relative location to DTI folder:

#SUB_HCPMM_FILE_IN_FS="${run_fs_dir}/${run_glasser_rel_dir}/${run_subj_name}/HCPMMP1.nii.gz"

#SUB_HCPMM_FILE_IN_DTI="${run_glasser_dest_dir}/"

#echo "copying from  ${SUB_HCPMM_FILE_IN_FS} to ${SUB_HCPMM_FILE_IN_DTI}"
#cp $SUB_HCPMM_FILE_IN_FS $SUB_HCPMM_FILE_IN_DTI





