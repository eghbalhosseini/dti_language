#!/bin/bash
#SBATCH -n 1 # one core
#SBATCH -t 8:00:00
#SBATCH --mem=10G

GRAND_FILE=$1
OVERWRITE='true' # or 'true'

if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
  JID=$SLURM_ARRAY_TASK_ID
else
  JID=$2
fi

echo "Processing GRAND_FILE: ${GRAND_FILE} for Job ID: $JID"

SUBJ=$(awk -F, -v jid="$JID" 'gsub(/ /, "", $1) == jid {gsub(/ /, "", $2); print $2; exit}' "${GRAND_FILE}")

if [ -z "$SUBJ" ]; then
    echo "Error: Subject not found for JID $JID in ${GRAND_FILE}"
    exit 1
fi

echo "Processing subject: ${SUBJ}"

HOMEDIR=/mindhive/evlab/Shared/diffusionzeynep/
SUBJECT_TRACULA_DIR="${HOMEDIR}/${SUBJ}/trc/${SUBJ}"
SUBJECT_FS_DIR="${HOMEDIR}/${SUBJ}/fs/"
XFMS_DIR="${SUBJECT_TRACULA_DIR}/dmri/xfms"
anatorig2diff_dat="${XFMS_DIR}/anatorig2diff.bbr.dat"
FS_file="${SUBJECT_FS_DIR}/mri/brain.mgz"

# --- Load necessary modules ---
module add openmind/freesurfer
module add openmind/fsl/5.0.6

# --- Check for essential files and directories ---
for item in "$SUBJECT_TRACULA_DIR" "$XFMS_DIR" "$anatorig2diff_dat" "$FS_file"; do
    if [ ! -e "$item" ]; then
        echo "Error: Required file or directory not found: $item"
        exit 1
    fi
done

echo "Starting mri_vol2vol transformation..."

TRACT_LIST=(
  "fmajor_PP_avg33" "fminor_PP_avg33" "atr_PP_avg33" "cab_PP_avg33"
  "ccg_PP_avg33" "cst_AS_avg33" "ilf_AS_avg33" "slfp_PP_avg33"
  "slft_PP_avg33" "unc_AS_avg33"
)
HEMISPHERES=("lh" "rh")

for TRACT_BASE in "${TRACT_LIST[@]}"; do
    if [[ "$TRACT_BASE" == "fmajor_PP_avg33" || "$TRACT_BASE" == "fminor_PP_avg33" ]]; then
        HEMI_LOOP=("none") # A trick to loop once for midline tracts
    else
        HEMI_LOOP=("${HEMISPHERES[@]}")
    fi

    for HEMI in "${HEMI_LOOP[@]}"; do
        if [ "$HEMI" == "none" ]; then
            TRACT_NAME="${TRACT_BASE}"
            INPUT_TRACT_DIR="${SUBJECT_TRACULA_DIR}/dpath/${TRACT_NAME}_mni_bbr"
        else
            TRACT_NAME="${HEMI}.${TRACT_BASE}"
            INPUT_TRACT_DIR="${SUBJECT_TRACULA_DIR}/dpath/${TRACT_NAME}_mni_bbr"
        fi

        INPUT_FILE="${INPUT_TRACT_DIR}/path.pd.nii.gz"
        OUTPUT_FILE="${INPUT_TRACT_DIR}/path.pd.in_orig.nii.gz"

        if [ ! -f "$INPUT_FILE" ]; then
            echo "Warning: Input file not found for ${TRACT_NAME}: $INPUT_FILE - Skipping."
            continue
        fi

        if [ -f "$OUTPUT_FILE" ] && [ "$OVERWRITE" != "true" ]; then
            echo "Output file already exists for ${TRACT_NAME}: $OUTPUT_FILE - Skipping."
            continue
        fi

        echo "Transforming: ${TRACT_NAME}"

        mri_vol2vol \
            --mov "$INPUT_FILE" \
            --targ "$FS_file" \
            --interp nearest \
            --reg "$anatorig2diff_dat" --no-save-reg \
            --o "$OUTPUT_FILE"

    done # End hemisphere loop
done # End tract list loop

echo "Transformation script finished for subject ${SUBJ}."