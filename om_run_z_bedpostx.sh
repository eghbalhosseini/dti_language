#!/bin/bash

module add openmind/freesurfer
module add openmind/fsl/5.0.6

SUBJ=sub007
HOMEDIR=/mindhive/evlab/Shared/diffusionzeynep
sbatch --array=0-100 -p normal --time=56:00:00 /mindhive/evlab/Shared/diffusionzeynep/scripts/Architract/z_run_bedpostX -h $HOMEDIR -s $SUBJ

##shell /mindhive/evlab/Shared/diffusionzeynep/scripts/Architract/z_run_bedpostX -h $HOMEDIR -s $SUBJ
