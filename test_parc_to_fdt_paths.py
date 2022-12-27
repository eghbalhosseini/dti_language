import nibabel as nib
import nilearn as nil
from nilearn import datasets
import nilearn.plotting as plotting
import numpy as np
import os
import subprocess
import argparse
import copy
from utils.parcel_utils import d_parcel_fsaverage, d_parcel_name_map
from utils.fmri_utils import subj_lang_path, subj_FS_path,HOME_DIR,PLOTDIR
fsaverage = datasets.fetch_surf_fsaverage(mesh='fsaverage')
from pathlib import Path
from shutil import copyfile
import matplotlib.pyplot as plt
from nilearn.image import load_img, math_img
from matplotlib.colors import ListedColormap
from utils.lookuptable import FSLUT
from glob import glob


if __name__ == '__main__':
    train_subjects=['sub117','sub308','sub087','sub157','sub191','sub130','sub193','sub264'
        ,'sub113','sub125','sub147','sub219','sub170','sub198','sub209','sub449','sub053','sub178','sub298',
              'sub132','sub184','sub108','sub112','sub018','sub007','sub206','sub539','sub218','sub223','sub201',
              'sub225','sub118','sub158','sub295','sub169','sub164','sub133','sub119','sub211','sub243','sub146',
              'sub050','sub212','sub244','sub109','sub174','sub214','sub116','sub101','sub107','sub233','sub103',
              'sub721','sub297','sub253','sub160','sub192','sub216','sub236','sub237','sub161','sub145','sub232',
              'sub306','sub229','sub156','sub278','sub279','sub226','sub176']
    subj_id='sub117'
    IFG_MFG_ratio=[]
    IFG_MFG_count=[]
    for subj_id in (train_subjects):
        network_id = 'lang'
        tracks=['probtrackX_results_IFG_top_20-PostTemp_top_20_TO_IFG_top_20-PostTemp_top_20_EX_IFGorb_top_20-MFG_top_20',
            'probtrackX_results_MFG_top_20-PostTemp_top_20_TO_MFG_top_20-PostTemp_top_20_EX_IFG_top_20-IFGorb_top_20']
        postTemp=1405
        IFG_fdt_path=load_img(os.path.join(f'{HOME_DIR}/{tracks[0]}/{subj_id}_LH_fdt_paths.nii.gz'))
        MFG_fdt_path = load_img(os.path.join(f'{HOME_DIR}/{tracks[1]}/{subj_id}_LH_fdt_paths.nii.gz'))
        parcel_image=load_img(os.path.join(f'{HOME_DIR}/parcels_in_dti/{subj_id}_lang_parcels_indti.nii.gz'))
        IFG_network = np.asarray(IFG_fdt_path.dataobj).flatten()>0
        MFG_network = np.asarray(MFG_fdt_path.dataobj).flatten()>0
        parcel=np.asarray(parcel_image.dataobj).flatten().astype(int)
        postTemp_mask=np.asarray(parcel==postTemp)

        IFG_postemp=np.logical_and(IFG_network,postTemp_mask)
        MFG_posttemp=np.logical_and(MFG_network,postTemp_mask)
        if any(IFG_postemp) and any(MFG_posttemp):
            overlap=np.logical_and(IFG_postemp,MFG_posttemp)
            non_overlap=np.logical_xor(IFG_postemp,MFG_posttemp)
            IFG_MFG_count.append([np.sum(overlap),np.sum(IFG_postemp),np.sum(MFG_posttemp),np.sum(non_overlap)])
            IFG_MFG_ratio.append([np.sum(overlap)/np.sum(IFG_postemp), np.sum(overlap)/np.sum(MFG_posttemp), np.sum(overlap)/np.sum(non_overlap)])
        # postTemp_mask=np.asarray(parcel==postTemp).astype(int)
        # network_postTemp_IFG=np.multiply(IFG_network,postTemp_mask)
        # posttemp_mask_img = math_img(
        #     f'np.logical_and(img>{postTemp-1},img<={postTemp})',
        #     img=parcel_image)
        #
        # network_postTemp_IFG_img = math_img(f'np.multiply(img1,img2)',img1=posttemp_mask_img,img2=IFG_fdt_path)
        # network_postTemp_MFG_img = math_img(f'np.multiply(img1,img2)', img1=posttemp_mask_img, img2=MFG_fdt_path)
        #
        # fig, axs = plt.subplots(nrows=2, ncols=1,  figsize=[11, 8])
        # subj_vol_path=f'/mindhive/evlab/Shared/diffusionzeynep/{subj_id}/dti.bedpostX/nodif_brain.nii.gz'
        # plotting.plot_stat_map(IFG_fdt_path, bg_img=subj_vol_path, axes=axs[0], display_mode='ortho', draw_cross=False, alpha=1,
        #               annotate=False,threshold=.1,
        #               black_bg=True,cmap='inferno')
        #
        # plotting.plot_roi(posttemp_mask_img, bg_img=subj_vol_path, axes=axs[1], display_mode='ortho', draw_cross=False,
        #               alpha=1,
        #               annotate=False,
        #               black_bg=True,cmap='viridis')
        #
        #
        # fig.show()
    plt.close('all')

    IFG_MFG_Ratio_np=np.stack(IFG_MFG_ratio)
    fig = plt.figure(figsize=(11, 8), dpi=250, frameon=False, edgecolor='w',facecolor='w')
    ax = plt.axes((.1, .1, .35, .35*11/8),facecolor='w')
    ax.scatter(IFG_MFG_Ratio_np[:,0],IFG_MFG_Ratio_np[:,1],facecolor='r',edgecolor='k')
    ax.set_ylim([-.1, 1.1])
    ax.set_xlim([-.1, 1.1])
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.set_ylabel('postTemp to MFG')
    ax.set_xlabel('PostTemp to IFG')
    ax.set_title('Ratio of voxels that jointly project to \n IFG and MFG from PostTemp \n in individual subjects')
    ax1 = plt.axes((.55, .1, .1, .35 * 11 / 8), facecolor='w')
    wid = .4
    y=IFG_MFG_Ratio_np[:,0]
    ax1.bar(0, np.mean(y), width=wid, edgecolor='k', color='r',)
    ax1.errorbar(0, np.mean(y),
                yerr=np.mean(y) / np.sqrt(y.shape[0]), linestyle='',color='k',elinewidth=2)
    y = IFG_MFG_Ratio_np[:, 1]
    ax1.bar(1, np.mean(y), width=wid, edgecolor='k', color='b', )

    ax1.errorbar(1, np.mean(y),
                yerr=np.mean(y) / np.sqrt(y.shape[0]), linestyle='', color='k',elinewidth=2)


    ax1.axhline(y=0,color='k')
    ax1.spines['top'].set_visible(False)
    ax1.spines['right'].set_visible(False)
    ax1.set_ylim([-.1, 1])

    ax1.set_xticks([0,1])
    ax1.get_xticks()
    ax1.set_title('Ratio across \n subject population')
    ax1.set_ylabel('mean ratio')
    ax1.set_xticklabels(['IFG','MFG'])

    ax1 = plt.axes((.8, .1, .05, .35 * 11 / 8), facecolor='w')

    y = IFG_MFG_Ratio_np[:, 2]
    ax1.bar(0, np.mean(y), width=wid, edgecolor='k', color=(.5,.5,.5), )

    ax1.errorbar(0, np.mean(y),
                 yerr=np.mean(y) / np.sqrt(y.shape[0]), linestyle='', color='k', elinewidth=2)
    ax1.axhline(y=0,color='k')
    ax1.spines['top'].set_visible(False)
    ax1.spines['right'].set_visible(False)
    ax1.set_ylim([-.1, 1])
    ax1.set_xlim([-.5, .5])
    ax1.set_xticks([0])
    ax1.get_xticks()
    ax1.set_title('ratio of shared vs \nindependent PosTemp Voxels')
    ax1.set_xticklabels([])



    fig.show()

    fig.savefig(os.path.join('/om/user/ehoseini/MyData/dti_language/',f'ratio_of_shared_voxels_IFG_MFG_PostTemp.png'), dpi=250, format='png', metadata=None,
        bbox_inches=None, pad_inches=0.1,facecolor='auto', edgecolor='auto',backend=None)

    fig.savefig(os.path.join('/om/user/ehoseini/MyData/dti_language/', f'ratio_of_shared_voxels_IFG_MFG_PostTemp.eps'), format='eps',metadata=None,
                bbox_inches=None, pad_inches=0.1,facecolor='auto', edgecolor='auto',backend=None)


    POSTTEMP_ANTTEMP_Ratio = []
    for subj_id in (train_subjects):
        network_id = 'lang'
        tracks = [
        'probtrackX_results_IFGorb_top_20-AntTemp_top_20_TO_IFGorb_top_20-AntTemp_top_20_EX_IFG_top_20-MFG_top_20',
        'probtrackX_results_IFGorb_top_20-PostTemp_top_20_TO_IFGorb_top_20-PostTemp_top_20_EX_IFG_top_20-MFG_top_20']
        IFGorb = 1401
        Anttemp_fdt_path = load_img(os.path.join(f'{HOME_DIR}/{tracks[0]}/{subj_id}_LH_fdt_paths.nii.gz'))
        Posttemp_fdt_path = load_img(os.path.join(f'{HOME_DIR}/{tracks[1]}/{subj_id}_LH_fdt_paths.nii.gz'))
        parcel_image = load_img(os.path.join(f'{HOME_DIR}/parcels_in_dti/{subj_id}_lang_parcels_indti.nii.gz'))
        Anttemp_network = np.asarray(Anttemp_fdt_path.dataobj).flatten()
        Posttemp_network = np.asarray(Posttemp_fdt_path.dataobj).flatten()
        parcel = np.asarray(parcel_image.dataobj).flatten().astype(int)
        IFGorb_mask = np.asarray(parcel == IFGorb).astype(int)
        IFGorb_postemp = np.multiply(Posttemp_network, IFGorb_mask)
        IFGorb_anttemp = np.multiply(Anttemp_network, IFGorb_mask)
        if any(IFGorb_postemp > 0) and any(IFGorb_anttemp > 0):
            overlap = np.multiply(IFGorb_postemp > 0, IFGorb_anttemp > 0)
            POSTTEMP_ANTTEMP_Ratio.append(
                [np.sum(overlap) / np.sum(IFGorb_postemp > 0), np.sum(overlap) / np.sum(IFGorb_anttemp > 0)])
        # postTemp_mask=np.asarray(parcel==postTemp).astype(int)
        # network_postTemp_IFG=np.multiply(IFG_network,postTemp_mask)
        # posttemp_mask_img = math_img(
        #     f'np.logical_and(img>{postTemp-1},img<={postTemp})',
        #     img=parcel_image)
        #
        # network_postTemp_IFG_img = math_img(f'np.multiply(img1,img2)',img1=posttemp_mask_img,img2=IFG_fdt_path)
        # network_postTemp_MFG_img = math_img(f'np.multiply(img1,img2)', img1=posttemp_mask_img, img2=MFG_fdt_path)
        #
        # fig, axs = plt.subplots(nrows=2, ncols=1,  figsize=[11, 8])
        # subj_vol_path=f'/mindhive/evlab/Shared/diffusionzeynep/{subj_id}/dti.bedpostX/nodif_brain.nii.gz'
        # plotting.plot_stat_map(IFG_fdt_path, bg_img=subj_vol_path, axes=axs[0], display_mode='ortho', draw_cross=False, alpha=1,
        #               annotate=False,threshold=.1,
        #               black_bg=True,cmap='inferno')
        #
        # plotting.plot_roi(posttemp_mask_img, bg_img=subj_vol_path, axes=axs[1], display_mode='ortho', draw_cross=False,
        #               alpha=1,
        #               annotate=False,
        #               black_bg=True,cmap='viridis')
        #
        #
        # fig.show()
    plt.close('all')
    IFG_MFG_Ratio_np = np.stack(IFG_MFG_Ratio)
    fig = plt.figure(figsize=(11, 8), dpi=250, frameon=False, edgecolor='w', facecolor='w')
    ax = plt.axes((.1, .1, .35, .35 * 11 / 8), facecolor='w')
    ax.scatter(IFG_MFG_Ratio_np[:, 0], IFG_MFG_Ratio_np[:, 1], facecolor='r', edgecolor='k')
    ax.set_ylim([-.1, 1])
    ax.set_xlim([-.1, 1])
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.set_ylabel('postTemp to MFG')
    ax.set_xlabel('PostTemp to IFG')
    ax.set_title('Ratio of voxels that jointly project to \n IFG and MFG from PostTemp \n in individual subjects')
    ax1 = plt.axes((.55, .1, .05, .35 * 11 / 8), facecolor='w')
    wid = .4
    y = IFG_MFG_Ratio_np[:, 0]
    ax1.bar(0, np.mean(y), width=wid, edgecolor='k', color='r', )
    ax1.errorbar(0, np.mean(y),
                 yerr=np.mean(y) / np.sqrt(y.shape[0]), linestyle='', color='k', elinewidth=2)
    y = IFG_MFG_Ratio_np[:, 1]
    ax1.bar(1, np.mean(y), width=wid, edgecolor='k', color='b', )

    ax1.errorbar(1, np.mean(y),
                 yerr=np.mean(y) / np.sqrt(y.shape[0]), linestyle='', color='k', elinewidth=2)
    ax1.axhline(y=0)
    ax1.spines['top'].set_visible(False)
    ax1.spines['right'].set_visible(False)
    ax1.set_ylim([-.1, 1])

    ax1.set_xticks([0, 1])
    ax1.get_xticks()
    ax1.set_title('Ratio across \n subject population')
    ax1.set_ylabel('mean ratio')
    ax1.set_xticklabels(['IFG', 'MFG'])
    fig.show()

    fig.savefig(os.path.join(PLOTDIR, f'ratio_of_shared_voxels_IFG_MFG_PostTemp.png'), dpi=250, format='png',
                metadata=None,
                bbox_inches=None, pad_inches=0.1, facecolor='auto', edgecolor='auto', backend=None)

    fig.savefig(os.path.join(PLOTDIR, f'ratio_of_shared_voxels_IFG_MFG_PostTemp.eps'), format='eps', metadata=None,
                bbox_inches=None, pad_inches=0.1, facecolor='auto', edgecolor='auto', backend=None)

