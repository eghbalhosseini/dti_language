
import subprocess
from pathlib import Path
# import nibabel as nib
# import nilearn as nil
# from nilearn import datasets
# import nilearn.plotting as plotting
# import numpy as np
import os
import argparse
import requests
import bs4
from utils.parcel_utils import d_parcel_fsaverage, d_parcel_name_map
from utils.fmri_utils import HOME_DIR


# from utils.parcel_utils import d_parcel_fsaverage, d_parcel_name_map
from utils.fmri_utils import subj_lang_path, subj_FS_path

parser = argparse.ArgumentParser(description='create_subj_parcellation_from_glasser_to_native')

parser.add_argument('subj_id', type=str, default='sub190',
                    help='subject ID, e.g. "sub190" to run this script on')
parser.add_argument('--subjects_dir', type=str,
                    default='/om/user/ehoseini/dti_language/glasser_to_native/subjects_for_processing')
parser.add_argument('--data_source_dir', type=str,
                    default='/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/')

args = parser.parse_args()


if __name__ == '__main__':

    print(f'received arguments: {args}')

    subj_id = args.subj_id
    subj_id='sub190'
    subjects_dir = Path(args.subjects_dir)
    data_src = Path(args.data_source_dir)

    my_env = os.environ.copy()
    temp_dir='/mindhive/evlab/Shared/diffusionzeynep/temporary/'
    my_env['SUBJECTS_DIR'] = temp_dir
    # add HCP labels if they are not in the subjects folder
    output_dir=Path(f'{temp_dir}/glasser_annot')
    output_dir.mkdir(exist_ok=True, parents=True)
    dummy_sub_list=Path(f'{output_dir}/temp_subject_list_{subj_id}.txt')

    with dummy_sub_list.open('w') as f:
        f.write(f'{subj_id}\n')

    os.environ['SUBJECTS_DIR'] = str(subjects_dir)
    link_to_subject = subjects_dir / subj_id
    try:
        link_to_subject.symlink_to(str(data_src / subj_id))
    except FileExistsError:
        print(f'symlink or directory already exists: {link_to_subject}')

    print(f'making call to "create_subj_volumne_parcellation.sh"')
    cmd = ['./glasser_to_native/create_subj_volume_parcellation.sh',
           '-L', str(dummy_sub_list),
           '-a', 'HCP-MMP1',
           '-d', 'glasser_annot']
    output = subprocess.call(' '.join(cmd), env=my_env,shell=True,executable='/bin/bash')
    output.communicate()
    subprocess.call(cmd)
    subprocess.Popen(['mri_annotation2label','--help'],env=my_env)
    subprocess.Popen(cmd,env=my_env)
    #subprocess.Popen('fslmaths',shell=True,executable='/bin/bash')
    subprocess.Popen(['bash','~/.bash_profile'])
    output = subprocess.Popen(['fslmaths,--help'])
    # move everything from /mindhive/evlab/u/Shared/SUBJECTS_FS/DTI/sub190/glasser/sub190 into a dir above
    actual_output_files = [*(output_dir / subj_id).glob('*')]
    print(f'renaming output files {[*actual_output_files]}, continue? [Nn]')
    if input() not in set('Yy'): raise ValueError()

    Path(f'./out/{subj_id}').rename(str(output_dir))

    print(f'removing temp files {[*output_dir.glob("temp*")]}. continue? [Nn]')
    if input() not in set('Yy'): raise ValueError()
    for f in Path('./out').glob('temp*'):
        print(f'REMOVING {f}')
        f.rename('/om2/scratch/Mon/' + f.name)

    print(f'FIN. removing dummy sub list {dummy_sub_list}')
    dummy_sub_list.unlink()

