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

parser = argparse.ArgumentParser(description='find_subj_actvation_in_language_ROIs')
parser.add_argument('subj_id', type=str)
parser.add_argument('network_id', type=str)#, default='lang')
parser.add_argument('threshold', type=int)#, default=90)
parser.add_argument('thr_type',type=str,default='top') # top or bottom
args=parser.parse_args()


if __name__ == '__main__':
    subj_id = args.subj_id
    subj_id='sub114'
    network_id = args.network_id # 'lang'
    network_id='lang'
    threshold=args.threshold
    threshold= 20
    thr_type=args.thr_type
    thr_type='top'
    ####################
    file_name = 'fsig'
    my_env = os.environ.copy()
    my_env['SUBJECTS_DIR'] = subj_FS_path
    hemis_ = ['LH', 'RH'] # shorthand version
    hemis = ['left', 'right'] # longform version
    thr_types=['top','bottom']
    #####################################################################
    # Part 1 : select voxels based on overlap with langauge parcels:
    plt.close('all')
    for thr_type in thr_types:
        # 1.a: find language signinifant voxels in fsaverge space
        for idx, hemi in enumerate(hemis):
            functional_path=f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
            sub_func_dir = os.path.join(subj_lang_path, subj_id, 'bold', functional_path, file_name+'.nii.gz')
            assert(Path(sub_func_dir).exists())
            sub_dti_dir= os.path.join(HOME_DIR,subj_id,'fmri',functional_path.replace('lang',f'lang_thr_{threshold}'))
            Path(sub_dti_dir).mkdir(parents=True, exist_ok=True)
            network_img=nib.load(sub_func_dir)
            network = np.asarray(network_img.dataobj).flatten()
            sub_parcel_roi_vxl = np.zeros(network.shape).astype(int)
            sub_parcel_roi = np.zeros(network.shape).astype(int)
            hist_bins=np.linspace(min(network),max(network),100)
            # create an annotation file from the activation masks
            for ROI_name in d_parcel_name_map[network_id].values():
                if ROI_name.__contains__(hemis_[idx]):
                    roi_surf = d_parcel_fsaverage[network_id][ROI_name]
                    samples = network[(roi_surf == 1) & ~(np.isnan(network))]
                    if thr_type=='top':
                        samples_th = np.percentile(samples, int(100-threshold))
                        roi_voxels = ((roi_surf == 1)) & (network >= samples_th)
                    elif thr_type =='bottom':
                        samples_th = np.percentile(samples, int(threshold))
                        roi_voxels = ((roi_surf == 1)) & (network <= samples_th)
                    else:
                        raise Exception('unknown thershold type')
                    print(f'ROI name: {ROI_name}, number of voxels {np.sum(roi_voxels)}')
                    fig = plt.figure( figsize=[11, 8])
                    ax0 = fig.add_axes((.05,.1,.6,.7), projection='3d')
                    plotting.plot_surf_roi(surf_mesh=fsaverage['infl_' + hemi], roi_map=roi_voxels,hemi=hemi, view='lateral',
                                           cmap='hot',bg_map=network, bg_on_data=True, alpha=.3,darkness=.2,axes=ax0)
                    plotting.plot_surf_contours(fsaverage['infl_' + hemi], roi_surf, levels=[1, ], axes=ax0,
                                            legend=True, colors=['k', ], labels=[f'{ROI_name},  #vox: {np.sum(roi_voxels)}'])
                    ax1 = fig.add_axes((.65,.3,.3,.3))
                    ax1.hist(samples, bins=hist_bins, align='mid',edgecolor='k',linewidth=.5)
                    ax1.set_xlabel("voxel activation")
                    ax1.set_ylabel("Frequency")
                    ax1.axvline(x=samples_th,color='r',linewidth=1)
                    fig.savefig(f'{sub_dti_dir}/{subj_id}_{ROI_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.png',facecolor=(1,1,1),edgecolor='none')
                    # save individual annotation file and create label form them
                    nib.freesurfer.write_annot(f'{sub_dti_dir}/{ROI_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.annot',
                                           roi_voxels.astype(int), np.asarray([[0, 0, 0, 0, 0], [255, 0, 0, 255, 1]]),
                                           [b'???', f'{ROI_name}_roi'], fill_ctab=True)
                    sub_parcel_roi_vxl += roi_voxels.astype(int)
                    sub_parcel_roi += roi_surf
            # plot full ROI map
            figure = plotting.plot_surf_roi(surf_mesh=fsaverage['infl_' + hemi], roi_map=sub_parcel_roi_vxl,
                                            hemi=hemi, view='lateral', cmap='hot',bg_map=network, bg_on_data=True, alpha=.3,
                                            title=f'num of voxels{sub_parcel_roi_vxl.sum()}',darkness=.7)
            plotting.plot_surf_contours(fsaverage['infl_' + hemi], sub_parcel_roi, levels=[1, ], figure=figure,
                                        legend=True, colors=['k', ], labels=[f'{hemis_[idx]} ROIs,  #vox: {sub_parcel_roi_vxl.sum()}'])
            figure.savefig(f'{sub_dti_dir}/{subj_id}_{hemis_[idx]}_all_ROIs_{file_name}_{thr_type}_{threshold}_fsavg.png',
                           facecolor=(1, 1, 1), edgecolor='none')
        #1.b: make annotation to labels for easier transformation from average to native
        for idx, hemi in enumerate(hemis):
            functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
            sub_dti_dir = os.path.join(HOME_DIR, subj_id, 'fmri', functional_path.replace('lang',f'lang_thr_{threshold}'))
            for ROI_name in d_parcel_name_map[network_id].values():
                if ROI_name.__contains__(hemis_[idx]):
                # move from annot to label
                    unix_pattern = ['mri_annotation2label','--hemi', hemis_[idx].lower(),
                                    '--subject', 'fsaverage','--label', str(1),'--outdir', f'{sub_dti_dir}',
                                    '--annotation', f'{sub_dti_dir}/{ROI_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.annot'
                                    ]
                    output = subprocess.Popen(unix_pattern, env=my_env)
                    output.communicate()
                    # immediately change the label name:
                    unix_pattern=['mv',f'{sub_dti_dir}/{hemis_[idx].lower()}.{ROI_name}_roi.label',
                                  f'{sub_dti_dir}/{ROI_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label']
                    output = subprocess.Popen(unix_pattern, env=my_env)
                    output.communicate()
                    # make sure the annotation to label is done correctly
                    roi_annot=nib.freesurfer.read_annot(f'{sub_dti_dir}/{ROI_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.annot')
                    annot_=roi_annot[0]
                    annot_[roi_annot[0]<0]=0
                    label_roi = nib.freesurfer.read_label(f'{sub_dti_dir}/{ROI_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label')
                    label_fsaverage_ROI = np.zeros(network.shape)
                    label_fsaverage_ROI[label_roi] = 1
                    assert np.array_equal(annot_,label_fsaverage_ROI)
    #####################################################################
    ## Part 2 : move labels from fsaverage to fsnative
    plt.close('all')
    for thr_type in thr_types:
        for idx, hemi in enumerate(hemis):
            functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
            functional_native_path = functional_path.replace('fsavg', 'self')
            sub_dti_dir = os.path.join(HOME_DIR, subj_id, 'fmri', functional_path.replace('lang',f'lang_thr_{threshold}'))
            sub_dti_native_dir = sub_dti_dir.replace('fsavg', 'fsnative')
            Path(sub_dti_native_dir).mkdir(parents=True, exist_ok=True)
            # sub_func_native_dir = os.path.join(subj_lang_path, subj_id, 'bold', functional_native_path, file_name + '.nii.gz')
            # load subject fsaverage and native, for plotting
            sub_func_dir = os.path.join(subj_lang_path, subj_id, 'bold', functional_path, file_name + '.nii.gz')
            network_img=nib.load(sub_func_dir)
            network_fsavg = np.asarray(network_img.dataobj).flatten()
            sub_func_native_dir = os.path.join(subj_lang_path,subj_id, 'bold', functional_native_path, file_name+'.nii.gz')
            if os.path.exists(sub_func_native_dir):
                network_native_img = nib.load(sub_func_native_dir)
                network_native = np.asarray(network_native_img.dataobj).flatten()
            else:
                network_native=None
            subj_surf_file = Path(subj_FS_path, subj_id, 'surf', hemis_[idx].lower() + '.inflated')
            subj_sulc_file = Path(subj_FS_path, subj_id, 'surf', hemis_[idx].lower() + '.sulc')
            for ROI_name in d_parcel_name_map[network_id].values():
                if ROI_name.__contains__(hemis_[idx]):
                    unix_pattern = ['mri_label2label',
                                    '--srcsubject', 'fsaverage','--hemi', hemis_[idx].lower(),'--trgsubject', subj_id,'--regmethod', 'surface',
                                    '--srclabel', f'{sub_dti_dir}/{ROI_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label',
                                    '--trglabel', f'{sub_dti_native_dir}/{ROI_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label'
                                    ]
                    output = subprocess.Popen(unix_pattern, env=my_env)
                    output.communicate()
                    #
                    fig, ax = plt.subplots(nrows=2, ncols=1,subplot_kw={'projection': '3d'},figsize=[8,11])
                    # plot fsaverage:
                    label_roi = nib.freesurfer.read_label(f'{sub_dti_dir}/{ROI_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label')
                    network_fsaverage_ROI = np.zeros(network_fsavg.shape)
                    network_fsaverage_ROI[label_roi] = 1
                    plotting.plot_surf_roi(surf_mesh=fsaverage['infl_' + hemi], roi_map=network_fsaverage_ROI,hemi=hemi,
                                       view='lateral', cmap='hot',bg_map=network_fsavg, bg_on_data=False,darkness=1,axes=ax[0],alpha=1)
                    ax[0].set_title(f'fsaverage, {ROI_name}_roi, #vox: {np.sum(network_fsaverage_ROI)}')
                    # plot fs native
                    label_file=f'{sub_dti_native_dir}/{ROI_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label'
                    label_roi = nib.freesurfer.read_label(f'{sub_dti_native_dir}/{ROI_name}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label')
                    n_vertices=len(nib.freesurfer.read_geometry(subj_surf_file)[0])
                    roi_map = np.zeros(n_vertices)
                    roi_map[label_roi] = 1
                    plotting.plot_surf_roi(str(subj_surf_file), roi_map=roi_map, hemi=hemi, view='lateral',
                                           cmap='hot',bg_map=str(subj_sulc_file), bg_on_data=False, darkness=1, axes=ax[1])
                    ax[1].set_title(f'fsnative, {ROI_name}_roi, #vox: {len(label_roi)}')
                    fig.savefig(f'{sub_dti_native_dir}/{ROI_name}_roi_{file_name}_{thr_type}_{threshold}.png',edgecolor='none')
    #####################################################################
    # Part 3 : transforming native label to volume for subject
    # 3.A transform labels to annotation first
    R_col = np.linspace(0, 255, len(d_parcel_name_map[network_id].values()), dtype=int)
    G_col = np.flip(R_col)
    # breakdown the areas based on hemisphere
    #LUT_prime = _FSLUT_HEADER + '\n' + FSLUT
    LUT_prime = FSLUT
    for idx, hemi in enumerate(hemis):
        print(f'in step 3. processing hemisphere {hemi}.')
        functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'.replace('lang',f'lang_thr_{threshold}')
        functional_native_path = functional_path.replace('fsavg', 'self')
        sub_dti_dir = os.path.join(HOME_DIR, subj_id, 'fmri', functional_path)
        sub_dti_native_dir = sub_dti_dir.replace('fsavg', 'fsnative')
        # https://github.com/freesurfer/freesurfer/blob/e34ae4559d26a971ad42f5739d28e84d38659759/mri_aparc2aseg/mri_aparc2aseg.cpp#L836
        # ACTUAL_OFFSET = {
        #       OFFSET + 1000,  if LH
        #       OFFSET + 2000,  if RH
        # }
        # these values are HARD-CODED in the freesurfer
        if thr_type=='top':
            offset = 400  # *1000+1000*idx # results in 2000 for lh; 4000 for rh
        elif thr_type=='bottom':
            offset = 500  # *1000+1000*idx # results in 2000 for lh; 4000 for rh
        else:
            raise Exception('unknown threshold type')

        ROI_names = list(d_parcel_name_map[network_id].values())
        hemi_rois_idx = np.where([x.__contains__(hemis_[idx]) for x in ROI_names])[0]

        # create a nicely formatted ctab file
        fmt = '{:<19} ' * 2 + '{: >5} ' * 4
        # txt_lines = ['#$Id: FreeSurferColorLUT.txt,v 1.38.2.1 2007/08/20 01:52:07 nicks Exp $',
        txt_lines = ['#$ Id: FreeSurferColorLUT_dti_evlab.txt, Fall 2021 $',
                     fmt.format('#No.', 'Label Name:', 'R', 'G', 'B', 'A'),
                     #fmt.format(offset, 'Unknown', 0, 0, 0, 0)]
                     fmt.format(0, 'Unknown', 0, 0, 0, 0)]
        #LUT_prime += '\n' + fmt.format(offset + 1000 + (1000 * idx), 'Unknown', 0, 0, 0, 0)
        for idy, y in enumerate(hemi_rois_idx):
            txt_lines.append(fmt.format(idy + offset + 1, f'{ROI_names[y]}_{thr_type}_{threshold}', R_col[y], G_col[y], 0, 1))
            #txt_lines.append(
            #    fmt.format(idy + offset + 1 + 1000 + (1000 * idx), f'{ROI_names[y]}_{thr_type}_{threshold}', R_col[y], G_col[y], 0, 1))
            # does what freesurfer does internally to the indices it reads from the ctab files.
            # for LH, we want to transform x -> x + 1000 + offset if LH, else x + 2000 + offset
            LUT_prime += '\n' + fmt.format(idy + offset + 1 + 1000 + (1000 * idx), f'{ROI_names[y]}_{thr_type}_{threshold}', R_col[y], G_col[y], 0,1)
        if os.path.exists(f'{sub_dti_native_dir}/{hemis_[idx].lower()}_{network_id}_roi_{thr_type}_{threshold}_ctab.txt'):
            os.remove(f'{sub_dti_native_dir}/{hemis_[idx].lower()}_{network_id}_roi_{thr_type}_{threshold}_ctab.txt')
        with open(f'{sub_dti_native_dir}/{hemis_[idx].lower()}_{network_id}_roi_{thr_type}_{threshold}_ctab.txt', "w") as textfile:
           for element in txt_lines:
               textfile.write(element + "\n")

        # create the unix pattern to run mri_label2annot command:
        unix_pattern = ['mris_label2annot',
                        '--s', subj_id,
                        '--h', hemis_[idx].lower(),
                        '--ctab', f'{sub_dti_native_dir}/{hemis_[idx].lower()}_{network_id}_roi_{thr_type}_{threshold}_ctab.txt',
                        '--annot-path', f'{sub_dti_native_dir}/{hemis_[idx].lower()}.{network_id}_roi_{thr_type}_{threshold}',
                        # NOTE: we do not observe any difference in the output generated using the
                        # --surf pial or --surf orig flags. we may use either one.
                        '--surf', 'orig',  # '--surf', 'orig', # Note this is an option for verision 6.0.0 of freesurfer
                        '--offset', f'{offset}'  # NOTE: expects offset of 0 for lh and rh
                        #'--offset', f'{offset + 1000 + (1000 * idx)}'  # NOTE: expects offset of 0 for lh and rh
                        ]
        for idy, y in enumerate(hemi_rois_idx):
            unix_pattern.append('--l'),
            unix_pattern.append(f'{sub_dti_native_dir}/{ROI_names[y]}_roi_{file_name}_{thr_type}_{threshold}_fsavg.label')
            #unix_pattern.append(f'{sub_dti_native_dir}/{hemis_[idx].lower()}.{ROI_names[y]}_roi.label')

        output = subprocess.Popen(unix_pattern, env=my_env)
        output.communicate()
        #roi_annot = nib.freesurfer.read_annot(
        #    f'{sub_dti_native_dir}/{hemis_[idx].lower()}.{network_id}_roi_{thr_type}_{threshold}.annot')
        #np.sum(roi_annot[0]==2403)
        #fig, ax = plt.subplots(nrows=1, ncols=1, figsize=[8, 11])
        #plotting.plot_surf_roi(str(subj_surf_file), roi_map=roi_annot[0], hemi=hemi, view='lateral',
        #                   threshold=1)
        #fig.show()
    #sub_dti_dir = os.path.join(subj_lang_path, 'DTI', subj_id, functional_path)
    #p_target_dir = sub_dti_dir.replace('fsavg', 'fsnative')

    with open(f'{os.path.join(HOME_DIR, subj_id)}/fmri/FSColorLUT_with_{network_id}_rois_{thr_type}_{threshold}.txt',"w") as ctab:
        ctab.write(LUT_prime)
    # 3.B move from annotation in surface to volume
    for idx, hemi in enumerate(hemis):
        functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'.replace('lang',f'lang_thr_{threshold}')
        sub_dti_dir = os.path.join(HOME_DIR, subj_id, 'fmri', functional_path)
        sub_dti_native_dir = sub_dti_dir.replace('fsavg', 'fsnative')
        assert os.path.exists(f'{sub_dti_native_dir}/{hemis_[idx].lower()}.{network_id}_roi_{thr_type}_{threshold}.annot')
        copyfile(f'{sub_dti_native_dir}/{hemis_[idx].lower()}.{network_id}_roi_{thr_type}_{threshold}.annot',
                 f'{subj_FS_path}/{subj_id}/label/{hemis_[idx].lower()}.{network_id}_roi_{thr_type}_{threshold}.annot')

    
    # output a unified volume file (for both hemispheres) at the root of the fsnative folder 
    # need to only do this once for the subject
    unix_pattern = ['mri_aparc2aseg',
                    '--s', subj_id,
                    '--o', f'{str(Path(sub_dti_native_dir).parent.parent)}/x.fsnative.{network_id}_roi_{thr_type}_{threshold}.nii.gz',
                    '--annot', f'{network_id}_roi_{thr_type}_{threshold}'
                    ]

    output = subprocess.Popen(unix_pattern, env=my_env)
    output.communicate()
    # do some plotting here
    plt.close('all')
    subj_vol_path = os.path.join(subj_FS_path, subj_id, 'mri', 'brain.mgz')
    # plot hemispheres
    test_img = load_img(f'{str(Path(sub_dti_native_dir).parent.parent)}/x.fsnative.{network_id}_roi_{thr_type}_{threshold}.nii.gz')
    for idx, hemi in enumerate(hemis):
        fig, axs = plt.subplots(nrows=2, ncols=3, subplot_kw={'projection': '3d'}, figsize=[11, 8])
        plt.rcParams['axes.facecolor'] = 'black'
        axs=axs.flatten()
        hemi_rois_idx = np.where([x.__contains__(hemis_[idx]) for x in ROI_names])[0]
        for idy, y in enumerate(hemi_rois_idx):
            mask = math_img(f'np.logical_and(img>{ offset + 1000 + (1000 * idx)+idy},img<={offset + 1000 + (1000 * idx)+idy+1})', img=test_img)
            x=ListedColormap([[R_col[y]/256, G_col[y]/256, 0]])
            plotting.plot_roi(mask, bg_img=subj_vol_path, axes=axs[idy], display_mode='ortho',draw_cross=False,alpha=1,annotate=False,
                              black_bg=True,cmap=x)
            axs[idy].set_title(f'{ROI_names[y]}\nthreshold_{threshold}%', color='white')
        fig.savefig(f'{str(Path(sub_dti_native_dir).parent.parent)}/{subj_id}_{hemis_[idx].lower()}._lang_roi_{thr_type}_{threshold}_in_vol.png', edgecolor='k',facecolor='k')

    #####################################################################
    # part 4
    # dti_vol_file=f'{HOME_DIR}/{subj_id}/dti/nodif_brain.nii.gz'
    #
    # # create a registeration file between functional and dti
    # unix_pattern = ['bbregister',
    #                 '--s', subj_id,
    #                 '--mov', dti_vol_file,
    #                 '--init-fsl',
    #                 '--dti',
    #                 '--reg', f'{str(Path(sub_dti_native_dir).parent.parent)}/reg_FS2nodif.dat']
    # #output = subprocess.Popen(unix_pattern, env=my_env)
    # #output.communicate()
    #
    # unix_str = ' '.join(unix_pattern)
    # cmd = f'''
    #     export SUBJECTS_DIR={subj_FS_path}
    #     module list
    #     echo $SUBJECTS_DIR
    #     {unix_str}
    #     '''
    # subprocess.call(cmd, shell=True, executable='/bin/bash')
    #
    # # do mri_vol2vol
    # unix_pattern = ['mri_vol2vol',
    #                 '--targ', f'{str(Path(sub_dti_native_dir).parent.parent)}/x.fsnative.{network_id}_roi_{thr_type}_{threshold}.nii.gz',
    #                 '--mov', dti_vol_file,
    #                 '--inv',
    #                 '--interp', 'nearest',
    #                 '--reg', f'{str(Path(sub_dti_native_dir).parent.parent)}/reg_FS2nodif.dat',
    #                 '--o',f'{str(Path(sub_dti_native_dir).parent.parent)}/x.fsnative.{network_id}_roi_{thr_type}_{threshold}_in_DTI.nii.gz']
    # #output = subprocess.Popen(unix_pattern, env=my_env)
    # #output.communicate()
    # unix_str = ' '.join(unix_pattern)
    # cmd = f'''
    #     export SUBJECTS_DIR={subj_FS_path}
    #     module list
    #     echo $SUBJECTS_DIR
    #     {unix_str}
    #     '''
    # subprocess.call(cmd, shell=True, executable='/bin/bash')
    #
    # test_img = load_img(f'{str(Path(sub_dti_native_dir).parent.parent)}/x.fsnative.{network_id}_roi_{thr_type}_{threshold}_in_DTI.nii.gz')
    # for idx, hemi in enumerate(hemis):
    #     fig, axs = plt.subplots(nrows=2, ncols=3, subplot_kw={'projection': '3d'}, figsize=[11, 8])
    #     plt.rcParams['axes.facecolor'] = 'black'
    #     axs=axs.flatten()
    #     hemi_rois_idx = np.where([x.__contains__(hemis_[idx]) for x in ROI_names])[0]
    #     for idy, y in enumerate(hemi_rois_idx):
    #         mask = math_img(f'np.logical_and(img>{ offset + 1000 + (1000 * idx)+idy},img<={offset + 1000 + (1000 * idx)+idy+1})', img=test_img)
    #         x=ListedColormap([[R_col[y]/256, G_col[y]/256, 0]])
    #
    #         plotting.plot_roi(mask, bg_img=dti_vol_file, axes=axs[idy], display_mode='ortho',draw_cross=False,alpha=1,annotate=False,
    #                           black_bg=True,cmap=x)
    #         axs[idy].set_title(ROI_names[y],color='white')
    #     fig.savefig(f'{str(Path(sub_dti_native_dir).parent.parent)}/{subj_id}_{hemis_[idx].lower()}._lang_roi_{thr_type}_{threshold}_lang_roi_in_DTI_vol.png', edgecolor='k',facecolor='k')
    #

