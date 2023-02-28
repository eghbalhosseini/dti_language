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
from matplotlib import cm
from matplotlib.colors import ListedColormap, LinearSegmentedColormap


if __name__=='__main__':
    subj_id= 'sub721'
    network_id="lang"
    threshold=20
    thr_type='top'

    file_name = 'fsig'
    my_env = os.environ.copy()
    my_env['SUBJECTS_DIR'] = subj_FS_path
    hemis_ = ['LH', 'RH'] # shorthand version
    hemis = ['left', 'right'] # longform version
    thr_types=['top','bottom']
    idx = 0
    hemi = hemis[idx]

    functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
    sub_dti_dir = os.path.join(HOME_DIR, subj_id, 'fmri', functional_path.replace('lang', f'lang_thr_{threshold}'))
    functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
    sub_func_dir = os.path.join(subj_lang_path, subj_id, 'bold', functional_path, file_name + '.nii.gz')
    network_img = nib.load(sub_func_dir)
    network_fsavg = np.asarray(network_img.dataobj).flatten()
    # glasser
    LH_glasser_file= Path(subj_FS_path,'lh.HCPMMP1.annot')
    RH_glasser_file= Path(subj_FS_path,'rh.HCPMMP1.annot')
    LH_glasser=nib.freesurfer.io.read_annot(LH_glasser_file)
    RH_glaser=nib.freesurfer.io.read_annot(RH_glasser_file)


    target_1_name=list(d_parcel_name_map[network_id].values())[0]
    target_2_name = list(d_parcel_name_map[network_id].values())[1]
    target_3_name = list(d_parcel_name_map[network_id].values())[2]
    source_1_name=list(d_parcel_name_map[network_id].values())[3]
    source_2_name=list(d_parcel_name_map[network_id].values())[4]
    source_3_name=list(d_parcel_name_map[network_id].values())[5]

    target_roi_1 = nib.freesurfer.read_label(
        f'{sub_dti_dir}/{target_1_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label')
    target_roi_2 = nib.freesurfer.read_label(
        f'{sub_dti_dir}/{target_2_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label')
    target_roi_3 = nib.freesurfer.read_label(
        f'{sub_dti_dir}/{target_3_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label')

    source_1_roi = nib.freesurfer.read_label(
        f'{sub_dti_dir}/{source_1_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label')
    source_2_roi = nib.freesurfer.read_label(
        f'{sub_dti_dir}/{source_2_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label')
    source_3_roi = nib.freesurfer.read_label(
        f'{sub_dti_dir}/{source_3_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label')

    network_fsaverage_postTemp_ROI = np.zeros(network_fsavg.shape)
    network_fsaverage_AntTemp_ROI = np.zeros(network_fsavg.shape)
    network_fsaverage_Lang_ROI = np.zeros(network_fsavg.shape)

    # in LH_glasser[2] find the location of elemnt that is equalt to 'L_MST_ROI'

    LH_neighbor_1 = LH_glasser[2].index(b'L_TPOJ1_ROI')
    LH_neighbor_2 = LH_glasser[2].index(b'L_STV_ROI')
    n_1_roi = np.where(LH_glasser[0] == LH_neighbor_1)[0]
    n_2_roi = np.where(LH_glasser[0] == LH_neighbor_2)[0]


    network_fsaverage_postTemp_ROI[n_1_roi] = 1
    network_fsaverage_postTemp_ROI[n_2_roi] = 2
    network_fsaverage_postTemp_ROI[target_roi_1] = 3
    network_fsaverage_postTemp_ROI[target_roi_2] = 4
    network_fsaverage_postTemp_ROI[target_roi_3] = 5
    network_fsaverage_postTemp_ROI[source_2_roi] = 6

    network_fsaverage_Lang_ROI[target_roi_1] =1
    network_fsaverage_Lang_ROI[target_roi_2] =2
    network_fsaverage_Lang_ROI[target_roi_3] =3
    network_fsaverage_Lang_ROI[source_1_roi] =4
    network_fsaverage_Lang_ROI[source_2_roi] =5
    #network_fsaverage_Lang_ROI[source_3_roi] =6

    LH_neighbor_1 = LH_glasser[2].index(b'L_STSva_ROI')
    LH_neighbor_2 = LH_glasser[2].index(b'L_STSda_ROI')
    n_1_roi = np.where(LH_glasser[0] == LH_neighbor_1)[0]
    n_2_roi = np.where(LH_glasser[0] == LH_neighbor_2)[0]


    network_fsaverage_AntTemp_ROI[n_1_roi] = 1
    network_fsaverage_AntTemp_ROI[n_2_roi] = 2
    network_fsaverage_AntTemp_ROI[target_roi_1] = 3
    network_fsaverage_AntTemp_ROI[target_roi_2] = 4
    network_fsaverage_AntTemp_ROI[target_roi_3] = 5
    network_fsaverage_AntTemp_ROI[source_1_roi] = 6

    viridis = cm.get_cmap('viridis', 256)
    newcolors = viridis(np.linspace(0, 1, 256))
    source_col = np.array([255 / 256, 0 / 256, 0 / 256, 1])
    target_1_col= np.array([125 / 256, 125 / 256, 125 / 256, 1])
    target_2_col = np.array([0 / 256, 0 / 256, 0 / 256, 1])
    target_3_col = np.array([175 / 256, 175 / 256, 175 / 256, 1])
    n_1_col = np.array([77 / 256, 166 / 256, 255 / 256, 1])
    n_2_col = np.array([0 / 256, 89 / 256, 179 / 256, 1])

    newcolors= np.vstack((n_1_col,n_2_col,target_1_col,target_2_col,target_3_col,
                          source_col))

    newcmp = ListedColormap(newcolors)
    # create a figure with size 8*11 and 300 dpi
    fig = plt.figure(figsize=(8, 11), dpi=150)
    pa_ratio=8/11
    #fig, ax = plt.subplots(nrows=1, ncols=1, subplot_kw={'projection': '3d'}, figsize=[8, 11])
    # add axes with position [left, bottom, width, height]
    ax = fig.add_axes([0.1, 0.1, 0.25, 0.25*pa_ratio], projection='3d')
    plotting.plot_surf_roi(surf_mesh=fsaverage['infl_' + hemi], roi_map=network_fsaverage_postTemp_ROI, hemi=hemi,
                           view='lateral', cmap=newcmp, bg_on_data=True,bg_map=fsaverage['sulc_left'],
                           darkness=.3, axes=ax,alpha=1)
    plotting.plot_surf_contours(fsaverage['infl_' + hemi], network_fsaverage_postTemp_ROI, levels=[1,2,3,4,5,6 ], axes=ax,
                                legend=False, colors=['k','k','k','k','k','k' ])

    ax = fig.add_axes([0.1, 0.4, 0.25, 0.25*pa_ratio], projection='3d')
    plotting.plot_surf_roi(surf_mesh=fsaverage['infl_' + hemi], roi_map=network_fsaverage_AntTemp_ROI, hemi=hemi,
                            view='lateral', cmap=newcmp, bg_on_data=True,bg_map=fsaverage['sulc_left'],
                            darkness=.3, axes=ax,alpha=1)
    plotting.plot_surf_contours(fsaverage['infl_' + hemi], network_fsaverage_AntTemp_ROI, levels=[1,2,3,4,5,6 ], axes=ax,
                                legend=False, colors=['k','k','k','k','k','k' ])




    target_1_col= np.array([36 / 256, 68 / 256, 120 / 256, 1])
    target_2_col = np.array([77 / 256, 145 / 256, 240 / 256, 1])
    target_3_col = np.array([60 / 256, 114 / 256, 189 / 256, 1])
    source_1_roi = np.array([198 / 256, 52 / 256, 255 / 256, 1])
    source_2_roi = np.array([250 / 256, 50 / 256, 15 / 256, 1])

    newcolors= np.vstack((target_1_col,target_2_col,target_3_col,
                          source_1_roi,source_2_roi))
    newcmp = ListedColormap(newcolors)

    ax = fig.add_axes([0.1, 0.7, 0.25, 0.25*pa_ratio], projection='3d')
    plotting.plot_surf_roi(surf_mesh=fsaverage['infl_' + hemi], roi_map=network_fsaverage_Lang_ROI, hemi=hemi,
                            view='lateral', cmap=newcmp, bg_on_data=True,bg_map=fsaverage['sulc_left'],
                            darkness=.3, axes=ax,alpha=1)
    #plotting.plot_surf_contours(fsaverage['infl_' + hemi], network_fsaverage_Lang_ROI, levels=[1,2,3,4,5,6 ], axes=ax,
    #                            legend=False, colors=['k','k','k','k','k','k' ])



    # save plot as pdf file
    plt.savefig(f'{sub_dti_dir}/{network_id}_fsaverage_for_figure_1_v2.pdf', dpi=150)
    plt.savefig(f'{sub_dti_dir}/{network_id}_fsaverage_for_figure_1_v2.png', dpi=300)
    #ax.set_title(f'fsaverage, {ROI_name}_roi, #vox: {np.sum(network_fsaverage_ROI)}')
    fig.show()

    source_name = list(d_parcel_name_map[network_id].values())[4]

    #