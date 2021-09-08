import nibabel as nib

import nilearn as nil
from nilearn import datasets
import nilearn.plotting as plotting
import numpy as np
import os
import copy
fsaverage = datasets.fetch_surf_fsaverage(mesh='fsaverage')
# from utils.parcel_utils import d_parcel_fsaverage

sub_dir = '/Applications/freesurfer/subjects/sub190/bold/bold/bold.fsavg.sm4.lh.lang/S-v-N/'
network_id='fsig.nii.gz'
network = nib.load(os.path.join(sub_dir,network_id))

func_threshold = 90
netw_of_interest = 'lang'
hemi='LH'
hemi_='left'
#

parc_path = '/Users/eghbalhosseini/Desktop/ROIS_NOV2020/Func_Lang_LHRH_SN220/language_separFiles_in_fsaverage/lh.01_LH_IFGorb.avgMapping_allSub_RF_ANTs_MNI152_orig_to_fsaverage.label.gii'

parc_surf = np.rint(np.asarray(nib.load(parc_path).dataobj).flatten())

network_img = nib.load('/Applications/freesurfer/subjects/sub190/bold/bold/bold.fsavg.sm4.lh.lang/S-v-N/fsig.nii.gz')
network = np.asarray(network_img.dataobj).flatten()

mask_roi_all_netw = np.zeros(network.shape).astype(int)
# for storing masks for every ROI
mask_entire_netw = np.zeros(network.shape)  # for storing the entire network

sub_parcel_roi_vxl=np.zeros(network.shape).astype(int)
for ROI_name in d_parcel_name_map[netw_of_interest].values():
    if ROI_name.__contains__(hemi):

        roi_surf=d_parcel_fsaverage[netw_of_interest][ROI_name]
        samples=network[(roi_surf==1)  & ~(np.isnan(network))]
        samples_90 = np.percentile(samples, int(func_threshold))
        roi_voxels = ((roi_surf==1)) & (network >= samples_90)
        print(f'ROI name: {ROI_name}, number of voxels {np.sum(roi_voxels)}')
        figure = plotting.plot_surf_stat_map(fsaverage['infl_'+hemi_], roi_voxels.astype(int), hemi=hemi_,
                                             title=f'Surface {hemi_} hemisphere', colorbar=False,
                                             threshold=1., bg_map=fsaverage['sulc_'+hemi_])
        plotting.plot_surf_contours(fsaverage['infl_'+hemi_], roi_surf,levels=[1, ], figure=figure,
                                    legend=True,colors=['g', ], labels=[ROI_name],
                                    output_file=f'{sub_dir}/roi_{ROI_name}.png')


        sub_parcel_roi_vxl +=roi_voxels.astype(int)

# plot all voxels
all_ROIS=d_parcel_fsaverage[netw_of_interest][hemi+'_ROIs']
print(f'ROI name: {hemi}_ROIs, number of voxels {np.sum(sub_parcel_roi_vxl)}')
figure = plotting.plot_surf_stat_map(fsaverage['infl_'+hemi_], sub_parcel_roi_vxl.astype(int), hemi=hemi_,title=f'Surface {hemi_} hemisphere',
                                     colorbar=False,threshold=1., bg_map=fsaverage['sulc_'+hemi_])
plotting.plot_surf_contours(fsaverage['infl_'+hemi_], all_ROIS,levels=[1, ], figure=figure,legend=True,colors=['g', ],
                            labels=[hemi+'_ROIs'], output_file=f'{sub_dir}/roi_{hemi}_ROIs.png')



network_img

sub_parc=copy.deepcopy(parc_surf)
parc_surf.agg_data()
sub_parc.data

ni_img = nib.Nifti1Image(np.reshape(sub_parcel_roi_vxl.astype(float),network_img.shape),header=network_img._header,affine=network_img.affine )


nib.save(ni_img,os.path.join(sub_dir,hemi+'_ROIs_'+network_id))


for roi in np.unique(parc_surf):
    roi = int(roi)
    mask_roi_netw = np.zeros(network.shape)  # for storing masks for every ROI
    if roi > 0:
        roi_name = d_parcel_name_map[netw_of_interest][str(int(roi))]
        samples = network[(parc_surf == roi) & (~(np.isnan(network)))]
        samples_90 = np.percentile(samples, np.int(func_threshold))
        roi_voxels = (parc_surf == roi) & (network >= samples_90)
        print(f'ROI number: {roi}, number of voxels {np.sum(roi_voxels)}')
        plotting.plot_surf_stat_map('/Applications/freesurfer/subjects/fsaverage/surf/lh.inflated',
                                    ((parc_surf == roi)).astype(int), threshold=.1,
                                    output_file=f'{sub_dir}/roi_{roi}_mask.png')
        plotting.plot_surf_stat_map('/Applications/freesurfer/subjects/fsaverage/surf/lh.inflated',
                                    network * roi_voxels, threshold=.01, output_file=f'{sub_dir}/roi_{roi}.png')
        froi = network * roi_voxels
        froi = froi.reshape(network_img.shape)
        froi_image = nib.Nifti1Image(froi, network_img.affine)
        nib.save(froi_image, f'{sub_dir}/fsig_{roi_name}.nii.gz')
        mask_entire_netw += roi_voxels
        mask_roi_netw += roi_voxels
        mask_roi_all_netw += roi_voxels * roi

