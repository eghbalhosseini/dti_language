import nibabel as nib
import nilearn as nil
from nilearn import datasets
import nilearn.plotting as plotting
import numpy as np
import os
import subprocess
import argparse
from utils.parcel_utils import d_parcel_fsaverage, d_parcel_name_map
from utils.fmri_utils import subj_lang_path, subj_FS_path,HOME_DIR
fsaverage = datasets.fetch_surf_fsaverage(mesh='fsaverage')
from pathlib import Path
from shutil import copyfile
import matplotlib.pyplot as plt
from nilearn.image import load_img, math_img
from matplotlib.colors import ListedColormap, LinearSegmentedColormap
from utils.lookuptable import FSLUT, _FSLUT_HEADER


if __name__ == '__main__':
    subj_id = 'sub721'
    my_env = os.environ.copy()
    my_env['SUBJECTS_DIR'] = '/mindhive/evlab/Shared/diffusionzeynep/GLASSER'
    TEMP_DIR='/mindhive/evlab/Shared/diffusionzeynep/GLASSER'
    # part 4
    dti_vol_file = f'{HOME_DIR}/{subj_id}/dti/nodif_brain.nii.gz'
    sub_glasser_file=f'{HOME_DIR}/{subj_id}/glasser/HCPMMP1.nii.gz'
    sub_glasser_dti_file = f'{HOME_DIR}/{subj_id}/glasser/HCPMMP1_in_DTI.nii.gz'
    # create a registeration file between functional and dti
    unix_pattern = ['bbregister',
                    '--s', subj_id,
                    '--mov', dti_vol_file,
                    '--init-fsl',
                    '--dti',
                    #'--bold',
                    '--reg', f'{HOME_DIR}/{subj_id}/glasser/reg_glaser2nodif.dat']
    unix_str=' '.join(unix_pattern)
    cmd = f'''
    export SUBJECTS_DIR={TEMP_DIR}
    module list
    echo $SUBJECTS_DIR
    {unix_str}
    '''
    subprocess.call(cmd, shell=True, executable='/bin/bash')
    # do mri_vol2vol
    unix_pattern = ['mri_vol2vol',
                    '--targ',
                    f'{sub_glasser_file}',
                    '--mov', dti_vol_file,
                    '--inv',
                    '--interp', 'nearest',
                    '--reg', f'{HOME_DIR}/{subj_id}/glasser/reg_glaser2nodif.dat',
                    '--o',
                    f'{sub_glasser_dti_file}']
    unix_str = ' '.join(unix_pattern)
    cmd = f'''
    export SUBJECTS_DIR={TEMP_DIR}
    module list
    echo $SUBJECTS_DIR
    {unix_str}
    '''
    subprocess.call(cmd, shell=True, executable='/bin/bash')