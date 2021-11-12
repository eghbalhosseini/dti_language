import nibabel as nib
import nilearn as nil
from nilearn import datasets
import nilearn.plotting as plotting
import numpy as np
import os
import subprocess
import argparse
from utils.parcel_utils import d_parcel_fsaverage, d_parcel_name_map
from utils.fmri_utils import subj_path, subj_FS_path
fsaverage = datasets.fetch_surf_fsaverage(mesh='fsaverage')
from pathlib import Path
from shutil import copyfile
import matplotlib.pyplot as plt
from nilearn.image import load_img, math_img


parser = argparse.ArgumentParser(description='find_subj_actvation_in_language_ROIs')
parser.add_argument('subj_id', type=str) # DEBUG
parser.add_argument('network_id', type=str)#, default='lang')
parser.add_argument('threshold', type=int)#, default=90)
args=parser.parse_args()


if __name__ == '__main__':
    subj_id = args.subj_id
    subj_id='sub239'
    threshold=90
    network_id = 'lang'
    threshold = args.threshold
    file_name = 'fsig'

    my_env = os.environ.copy()
    my_env['SUBJECTS_DIR'] = subj_FS_path

    hemis_ = ['LH', 'RH'] # shorthand version
    hemis = ['left', 'right'] # longform version

    #####################################################################
    ## Part 1 : select voxels based on overlap with langauge parcels:
    # find language signinifant voxels in fsaverge space

    for idx, hemi in enumerate(hemis):
        functional_path=f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
        # sub_func_dir = os.path.join(subj_path, subj_id, 'bold', functional_path, file_name+'.nii.gz')

        # replacing the original FS directory stuff with the "archived" stuff, because the newly processed directories
        # are still missing certain files necessary for processing here (TODO: which files are missing? I think the 
        # bold/*.nii.gz onces)
        sub_func_dir = os.path.join(subj_path, 'archive', 'n810_archived_18Oct2021',
                                    subj_id, 'bold', functional_path, file_name+'.nii.gz')
        sub_dti_dir= os.path.join(subj_path,'DTI',subj_id,functional_path)
        Path(sub_dti_dir).mkdir(parents=True, exist_ok=True)

        network_img=nib.load(sub_func_dir)
        network = np.asarray(network_img.dataobj).flatten()
        sub_parcel_roi_vxl = np.zeros(network.shape).astype(int)
        sub_parcel_roi = np.zeros(network.shape).astype(int)
        # plot surface data
        # create an annotation file from the activation masks
        for ROI_name in d_parcel_name_map[network_id].values():
            if ROI_name.__contains__(hemis_[idx]):
                roi_surf = d_parcel_fsaverage[network_id][ROI_name]
                samples = network[(roi_surf == 1) & ~(np.isnan(network))]
                samples_90 = np.percentile(samples, int(threshold))
                roi_voxels = ((roi_surf == 1)) & (network >= samples_90)
                print(f'ROI name: {ROI_name}, number of voxels {np.sum(roi_voxels)}')

                figure=plotting.plot_surf_roi(surf_mesh=fsaverage['infl_' + hemi], roi_map=roi_voxels,
                                       hemi=hemi, view='lateral', cmap='hot',
                                       bg_map=network, bg_on_data=True, alpha=.3,
                                       darkness=1)

                plotting.plot_surf_contours(fsaverage['infl_' + hemi], roi_surf, levels=[1, ], figure=figure,
                                        legend=True, colors=['k', ], labels=[f'{ROI_name},  #vox: {np.sum(roi_voxels)}'])

                figure.savefig(f'{sub_dti_dir}/{subj_id}_{ROI_name}_roi_{file_name}_{threshold}_fsavg.png',facecolor=(.7,.7,.7),edgecolor='none')
            # save individual annotation file and create label form them
                nib.freesurfer.write_annot(f'{sub_dti_dir}/{ROI_name}_roi_{file_name}_{threshold}_fsavg.annot',
                                       roi_voxels.astype(int), np.asarray([[0, 0, 0, 0, 0], [255, 0, 0, 255, 1]]),
                                       [b'???', f'{ROI_name}_roi'], fill_ctab=True)
                sub_parcel_roi_vxl += roi_voxels.astype(int)
                sub_parcel_roi += roi_surf
        # plot full ROI map
        figure = plotting.plot_surf_roi(surf_mesh=fsaverage['infl_' + hemi], roi_map=sub_parcel_roi_vxl,
                                        hemi=hemi, view='lateral', cmap='hot',
                                        bg_map=network, bg_on_data=True, alpha=.3,
                                        title=f'num of voxels{sub_parcel_roi_vxl.sum()}',
                                        darkness=1)


        plotting.plot_surf_contours(fsaverage['infl_' + hemi], sub_parcel_roi, levels=[1, ], figure=figure,
                                    legend=True, colors=['k', ], labels=[f'{hemis_[idx]} ROIs,  #vox: {sub_parcel_roi_vxl.sum()}'])
        figure.savefig(f'{sub_dti_dir}/{subj_id}_{hemis_[idx]}_all_ROIs_{file_name}_{threshold}_fsavg.png',
                       facecolor=(.7, .7, .7), edgecolor='none')

    # make annotation to labels for easier transformation from average to native
    for idx, hemi in enumerate(hemis):
        functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
        sub_dti_dir = os.path.join(subj_path, 'DTI', subj_id, functional_path)
        for ROI_name in d_parcel_name_map[network_id].values():
            if ROI_name.__contains__(hemis_[idx]):
            # move from annot to label
                unix_pattern = ['mri_annotation2label',
                                '--hemi', hemis_[idx].lower(),
                                '--subject', 'fsaverage',
                                '--label', str(1),
                                '--outdir', f'{sub_dti_dir}',
                                '--annotation', f'{sub_dti_dir}/{ROI_name}_roi_{file_name}_{threshold}_fsavg.annot',
                                '--surface', 'inflated']
                output = subprocess.Popen(unix_pattern, env=my_env)
                output.communicate()
    
    #####################################################################
    ## Part 2 : move labels from fsaverage to fsnative
    for idx, hemi in enumerate(hemis):
        functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
        sub_dti_dir = os.path.join(subj_path, 'DTI', subj_id, functional_path)
        p_target_dir = sub_dti_dir.replace('fsavg', 'fsnative')
        Path(p_target_dir).mkdir(parents=True, exist_ok=True)
        functional_native_path = functional_path.replace('fsavg', 'self')
        
        # sub_func_native_dir = os.path.join(subj_path, subj_id, 'bold', functional_native_path, file_name + '.nii.gz')
        ######!!! ^ didnt run for sub191, so tried making modificaiton below:
        # load subject fsaverage activation, this is for plotting only
        sub_func_dir = os.path.join(subj_path, 'archive', 'n810_archived_18Oct2021',
                                    subj_id, 'bold', functional_path, file_name + '.nii.gz')
        network_img=nib.load(sub_func_dir)
        network_fsavg = np.asarray(network_img.dataobj).flatten()

        # load subject native activation, this is for plotting only
        sub_func_native_dir = os.path.join(subj_path, 'archive', 'n810_archived_18Oct2021',
                                           subj_id, 'bold', functional_native_path, file_name+'.nii.gz')
        network_native_img = nib.load(sub_func_native_dir)
        network_native = np.asarray(network_native_img.dataobj).flatten()

        subj_surf_file = Path(subj_FS_path, subj_id, 'surf', hemis_[idx].lower() + '.inflated')
        subj_sulc_file = Path(subj_FS_path, subj_id, 'surf', hemis_[idx].lower() + '.sulc')
    #
        for ROI_name in d_parcel_name_map[network_id].values():
            if ROI_name.__contains__(hemis_[idx]):
                unix_pattern = ['mri_label2label',
                            '--srcsubject', 'fsaverage',
                             '--hemi', hemis_[idx].lower(),
                             '--srclabel', f'{sub_dti_dir}/{hemis_[idx].lower()}.{ROI_name}_roi.label',
                             '--trgsubject', subj_id,
                             #'--trgsurf', 'pial', # TODO :do we need this here ? this is for when the label in volume and need to be tranformed to surface
                             '--trglabel', f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi.label',
                             '--regmethod', 'surface']
                output = subprocess.Popen(unix_pattern, env=my_env)
                output.communicate()
                # plot the resulting surface

                #
                fig, ax = plt.subplots(nrows=2, ncols=1,subplot_kw={'projection': '3d'},figsize=[8,11])
                # plot fsaverage:
                label_roi = nib.freesurfer.read_label(f'{sub_dti_dir}/{hemis_[idx].lower()}.{ROI_name}_roi.label')
                network_fsaverage_ROI = np.zeros(network_fsavg.shape)
                network_fsaverage_ROI[label_roi] = 1
                plotting.plot_surf_roi(surf_mesh=fsaverage['infl_' + hemi], roi_map=network_fsaverage_ROI,
                                       hemi=hemi, view='lateral', cmap='hot',
                                       bg_map=network_fsavg, bg_on_data=True,
                                       darkness=1,axes=ax[0])
                ax[0].set_title(f'fsaverage, {ROI_name}_roi, #vox: {np.sum(network_fsaverage_ROI)}')
                # plot fs native
                label_roi = nib.freesurfer.read_label(f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi.label')
                network_fsnative_ROI = np.zeros(network_native.shape)
                network_fsnative_ROI[label_roi] = 1

                plotting.plot_surf_roi(str(subj_surf_file), roi_map=network_fsnative_ROI,
                                       hemi=hemi, view='lateral', cmap='hot',
                                       bg_map=network_native, bg_on_data=True,
                                       darkness=1,axes=ax[1]
                                       )
                ax[1].set_title(f'fsnative, {ROI_name}_roi, #vox: {np.sum(network_fsnative_ROI)}')

                fig.savefig(f'{p_target_dir}/{subj_id}_{hemis_[idx].lower()}.{ROI_name}_roi.png',edgecolor='none')


    #####################################################################
    # Part 3 : transforming native label to volume for subject
    # 3.A tranform labels to annoation first
    R_col=np.linspace(0,255,len(d_parcel_name_map[network_id].values()),dtype=int)
    G_col=np.flip(R_col)
    # breakdown the areas based on hemisphere
    for idx, hemi in enumerate(hemis):

        print(f'in step 3. processing hemisphere {hemi}.')

        functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
        # TODO possibly problematic? currenly outputs 2000s for LH and 3000s for
        # RH
        offset=0 #*1000+1000*idx # results in 2000 for lh; 4000 for rh
        sub_dti_dir = os.path.join(subj_path, 'DTI', subj_id, functional_path)
        p_target_dir = sub_dti_dir.replace('fsavg', 'fsnative')
        ROI_names=list(d_parcel_name_map[network_id].values())
        hemi_rois_idx=np.where([x.__contains__(hemis_[idx]) for x in ROI_names])[0]

        # create a nicely formatted ctab file
        fmt = '{:>19} ' * 2 + '{: >5} ' * 4
        txt_lines = ['#$Id: FreeSurferColorLUT.txt,v 1.38.2.1 2007/08/20 01:52:07 nicks Exp $',
                     fmt.format('#No.','Label Name:','R','G','B','A'),
                     fmt.format(offset, 'Unknown', 0, 0, 0, 0)
                     ]
        for idy, y in enumerate(hemi_rois_idx):
            txt_lines.append(fmt.format(idy+offset+1, ROI_names[y], R_col[y], G_col[y], 0, 1))
        with open(f'{p_target_dir}/{hemis_[idx].lower()}_{network_id}_roi_ctab.txt', "w") as textfile:
            for element in txt_lines:
                textfile.write(element + "\n")

        # create the unix pattern to run mri_label2annot command:
        unix_pattern = ['mris_label2annot',
                        '--s', subj_id,
                        '--h', hemis_[idx].lower(),
                        '--ctab', f'{p_target_dir}/{hemis_[idx].lower()}_{network_id}_roi_ctab.txt',
                        '--annot-path', f'{p_target_dir}/{hemis_[idx].lower()}.{network_id}_roi',
                        # NOTE: we do not observe any difference in the output generated using the
                        # --surf pial or --surf orig flags. we may use either one.
                        '--surf', 'orig', # '--surf', 'orig',
                        '--offset', f'{offset}' # NOTE: expects offset of 0 for lh and rh
                        ]
        for idy, y in enumerate(hemi_rois_idx):
            unix_pattern.append('--l'),
            unix_pattern.append(f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_names[y]}_roi.label')

        output = subprocess.Popen(unix_pattern, env=my_env)
        output.communicate()

    # 3.B move from annotation in surface to volume
    for idx, hemi in enumerate(hemis):
        functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
        sub_dti_dir = os.path.join(subj_path, 'DTI', subj_id, functional_path)
        p_target_dir = sub_dti_dir.replace('fsavg', 'fsnative')

        Path(f'{subj_FS_path}/{subj_id}/label/').mkdir(parents=True, exist_ok=True)
        copyfile(f'{p_target_dir}/{hemis_[idx].lower()}.{network_id}_roi.annot',
                 f'{subj_FS_path}/{subj_id}/label/{hemis_[idx].lower()}.{network_id}_roi.annot')
    
    # output a unified volume file (for both hemispheres) at the root of the fsnative folder 
    # need to only do this once for the subject
    unix_pattern = ['mri_aparc2aseg',
                    '--s', subj_id,
                    '--o', f'{str(Path(p_target_dir).parent.parent)}/x.fsnative.{network_id}_roi.nii.gz',
                    '--annot', f'{network_id}_roi'
                    ]
    
    output = subprocess.Popen(unix_pattern, env=my_env)
    output.communicate()
    # do some plotting here
    subj_vol_path=os.path.join(subj_FS_path,subj_id,'mri','brain.mgz')

    fig, ax = plt.subplots(nrows=1, ncols=1, subplot_kw={'projection': '3d'}, figsize=[8, 11])
    test_img=load_img(f'{str(Path(p_target_dir).parent.parent)}/x.fsnative.{network_id}_roi.nii.gz')
    mask=math_img('np.logical_and(img>1000,img<=1001)',img=test_img)

    plotting.plot_stat_map(mask,bg_img=subj_vol_path,axes=ax,display_mode='ortho',draw_cross=False)
    fig.show()
    #####################################################################
    # part 4

    dti_vol_file='/mindhive/evlab/Shared/diffusionzeynep/sub190/dti/nodif_brain.nii.gz'

    # create a registeration file between functional and dti
    unix_pattern = ['bbregister',
                    '--s', subj_id,
                    '--mov', dti_vol_file,
                    #'--init-fsl',
                    '--dti',
                    '--reg', f'{str(Path(p_target_dir).parent.parent)}/reg_FS2nodif.dat']
    output = subprocess.Popen(unix_pattern, env=my_env)
    output.communicate()

    # do mri_vol2vol
    unix_pattern = ['mri_vol2vol',
                    '--targ', f'{str(Path(p_target_dir).parent.parent)}.orig/x.fsnative.{network_id}_roi.nii.gz',
                    '--mov', dti_vol_file,
                    '--inv',
                    '--interp', 'nearest',
                    '--reg', f'{str(Path(p_target_dir).parent.parent)}/reg_FS2nodif.dat',
                    '--o',f'{str(Path(p_target_dir).parent.parent)}/x.fsnative.{network_id}_roi_in_DTI.nii.gz']
    output = subprocess.Popen(unix_pattern, env=my_env)
    output.communicate()