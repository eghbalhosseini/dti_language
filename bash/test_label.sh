#!/bin/bash

SUB=sub540
mri_vol2vol --targ /mindhive/evlab/Shared/diffusionzeynep/$SUB/fs/mri/aparc+aseg.mgz --reg /mindhive/evlab/Shared/diffusionzeynep/$SUB/lang_glasser/reg_FS2nodif.dat --mov /mindhive/evlab/Shared/diffusionzeynep/$SUB/dti/nodif_brain.nii.gz --inv --nearest --o /mindhive/evlab/Shared/diffusionzeynep/$SUB/indti/aparc+aseg-in-dti.nii.gz
matlab -nosplash -nojvm -r "cd('/mindhive/evlab/Shared/diffusionzeynep/scripts/Architract/');label_all('$SUB','/mindhive/evlab/Shared/diffusionzeynep/','aparc+aseg');exit"

#ln -s /mindhive/evlab/Shared/diffusionzeynep/$SUB/indti/lang_glasser_LH_indti.nii.gz /mindhive/evlab/Shared/diffusionzeynep//$SUB/indti/lang_glasser_LH-in-dti.nii.gz
#ln -s /mindhive/evlab/Shared/diffusionzeynep//$SUB/indti/lang_glasser_RH_indti.nii.gz /mindhive/evlab/Shared/diffusionzeynep//$SUB/indti/lang_glasser_RH-in-dti.nii.gz

#matlab -nosplash -nojvm -r "cd('/mindhive/evlab/Shared/diffusionzeynep/scripts/Architract/');\
#label_all_general('$SUB','/mindhive/evlab/Shared/diffusionzeynep/','lang_glasser_LH','/mindhive/evlab/Shared/diffusionzeynep/FSLUT_lang_glasser/FSLUT_LH_lang_glasser_ctab.txt’);\
#label_all_general('$SUB','/mindhive/evlab/Shared/diffusionzeynep/','lang_glasser_RH','/mindhive/evlab/Shared/diffusionzeynep/FSLUT_lang_glasser/FSLUT_RH_lang_glasser_ctab.txt’);exit"

#cp  /mindhive/evlab/Shared/diffusionzeynep/$SUB/indti/Labels/aparc+aseg/all* /mindhive/evlab/Shared/diffusionzeynep/$SUB//indti/Labels/lang_glasser_LH/.
#cp  /mindhive/evlab/Shared/diffusionzeynep/$SUB//indti/Labels/aparc+aseg/all* /mindhive/evlab/Shared/diffusionzeynep/$SUB//indti/Labels/lang_glasser_RH/.