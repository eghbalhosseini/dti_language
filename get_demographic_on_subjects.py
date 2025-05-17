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
from matplotlib.colors import ListedColormap
from utils.lookuptable import FSLUT
from glob import glob
import pandas as pd


if __name__ == '__main__':
    root_dir='/mindhive/evlab/Shared/diffusionzeynep/'

    # find directory that start with sub and end with number in the form of subXXX
    sub_dirs = [d for d in os.listdir(root_dir) if os.path.isdir(os.path.join(root_dir, d)) and d.startswith('sub') and d[3:].isdigit()]
    len(sub_dirs)
    sub_ids= [float(d[3:]) for d in sub_dirs]
    # read the excel sheet that contains subject information
    sub_info_file='/mindhive/evlab/Shared/diffusionzeynep/fmri_subjects_info.xlsx'
    sub_info_df = pd.read_excel(sub_info_file)
    # load subject with dti
    sub_dti_info_df= pd.read_excel('/mindhive/evlab/Shared/diffusionzeynep/DTI_Sessions_05062025_ev_eh.xlsx')
    # # for each subject first find the correpsondign rows in sub_info_df, then use the corresponding row in sub_dti_info_df to find the exact row
    # find out for which sub_ids there is no corresponding row in sub_dti_info_df
    for id in sub_ids:
        if len(sub_dti_info_df[sub_dti_info_df['UID'] == int(id)])==0:
            print(f'subject {id} not found in sub_info_df')

    # find the rows in sub_info_df that contain the subject id


    subs_age=[]
    subs_gender=[]
    sessions_dates=[]
    subs_handedness=[]
    subs_native_language=[]
    subs_ethnicity=[]
    subs_scanner=[]
    subs_exp_type=[]
    subs_exp=[]
    # drop subject id 106
    sub_ids=[x for x in sub_ids if x!=106]
    for subject in sub_ids:
        # first find the rows in sub_info_df that contain the subject id
        sub_info_rows = sub_info_df[sub_info_df['Subjects::UniqueID'] == subject]
        # find the session id from sub_dti_info_df that corresponds to the subject id
        sub_dti_info_rows = sub_dti_info_df[sub_dti_info_df['UID'] == subject]
        dti_session=sub_dti_info_rows.SessionID.values[0].replace('_PL2017','')
        # remove the subject id in the begining of dti_session, makeing sure that the format is XXX, so 7 becomes 007
        dti_session=dti_session[4:]
        overlap=[dti_session in x for x in sub_info_rows['ScanSessions::SessionID'].values].index(True)
        # get the row based on overlap
        sub_info_rows=sub_info_rows.iloc[overlap]
        subject_age=sub_info_rows['ScanSessions::AgeAtSession']
        # make sure all values in subject_age are the same
        subs_age.append(subject_age)
        subs_gender.append(sub_info_rows['Subjects::Gender'])
        sessions_dates.append(sub_info_rows['ScanSessions::Date'])
        subs_handedness.append(sub_info_rows['Subjects::Handedness'])
        subs_native_language.append(sub_info_rows['Subjects::NativeEnglish'])
        subs_ethnicity.append(sub_info_rows['Subjects::Ethnicity'])
        subs_scanner.append(sub_info_rows['ScanSessions::Scanner'])
        subs_exp_type.append(sub_info_rows['ExperimentType'])
        subs_exp.append(sub_info_rows['Experiment'])
    # find min of sessions_dates
    min_date=min(sessions_dates)
    # find max of sessions_dates
    max_date=max(sessions_dates)

    max(subs_age)
    np.sum([x=='F' for x in subs_gender])

    np.sum([x=='right' for x in subs_handedness])
    np.sum([x == '1' for x in subs_native_language])

