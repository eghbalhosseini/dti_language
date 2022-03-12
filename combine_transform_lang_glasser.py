import nibabel as nib
from nilearn import datasets
import numpy as np
import subprocess
import pandas as pd
import argparse
from utils.fmri_utils import subj_lang_path, subj_FS_path,HOME_DIR
from utils.lookuptable import FSLUT_lang_pd, FSLUT_glasser_pd, FSLUT_RH_lang_glasser_pd, FSLUT_LH_lang_glasser_pd
fsaverage = datasets.fetch_surf_fsaverage(mesh='fsaverage')
from pathlib import Path
from nilearn.image import load_img
from copy import deepcopy
from collections import namedtuple
from glob import glob

def get_args():
    parser = argparse.ArgumentParser(description='combine fmri and glasser data ')
    parser.add_argument('subj_id', type=str)
    parser.add_argument('network_id', type=str)#, default='lang')
    args=parser.parse_args()
    return args

def mock_get_args():
    mock_args = namedtuple('debug', ['subj_id', 'network_id'])
    new_args = mock_args('sub540', 'lang')
    return new_args

debug=True

if __name__ == '__main__':
    if debug:
        args=mock_get_args()
    else:
        args=get_args()
    subj_id = args.subj_id
    network_id = args.network_id  # 'lang'
    #
    file_name = 'fsig'
    sub_lang_path=Path(f"{HOME_DIR}/{subj_id}/fmri")
    sub_mri_path=Path(f"{HOME_DIR}/{subj_id}/fs/mri/brain.mgz")
    # find images for network of interest
    network_paths=np.asarray(glob(Path(f"{sub_lang_path}/x.fsnative.{network_id}*").__str__()))
    non_dti=[not 'DTI' in x for x in network_paths]
    network_paths_non_dti=network_paths[non_dti]
    lang_imges = [load_img(x) for x in network_paths_non_dti]
    glasser_img=load_img(f'{str(sub_lang_path.parent)}/glasser/HCPMMP1.nii.gz')
    # make sure they have same size
    for im in lang_imges:
        assert(im.shape==glasser_img.shape)
        assert((im.affine == glasser_img.affine).all())
    ## 1. combining glasser and lang images. we start by a glasser image and replace the voxel ids for language from lang_img
    lang_np_lst=[np.asarray(x.dataobj) for x in lang_imges]
    glasser_np=np.asarray(glasser_img.dataobj)
    # fixed variable here : this is from
    # make sure subject at least have 1 roi
    for l_np in lang_np_lst:
        assert(len(set(FSLUT_lang_pd.id).intersection(np.unique(l_np)))>=1)

    assert (len(set(FSLUT_glasser_pd.id).intersection(np.unique(glasser_np))) >= 1)
    # make sure there is no overlap between lang and glasser ids
    assert (set(FSLUT_glasser_pd.id).intersection(set(FSLUT_lang_pd.id)) =={0})

    # reset image so it contain either glasser or lang ids
    for idx, l_np in enumerate(lang_np_lst):
        non_lang=~np.isin(l_np,np.asarray(FSLUT_lang_pd.id.drop(0)))
        l_np[non_lang]=0
        lang_np_lst[idx]=l_np
    #
    # combine language nps to only one
    # first make sure there is no overlap
    a = lang_np_lst[0] > 0
    b = lang_np_lst[1] > 0
    assert (np.sum(np.multiply(a,b))==0)
    lang_np=lang_np_lst[0]+lang_np_lst[1]
    non_glasser = ~np.isin(glasser_np, np.asarray(FSLUT_glasser_pd.id.drop(0)))
    glasser_np[non_glasser] = 0
    #
    combined_np=deepcopy(glasser_np)
    # drop unknown

    for _,key_id in enumerate(np.asarray(FSLUT_lang_pd.id.drop(0))):
        mask_loc=np.isin(lang_np,key_id)
        print(f"\n {key_id} {np.sum(mask_loc)} \n")
        combined_np[mask_loc]=key_id
    # format the image for saving
    combine_img=nib.Nifti1Image(combined_np,lang_imges[0].affine,lang_imges[0].header)
    combine_file_pth=Path(f"{HOME_DIR}/{subj_id}/lang_glasser/lang_glasser_BOTH.nii.gz")
    combine_file_pth.parent.mkdir(parents=True, exist_ok=True)
    nib.save(combine_img,str(combine_file_pth))
    # save a table for voxel per region
    [reg_id,reg_count]=np.unique(combined_np,return_counts=True)
    FSLUT_pd=pd.concat([FSLUT_lang_pd,FSLUT_glasser_pd]).drop_duplicates()
    assert(len(np.setdiff1d(reg_id,np.unique(FSLUT_pd.id)))==0)
    FSLUT_reg=pd.concat([FSLUT_pd[FSLUT_pd.id==x] for x in reg_id])
    FSLUT_reg.insert(2,'num_voxel',reg_count)
    FSLUT_reg=FSLUT_reg.drop(['R','G','B','A'],axis=1)
    FSLUT_reg=FSLUT_reg.drop(0)
    combine_count_pth = Path(f"{HOME_DIR}/{subj_id}/lang_glasser/lang_glasser_BOTH_count.csv")
    FSLUT_reg.to_csv(str(combine_count_pth))
    #   SAVE HEMSPHERIC VERSIONS
    # here we drop the zero index
    # left
    left_lang_glass_np=deepcopy(combined_np)
    non_left=~np.isin(left_lang_glass_np,FSLUT_LH_lang_glasser_pd.id.drop(0))
    left_lang_glass_np[non_left] = 0
    left_img = nib.Nifti1Image(left_lang_glass_np, lang_imges[0].affine, lang_imges[0].header)
    left_file_pth = Path(f"{HOME_DIR}/{subj_id}/lang_glasser/lang_glasser_LH.nii.gz")
    left_file_pth.parent.mkdir(parents=True, exist_ok=True)
    nib.save(left_img, str(left_file_pth))
    # save a table for voxel per region
    [reg_id, reg_count] = np.unique(left_lang_glass_np, return_counts=True)
    np.argwhere(reg_id==0)
    np.delete(reg_id,[0])
    np.delete(reg_count,np.argwhere(reg_id==0))
    assert (np.setdiff1d(reg_id, np.unique(FSLUT_LH_lang_glasser_pd.id)) == 0)
    FSLUT_L_reg = pd.concat([FSLUT_LH_lang_glasser_pd[FSLUT_LH_lang_glasser_pd.id == x] for x in reg_id])
    FSLUT_L_reg.insert(2, 'num_voxel', reg_count)
    FSLUT_L_reg = FSLUT_L_reg.drop(['R', 'G', 'B', 'A'], axis=1)
    FSLUT_L_reg = FSLUT_L_reg.drop(0)
    lh_count_pth = Path(f"{HOME_DIR}/{subj_id}/lang_glasser/lang_glasser_LH_count.csv")
    FSLUT_L_reg.to_csv(str(lh_count_pth))

    # right
    right_lang_glass_np = deepcopy(combined_np)
    non_right = ~np.isin(right_lang_glass_np, FSLUT_RH_lang_glasser_pd.id.drop(0))
    right_lang_glass_np[non_right] = 0
    right_img = nib.Nifti1Image(right_lang_glass_np, lang_imges[0].affine, lang_imges[0].header)
    right_file_pth = Path(f"{HOME_DIR}/{subj_id}/lang_glasser/lang_glasser_RH.nii.gz")
    right_file_pth.parent.mkdir(parents=True, exist_ok=True)
    nib.save(right_img, str(right_file_pth))
    # save a table for voxel per region
    [reg_id, reg_count] = np.unique(right_lang_glass_np, return_counts=True)
    assert (len(np.setdiff1d(reg_id, np.unique(FSLUT_RH_lang_glasser_pd.id))) == 0)
    FSLUT_R_reg = pd.concat([FSLUT_RH_lang_glasser_pd[FSLUT_RH_lang_glasser_pd.id == x] for x in reg_id])
    FSLUT_R_reg.insert(2, 'num_voxel', reg_count)
    FSLUT_R_reg = FSLUT_R_reg.drop(['R', 'G', 'B', 'A'], axis=1)
    FSLUT_R_reg = FSLUT_R_reg.drop(0)
    rh_count_pth = Path(f"{HOME_DIR}/{subj_id}/lang_glasser/lang_glasser_RH_count.csv")
    FSLUT_R_reg.to_csv(str(rh_count_pth))

    # save a
    ## 2. tranform the volume to dti space
    dti_vol_file=f'{HOME_DIR}/{subj_id}/dti/nodif_brain.nii.gz'
    reg_file_pth=Path(f'{HOME_DIR}/{subj_id}/lang_glasser/reg_FS2nodif.dat')
    if not reg_file_pth.exists():
    # create a registeration file between functional and dti
        unix_pattern = ['bbregister',
                    '--s', subj_id,
                    '--mov', dti_vol_file,
                    '--init-fsl',
                    '--dti',
                    '--reg', str(reg_file_pth)]
        unix_str = ' '.join(unix_pattern)
        cmd = f'''
        export SUBJECTS_DIR={subj_FS_path}
        module list
        echo $SUBJECTS_DIR
        {unix_str}
        '''
        subprocess.call(cmd, shell=True, executable='/bin/bash')
    # do mri_vol2vol
    combine_dti_file_pth=Path(f"{HOME_DIR}/{subj_id}/indti/lang_glasser_BOTH_indti.nii.gz")
    combine_dti_file_pth.parent.mkdir(parents=True, exist_ok=True)
    unix_pattern = ['mri_vol2vol',
                    '--targ', str(combine_file_pth),
                    '--mov', dti_vol_file,
                    '--inv',
                    '--interp', 'nearest',
                    '--reg', str(reg_file_pth),
                    '--o',str(combine_dti_file_pth)]
    unix_str = ' '.join(unix_pattern)
    cmd = f'''
        export SUBJECTS_DIR={subj_FS_path}
        module list
        echo $SUBJECTS_DIR
        {unix_str}
        '''
    subprocess.call(cmd, shell=True, executable='/bin/bash')
    #
    left_dti_file_pth = Path(f"{HOME_DIR}/{subj_id}/indti/lang_glasser_LH_indti.nii.gz")
    unix_pattern = ['mri_vol2vol',
                    '--targ', str(left_file_pth),
                    '--mov', dti_vol_file,
                    '--inv',
                    '--interp', 'nearest',
                    '--reg', str(reg_file_pth),
                    '--o', str(left_dti_file_pth)]
    unix_str = ' '.join(unix_pattern)
    cmd = f'''
            export SUBJECTS_DIR={subj_FS_path}
            module list
            echo $SUBJECTS_DIR
            {unix_str}
            '''
    subprocess.call(cmd, shell=True, executable='/bin/bash')
    # right
    right_dti_file_pth = Path(f"{HOME_DIR}/{subj_id}/indti/lang_glasser_RH_indti.nii.gz")
    unix_pattern = ['mri_vol2vol',
                    '--targ', str(right_file_pth),
                    '--mov', dti_vol_file,
                    '--inv',
                    '--interp', 'nearest',
                    '--reg', str(reg_file_pth),
                    '--o', str(right_dti_file_pth)]
    unix_str = ' '.join(unix_pattern)
    cmd = f'''
                export SUBJECTS_DIR={subj_FS_path}
                module list
                echo $SUBJECTS_DIR
                {unix_str}
                '''
    subprocess.call(cmd, shell=True, executable='/bin/bash')
