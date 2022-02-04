#!/bin/bash
#SBATCH -c 8
#SBATCH --exclude node[017-018]
#SBATCH -t 5:00:00
#SBATCH --mem=32G
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

while IFS=, read -r line_count subj_name ; do
  #echo "line_count ${model}"
  if [ $JID == $line_count ]
    then
      echo "found the right match ${line_count}"
      SUB=$subj_name
      do_run=true
      break
    else
      do_run=false
  fi

done <"${GRAND_FILE}"
echo "subj:${SUB}"


. ~/.bash_profile
. ~/.bashrc
conda activate dti_language

# step 1
reg_file="/mindhive/evlab/Shared/diffusionzeynep/${SUB}/lang_glasser/reg_FS2nodif.dat"
mov_file="/mindhive/evlab/Shared/diffusionzeynep/${SUB}/dti/nodif_brain.nii.gz"
targ_file="/mindhive/evlab/Shared/diffusionzeynep/${SUB}/fs/mri/aparc+aseg.mgz"
out_file="/mindhive/evlab/Shared/diffusionzeynep/${SUB}/indti/aparc+aseg-in-dti.nii.gz"
mri_vol2vol --targ "${targ_file}" --reg "${reg_file}" --mov "${mov_file}"--inv --nearest --o "${out_file}"

# step 2

matlab -nosplash -nojvm -r "cd('/mindhive/evlab/Shared/diffusionzeynep/scripts/Architract/');\
label_all_eh('${SUB}','/mindhive/evlab/Shared/diffusionzeynep/','aparc+aseg');\
print('step 2 is done');exit"

link_src="/mindhive/evlab/Shared/diffusionzeynep/${SUB}/indti/lang_glasser_LH_indti.nii.gz"
link_targ="/mindhive/evlab/Shared/diffusionzeynep/${SUB}/indti/lang_glasser_LH-in-dti.nii.gz"
ln -s "${link_src}" "${link_targ}"

link_src="/mindhive/evlab/Shared/diffusionzeynep/${SUB}/indti/lang_glasser_RH_indti.nii.gz"
link_targ="/mindhive/evlab/Shared/diffusionzeynep/${SUB}/indti/lang_glasser_RH-in-dti.nii.gz"

ln -s "${link_src}" "${link_targ}"


# step 3

matlab -nosplash -nojvm -r "cd('/mindhive/evlab/Shared/diffusionzeynep/scripts/Architract/');\
label_all_general('${SUB}','/mindhive/evlab/Shared/diffusionzeynep/','lang_glasser_LH','/mindhive/evlab/Shared/diffusionzeynep/FSLUT_lang_glasser/FSLUT_LH_lang_glasser_ctab.txt');\
label_all_general('${SUB}','/mindhive/evlab/Shared/diffusionzeynep/','lang_glasser_RH','/mindhive/evlab/Shared/diffusionzeynep/FSLUT_lang_glasser/FSLUT_RH_lang_glasser_ctab.txt');\
;exit"

# step 4


cp  "/mindhive/evlab/Shared/diffusionzeynep/${SUB}/indti/Labels/aparc+aseg/all*" "/mindhive/evlab/Shared/diffusionzeynep/${SUB}//indti/Labels/lang_glasser_LH/."
cp  "/mindhive/evlab/Shared/diffusionzeynep/${SUB}//indti/Labels/aparc+aseg/all*" "/mindhive/evlab/Shared/diffusionzeynep/${SUB}//indti/Labels/lang_glasser_RH/."