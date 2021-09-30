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
import matplotlib.pyplot as plt
import seaborn as sns

parser = argparse.ArgumentParser(description='find_subj_actvation_in_language_ROIs')
parser.add_argument('subj_id', type=str,default='sub190')
parser.add_argument('network_id',type=str,default='lang')
parser.add_argument('hemi',type=str,default='left')
parser.add_argument('threshold',type=int,default=90)
args=parser.parse_args()


if __name__ == '__main__':
    #subj_id=args.subj_id
    subj_id='sub190'
    #network_id=args.network_id
    network_id='lang'
    #hemi=args.hemi
    hemi = 'left'
    #threshold = args.threshold
    threshold = 90
    n_smooth=6
    file_name='fsig'
    if hemi=='left':
        hemi_='LH'
    else:
        hemi_='RH'
    #
    my_env = os.environ.copy()
    my_env['SUBJECTS_DIR'] = subj_FS_path

    #####################################################################
    ## Part 1 : select voxels based on overlap with langauge parcels:

    # load language signinifant voxels in fsaverge space
    functional_path='bold.fsavg.sm4.lh.lang/S-v-N'
    sub_func_dir=os.path.join(subj_path,subj_id,'bold',functional_path,file_name+'.nii.gz')
    sub_dti_dir= os.path.join(subj_path,'DTI',subj_id,functional_path)
    Path(sub_dti_dir).mkdir(parents=True, exist_ok=True)
    p_target_dir = sub_dti_dir.replace('fsavg', 'fsnative')
    Path(p_target_dir).mkdir(parents=True, exist_ok=True)

    network_img=nib.load(sub_func_dir)
    network = np.asarray(network_img.dataobj).flatten()
    sub_parcel_roi_vxl = np.zeros(network.shape).astype(int)
    for ROI_name in d_parcel_name_map[network_id].values():
        if ROI_name.__contains__(hemi_):
            roi_surf = d_parcel_fsaverage[network_id][ROI_name]
            samples = network[(roi_surf == 1) & ~(np.isnan(network))]
            samples_90 = np.percentile(samples, int(threshold))
            roi_voxels = ((roi_surf == 1)) & (network >= samples_90)
            print(f'ROI name: {ROI_name}, number of voxels {np.sum(roi_voxels)}')
            figure = plotting.plot_surf_stat_map(fsaverage['infl_' + hemi], roi_voxels.astype(int), hemi=hemi,
                                                 title=f'Surface {hemi} hemisphere', colorbar=False,
                                                 threshold=1., bg_map=fsaverage['sulc_' + hemi])
            plotting.plot_surf_contours(fsaverage['infl_' + hemi], roi_surf, levels=[1, ], figure=figure,
                                        legend=True, colors=['g', ], labels=[ROI_name],
                                        output_file=f'{sub_dti_dir}/{ROI_name}_roi_{file_name}_{threshold}_fsavg.png')
            # save individual annotation file and create label form them
            nib.freesurfer.write_annot(f'{sub_dti_dir}/{ROI_name}_roi_{file_name}_{threshold}_fsavg.annot',
                                       roi_voxels.astype(int), np.asarray([[0, 0, 0, 0, 0], [255, 0, 0, 255, 1]]),
                                       [b'???', f'{ROI_name}_roi'], fill_ctab=True)
            sub_parcel_roi_vxl += roi_voxels.astype(int)
    #
    for ROI_name in d_parcel_name_map[network_id].values():
        if ROI_name.__contains__(hemi_):
            # move from annot to label
            unix_pattern = ['mri_annotation2label',
                             '--hemi', hemi_.lower(),
                             '--subject', 'fsaverage',
                             '--label', str(1),
                             '--outdir', f'{sub_dti_dir}',
                             '--annotation', f'{sub_dti_dir}/{ROI_name}_roi_{file_name}_{threshold}_fsavg.annot',
                             '--surface', 'inflated']
            output = subprocess.Popen(unix_pattern, env=my_env)
            output.communicate()
    # move from fsaverage to fsnative
    functional_native_path = functional_path.replace('fsavg', 'self')
    sub_func_native_dir = os.path.join(subj_path, subj_id, 'bold', functional_native_path, file_name + '.nii.gz')
    network_native_img = nib.load(sub_func_native_dir)
    network_native = np.asarray(network_native_img.dataobj).flatten()
    subj_surf_file = Path(subj_FS_path, subj_id, 'surf', hemi_.lower() + '.inflated')
    subj_sulc_file = Path(subj_FS_path, subj_id, 'surf', hemi_.lower() + '.sulc')
    #
    for ROI_name in d_parcel_name_map[network_id].values():
        if ROI_name.__contains__(hemi_):
            unix_pattern = ['mri_label2label',
                            '--srcsubject', 'fsaverage',
                             '--hemi', 'lh',
                             '--srclabel', f'{sub_dti_dir}/{hemi_.lower()}.{ROI_name}_roi.label',
                             '--trgsubject', subj_id,
                             '--trgsurf', 'inflated',
                             '--trglabel', f'{p_target_dir}/{hemi_.lower()}.{ROI_name}_roi.label',
                             '--regmethod', 'surface']
            output = subprocess.Popen(unix_pattern, env=my_env)
            output.communicate()

    for ROI_name in d_parcel_name_map[network_id].values():
        if ROI_name.__contains__(hemi_):
            label_roi = nib.freesurfer.read_label(f'{p_target_dir}/{hemi_.lower()}.{ROI_name}_roi.label')
            network_fsnative_ROI = np.zeros(network_native.shape)
            network_fsnative_ROI[label_roi] = 1
            plotting.plot_surf_roi(str(subj_surf_file), roi_map=network_fsnative_ROI,
                           hemi='left', view='lateral',cmap='hot',
                           bg_map=network_native, bg_on_data=True,
                           darkness=1, output_file=f'{p_target_dir}/{hemi_.lower()}.{ROI_name}_roi.png')

    # plot labels and actvations to verify the tranformationed worked

    functional_native_path = functional_path.replace('fsavg', 'self')
    sub_func_native_dir = os.path.join(subj_path, subj_id, 'bold', functional_native_path, file_name + '.nii.gz')
    network_native_img = nib.load(sub_func_native_dir)
    network_native = np.asarray(network_native_img.dataobj).flatten()
    subj_surf_file = Path(subj_FS_path, subj_id, 'surf', hemi_.lower() + '.inflated')
    subj_sulc_file = Path(subj_FS_path, subj_id, 'surf', hemi_.lower() + '.sulc')
    figure, axes = plt.subplots(subplot_kw={'projection': '3d'})
    plotting.plot_surf_stat_map(str(subj_surf_file), network_native, hemi=hemi,
                                title=f'Surface {hemi} hemisphere', bg_map=str(subj_sulc_file),
                                threshold=np.percentile(network_native, 75), axes=axes)
    for ROI_name in d_parcel_name_map[network_id].values():
        if ROI_name.__contains__(hemi_):
            print(ROI_name)
            label_roi = nib.freesurfer.read_label(f'{p_target_dir}/{hemi_.lower()}.{ROI_name}_roi.label')
            network_fsnative_ROI = np.zeros(network_native.shape)
            network_fsnative_ROI[label_roi] = 1
            plotting.plot_surf_contours(str(subj_surf_file), roi_surf, levels=[1,], figure=figure, axes=axes,
                                legend=True, colors=['g', ], labels=[ROI_name])

    figure.savefig(os.path.join(p_target_dir,'ROI_activation.png'), dpi=None, facecolor='w', edgecolor='w',
            orientation='landscape', format=None,
            transparent=False, bbox_inches=None, pad_inches=0.1)

    # plot all ROIs
    all_ROIS = d_parcel_fsaverage[network_id][hemi_ + '_ROIs']
    print(f'ROI name: {hemi_}_ROIs, number of voxels {np.sum(sub_parcel_roi_vxl)}')
    figure = plotting.plot_surf_stat_map(fsaverage['infl_' + hemi], sub_parcel_roi_vxl.astype(int), hemi=hemi,
                                         title=f'Surface {hemi} hemisphere',
                                         colorbar=False, threshold=1., bg_map=fsaverage['sulc_' + hemi])
    # save the rois
    ni_img = nib.Nifti1Image(np.reshape(sub_parcel_roi_vxl.astype(float), network_img.shape),
                             header=network_img._header, affine=network_img.affine)
    nib.nifti1.save(ni_img, f'{sub_dti_dir}/{hemi_}_ROIs_{file_name}_{threshold}_fsavg')
    # save as annotation file --> for use in the next step

    nib.freesurfer.write_annot(f'{sub_dti_dir}/{hemi_}_ROIs_{file_name}_{threshold}_fsavg.annot',sub_parcel_roi_vxl,np.asarray([[0,0,0,0,0],[255,0,0,255,1]]),[b'???',f'{hemi_}_ROIs'],fill_ctab=True)

    plotting.plot_surf_roi(fsaverage['infl_left'], roi_map=sub_parcel_roi_vxl,
                           hemi='left', view='lateral',
                           bg_map=fsaverage['sulc_left'], bg_on_data=True,
                           darkness=.5,output_file=f'{sub_dti_dir}/{hemi_}_ROIs_{file_name}_{threshold}_fsavg_.png')

    print('done making fROIs\n')

    #####################################################################
    ## Part 2 : tranfroming surface between fsaverage and subject space :
    print('doing surf to volume transformation for subject in fsaverage space\n')
    map_method = 'nnfr'
    p_source=Path(f'{sub_dti_dir}/{hemi_}_ROIs_{file_name}_{threshold}_fsavg.nii')
    p_target_dir=str(p_source.parent).replace('fsavg', 'fsnative')
    p_target = str(p_source).replace('fsavg', 'fsnative')
    p_target = p_target.replace('.nii', f'_nrep_{n_smooth}_map_{map_method}.nii')

    Path(p_target_dir).mkdir(parents=True, exist_ok=True)
    # change where subject dir is
    my_env = os.environ.copy()
    my_env['SUBJECTS_DIR']=subj_FS_path
    unix_pattern=['mri_surf2surf',
                  '--hemi',hemi_.lower(),
                  '--srcsubject','fsaverage',
                  '--srcsurfval',str(p_source),
                  '--surfreg','inflated',
                  '--mapmethod', map_method,
                  '--trgsubject',subj_id,
                  '--nsmooth-out',str(n_smooth),
                  '--trgsurfval',p_target
                  ]
    output=subprocess.Popen(unix_pattern,env=my_env)
    output.communicate()

    # method 2: try label instead
    unix_pattern = ['mri_annotation2label',
                    '--hemi', hemi_.lower(),
                    '--subject', 'fsaverage',
                    '--label', str(1),
                    '--outdir',f'{sub_dti_dir}',
                    '--annotation', f'{sub_dti_dir}/{hemi_}_ROIs_{file_name}_{threshold}_fsavg.annot',
                    '--surface','inflated']

    output = subprocess.Popen(unix_pattern, env=my_env)
    output.communicate()


    unix_pattern = ['mri_label2label',
                    '--srcsubject', 'fsaverage',
                    '--hemi','lh',
                    '--srclabel', f'{sub_dti_dir}/{hemi_.lower()}.{hemi_}_ROIs.label',
                    '--trgsubject',subj_id,
                    '--trgsurf','inflated',
                    '--trglabel', f'{p_target_dir}/{hemi_.lower()}.{hemi_}_ROIs.label',
                    '--regmethod','surface']

    output = subprocess.Popen(unix_pattern, env=my_env)
    output.communicate()
    #
    functional_native_path=functional_path.replace('fsavg','self')
    sub_func_native_dir = os.path.join(subj_path, subj_id, 'bold', functional_native_path, file_name + '.nii.gz')
    network_native_img = nib.load(sub_func_native_dir)
    network_native = np.asarray(network_native_img.dataobj).flatten()
    subj_surf_file = Path(subj_FS_path, subj_id, 'surf', hemi_.lower() + '.inflated')
    subj_sulc_file = Path(subj_FS_path, subj_id, 'surf', hemi_.lower() + '.sulc')
    figure, axes = plt.subplots(subplot_kw={'projection': '3d'})
    plotting.plot_surf_stat_map(str(subj_surf_file), network_native, hemi=hemi,
                                title=f'Surface {hemi} hemisphere', bg_map=str(subj_sulc_file),
                                threshold=np.percentile(network_native, 75),axes=axes)

    plotting.plot_surf_stat_map(str(subj_surf_file), p_target, hemi=hemi,
                                             title=f'Surface {hemi} hemisphere',
                                            cmap='viridis',
                                             colorbar=True, bg_map=network_native,threshold=.1,axes=axes
                                ,output_file=p_target.replace('.nii', '.png'))

    plotting.plot_surf_contours(fsaverage['infl_' + hemi], all_ROIS, levels=[1, ], figure=figure, legend=True,
                                colors=['g', ],
                                labels=[hemi_ + '_ROIs'],
                                output_file=f'{sub_dti_dir}/{hemi_}_ROIs_{file_name}_{threshold}_fsavg.png')

    print(f'done plotting ROIs fsnative for {subj_id} and smoothing {n_smooth} \n')
    #
    print (f'done changing fsaverage surface to fsnative for {subj_id} \n')
    # binarize the image
    network_fsnative_img=nib.load(p_target)
    network_fsnative=np.asarray(network_fsnative_img.dataobj).flatten()
    network_fsnative_binary=np.ceil(network_fsnative)

    #
    ni_fsnative_bin_img = nib.Nifti1Image(np.reshape(network_fsnative_binary.astype(float), network_fsnative_img.shape),
                             header=network_fsnative_img._header, affine=network_fsnative_img.affine)
    p_target_binary=p_target.replace('fsnative_','fsnative_binary_')
    nib.nifti1.save(ni_fsnative_bin_img, p_target_binary)
    print('done binarizing fsnative\n')

    figure = plotting.plot_surf_stat_map(str(subj_surf_file), p_target_binary,
                                         hemi=hemi,title=f'Surface {hemi} hemisphere',
                                         colorbar=True, bg_map=str(subj_sulc_file), threshold=.1,
                                         output_file=p_target_binary.replace('.nii', '.png'))


    plotting.plot_surf_roi(fsaverage['infl_left'], roi_map=sub_parcel_roi_vxl,
                           hemi='left', view='lateral',
                           bg_map=fsaverage['sulc_left'], bg_on_data=True,
                           darkness=.5,output_file=f'{sub_dti_dir}/{hemi_}_ROIs_{file_name}_{threshold}_fsavg_.png')

    # finally plot based on roi
    p_target_ROI=f'{p_target_dir}/{hemi_.lower()}.{hemi_}_ROIs.label'
    test=nib.freesurfer.read_label(p_target_ROI)
    network_fsnative_ROI=np.zeros(network_fsnative_binary.shape)
    network_fsnative_ROI[test]=1

    figure=plotting.plot_surf_roi(str(subj_surf_file),network_fsnative_ROI,hemi=hemi,bg_map=str(subj_sulc_file),output_file=p_target_ROI.replace('.label','.png'))
    #####################################################################
    ## Part 3 : transforming native surface to volume for subject
    p_target_volume = str(p_target).replace('fsnative.nii', 'fsnative_volume.nii')
    #
    unix_pattern = ['mri_surf2vol',
                    '--o', p_target_volume,
                    '--subject', subj_id,
                    '--so', str(subj_surf_file).replace('.inflated','.pial'), p_target
                    ]
    output = subprocess.Popen(unix_pattern, env=my_env)
    # plot volume data
    subj_mgz_file=Path(subj_FS_path,subj_id,'mri','brain.mgz')
    figure = plotting.plot_stat_map(p_target_volume, str(subj_mgz_file),
                                         colorbar=True,
                                         output_file=p_target_volume.replace('.nii', '.png'))

