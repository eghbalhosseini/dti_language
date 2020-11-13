#!/bin/bash

module add openmind/freesurfer
module add openmind/fsl/5.0.6

module unload openmind/anaconda/2.5.0
module load openmind/anaconda/1.9.2

HOMEDIR=/mindhive/evlab/Shared/diffusionzeynep

for SUBJ in $HOMEDIR/sub?*; do
	FILE=$SUBJ/dti.bedpostX/dyads1.nii.gz
	if ! test -f $FILE; then
		sbatch --array=0-100 -p normal --time=2:00:00 $ARCHITRACTDIR/z_run_bedpostX -h $HOMEDIR -s ${SUBJ##*/}
		sleep 2h
		ls $FILE
	fi
done
