#!/bin/bash

module add openmind/freesurfer
module add openmind/fsl/5.0.6

HOMEDIR=/mindhive/evlab/Shared/diffusionzeynep

sb=0
se=20

for i in {1..11}; do

	n=0
	for SUBJ in $HOMEDIR/sub*; do
		if [ "$n" -ge "$sb" ] && [ "$n" -lt "$se" ]; then
			sbatch --array=0-100 -p normal --time=6:00:00 $ARCHITRACTDIR/z_run_bedpostX -h $HOMEDIR -s ${SUBJ##*/}
		fi
	n=$((n+1))
	done

	sb=$((sb+20))
	se=$((se+20))

	sleep 6.1h

done
