import numpy as np
from regfusion import vol_to_fsaverage
import glob
import os
import nibabel as nib
import nilearn.plotting as plotting
from nilearn import datasets
import pickle
import fnmatch
import getpass
import subprocess

def save_obj(di_, filename_):
    with open(filename_, 'wb') as f:
        pickle.dump(di_, f, protocol=4)

def load_obj(filename_, silent=False):
    if not silent:
        print('loading ' + filename_)
    with open(filename_, 'rb') as f:
        return pickle.load(f)

if getpass.getuser()=='eghbalhosseini':
    path_to_masks='/Users/eghbalhosseini/Desktop/ROIS_NOV2020/Func_Lang_LHRH_SN220/'
elif getpass.getuser() == 'ehoseini':
    path_to_masks = '/om/user/ehoseini/MyData/dti_language/ROIS_NOV2020/Func_Lang_LHRH_SN220/'



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




if os.path.isdir(os.path.join(path_to_masks,'language_separFiles_in_fsaverage')):
    d_parcel_fsaverage=load_obj(os.path.join(path_to_masks,'ROIS_in_fsaverge.pkl'))
else:
    # either construct or load parcels in
    ROI_files = glob.glob(os.path.join(path_to_masks, 'language_separFiles', '*.nii'))
    lh_list = []
    rh_list = []
    for ROI_file in ROI_files:
        if ROI_file.__contains__('_RH_'):
            # find which network it is
            lh_del, rh = vol_to_fsaverage(ROI_file, os.path.join(path_to_masks, 'language_separFiles_in_fsaverage'),
                                          interp='nearest', out_type='label.gii')
            rh_list.append(rh)
            os.remove(lh_del)
        elif ROI_file.__contains__('_LH_'):
            lh, rh_del = vol_to_fsaverage(ROI_file, os.path.join(path_to_masks, 'language_separFiles_in_fsaverage'),
                                          interp='nearest', out_type='label.gii')
            lh_list.append(lh)
            os.remove(rh_del)
    # creat d_parcel_fsaverage
    d_parcel_fsaverage = dict.fromkeys(list(d_parcel_name_map.keys()))
    network_name = 'lang'
    parc_to_srch = list(d_parcel_name_map[network_name].values())
    lang_parc_dict = dict()
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
    save_obj(d_parcel_fsaverage,os.path.join(path_to_masks,'ROIS_in_fsaverge.pkl'))
    do_plotting = False
    if do_plotting:
        fsaverage = datasets.fetch_surf_fsaverage(mesh='fsaverage')
        for ROI_file in os.listdir(os.path.join(path_to_masks, 'language_separFiles_in_fsaverage')):
            if ROI_file.__contains__('_LH_'):
                lh_surf = nib.load(os.path.join(path_to_masks, 'language_separFiles_in_fsaverage', ROI_file))
                figure = plotting.plot_surf_stat_map(fsaverage.infl_left, lh_surf.agg_data(), hemi='left',
                                                     title='Surface left hemisphere', colorbar=True,
                                                     threshold=1., bg_map=fsaverage.sulc_left)
                plotting.plot_surf_contours(fsaverage.infl_left, lh_surf.agg_data(),
                                            levels=[1, ], figure=figure, legend=False,
                                            colors=['g', ],
                                            output_file=os.path.join(path_to_masks, 'language_separFiles_in_fsaverage',
                                                                     ROI_file.replace('.gii', '.png')))
            elif ROI_file.__contains__('_RH_'):
                rh_surf = nib.load(os.path.join(path_to_masks, 'language_separFiles_in_fsaverage', ROI_file))
                figure = plotting.plot_surf_stat_map(fsaverage.infl_right, rh_surf.agg_data(), hemi='right',
                                                     title='Surface right hemisphere', colorbar=True,
                                                     threshold=1., bg_map=fsaverage.sulc_right)
                plotting.plot_surf_contours(fsaverage.infl_right, rh_surf.agg_data(),
                                            levels=[1, ], figure=figure, legend=False,
                                            colors=['g', ],
                                            output_file=os.path.join(path_to_masks, 'language_separFiles_in_fsaverage',
                                                                     ROI_file.replace('.gii', '.png')))

# register MNI parcels on MNI surface
parcel_file=glob.glob(os.path.join(path_to_masks, 'allParcels_language_79x95x69.nii'))

for hemi in ['lh','rh']:
    unix_pattern = ['mri_vol2surf',
                '--src',parcel_file[0],
                '--out',parcel_file[0].replace('.nii',f'_on_mni_surface_{hemi}.img'),
                '--hemi', hemi,
                '--regheader', 'cvs_avg35_inMNI152',
                '--surf', 'pial']
    output = subprocess.Popen(unix_pattern)
    output.communicate()


