#!/bin/bash

SUBJ=sub129
HOMEDIR=/mindhive/evlab/Shared/diffusionzeynep
sbatch --array=0-100 -p normal --time=56:00:00 /mindhive/evlab/Shared/diffusionzeynep/scripts/Architract/z_run_bedpostX -h $HOMEDIR -s $SUBJ

##shell /mindhive/evlab/Shared/diffusionzeynep/scripts/Architract/z_run_bedpostX -h $HOMEDIR -s $SUBJ