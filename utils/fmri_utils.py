import nibabel as nib
import numpy as np
from os.path import join
from nilearn import plotting
from pathlib import Path
import getpass

if getpass.getuser()=='eghbalhosseini':
    subj_path='/Applications/freesurfer/subjects/'
    subj_FS_path = '/Applications/freesurfer/subjects/'
    HOME_DIR = '/mindhive/evlab/Shared/diffusionzeynep/'
elif getpass.getuser()=='ehoseini':
    subj_lang_path = '/mindhive/evlab/u/Shared/SUBJECTS_FS/'
    subj_FS_path='/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/'
    HOME_DIR='/mindhive/evlab/Shared/diffusionzeynep/'



SUBJECTDIR = '/mindhive/evlab/u/Shared/SUBJECTS_FS'
ROIDIR = '/mindhive/evlab/u/Shared/ROIS_Nov2020'
ROOTDIR = (Path('/om/user/ehoseini/MyData/fmri_DNN/') ).resolve()
OUTDIR = (Path(ROOTDIR /  'outputs')).resolve()
PLOTDIR = (Path(OUTDIR / 'plots')).resolve()

def load_nii_flat(file):
    return np.array(nib.load(file).dataobj).flatten()

def get_thresh(samples, thresh=90):
    # Get percentile value, and take all values that are above that
    return np.percentile(samples, np.int(thresh))

def get_3D_coords(shape):
    """Get 3D coordinates for the flattened voxel array (column to coordinate)
    Based on these coords, it is possible to create an empty brain matrix of shape [shape] and fill in values.
    """
    indices = []
    for idx in np.ndindex(shape):
        indices.append(np.array(idx))
    print('OBS: adding +1 for MATLAB')
    coords = (np.array(indices) + 1).astype(int)
    return coords

def get_3D_indices(mask):
    print('OBS: adding +1 for MATLAB')
    return (mask.nonzero()[0] + 1).astype(int).reshape((-1, 1))

def get_contrast_num(netw_of_interest):
    if netw_of_interest in ["lang", "md"]:
        contrast_num = 3
    elif netw_of_interest in ["dmn"]:
        contrast_num = 5 # fix vs H
    else:
        raise LookupError()
    return str(contrast_num).zfill(4)

def get_loc_FOLDER(netw_of_interest='lang'):
	if netw_of_interest == 'lang':
		parc = "firstlevel_langlocSN"
	elif netw_of_interest == 'md':
		parc = "firstlevel_MDloc_ips224"
	elif netw_of_interest == 'dmn':
		parc = "firstlevel_MDloc_ips224"
	elif netw_of_interest in ['aud', 'vis']:
		parc = None
	else:
		raise LookupError()
	return parc

def get_parc_PATH(netw_of_interest='lang'):
    if netw_of_interest == 'lang':
        parc = "Func_Lang_LHRH_SN220/allParcels_language.nii"
    elif netw_of_interest == 'md':
        parc = "Func_MD_LHRH_HE197_SYM/MDfuncparcels_Apr2017_sym_91x109x91.nii"
    elif netw_of_interest == 'dmn':
        parc = "Func_DMN_LHRH_EH197/allParcels_DMN_91x109x91.nii"
    elif netw_of_interest == 'aud':
        parc = "Anat_Audit_LHRH_MultAtlases/AuditoryfROIs_91x109x91.nii"
    elif netw_of_interest == 'vis':
        parc = "Anat_Occipital_LHRH_AAL_3v1/OccipROIs_AAL3v1.nii"
    else:
        raise LookupError()

    return f'{join(ROIDIR, parc)}'


def get_func_network(netw_of_interest='lang', firstlevel_UID='836_FED_20210308a_3T2_PL2017', plot=True):
    """
    Load predefined parcels and a first level contrast. Mask the first level contrast with parcels.

    :param network: str, which network to load
    :param firstlevel_UID: str, UID
    :return: The first level contrast masked with the predefined parcel, and the parcel mask
    """
    # PARCEL
    PATH_parc = get_parc_PATH(netw_of_interest)
    parc = np.rint(load_nii_flat(PATH_parc))
    if plot:
        plotting.plot_stat_map(PATH_parc, output_file=join(PLOTDIR, f'{PATH_parc.split("/")[-1][:-4]}.png'))

    # FIRST LEVEL
    FOLDER_loc = get_loc_FOLDER(netw_of_interest)
    PATH_loc = join(SUBJECTDIR, firstlevel_UID, FOLDER_loc)
    c_num = get_contrast_num(netw_of_interest)
    network = load_nii_flat(join(PATH_loc, f'spmT_{c_num}.nii'))
    if plot:
        plotting.plot_stat_map(join(PATH_loc, f'spmT_{c_num}.nii'),
                               output_file=join(PLOTDIR, f'{netw_of_interest}_spmT_{c_num}_{firstlevel_UID}.png'))

    # return the first level network where there is a parcel
    return network * (parc > 0), parc