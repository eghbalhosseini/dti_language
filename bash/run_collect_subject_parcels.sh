#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/

i=0
LINE_COUNT=0

echo "looking at ${DTI_DIR} "
SUBJ_LINE=0
mkdir -p "${DTI_DIR}/parcels_in_dti"
overwrite=false
while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      parcel_file="${DTI_DIR}/parcels_in_dti/${subject_name}_lang_parcels_indti.nii.gz"
      if [ "$overwrite" = true ]
      then
        echo "overwriting ${parcel_file}"
        LINE_COUNT=$(expr ${LINE_COUNT} + 1)
        # folder to find the file
        parcel_src_file="${DTI_DIR}/${subject_name}/parcel/${subject_name}_lang_parcels_indti.nii.gz"
        cp $parcel_src_file $parcel_file
      else
        if [ ! -f "$parcel_file" ]
          then
            echo "missing ${parcel_file}"
            LINE_COUNT=$(expr ${LINE_COUNT} + 1)
            # folder to find the file
            parcel_src_file="${DTI_DIR}/${subject_name}/parcel/${subject_name}_lang_parcels_indti.nii.gz"
            cp $parcel_src_file $parcel_file

        fi
      fi
done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")