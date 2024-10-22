#!/bin/bash
#!/bin/bash
#SBATCH --exclude node[017-018,094]
#SBATCH -t 8:00:00
#SBATCH --mem=10G
GRAND_FILE=$1
OVERWRITE='false' # or 'true'
#
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
  JID=$SLURM_ARRAY_TASK_ID    # Taking the task ID in a job array as an input parameter.
else
  JID=$2       # Taking the task ID as an input parameter.
fi
echo "${GRAND_FILE}"
echo $JID

while IFS=, read -r line_count subj_name ; do
  #echo "line_count ${model}"
  if [ $JID == $line_count ]
    then
      echo "found the right match ${line_count}"
      SUBJ=$subj_name
      do_run=true
      break
    else
      do_run=false
  fi

done <"${GRAND_FILE}"
echo "subj:${SUBJ}"
echo "segment :${SEGNAME}"

HOMEDIR=/mindhive/evlab/Shared/diffusionzeynep/

# Load necessary modules
module add openmind/freesurfer
module add openmind/fsl/5.0.6
module add openmind/miniconda/3.18.3-python2

# Change to the subject's directory
cd ${HOMEDIR}/${SUBJ}/ || { echo "Error: Could not change to subject directory ${HOMEDIR}/${SUBJ}/"; exit 1; }

# Create symbolic link for bedpostX directory
ln -sf /mindhive/evlab/Shared/diffusionzeynep/${SUBJ}/dti.bedpostX /mindhive/evlab/Shared/diffusionzeynep/${SUBJ}/trc/${SUBJ}/dmri.bedpostX/

# Run trac-all commands with the subject-specific configuration file
CONFIG_FILE="tracula_config_${SUBJ}.csh"

# Run trac-all pipeline
trac-all -prep -c ${CONFIG_FILE}
trac-all -path -c ${CONFIG_FILE}