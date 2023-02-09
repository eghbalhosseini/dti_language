#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/


threshold=$1
echo "threshold:${threshold}"

echo "looking at ${DTI_DIR} "
path_directory="${DTI_DIR}/probtrackX_paths_lang_glasser_thr_${threshold}"
# if path_directory directory doesnt exist, create it
if [ ! -d "$path_directory" ]; then
    mkdir -p $path_directory
fi
overwrite=false
while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      lh_path_file="${DTI_DIR}/probtrackX_paths_lang_glasser_thr_${threshold}/${subject_name}_LH_fdt_paths.nii.gz"
      rh_path_file="${DTI_DIR}/probtrackX_paths_lang_glasser_thr_${threshold}/${subject_name}_RH_fdt_paths.nii.gz"
      if [ "$overwrite" = true ]
      then
        echo "overwriting ${lh_file}"
        lh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_LH_thr_${threshold}/fdt_paths.nii.gz"
        # check of lh_tr_file exists
        if [ -f "$lh_tr_file" ]
        then
          cp ${lh_tr_file} ${lh_path_file}
        else
          echo "file ${lh_tr_file} does not exist"
        fi
        rh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_RH_thr_${threshold}/fdt_network_matrix"
        # check of rh_tr_file exists
        if [ -f "$rh_tr_file" ]
        then
          cp ${rh_tr_file} ${rh_path_file}
        else
          echo "file ${rh_tr_file} does not exist"
        fi
      else
        # check if lh_path_file exists
        if [ -f "$lh_path_file" ]
        then
          true
        else
          echo "path files dont exist, adding them"
          lh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_LH_thr_${threshold}/fdt_paths.nii.gz"
          # check of lh_tr_file exists
          if [ -f "$lh_tr_file" ]
          then
            cp ${lh_tr_file} ${lh_path_file}
          else
            echo "file ${lh_tr_file} does not exist"
          fi
       fi
        # check of rh_path_file exists
        if [ -f "$rh_path_file" ]
        then
          true
        else
          echo "path files dont exist, adding them"
          rh_tr_file="${DTI_DIR}/${subject_name}/dti.probtrackx/lang_glasser_RH_thr_${threshold}/fdt_paths.nii.gz"
          # check of rh_tr_file exists
          if [ -f "$rh_tr_file" ]
          then
            cp ${rh_tr_file} ${rh_path_file}
          else
            echo "file ${rh_tr_file} does not exist"
          fi
        fi

      fi
done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")
