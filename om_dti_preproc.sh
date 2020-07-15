#!/bin/bash
#SBATCH --job-name=dti_preproc
#SBATCH --array=0
#SBATCH --time=56:00:00
#SBATCH -c 16
#SBATCH --mem=267G
#SBATCH --exclude node017,node018
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ehoseini@mit.edu


SUBJ=sub124
HOMEDIR=/mindhive/evlab/Shared/diffusionzeynep/
DIR=/mindhive/evlab/Shared/diffusionzeynep/DICOMS/sub124/dti/006/
#this should have been run:unpacksdcmdir -src $PROJECT_DIR/DICOMS/$SUB/dicoms/ -targ $PROJECT_DIR/DICOMS/$SUB/ -run $dtirun dti nii dti.nii
module add openmind/freesurfer/6.0.0
module add openmind/fsl/5.0.6
source /etc/profile.d/modules.sh
mkdir -p $HOMEDIR/$SUBJ/dti/

mv $DIR/dti.nii $HOMEDIR/$SUBJ/dti/diffusionseries.nii.gz
mv $DIR/dti.bvals $HOMEDIR/$SUBJ/dti/bvals
mv $DIR/dti.voxel_space.bvecs $HOMEDIR/$SUBJ/dti/bvecs


eddy_correct $HOMEDIR/$SUBJ/dti/diffusionseries.nii.gz $HOMEDIR/$SUBJ/dti/data.nii.gz 0

mkdir $HOMEDIR/$SUBJ/dti/temp
cp $HOMEDIR/$SUBJ/dti/data.nii.gz $HOMEDIR/$SUBJ/dti/temp/
fslsplit $HOMEDIR/$SUBJ/dti/temp/data.nii.gz $HOMEDIR/$SUBJ/dti/temp/vol -t
cp $HOMEDIR/$SUBJ/dti/temp/vol0000.nii.gz $HOMEDIR/$SUBJ/dti/nodif.nii.gz;
bet $HOMEDIR/$SUBJ/dti/nodif.nii.gz $HOMEDIR/$SUBJ/dti/nodif_brain -m -v -o -g 0.2 -f 0.3;
dtifit -k $HOMEDIR/$SUBJ/dti/temp/data.nii.gz -o $HOMEDIR/$SUBJ/dti/dti -m $HOMEDIR/$SUBJ/dti/nodif_brain_mask -r $HOMEDIR/$SUBJ/dti/bvecs -b $HOMEDIR/$SUBJ/dti/bvals -V ;

rm -r $HOMEDIR/$SUBJ/dti/temp