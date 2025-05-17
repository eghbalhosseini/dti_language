
import numpy as np
import os
import subprocess
from pathlib import Path
from shutil import copyfile

from glob import glob
import pandas as pd


if __name__ == '__main__':
    root_dir="/Users/eghbalhosseini/MyData/dti_language/"

    # find directory that start with sub and end with number in the form of subXXX
    # read the excel sheet that contains subject information
    sub_info_file='/Users/eghbalhosseini/MyData/dti_language/fmri_subjects_info.xlsx'
    sub_info_df = pd.read_excel(sub_info_file)
    # load subject with dti
    sub_dti_file=f"{root_dir}/DTI_Sessions_05062025_ev_eh.xlsx"
    sub_dti_info_df = pd.read_excel(sub_dti_file)
    sub_sequence_df = pd.read_csv(f"{root_dir}/all_subjects.csv")
    # # for each subject first find the correpsondign rows in sub_info_df, then use the corresponding row in sub_dti_info_df to find the exact row
    # find out for which sub_ids there is no corresponding row in sub_dti_info_df
    # filter su
    sub_ids=sub_dti_info_df.UID.values
    # find the rows in sub_info_df that contain the subject id


    subs_diffusion_session=[]
    for subject in sub_ids:
        True
        # first find the rows in sub_info_df that contain the subject id
        sub_session = sub_dti_info_df
        sub_info_rows = sub_sequence_df[sub_sequence_df['uid'] == subject]
        # find the session id from sub_dti_info_df that corresponds to the subject id
        sub_dti_info_rows = sub_dti_info_df[sub_dti_info_df['UID'] == subject]
        dti_session=sub_dti_info_rows.SessionID.values[0].replace('_PL2017','')
        # remove the subject id in the begining of dti_session, makeing sure that the format is XXX, so 7 becomes 007
        dti_session=dti_session[4:]
        # filter out subject
        session_with_dti=[ dti_session in x for x in sub_info_rows.sid.values]
        sub_info_rows=sub_info_rows[session_with_dti]
        diff_name="DIFFUSION"
        diffisuion_row=[diff_name in x for x in sub_info_rows.series_description.values]
        sub_info_rows=sub_info_rows[diffisuion_row]
        # make sure the length of sub_info_row is larger than 1
        assert len(sub_info_rows)>0
        subs_diffusion_session.append(sub_info_rows)
    # find min of sessions_dates
    # combine the list of arrays into one pandas
    subs_diffusion_session=pd.concat(subs_diffusion_session)
    # save it in the root dir
    subs_diffusion_session.to_csv(f"{root_dir}/subs_diffusion_session_sequence_info.csv",index=False)
    # group by subject and get the name for series_description for each subject
    sess_description_list=[]
    session_desc_template=list(subs_diffusion_session[sub_sequence_df['uid'] == 7]['series_description'].values)
    for gr_,grp in subs_diffusion_session.groupby('uid'):
        session_desc=list(grp['series_description'].values)

        # check if the session_desc is equal to the template
        if len(session_desc)!=len(session_desc_template):
            print(f"subject {gr_} has different number of sessions")
        # check if the session_desc is equal to the template
        if not all([session_desc[i]==session_desc_template[i] for i in range(len(session_desc))]):
            print(f"subject {gr_} has different session description")


    # make sure all elements have the same order and names
    # check the first element
    first_element=sess_description_list[0]
    # check if all elements have the same length
    assert all([len(x)==len(first_element) for x in sess_description_list])
    # check if all elements have the same order, each element has 7 strings in them
    for x in sess_description_list:
        assert len(x)==len(first_element)
        # check if all elements have the same order
        if not all([x[i]==first_element[i] for i in range(len(x))]):
            print(f"Not all elements have the same order, {x} and {first_element}")
            break






