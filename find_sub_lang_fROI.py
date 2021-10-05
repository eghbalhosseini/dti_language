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


parser = argparse.ArgumentParser(description='find_subj_actvation_in_language_ROIs')
parser.add_argument('subj_id', type=str,default='sub190')
parser.add_argument('network_id',type=str,default='lang')
parser.add_argument('threshold',type=int,default=90)
args=parser.parse_args()


if __name__ == '__main__':
    #subj_id=args.subj_id
    subj_id='sub190'
    #network_id=args.network_id
    network_id='lang'
    #threshold = args.threshold
    threshold = 90
    file_name='fsig'
    my_env = os.environ.copy()
    my_env['SUBJECTS_DIR'] = subj_FS_path
    hemis_=['LH','RH']
    hemis=['left','right']
    # adding stuff for checking
    #####################################################################
    ## Part 1 : select voxels based on overlap with langauge parcels:
    # find language signinifant voxels in fsaverge space

    for idx, hemi in enumerate(hemis):
        functional_path=f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
        sub_func_dir=os.path.join(subj_path,subj_id,'bold',functional_path,file_name+'.nii.gz')
        sub_dti_dir= os.path.join(subj_path,'DTI',subj_id,functional_path)
        Path(sub_dti_dir).mkdir(parents=True, exist_ok=True)


        network_img=nib.load(sub_func_dir)
        network = np.asarray(network_img.dataobj).flatten()
        sub_parcel_roi_vxl = np.zeros(network.shape).astype(int)
        # create an annotation file from the activation masks
        for ROI_name in d_parcel_name_map[network_id].values():
            if ROI_name.__contains__(hemis_[idx]):
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
        sub_func_native_dir = os.path.join(subj_path, subj_id, 'bold', functional_native_path, file_name + '.nii.gz')
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
                             '--trgsurf', 'pial',
                             '--trglabel', f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi.label',
                             '--regmethod', 'surface']
                output = subprocess.Popen(unix_pattern, env=my_env)
                output.communicate()

        for ROI_name in d_parcel_name_map[network_id].values():
            if ROI_name.__contains__(hemis_[idx]):
            # plot labels and actvations to verify the tranformationed worked
                print(ROI_name)
                label_roi = nib.freesurfer.read_label(f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi.label')
                network_fsnative_ROI = np.zeros(network_native.shape)
                network_fsnative_ROI[label_roi] = 1
                plotting.plot_surf_roi(str(subj_surf_file), roi_map=network_fsnative_ROI,
                                           hemi=hemi, view='lateral', cmap='hot',
                                            bg_map=network_native, bg_on_data=True,
                                            darkness=1, output_file=f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi.png')

    #####################################################################
    # Part 3 : transforming native label to volume for subject
    # 3.A tranform labels to annoation first
    R_col=np.linspace(0,255,len(d_parcel_name_map[network_id].values()),dtype=int)
    G_col=np.flip(R_col)
    # breakdown the areas based on hemisphere
    for idx, hemi in enumerate(hemis):
        functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
        offset=2000+1000*idx
        sub_dti_dir = os.path.join(subj_path, 'DTI', subj_id, functional_path)
        p_target_dir = sub_dti_dir.replace('fsavg', 'fsnative')
        ROI_names=list(d_parcel_name_map[network_id].values())
        hemi_rois_idx=np.where([x.__contains__(hemis_[idx]) for x in ROI_names])[0]
        # create the ctab file
        txt_lines = ['#$Id: FreeSurferColorLUT.txt,v 1.38.2.1 2007/08/20 01:52:07 nicks Exp $',
                     '#No. Label Name:                            R   G   B   A',
                     f'{offset}   Unknown                                 0   0   0   0']
        for idy, y in enumerate(hemi_rois_idx):
            txt_lines.append(f'{idy+offset+1}   {ROI_names[y]}                                 {R_col[y]}   {G_col[y]}   0   1')
        textfile = open(f'{p_target_dir}/{hemis_[idx].lower()}_{network_id}_roi_ctab.txt', "w")
        for element in txt_lines:
            textfile.write(element + "\n")
        textfile.close()
        # create the unix pattern:
        unix_pattern = ['mris_label2annot',
                        '--s', subj_id,
                        '--h', hemis_[idx].lower(),
                        '--ctab', f'{p_target_dir}/{hemis_[idx].lower()}_{network_id}_roi_ctab.txt',
                        '--annot-path', f'{p_target_dir}/{hemis_[idx].lower()}.{network_id}_roi',
                        '--surf', 'pial',
                        '--offset',f'{offset}']
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

        copyfile(f'{p_target_dir}/{hemis_[idx].lower()}.{network_id}_roi.annot',
                 f'{subj_FS_path}/{subj_id}/label/{hemis_[idx].lower()}.{network_id}_roi.annot')

        unix_pattern = ['mri_aparc2aseg',
                    '--s', subj_id,
                    '--o', f'{p_target_dir}/{hemis_[idx].lower()}.{network_id}_roi.nii.gz',
                    '--annot', f'{network_id}_roi']
        output = subprocess.Popen(unix_pattern, env=my_env)
        output.communicate()

    #####################################################################
    ## Part 3 : transforming native label to volume for subject using label2vol method
    # unix_pattern = ['tkregister2',
    #                 '--mov',  f'{subj_FS_path}/{subj_id}/mri/rawavg.mgz',
    #                 '--noedit',
    #                 '--s', subj_id,
    #                 '--regheader',
    #                 '--reg',  f'{subj_FS_path}/{subj_id}/mri/label_register.dat'
    #                 ]
    # output = subprocess.Popen(unix_pattern, env=my_env)
    # output.communicate()
    #
    # # unix_pattern = ['mri_convert',
    # #                 f'{subj_FS_path}/{subj_id}/mri/rawavg.mgz',
    # #                 f'{subj_FS_path}/{subj_id}/mri/rawavg.nii.gz'
    # #                 ]
    # # output = subprocess.Popen(unix_pattern, env=my_env)
    # #  output.communicate()
    #
    # fill_thr=.1
    #
    # for idx, hemi in enumerate(hemis):
    #     functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
    #     sub_dti_dir = os.path.join(subj_path, 'DTI', subj_id, functional_path)
    #     p_target_dir = sub_dti_dir.replace('fsavg', 'fsnative')
    #     for ROI_name in d_parcel_name_map[network_id].values():
    #         if ROI_name.__contains__(hemis_[idx]):
    #             unix_pattern = ['mri_label2vol',
    #                         '--label', f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi.label',
    #                          '--subject', subj_id,
    #                             '--hemi', hemis_[idx].lower(),
    #                             #'--fillthresh',f'{fill_thr}',
    #                             '--proj', 'frac', '0','1','.01',
    #                         '--reg', f'{subj_FS_path}/{subj_id}/mri/label_register.dat',
    #                         '--temp', f'{subj_FS_path}/{subj_id}/mri/rawavg.mgz',
    #                         '--o', f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi.nii.gz'
    #                          ]
    #             output = subprocess.Popen(unix_pattern, env=my_env)
    #             output.communicate()
    #             plotting.plot_stat_map(f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi.nii.gz',
    #                                    bg_img=f'{subj_FS_path}/{subj_id}/mri/rawavg.nii.gz',draw_cross=False,
    #                                    output_file=f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi_in_vol.png')
    #             # binarize
    #             unix_pattern = ['mri_binarize',
    #                             '--dilate', '1',
    #                             '--erode', '1',
    #                             '--i', f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi.nii.gz',
    #                             '--o', f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi_bin.nii.gz',
    #                             '--min','1']
    #             output = subprocess.Popen(unix_pattern, env=my_env)
    #             output.communicate()
    #
    #             plotting.plot_stat_map(f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi_bin.nii.gz',
    #                                    bg_img=f'{subj_FS_path}/{subj_id}/mri/rawavg.nii.gz',draw_cross=False,
    #                                    output_file=f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi_in_vol_bin.png')
    #             # ribbonize!

                # unix_pattern = ['mris_calc',
                #                 '-o', f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi_bin_rib.nii.gz',
                #                 f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi_bin.nii.gz',
                #                 'mul',
                #                 f'{subj_FS_path}/{subj_id}/mri/{hemis_[idx].lower()}.ribbon.mgz']
                # output = subprocess.Popen(unix_pattern, env=my_env)
                # output.communicate()
                #
                # plotting.plot_stat_map(f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi_bin_rib.nii.gz',
                #                        bg_img=f'{subj_FS_path}/{subj_id}/mri/rawavg.nii.gz',
                #                        output_file=f'{p_target_dir}/{hemis_[idx].lower()}.{ROI_name}_roi_in_vol_bin_rib.png')
                #
