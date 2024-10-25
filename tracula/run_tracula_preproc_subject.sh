#!/bin/bash
#SBATCH -n 1 # one core
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
CONFIG_FILE="tracula_config_${SUBJ}.csh"
which python
trac-all -prep -c ${CONFIG_FILE}
# create an empty directory for linking the bedpostX directory @ /mindhive/evlab/Shared/diffusionzeynep/${SUBJ}/trc/${SUBJ}/dmri.bedpostX/ also create the parents
# make sure the parents to /mindhive/evlab/Shared/diffusionzeynep/${SUBJ}/trc/${SUBJ}/dmri.bedpostX/ exist
# Define the path
path="/mindhive/evlab/Shared/diffusionzeynep/${SUBJ}/trc/${SUBJ}/dmri.bedpostX/"
# Create parent directories if they don't exist
mkdir -p "$(dirname "$path")"
echo "Ensured parent directories exist for: $path"
# Create symbolic link for bedpostX directory
ln -sf /mindhive/evlab/Shared/diffusionzeynep/${SUBJ}/dti.bedpostX /mindhive/evlab/Shared/diffusionzeynep/${SUBJ}/trc/${SUBJ}/dmri.bedpostX/
# Run trac-all commands with the subject-specific configuration file
# Run trac-all pipeline
trac-all -path -c ${CONFIG_FILE}