#!/bin/bash

SUBJ=sub007
HOMEDIR=/mindhive/evlab/Shared/diffusionzeynep/

#this should have been run:unpacksdcmdir -src $PROJECT_DIR/DICOMS/$SUB/dicoms/ -targ $PROJECT_DIR/DICOMS/$SUB/ -run $dtirun dti nii dti.nii

module add openmind/freesurfer
module add openmind/fsl/5.0.6
module add openmind/miniconda/3.18.3-python2

cd ${HOMEDIR}/${SUBJ}/
#trac-all -prep -c tracula_config_sub007.csh
trac-all -path -c tracula_config_sub007.csh