import nibabel as nib
from nilearn import datasets
import numpy as np
import subprocess
import argparse
from utils.fmri_utils import subj_lang_path, subj_FS_path,HOME_DIR
from utils.lookuptable import FSLUT_lang_pd, FSLUT_glasser_pd, FSLUT_RH_lang_glasser_pd, FSLUT_LH_lang_glasser_pd
fsaverage = datasets.fetch_surf_fsaverage(mesh='fsaverage')
from pathlib import Path
from nilearn.image import load_img
from copy import deepcopy

parser = argparse.ArgumentParser(description='combine fmri and glasser data ')
parser.add_argument('subj_id', type=str)
parser.add_argument('network_id', type=str)#, default='lang')
parser.add_argument('threshold', type=int)#, default=90)
parser.add_argument('thr_type',type=str,default='top') # top or bottom
args=parser.parse_args()

if __name__ == '__main__':
    subj_id = args.subj_id
    # subj_id='sub721'
    network_id = args.network_id  # 'lang'
    # network_id='lang'
    threshold = args.threshold
    # threshold= 10
    thr_type = args.thr_type
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
    assert(len(set(FSLUT_lang_pd.id).intersection(np.unique(lang_np)))>=1)
    assert (len(set(FSLUT_glasser_pd.id).intersection(np.unique(glasser_np))) >= 1)
    # make sure there is no overlap between lang and glasser ids
    assert (len(set(FSLUT_glasser_pd.id).intersection(set(FSLUT_lang_pd.id))) ==1)
    assert((lang_img.affine==glasser_img.affine).all())
    # reset image so it contain either glasser or lang ids
    non_lang=~np.isin(lang_np,np.asarray(FSLUT_lang_pd.id.drop(0)))
    lang_np[non_lang]=0
    #
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
    combine_img=nib.Nifti1Image(combined_np,lang_img.affine,lang_img.header)
    combine_file_pth=Path(f"{HOME_DIR}/{subj_id}/lang_glasser/lang_glasser_BOTH.nii.gz")
    combine_file_pth.parent.mkdir(parents=True, exist_ok=True)
    nib.save(combine_img,str(combine_file_pth))
    #   SAVE HEMSPHERIC VERSIONS
    # left
    left_lang_glass_np=deepcopy(combined_np)
    non_left=~np.isin(left_lang_glass_np,FSLUT_LH_lang_glasser_pd.id.drop(0))
    left_lang_glass_np[non_left] = 0
    left_img = nib.Nifti1Image(left_lang_glass_np, lang_img.affine, lang_img.header)
    left_file_pth = Path(f"{HOME_DIR}/{subj_id}/lang_glasser/lang_glasser_LH.nii.gz")
    left_file_pth.parent.mkdir(parents=True, exist_ok=True)
    nib.save(left_img, str(left_file_pth))
    # right
    right_lang_glass_np = deepcopy(combined_np)
    non_right = ~np.isin(right_lang_glass_np, FSLUT_RH_lang_glasser_pd.id.drop(0))
    right_lang_glass_np[non_right] = 0
    right_img = nib.Nifti1Image(right_lang_glass_np, lang_img.affine, lang_img.header)
    right_file_pth = Path(f"{HOME_DIR}/{subj_id}/lang_glasser/lang_glasser_RH.nii.gz")
    right_file_pth.parent.mkdir(parents=True, exist_ok=True)
    nib.save(right_img, str(right_file_pth))

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
