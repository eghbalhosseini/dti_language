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
import matplotlib.pyplot as plt
from glob import glob

parser = argparse.ArgumentParser(description='find_subj_actvation_in_language_ROIs')
parser.add_argument('subj_id', type=str)
parser.add_argument('network_id', type=str)#, default='lang')
parser.add_argument('threshold', type=int)
args=parser.parse_args()

if __name__ == '__main__':
    subj_id = args.subj_id
    #subj_id='sub721'
    network_id = args.network_id # 'lang'
    #network_id='lang'
    threshold=args.threshold
    #threshold= 20

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
            sub_parcel_roi_vxl = np.zeros(network.shape)
            sub_parcel_roi = np.zeros(network.shape).astype(int)
            hist_bins=np.linspace(min(network),max(network),100)
            # create an annotation file from the activation masks
            for ROI_name in d_parcel_name_map[network_id].values():
                if ROI_name.__contains__(hemis_[idx]):
                    roi_surf = d_parcel_fsaverage[network_id][ROI_name]
                    samples = network[(roi_surf == 1) & ~(np.isnan(network))]
                    if thr_type=='top':
                        samples_th = np.percentile(samples, int(100-threshold))
                        roi_voxels = np.multiply(network,np.logical_and(roi_surf == 1,network >= samples_th).astype('int'))
                    elif thr_type =='bottom':
                        samples_th = np.percentile(samples, int(threshold))
                        roi_voxels = ((roi_surf == 1)) & (network <= samples_th)
                        roi_voxels = np.multiply(network,
                                                 np.logical_and(roi_surf == 1, network <= samples_th).astype('int'))
                    else:
                        raise Exception('unknown thershold type')
                    print(f'ROI name: {ROI_name}, number of voxels {np.sum(roi_voxels>0)}')
                    plot_thr = np.min(list(set(roi_voxels) - {0.0}))
                    fig = plt.figure( figsize=[11, 8])
                    ax0 = fig.add_axes((.05,.1,.6,.7), projection='3d')
                    plotting.plot_surf_stat_map(surf_mesh=fsaverage['infl_' + hemi], stat_map=roi_voxels,hemi=hemi, view='lateral',
                                           cmap='hot',bg_map=network, bg_on_data=True, alpha=.5,darkness=.8,axes=ax0,threshold=plot_thr)
                    plotting.plot_surf_contours(fsaverage['infl_' + hemi], roi_surf, levels=[1, ], axes=ax0,
                                            legend=True, colors=['k', ], labels=[f'{ROI_name},  #vox: {np.sum(roi_voxels)}'])
                    ax1 = fig.add_axes((.65,.3,.3,.3))
                    ax1.hist(samples, bins=hist_bins, align='mid',edgecolor='k',linewidth=.5)
                    ax1.set_xlabel("voxel activation")
                    ax1.set_ylabel("Frequency")
                    ax1.axvline(x=samples_th,color='r',linewidth=1)


                    fig.savefig(f'{sub_dti_dir}/{subj_id}_{ROI_name}_roi_activations_{file_name}_{thr_type}_{threshold}_fsavg.png',facecolor=(1,1,1),edgecolor='none')
                    # save as fsavergae image file
                    roi_act=np.reshape(roi_voxels,network_img.dataobj.shape)
                    ro_act_img = nib.Nifti1Image(roi_act, network_img.affine,header=network_img.header)
                    sub_roi_act=f'{sub_dti_dir}/{ROI_name}_roi_act_{file_name}_{thr_type}_{threshold}_fsavg.nii.gz'
                    nib.save(ro_act_img,sub_roi_act)
                    # save individual annotation file and create label form them
                    sub_parcel_roi_vxl += roi_voxels
                    sub_parcel_roi += roi_surf
            # plot full ROI map
            figure = plotting.plot_surf_stat_map(surf_mesh=fsaverage['infl_' + hemi], stat_map=sub_parcel_roi_vxl,
                                            hemi=hemi, view='lateral', cmap='hot',bg_map=network, bg_on_data=True, alpha=.5,darkness=.8,
                                            title=f'num of voxels{sub_parcel_roi_vxl.sum()}',threshold=np.min(list(set(sub_parcel_roi_vxl)-{0.0})))

            plotting.plot_surf_contours(fsaverage['infl_' + hemi], sub_parcel_roi, levels=[1, ], figure=figure,
                                        legend=True, colors=['k', ], labels=[f'{hemis_[idx]} ROIs,  #vox: {sub_parcel_roi_vxl.sum()}'])
            figure.savefig(f'{sub_dti_dir}/{subj_id}_{hemis_[idx]}_all_ROIs_activations_{file_name}_{thr_type}_{threshold}_fsavg.png',
                           facecolor=(1, 1, 1), edgecolor='none')

            roi_act = np.reshape(sub_parcel_roi_vxl, network_img.dataobj.shape)
            ro_act_img = nib.Nifti1Image(roi_act, network_img.affine, header=network_img.header)
            sub_roi_act = f'{sub_dti_dir}/{subj_id}_{hemis_[idx]}_all_ROIs_activations_{file_name}_{thr_type}_{threshold}_fsavg.nii.gz'
            nib.save(ro_act_img, sub_roi_act)

    #####################################################################
    ## Part 2 : move surfaces from fsaverage to fsnative
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
                    assert Path(f'{sub_dti_dir}/{ROI_name}_roi_act_{file_name}_{thr_type}_{threshold}_fsavg.nii.gz').exists()

                    unix_pattern = ['mri_surf2surf',
                                    '--srcsubject', 'fsaverage','--hemi', hemis_[idx].lower(),'--trgsubject', subj_id,
                                    '--srcsurfval', f'{sub_dti_dir}/{ROI_name}_roi_act_{file_name}_{thr_type}_{threshold}_fsavg.nii.gz',
                                    '--trgsurfval', f'{sub_dti_native_dir}/{ROI_name}_roi_act_{file_name}_{thr_type}_{threshold}_fsavg.nii.gz'
                                    ]
                    output = subprocess.Popen(unix_pattern, env=my_env)
                    output.communicate()
                    #
                    fig, ax = plt.subplots(nrows=2, ncols=1,subplot_kw={'projection': '3d'},figsize=[8,11])
                    # plot fsaverage:
                    label_roi = nib.load(f'{sub_dti_dir}/{ROI_name}_roi_act_{file_name}_{thr_type}_{threshold}_fsavg.nii.gz')
                    network_fsaverage_ROI = np.asarray(label_roi.dataobj).flatten()


                    figure = plotting.plot_surf_stat_map(surf_mesh=fsaverage['infl_' + hemi], stat_map=network_fsaverage_ROI,
                                            hemi=hemi, view='lateral', cmap='hot',bg_map=network_fsavg, bg_on_data=True, alpha=.5,darkness=.8,
                                            title=f'num of voxels{network_fsaverage_ROI.sum()}',threshold=np.min(list(set(network_fsaverage_ROI)-{0.0})))
                    # plot fs native
                    label_file=f'{sub_dti_native_dir}/{ROI_name}_roi_act_{file_name}_{thr_type}_{threshold}_fsavg.nii.gz'
                    label_roi = nib.load(label_file)
                    roi_map = np.asarray(label_roi.dataobj).flatten()

                    plotting.plot_surf_stat_map(surf_mesh=str(subj_surf_file), stat_map=roi_map, hemi=hemi, view='lateral',
                                           cmap='hot',bg_map=str(subj_sulc_file), bg_on_data=False,alpha=0.5, darkness=.8, axes=ax[1],threshold=np.min(list(set(roi_map) - {0.0})))
                    fig.savefig(f'{sub_dti_native_dir}/{ROI_name}_roi_act_{file_name}_{thr_type}_{threshold}.png',edgecolor='none')
    #####################################################################
    # Part 3 : transforming native surface to volume for subject
    # 3.A combine ROI files to make a 1 surf file
    for thr_type in thr_types:
        for idx,hemi in enumerate(hemis):
                functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'
                functional_native_path = functional_path.replace('fsavg', 'self')
                sub_dti_dir = os.path.join(HOME_DIR, subj_id, 'fmri',
                                       functional_path.replace('lang', f'lang_thr_{threshold}'))
                sub_dti_native_dir = sub_dti_dir.replace('fsavg', 'fsnative')
                # remove previous file
                roi_sum_file = Path(f'{sub_dti_native_dir}/{hemis_[idx]}_lang_roi_act_{file_name}_{thr_type}_{threshold}.nii.gz')
                roi_sum_file.exists()
                roi_files=glob(f'{sub_dti_native_dir}/{hemis_[idx]}_*_roi_act_{file_name}_{thr_type}_{threshold}_fsavg.nii.gz')
                assert len(roi_files)==6
                roi_sum=[]
                for roi_file in roi_files:
                    roi_dat=nib.load(roi_file)
                    roi_sum.append(np.asarray(roi_dat.dataobj).flatten())
                roi_sum=np.stack(roi_sum).sum(axis=0).astype(float)
                ro_sum_img = nib.Nifti1Image(np.reshape(roi_sum,roi_dat.shape), roi_dat.affine, header=roi_dat.header)
                nib.save(ro_sum_img, roi_sum_file.__str__())
                subj_surf_file = Path(subj_FS_path, subj_id, 'surf', hemis_[idx].lower() + '.inflated')
                subj_sulc_file = Path(subj_FS_path, subj_id, 'surf', hemis_[idx].lower() + '.sulc')
                fig, ax = plt.subplots(nrows=1, ncols=1, subplot_kw={'projection': '3d'}, figsize=[8, 11])
                plotting.plot_surf_stat_map(surf_mesh=str(subj_surf_file), stat_map=roi_sum, hemi=hemi, view='lateral',
                                            cmap='hot', bg_map=str(subj_sulc_file), bg_on_data=False, alpha=0.5,
                                            darkness=.8, axes=ax, threshold=np.min(list(set(roi_sum) - {0.0})))
                fig.savefig(f'{sub_dti_native_dir}/{hemis_[idx]}_lang_roi_act_{file_name}_{thr_type}_{threshold}.png',
                            edgecolor='none')
                # prior_rois = glob(f'{subj_FS_path}/{subj_id}/label/*.{network_id}_roi_*.annot')

    # 3.B move from surface to volume
    for thr_type in thr_types:
        # delete any prior language rois
        #prior_rois = glob(f'{subj_FS_path}/{subj_id}/label/*.{network_id}_roi_*.annot')
        #[os.remove(roi_file) for roi_file in prior_rois]
        for idx, hemi in enumerate(hemis):
            functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'.replace('lang',f'lang_thr_{threshold}')
            sub_dti_dir = os.path.join(HOME_DIR, subj_id, 'fmri', functional_path)
            sub_dti_native_dir = sub_dti_dir.replace('fsavg', 'fsnative')
            subj_lang_roi_surf=f'{sub_dti_native_dir}/{hemis_[idx]}_lang_roi_act_{file_name}_{thr_type}_{threshold}.nii.gz'
            assert Path(subj_lang_roi_surf).exists()
            subj_orig_file = Path(subj_FS_path, subj_id, 'surf', hemis_[idx].lower() + '.orig')
            unix_pattern = ['mri_surf2vol','--hemi',hemis_[idx].lower(),
                    '--subject', subj_id,'--so',subj_orig_file.__str__(), subj_lang_roi_surf,
                    '--o', f'{str(Path(sub_dti_native_dir).parent.parent)}/x.fsnative.{hemis_[idx]}_{network_id}_roi_act_{thr_type}_{threshold}.nii.gz'
                    ]
            output = subprocess.Popen(unix_pattern, env=my_env)
            output.communicate()
        # do one output for both hemis
        idx=0
        functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'.replace('lang', f'lang_thr_{threshold}')
        sub_dti_dir = os.path.join(HOME_DIR, subj_id, 'fmri', functional_path)
        sub_dti_native_dir = sub_dti_dir.replace('fsavg', 'fsnative')
        subj_lh_lang_roi_surf = f'{sub_dti_native_dir}/{hemis_[idx]}_lang_roi_act_{file_name}_{thr_type}_{threshold}.nii.gz'
        assert Path(subj_lh_lang_roi_surf).exists()
        subj_lh_orig_file = Path(subj_FS_path, subj_id, 'surf', hemis_[idx].lower() + '.orig')
        idx=1
        functional_path = f'bold.fsavg.sm4.{hemis_[idx].lower()}.lang/S-v-N'.replace('lang', f'lang_thr_{threshold}')
        sub_dti_dir = os.path.join(HOME_DIR, subj_id, 'fmri', functional_path)
        sub_dti_native_dir = sub_dti_dir.replace('fsavg', 'fsnative')
        subj_rh_lang_roi_surf = f'{sub_dti_native_dir}/{hemis_[idx]}_lang_roi_act_{file_name}_{thr_type}_{threshold}.nii.gz'
        assert Path(subj_rh_lang_roi_surf).exists()
        subj_rh_orig_file = Path(subj_FS_path, subj_id, 'surf', hemis_[idx].lower() + '.orig')


        unix_pattern = ['mri_surf2vol',
                        '--subject', subj_id,
                        '--so', subj_lh_orig_file.__str__(), subj_lh_lang_roi_surf,
                        '--so',subj_rh_orig_file.__str__(), subj_rh_lang_roi_surf,
                        '--o',
                        f'{str(Path(sub_dti_native_dir).parent.parent)}/x.fsnative.{network_id}_roi_act_{thr_type}_{threshold}.nii.gz'
                        ]
        output = subprocess.Popen(unix_pattern, env=my_env)
        output.communicate()

    #####################################################
    # 4. transform to dti space

    dti_vol_file = f'{HOME_DIR}/{subj_id}/dti/nodif_brain.nii.gz'
    assert(Path(dti_vol_file).exists())
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
    # do mri_vol2vol
    # remove previous files
    # for prev_file in glob(f"{HOME_DIR}/{subj_id}/indti/*H_indti.nii.gz*"):
    #     print(f"removing the prior files!{prev_file}")
    #     os.remove(prev_file)
    # for prev_file in glob(f"{HOME_DIR}/{subj_id}/indti/*H-in-dti.nii.gz*"):
    #     print(f"removing the prior files!{prev_file}")
    #     os.remove(prev_file)

        # see : https://surfer.nmr.mgh.harvard.edu/fswiki/FsTutorial/Diffusion/DTIscripts
        #
    debug = False
    vol2vol_method = 'nearest'
    for thr_type in thr_types:
        for idx, hemi in enumerate(hemis):
            hemi_dti_file_pth = Path(f"{HOME_DIR}/{subj_id}/indti/lang_act_{hemis_[idx]}_{thr_type}_{threshold}_indti.nii.gz")
            hemi_dti_file_pth.parent.mkdir(parents=True, exist_ok=True)
            hemi_lang_act = Path(f"{HOME_DIR}/{subj_id}/fmri/x.fsnative.{hemis_[idx]}_{network_id}_roi_act_{thr_type}_{threshold}.nii.gz")
            assert lang_act.exists()

            unix_pattern = ['mri_vol2vol',
                            '--targ', hemi_lang_act.__str__(),
                            '--mov', dti_vol_file,
                            '--inv',  # moving from structural (targ) to dti (mov)
                            '--interp', vol2vol_method,
                            '--reg', reg_file_pth.__str__(),
                            '--o', hemi_dti_file_pth.__str__()]
            unix_str = ' '.join(unix_pattern)
            cmd = f'''
                        export SUBJECTS_DIR={subj_FS_path}
                        module list
                        echo $SUBJECTS_DIR
                        {unix_str}
                        '''
            subprocess.call(cmd, shell=True, executable='/bin/bash')
        # do it for combine version

        combine_dti_file_pth = Path(f"{HOME_DIR}/{subj_id}/indti/lang_act_BOTH_{thr_type}_{threshold}_indti.nii.gz")
        combine_dti_file_pth.parent.mkdir(parents=True, exist_ok=True)
        lang_act=Path(f"{HOME_DIR}/{subj_id}/fmri/x.fsnative.{network_id}_roi_act_{thr_type}_{threshold}.nii.gz")
        assert lang_act.exists()

        unix_pattern = ['mri_vol2vol',
                        '--targ', lang_act.__str__(),
                        '--mov', dti_vol_file,
                        '--inv',  # moving from structural (targ) to dti (mov)
                        '--interp', vol2vol_method,
                        '--reg', reg_file_pth.__str__(),
                        '--o', combine_dti_file_pth.__str__()]
        unix_str = ' '.join(unix_pattern)
        cmd = f'''
            export SUBJECTS_DIR={subj_FS_path}
            module list
            echo $SUBJECTS_DIR
            {unix_str}
            '''
        subprocess.call(cmd, shell=True, executable='/bin/bash')

