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

while IFS=, read -r line_count subj_name network_id threshold ; do
  #echo "line_count ${model}"
  if [ $JID == $line_count ]
    then
      echo "found the right match ${line_count}"
      run_subj_name=$subj_name
      run_network_id=$network_id
      run_threshold=$threshold
      do_run=true
      break
    else
      do_run=false
  fi

done <"${GRAND_FILE}"
if $do_run; then
  echo "subj:${run_subj_name}"
  echo "network:${run_network_id}"
  echo "threshold:${run_threshold}"
  echo $SUBJECTS_DIR


  . ~/.bash_profile
  conda activate dti_language
  echo $(which python)
  python /om2/user/ehoseini/dti_language/combine_transform_lang_glasser.py "$run_subj_name" "$run_network_id" "$run_threshold"
fi


