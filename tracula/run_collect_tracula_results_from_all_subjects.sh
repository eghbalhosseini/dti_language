#!/bin/bash
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
FS_DIR=/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/

DUMP_DIR=/mindhive/evlab/Shared/diffusionzeynep/tracula_dpath/
# make sure the directory DUMP_DIR exists
mkdir -p $DUMP_DIR
threshold=$1
echo "threshold:${threshold}"

#threshold=20
probtrackX_labels_="all_subject_tracula"
i=0
LINE_COUNT=0
SUBJECT_TRX_FILE="${DTI_DIR}/${probtrackX_labels_}.txt"
rm -f $SUBJECT_TRX_FILE
touch $SUBJECT_TRX_FILE
printf "%s,%s\n" "row" "subject_name" >> $SUBJECT_TRX_FILE

echo "looking at ${DTI_DIR} "
SUBJ_LINE=0
overwrite= false
bad_sub=(sub007 sub072 sub106 sub124 sub126 sub135 sub136 sub138 sub148 sub159 sub163 sub171 sub172 sub190 sub195 sub199 sub202 sub210 sub234 sub254 sub311 sub540 sub541)

#while read x; do
#      # check if file already exist in labels dir
#      original=$DTI_DIR
#      correction=''
#      subject_name="${x/$original/$correction}"
#      if [[ " ${bad_sub[@]} " =~ " ${subject_name} " ]]; then
#        echo "skipping ${subject_name}"
#        continue
#      else
#        # first remove this file if it exists
#
#
#        trc_folder="${DTI_DIR}/${subject_name}/trc/${subject_name}"
#        dpath_folder="${DTI_DIR}/${subject_name}/trc/${subject_name}/dpath"
#        # create a subdirtoryc for subject under DUmp_DIR
#        mkdir -p $DUMP_DIR/${subject_name}
#        # copy the dpath_folder onto subject dump directory
#        # print what you are doing
#        echo "copying path_files to ${DUMP_DIR}/${subject_name}/"
#        cp -r $dpath_folder $DUMP_DIR/${subject_name}/
#
#        #rm $lh_folder
#        #rm $rh_folder
#
#      fi
#done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")


DUMP_DF_DIR=/mindhive/evlab/Shared/diffusionzeynep/dtifit_FA_dpath/
# make sure the directory DUMP_DIR exists
mkdir -p $DUMP_DF_DIR
while read x; do
      # check if file already exist in labels dir
      original=$DTI_DIR
      correction=''
      subject_name="${x/$original/$correction}"
      if [[ " ${bad_sub[@]} " =~ " ${subject_name} " ]]; then
        echo "skipping ${subject_name}"
        continue
      else
        # first remove this file if it exists


        trc_folder="${DTI_DIR}/${subject_name}/trc/${subject_name}"
        dtifit_FA_file="${DTI_DIR}/${subject_name}/trc/${subject_name}/dmri/dtifit_FA.nii.gz"
        "/mindhive/evlab/Shared/diffusionzeynep/sub206/trc/sub206/dmri/dtifit_FA.nii.gz"
        # create a subdirtoryc for subject under DUmp_DIR
        mkdir -p $DUMP_DF_DIR/${subject_name}
        # copy the dpath_folder onto subject dump directory
        # print what you are doing
        echo "copying path_files to ${DUMP_DF_DIR}/${subject_name}/"
        cp -r $dtifit_FA_file ${DUMP_DF_DIR}/${subject_name}/

        #rm $lh_folder
        #rm $rh_folder

      fi
done < <(find $DTI_DIR -maxdepth 1 -type d -name "sub*")
