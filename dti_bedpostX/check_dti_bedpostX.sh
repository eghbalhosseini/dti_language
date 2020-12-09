#!/bin/bash

freesurfer

HOMEDIR=/mindhive/evlab/Shared/diffusionzeynep

for SUBJ in $HOMEDIR/sub?*; do
	VOL=$SUBJ/dti.bedpostX/nodif_brain.nii.gz
	if test -f $VOL; then
		VEC=$SUBJ/dti.bedpostX/dyads1.nii.gz
		if test -f $VEC; then
			for VIEW in x y z; do
				freeview --dti $VEC:vector=True $VOL --viewport $VIEW --screenshot dti_bedpostX_QA/${SUBJ##*/}_$VIEW.jpg
			done 
		fi
	fi
done
