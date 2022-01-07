import nibabel as nib
import nilearn as nil
from nilearn import datasets
import nilearn.plotting as plotting
import numpy as np
from tqdm import tqdm
import os
import subprocess
import argparse

from utils.fmri_utils import subj_lang_path, subj_FS_path,HOME_DIR
from utils.lookuptable import FSLUT_lang_pd, FSLUT_glasser_pd
fsaverage = datasets.fetch_surf_fsaverage(mesh='fsaverage')
from pathlib import Path

import matplotlib.pyplot as plt
from nilearn.image import load_img
from copy import deepcopy


if __name__ == '__main__':
    subj_id = 'sub721'
    network_id = 'lang'
    threshold = 90
    thr_type = 'top'
    file_name = 'fsig'
    sub_lang_path=Path(f"{HOME_DIR}/{subj_id}/fmri")
    sub_mri_path=Path(f"{HOME_DIR}/{subj_id}/fs/mri/brain.mgz")
    lang_img = load_img(f'{str(sub_lang_path)}/x.fsnative.{network_id}_roi_{thr_type}_{threshold}.nii.gz')
    glasser_img=load_img(f'{str(sub_lang_path.parent)}/glasser/HCPMMP1.nii.gz')
    # make sure they have same size
    assert(lang_img.shape==glasser_img.shape)
    ## 1. combining glasser and lang images. we start by a glasser image and replace the voxel ids for language from lang_img
    lang_np=np.asarray(lang_img.dataobj)
    glasser_np=np.asarray(glasser_img.dataobj)
    # fixed variable here : this is from
    # make sure subject at least have 1 roi
    assert(len(set(lang_mask_ids.keys()).intersection(np.unique(lang_np)))>=1)
    assert (len(set(glasser_mask_ids.keys()).intersection(np.unique(glasser_np))) >= 1)
    # make sure there is no overlap between lang and glasser ids
    assert (len(set(glasser_mask_ids.keys()).intersection(set(lang_mask_ids.keys()))) == 0)
    assert((lang_img.affine==glasser_img.affine).all())
    # reset image so it contain either glasser or lang ids
    non_lang=~np.isin(lang_np,np.asarray(list(lang_mask_ids.keys())))
    lang_np[non_lang]=0
    #
    non_glasser = ~np.isin(glasser_np, np.asarray(list(glasser_mask_ids.keys())))
    glasser_np[non_glasser] = 0
    #
    combined_np=deepcopy(glasser_np)
    for _,key_id in tqdm(enumerate(lang_mask_ids.keys())):
        mask_loc=np.isin(lang_np,key_id)
        print(f"\n {np.sum(mask_loc)} \n")
        combined_np[mask_loc]=key_id
    # format the image for saving
    combine_img=nib.Nifti1Image(combined_np,lang_img.affine,lang_img.header)
    combine_file_pth=Path(f"{HOME_DIR}/{subj_id}/lang_glasser/combined_fROI.nii.gz")
    combine_file_pth.parent.mkdir(parents=True, exist_ok=True)
    nib.save(combine_img,str(combine_file_pth))

    ## 2. tranform the volume to dti space
    dti_vol_file=f'{HOME_DIR}/{subj_id}/dti/nodif_brain.nii.gz'
    reg_file_pth=f'{HOME_DIR}/{subj_id}/lang_glasser/reg_FS2nodif.dat'
    # create a registeration file between functional and dti
    unix_pattern = ['bbregister',
                    '--s', subj_id,
                    '--mov', dti_vol_file,
                    '--init-fsl',
                    '--dti',
                    '--reg', reg_file_pth]
    unix_str = ' '.join(unix_pattern)
    cmd = f'''
        export SUBJECTS_DIR={subj_FS_path}
        module list
        echo $SUBJECTS_DIR
        {unix_str}
        '''
    subprocess.call(cmd, shell=True, executable='/bin/bash')
    # do mri_vol2vol
    combine_dti_file_pth=Path(f"{HOME_DIR}/{subj_id}/lang_glasser/combined_fROI_in_DTI.nii.gz")
    unix_pattern = ['mri_vol2vol',
                    '--targ', f'{combine_file_pth}',
                    '--mov', dti_vol_file,
                    '--inv',
                    '--interp', 'nearest',
                    '--reg', reg_file_pth,
                    '--o',str(combine_dti_file_pth)]
    unix_str = ' '.join(unix_pattern)
    cmd = f'''
        export SUBJECTS_DIR={subj_FS_path}
        module list
        echo $SUBJECTS_DIR
        {unix_str}
        '''
    subprocess.call(cmd, shell=True, executable='/bin/bash')
