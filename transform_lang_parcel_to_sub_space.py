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

parser = argparse.ArgumentParser(description='find_subj_actvation_in_language_ROIs')
parser.add_argument('subj_id', type=str)
parser.add_argument('network_id', type=str)#, default='lang')
args=parser.parse_args()

if __name__ == '__main__':
    subj_id = args.subj_id
    #subj_id='sub721'
    #network_id = 'lang'
    network_id = args.network_id  # 'lang'
    ####################
    my_env = os.environ.copy()
    my_env['SUBJECTS_DIR'] = subj_FS_path
    hemis_ = ['LH', 'RH'] # shorthand version
    hemis = ['left', 'right'] # longform version
    #####################################################################
    # Part 1 : select voxels based on overlap with langauge parcels:
    plt.close('all')
    # 1.a: find language signinifant voxels in fsaverge space
    for idx, hemi in enumerate(hemis):
        sub_parcel_dir= os.path.join(HOME_DIR,subj_id,'parcel')
        Path(sub_parcel_dir).mkdir(parents=True, exist_ok=True)
        # create an annotation file from the activation masks
        for ROI_name in d_parcel_name_map[network_id].values():
            if ROI_name.__contains__(hemis_[idx]):
                try:
                    sub_parcel_roi_vxl
                except NameError:
                    sub_parcel_roi_vxl = np.zeros(d_parcel_fsaverage[network_id][ROI_name].shape).astype(int)
                    sub_parcel_roi = np.zeros(d_parcel_fsaverage[network_id][ROI_name].shape).astype(int)
                roi_surf = d_parcel_fsaverage[network_id][ROI_name]
                roi_voxels = roi_surf
                print(f'ROI name: {ROI_name}, number of voxels {np.sum(roi_voxels)}')
                fig = plt.figure( figsize=[11, 8])
                ax0 = fig.add_axes((.05,.1,.6,.7), projection='3d')
                plotting.plot_surf_roi(surf_mesh=fsaverage['infl_' + hemi], roi_map=roi_voxels,hemi=hemi, view='lateral',
                                       cmap='hot', bg_on_data=True, alpha=.3,darkness=.2,axes=ax0)
                #plotting.plot_surf_contours(fsaverage['infl_' + hemi], roi_surf, levels=[1, ], axes=ax0,
                #                        legend=True, colors=['k', ], labels=[f'{ROI_name},  #vox: {np.sum(roi_voxels)}'])


                fig.savefig(f'{sub_parcel_dir}/{subj_id}_{ROI_name}_roi_fsavg.png',facecolor=(1,1,1),edgecolor='none')
                # save individual annotation file and create label form them
                nib.freesurfer.write_annot(f'{sub_parcel_dir}/{ROI_name}_roi_fsavg.annot',
                                       roi_voxels.astype(int), np.asarray([[0, 0, 0, 0, 0], [255, 0, 0, 255, 1]]),
                                       [b'???', f'{ROI_name}_roi'], fill_ctab=True)
                sub_parcel_roi_vxl += roi_voxels.astype(int)
                sub_parcel_roi += roi_surf
        # plot full ROI map
        figure = plotting.plot_surf_roi(surf_mesh=fsaverage['infl_' + hemi], roi_map=sub_parcel_roi_vxl,
                                        hemi=hemi, view='lateral', cmap='hot', bg_on_data=True, alpha=.3,
                                        title=f'num of voxels{sub_parcel_roi_vxl.sum()}',darkness=.7)
        #lotting.plot_surf_contours(fsaverage['infl_' + hemi], sub_parcel_roi, levels=[1, ], figure=figure,
        #                            legend=True, colors=['k', ], labels=[f'{hemis_[idx]} ROIs,  #vox: {sub_parcel_roi_vxl.sum()}'])
        figure.savefig(f'{sub_parcel_dir}/{subj_id}_{hemis_[idx]}_all_ROIs_fsavg.png',
                       facecolor=(1, 1, 1), edgecolor='none')
    #1.b: make annotation to labels for easier transformation from average to native
    for idx, hemi in enumerate(hemis):
        for ROI_name in d_parcel_name_map[network_id].values():
            if ROI_name.__contains__(hemis_[idx]):
            # move from annot to label
                unix_pattern = ['mri_annotation2label','--hemi', hemis_[idx].lower(),
                                '--subject', 'fsaverage','--label', str(1),'--outdir', f'{sub_parcel_dir}',
                                '--annotation', f'{sub_parcel_dir}/{ROI_name}_roi_fsavg.annot'
                                ]
                output = subprocess.Popen(unix_pattern, env=my_env)
                output.communicate()
                # immediately change the label name:
                unix_pattern=['mv',f'{sub_parcel_dir}/{hemis_[idx].lower()}.{ROI_name}_roi.label',
                              f'{sub_parcel_dir}/{ROI_name}_roi_fsavg.label']
                output = subprocess.Popen(unix_pattern, env=my_env)
                output.communicate()
                # make sure the annotation to label is done correctly
    #####################################################################
    ## Part 2 : move labels from fsaverage to fsnative
    plt.close('all')
    for idx, hemi in enumerate(hemis):
        subj_surf_file = Path(subj_FS_path, subj_id, 'surf', hemis_[idx].lower() + '.inflated')
        subj_sulc_file = Path(subj_FS_path, subj_id, 'surf', hemis_[idx].lower() + '.sulc')
        for ROI_name in d_parcel_name_map[network_id].values():
            if ROI_name.__contains__(hemis_[idx]):
                unix_pattern = ['mri_label2label',
                                '--srcsubject', 'fsaverage','--hemi', hemis_[idx].lower(),'--trgsubject', subj_id,'--regmethod', 'surface',
                                '--srclabel', f'{sub_parcel_dir}/{ROI_name}_roi_fsavg.label',
                                '--trglabel', f'{sub_parcel_dir}/{ROI_name}_roi_fsnative.label'
                                ]
                output = subprocess.Popen(unix_pattern, env=my_env)
                output.communicate()
                try:
                    del roi_map
                    del label_file
                except:
                    pass
                label_file = f'{sub_parcel_dir}/{ROI_name}_roi_fsnative.label'
                label_roi = nib.freesurfer.read_label(label_file)
                n_vertices = len(nib.freesurfer.read_geometry(subj_surf_file)[0])
                roi_map = np.zeros(n_vertices)
                roi_map[label_roi] = 1
                figure = plotting.plot_surf_roi(surf_mesh=str(subj_surf_file), roi_map=roi_map,
                                                hemi=hemi, view='lateral', cmap='hot', bg_on_data=True, alpha=.3,
                                                title=f'num of voxels{roi_map.sum()}', darkness=.7)
                figure.savefig(f'{sub_parcel_dir}/{ROI_name}_roi_fsnative.png',edgecolor='none')
    #####################################################################
    # Part 3 : transforming native label to volume for subject
    # 3.A transform labels to annotation first
    R_col = np.linspace(0, 255, len(d_parcel_name_map[network_id].values()), dtype=int)
    G_col = np.flip(R_col)
    # breakdown the areas based on hemisphere
    LUT_prime = FSLUT
    for idx, hemi in enumerate(hemis):
        print(f'in step 3. processing hemisphere {hemi}.')

        # https://github.com/freesurfer/freesurfer/blob/e34ae4559d26a971ad42f5739d28e84d38659759/mri_aparc2aseg/mri_aparc2aseg.cpp#L836
        # ACTUAL_OFFSET = { OFFSET + 1000,  if LH
        #                   OFFSET + 2000,  if RH }
        # these values are HARD-CODED in the freesurfer
        ROI_names = list(d_parcel_name_map[network_id].values())
        offset=400
        hemi_rois_idx = np.where([x.__contains__(hemis_[idx]) for x in ROI_names])[0]
        # create a nicely formatted ctab file
        fmt = '{:<19} ' * 2 + '{: >5} ' * 4
        txt_lines = ['#$ Id: FreeSurferColorLUT_dti_evlab.txt, Fall 2021 $',
                     fmt.format('#No.', 'Label Name:', 'R', 'G', 'B', 'A'),
                     fmt.format(0, 'Unknown', 0, 0, 0, 0)]
        for idy, y in enumerate(hemi_rois_idx):
            txt_lines.append(fmt.format(idy + offset + 1, f'{ROI_names[y]}', R_col[y], G_col[y], 0, 1))
            # does what freesurfer does internally to the indices it reads from the ctab files.
            # for LH, we want to transform x -> x + 1000 + offset if LH, else x + 2000 + offset
            LUT_prime += '\n' + fmt.format(idy + offset + 1 + 1000 + (1000 * idx), f'{ROI_names[y]}', R_col[y], G_col[y], 0,1)
        if os.path.exists(f'{sub_parcel_dir}/{hemis_[idx].lower()}_{network_id}_parcels_ctab.txt'):
            os.remove(f'{sub_parcel_dir}/{hemis_[idx].lower()}_{network_id}_parcels_ctab.txt')
        with open(f'{sub_parcel_dir}/{hemis_[idx].lower()}_{network_id}_roi_parcels_ctab.txt', "w") as textfile:
           for element in txt_lines:
               textfile.write(element + "\n")
        # create the unix pattern to run mri_label2annot command:
        unix_pattern = ['mris_label2annot',
                        '--s', subj_id,'--h', hemis_[idx].lower(),
                        '--ctab', f'{sub_parcel_dir}/{hemis_[idx].lower()}_{network_id}_roi_parcels_ctab.txt',
                        '--annot-path', f'{sub_parcel_dir}/{hemis_[idx].lower()}.{network_id}_parcels.annot',
                        # NOTE: we do not observe any difference in the output generated using the
                        '--surf', 'orig',  # Note this is an option for verision 6.0.0 of freesurfer
                        '--offset', f'{offset}'  # NOTE: expects offset of 0 for lh and rh
                        ]
        for idy, y in enumerate(hemi_rois_idx):
            unix_pattern.append('--l'),
            unix_pattern.append(f'{sub_parcel_dir}/{ROI_names[y]}_roi_fsnative.label')
            #unix_pattern.append(f'{sub_dti_native_dir}/{hemis_[idx].lower()}.{ROI_names[y]}_roi.label')
        output = subprocess.Popen(unix_pattern, env=my_env)
        output.communicate()
    #with open(f'{os.path.join(HOME_DIR, subj_id)}/fmri/FSColorLUT_with_{network_id}_rois_{thr_type}_{threshold}.txt',"w") as ctab:
    #    ctab.write(LUT_prime)
    #with open(f'{os.path.join(HOME_DIR, subj_id)}/fmri/FSColorLUT_with_{network_id}_rois_threshold_{threshold}.txt',"w") as ctab:
    #   ctab.write(LUT_prime)
    # 3.B move from annotation in surface to volume
    # delete any prior language rois
    prior_rois = glob(f'{subj_FS_path}/{subj_id}/label/*.{network_id}_roi_*.annot')
    [os.remove(roi_file) for roi_file in prior_rois]
    for idx, hemi in enumerate(hemis):
        # delete any prievious lang rois
        copyfile(f'{sub_parcel_dir}/{hemis_[idx].lower()}.{network_id}_parcels.annot',
                 f'{subj_FS_path}/{subj_id}/label/{hemis_[idx].lower()}.{network_id}_parcels.annot')
    # output a unified volume file (for both hemispheres) at the root of the fsnative folder
    # need to only do this once for the subject
    unix_pattern = ['mri_aparc2aseg',
                '--s', subj_id,'--annot', f'{network_id}_parcels',
                '--o', f'{sub_parcel_dir}/x.fsnative.{network_id}_parcels.nii.gz'
                ]
    output = subprocess.Popen(unix_pattern, env=my_env)
    output.communicate()
    # do some plotting here
    plt.close('all')
    subj_vol_path = os.path.join(subj_FS_path, subj_id, 'mri', 'brain.mgz')
    # plot hemispheres
    test_img = load_img(f'{sub_parcel_dir}/x.fsnative.{network_id}_parcels.nii.gz')

    offset = 400
    for idx, hemi in enumerate(hemis):
        fig, axs = plt.subplots(nrows=2, ncols=3, subplot_kw={'projection': '3d'}, figsize=[11, 8])
        plt.rcParams['axes.facecolor'] = 'black'
        axs=axs.flatten()
        hemi_rois_idx = np.where([x.__contains__(hemis_[idx]) for x in ROI_names])[0]
        for idy, y in enumerate(hemi_rois_idx):
            mask = math_img(f'np.logical_and(img>{ offset + 1000 + (1000 * idx)+idy},img<={offset + 1000 + (1000 * idx)+idy+1})', img=test_img)
            print(f'{ROI_names[y]} #vox: {np.sum(mask.dataobj)}')
            x=ListedColormap([[R_col[y]/256, G_col[y]/256, 0]])
            plotting.plot_roi(mask, bg_img=subj_vol_path, axes=axs[idy], display_mode='ortho',draw_cross=False,alpha=1,annotate=False,
                              black_bg=True,cmap=x)
            axs[idy].set_title(f'{ROI_names[y]}\n% #vox:{np.sum(mask.dataobj)}', color='white')
        fig.savefig(f'{sub_parcel_dir}/{subj_id}_{hemis_[idx].lower()}._lang_parcels_in_vol.png', edgecolor='k',facecolor='k')

    #####################################################################
    # Part 4 : transforming native label to volume for subject
    dti_vol_file = f'{HOME_DIR}/{subj_id}/dti/nodif_brain.nii.gz'
    reg_file_pth = Path(f'{HOME_DIR}/{subj_id}/lang_glasser/reg_FS2nodif.dat')
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
    # see : https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/Diffusion/DTIscripts
    vol2vol_method='nearest'
    combine_dti_file_pth=Path(f"{HOME_DIR}/{subj_id}/parcel/{subj_id}_{network_id}_parcels_indti.nii.gz")
    subj_parcel_file=f'{sub_parcel_dir}/x.fsnative.{network_id}_parcels.nii.gz'
    combine_dti_file_pth.parent.mkdir(parents=True, exist_ok=True)
    unix_pattern = ['mri_vol2vol',
                    '--targ', str(subj_parcel_file),
                    '--mov', dti_vol_file,
                    '--inv', # moving from structural (targ) to dti (mov)
                    '--interp', vol2vol_method,
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
    print('All done! time to go home')