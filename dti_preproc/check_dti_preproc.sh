for d in /mindhive/evlab/Shared/diffusionzeynep/sub*
do
	fname=$d/dti/dti_V1.nii.gz
	if test -f $fname; then
		freeview $fname:vector=true
	else
		: #echo $d | tee -a missing_dti_preproc.txt
	fi
done
