import nibabel as nib
import nilearn as nil
from nilearn import datasets
import nilearn.plotting as plotting
import numpy as np
import os
import argparse
from utils.parcel_utils import d_parcel_fsaverage, d_parcel_name_map
from utils.fmri_utils import subj_path, subj_FS_path
fsaverage = datasets.fetch_surf_fsaverage(mesh='fsaverage')
from pathlib import Path


parser = argparse.ArgumentParser(description='find_subj_actvation_in_language_ROIs')
parser.add_argument('subj_id', type=str,default='sub190')
parser.add_argument('network_id',type=str,default='lang')
parser.add_argument('hemi',type=str,default='left')
parser.add_argument('threshold',type=int,default=90)
args=parser.parse_args()


if __name__ == '__main__':
    subj_id=args.subj_id
    network_id=args.network_id
    hemi=args.hemi
    if hemi=='left':
        hemi_='LH'
    else:
        hemi_='RH'
    threshold=args.threshold
    # load language signinifant voxels in fsaverge space
    functional_path='bold.fsavg.sm4.lh.lang/S-v-N'

    sub_func_dir=os.path.join(subj_path,subj_id,'bold',functional_path,'fsig.nii.gz')
    sub_dti_dir= os.path.join(subj_path,'DTI',subj_id,functional_path)
    Path(sub_dti_dir).mkdir(parents=True, exist_ok=True)
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
                                        output_file=f'{sub_dti_dir}/{ROI_name}_roi_{threshold}.png')

            sub_parcel_roi_vxl += roi_voxels.astype(int)

    # plot all ROIs
    all_ROIS = d_parcel_fsaverage[network_id][hemi_ + '_ROIs']
    print(f'ROI name: {hemi_}_ROIs, number of voxels {np.sum(sub_parcel_roi_vxl)}')
    figure = plotting.plot_surf_stat_map(fsaverage['infl_' + hemi], sub_parcel_roi_vxl.astype(int), hemi=hemi,
                                         title=f'Surface {hemi} hemisphere',
                                         colorbar=False, threshold=1., bg_map=fsaverage['sulc_' + hemi])
    plotting.plot_surf_contours(fsaverage['infl_' + hemi], all_ROIS, levels=[1, ], figure=figure, legend=True,
                                colors=['g', ],
                                labels=[hemi_ + '_ROIs'], output_file=f'{sub_dti_dir}/{hemi_}_ROIs_{threshold}.png')

