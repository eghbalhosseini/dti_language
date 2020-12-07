#!/bin/bash

HOMEDIR=/mindhive/evlab/Shared/diffusionzeynep

for SUBJ in $HOMEDIR/sub?*; do
	FILE=$SUBJ/dti.bedpostX/dyads1.nii.gz
	if ! test -f $FILE; then
		echo $SUBJ | tee -a missing_dti_bedpostX.txt
	fi
done

