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

    # part 4
    dti_vol_file = f'{HOME_DIR}/{subj_id}/dti/nodif_brain.nii.gz'
    sub_glasser_file=f'{HOME_DIR}/{subj_id}/glasser/HCPMMP1.nii.gz'
    # create a registeration file between functional and dti
    unix_pattern = ['bbregister',
                    '--s', subj_id,
                    '--mov', dti_vol_file,
                    '--init-fsl',
                    '--dti',
                    '--reg', f'{HOME_DIR}/{subj_id}/glasser/reg_glaser2nodif.dat']
    output = subprocess.Popen(unix_pattern, env=my_env,executable='/bin/bash',shell=False)
    output = subprocess.Popen(unix_pattern, env=my_env,  shell=False)
    output = subprocess.Popen(' '.join(unix_pattern), env=my_env, executable='/bin/bash', shell=False)
    output.communicate()