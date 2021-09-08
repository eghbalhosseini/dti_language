import numpy as np
from regfusion import vol_to_fsaverage
import glob
import os
path_to_masks='/Users/eghbalhosseini/Desktop/ROIS_NOV2020/Func_Lang_LHRH_SN220/'
import nibabel as nib
import nilearn.plotting as plotting
from nilearn import datasets
import fnmatch

d_parcel_name_map = {
    'lang':
        {'1': 'LH_IFGorb','2': 'LH_IFG','3': 'LH_MFG','4': 'LH_AntTemp','5': 'LH_PostTemp','6': 'LH_AngG',
         '7': 'RH_IFGorb','8': 'RH_IFG','9': 'RH_MFG','10': 'RH_AntTemp','11': 'RH_PostTemp','12': 'RH_AngG',
         },
    'md':
        {'1': 'LH_postParietal','2': 'LH_midParietal','3': 'LH_antParietal','4': 'LH_supFrontal',
         '5': 'LH_Precentral_A_precG','6': 'LH_Precentral_B_IFGop','7': 'LH_midFrontal','8': 'LH_midFrontalOrb',
         '9': 'LH_insula','10': 'LH_medialFrontal','11': 'RH_postParietal','12': 'RH_midParietal',
         '13': 'RH_antParietal','14': 'RH_supFrontal','15': 'RH_Precentral_A_precG','16': 'RH_Precentral_B_IFGop',
         '17': 'RH_midFrontal','18': 'RH_midFrontalOrb','19': 'RH_insula','20': 'RH_medialFrontal'},
    'dmn':
        {'1':"LH_FrontalMed",'2':"LH_PostCing",'3':"LH_TPJ",'4':"LH_MidCing",
         '5':"LH_STGorInsula",'6':"LH_AntTemp",'7':"RH_FrontalMed",'8':"RH_PostCing",
         '9':"RH_TPJ",'10':"RH_MidCing",'11':"RH_STGorInsula",'12':"RH_AntTemp"},
    'aud':
        {'1':'LH_ASTG','2':'LH_PP','3':'LH_PSTG','4':'LH_PT',
         '5':'RH_ASTG','6':'RH_PP','7':'RH_PSTG','8':'RH_PT',
         '9':'LH_TE11','10':'LH_TE12','11':'RH_TE11','12':'RH_TE12'},
    'vis':
        {'1':'Occipital_Sup_L','2':'Occipital_Sup_R','3':'Occipital_Mid_L',
         '4':'Occipital_Mid_R','5':'Occipital_Inf_L','6':'Occipital_Inf_R'}
}


# either construct or load parcels in

for ROI_file in os.listdir(os.path.join(path_to_masks,'language_separFiles')):
    if fnmatch.fnmatch(ROI_file,r'(\d)*.nii'):
        print(ROI_file)
def load_parcels_in_fsaverage():

    return 1
ROI_files=glob.glob(os.path.join(path_to_masks,'language_separFiles','*.nii'))
lh_list=[]
rh_list=[]
for ROI_file in  ROI_files:
    if ROI_file.__contains__('_RH_'):
        # find which network it is
        lh_del, rh = vol_to_fsaverage(ROI_file, os.path.join(path_to_masks,'language_separFiles_in_fsaverage'), interp='nearest', out_type='label.gii')
        rh_list.append(rh)
        os.remove(lh_del)
    elif ROI_file.__contains__('_LH_'):
        lh, rh_del = vol_to_fsaverage(ROI_file, os.path.join(path_to_masks,'language_separFiles_in_fsaverage'), interp='nearest', out_type='label.gii')
        lh_list.append(lh)
        os.remove(rh_del)

#
d_parcel_fsaverage=dict.fromkeys(list(d_parcel_name_map.keys()))
network_name='lang'
fsaverage = datasets.fetch_surf_fsaverage(mesh='fsaverage')
parc_to_srch=list(d_parcel_name_map[network_name].values())
lang_parc_dict=dict()
for ROI_file in os.listdir(os.path.join(path_to_masks,'language_separFiles_in_fsaverage')):
    if fnmatch.fnmatch(ROI_file,'*.gii'):
        # find which network it is
        print(ROI_file)
        parc_id=int(np.where(np.asarray([ROI_file.__contains__('_'+x+'.') for x in parc_to_srch]))[0])
        print(parc_to_srch[parc_id])
        parc_surf = nib.load(os.path.join(path_to_masks,'language_separFiles_in_fsaverage',ROI_file))
        lang_parc_dict[parc_to_srch[parc_id]]=np.asarray(parc_surf.agg_data())

lang_parc_dict['LH_ROIs']=np.sum(np.stack(list(lang_parc_dict.values()))[np.where([x.__contains__('LH') for x in lang_parc_dict.keys()])[0],:],axis=0)
lang_parc_dict['RH_ROIs']=np.sum(np.stack(list(lang_parc_dict.values()))[np.where([x.__contains__('RH') for x in lang_parc_dict.keys()])[0],:],axis=0)
lang_parc_dict['all_ROIs']=np.sum(np.stack(list(lang_parc_dict.values())),axis=0)

d_parcel_fsaverage[network_name]=lang_parc_dict


# plot them to make sure

for ROI_file in os.listdir(os.path.join(path_to_masks,'language_separFiles_in_fsaverage')):
    if ROI_file.__contains__('_LH_'):
        lh_surf= nib.load(os.path.join(path_to_masks,'language_separFiles_in_fsaverage',ROI_file))
        figure=plotting.plot_surf_stat_map(fsaverage.infl_left, lh_surf.agg_data(), hemi='left',
                                title='Surface left hemisphere', colorbar=True,
                                threshold=1., bg_map=fsaverage.sulc_left)
        plotting.plot_surf_contours(fsaverage.infl_left, lh_surf.agg_data(),
                                levels=[1, ], figure=figure, legend=False,
                                colors=['g', ],
                                output_file=os.path.join(path_to_masks,'language_separFiles_in_fsaverage',ROI_file.replace('.gii','.png')))
    elif ROI_file.__contains__('_RH_'):
        rh_surf= nib.load(os.path.join(path_to_masks,'language_separFiles_in_fsaverage',ROI_file))
        figure=plotting.plot_surf_stat_map(fsaverage.infl_right, rh_surf.agg_data(), hemi='right',
                                title='Surface right hemisphere', colorbar=True,
                                threshold=1., bg_map=fsaverage.sulc_right)
        plotting.plot_surf_contours(fsaverage.infl_right, rh_surf.agg_data(),
                                levels=[1,], figure=figure, legend=False,
                                colors=['g',],
                                output_file=os.path.join(path_to_masks,'language_separFiles_in_fsaverage',ROI_file.replace('.gii','.png')))


