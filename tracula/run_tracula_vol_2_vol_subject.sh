#!/bin/bash
#SBATCH -n 1 # one core
#SBATCH -t 8:00:00
#SBATCH --mem=10G
GRAND_FILE=$1
OVERWRITE='true' # or 'true'
# DTI_DIR variable is not strictly used in the core logic below,
# but keep it if needed elsewhere in your script.
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
JID=$SLURM_ARRAY_TASK_ID # Taking the task ID in a job array as an input parameter.
else
JID=$2 # Taking the task ID as an input parameter.
fi
echo "Processing GRAND_FILE: ${GRAND_FILE}"
echo "Job Array Task ID (JID): $JID"
SUBJ="" # Initialize subject name
while IFS=, read -r line_count subj_name ; do
# Remove leading/trailing whitespace from line_count and subj_name
line_count=$(echo "$line_count" | tr -d '[:space:]')
subj_name=$(echo "$subj_name" | tr -d '[:space:]')

if [ "$JID" == "$line_count" ]
then
echo "Found the right match: line_count=${line_count}, subj_name=${subj_name}"
SUBJ="$subj_name" # Use quotes for safety
do_run=true
break
else
do_run=false
fi
done <"${GRAND_FILE}"
if [ -z "$SUBJ" ]; then
echo "Error: Subject not found for JID $JID in ${GRAND_FILE}"
exit 1
fi
echo "Processing subject: ${SUBJ}"
HOMEDIR=/mindhive/evlab/Shared/diffusionzeynep/
SUBJECT_TRACULA_DIR="${HOMEDIR}/${SUBJ}/trc/${SUBJ}" # Base TRACULA output for the subject
SUBJECT_FS_DIR="${HOMEDIR}/${SUBJ}/fs/" # Base freesurfer dir
XFMS_DIR="${SUBJECT_TRACULA_DIR}/dmri/xfms"
anatorig2diff_dat="${XFMS_DIR}/anatorig2diff.bbr.dat"
DIFF_REF_IMAGE="${SUBJECT_TRACULA_DIR}/dmri/dtifit_FA.nii.gz"
# --- Load necessary modules ---

module add openmind/freesurfer

if [ ! -d "$SUBJECT_TRACULA_DIR" ]; then
echo "Error: Subject TRACULA directory not found: $SUBJECT_TRACULA_DIR"
exit 1
fi

echo "Starting transformation of TRACULA tracts from MNI to Diffusion space..."

TRACT_LIST=(
  "fmajor_PP_avg33"
  "fminor_PP_avg33"
  "atr_PP_avg33"
  "cab_PP_avg33"
  "ccg_PP_avg33"
  "cst_AS_avg33"
  "ilf_AS_avg33"
  "slfp_PP_avg33"
  "slft_PP_avg33"
  "unc_AS_avg33"
)
HEMISPHERES=("lh" "rh")

for TRACT_BASE in "${TRACT_LIST[@]}"; do
  # Handle midline tracts (fmajor, fminor) which don't have a hemisphere prefix
  if [[ "$TRACT_BASE" == "fmajor_PP_avg33" || "$TRACT_BASE" == "fminor_PP_avg33" ]]; then
    HEMI_PREFIX=""
    INPUT_TRACT_DIR="${SUBJECT_TRACULA_DIR}/dpath/${TRACT_BASE}_mni_bbr"
    INPUT_FILE="${INPUT_TRACT_DIR}/path.pd.nii.gz"
    OUTPUT_FILE="${INPUT_TRACT_DIR}/path.pd.in_orig.nii.gz"

    # --- Start of Block Moved into the 'if' statement ---
    # Check if input file exists
    if [ ! -f "$INPUT_FILE" ]; then
      echo "Warning: Input file not found for ${TRACT_BASE}: $INPUT_FILE - Skipping."
      continue # Skip to the next tract
    fi

    # Check if output file exists
    if [ -f "$OUTPUT_FILE" ] && [ "$OVERWRITE" != "true" ]; then
      echo "Output file already exists for ${TRACT_BASE}: $OUTPUT_FILE - Skipping."
      continue # Skip to the next tract
    fi

    echo "Transforming ${TRACT_BASE} from MNI to Diffusion space..."
    echo "Input: $INPUT_FILE"
    echo "Output: $OUTPUT_FILE"
    echo "Reference: $DIFF_REF_IMAGE"
    echo "Matrix: $MNI_TO_DIFF_MAT"

    FS_file="${SUBJECT_FS_DIR}/mri/brain.mgz"
    mri_vol2vol \
      --mov "$INPUT_FILE" \
      --targ "$FS_file" \
      --interp nearest \
      --reg "$anatorig2diff_dat" --no-save-reg \
      --o "$OUTPUT_FILE"
    # --- End of Moved Block ---

  else
    for HEMI in "${HEMISPHERES[@]}"; do
      HEMI_PREFIX="${HEMI}."
      INPUT_TRACT_DIR="${SUBJECT_TRACULA_DIR}/dpath/${HEMI_PREFIX}${TRACT_BASE}_mni_bbr"
      INPUT_FILE="${INPUT_TRACT_DIR}/path.pd.nii.gz"
      OUTPUT_FILE="${INPUT_TRACT_DIR}/path.pd.in_orig.nii.gz"

      # Check if input file exists for this hemisphere/tract
      if [ ! -f "$INPUT_FILE" ]; then
        echo "Warning: Input file not found for ${HEMI_PREFIX}${TRACT_BASE}: $INPUT_FILE - Skipping."
        continue # Skip to the next hemisphere/tract
      fi

      if [ -f "$OUTPUT_FILE" ] && [ "$OVERWRITE" != "true" ]; then
        echo "Output file already exists for ${HEMI_PREFIX}${TRACT_BASE}: $OUTPUT_FILE - Skipping."
        continue # Skip to the next hemisphere/tract
      fi

      echo "Transforming ${HEMI_PREFIX}${TRACT_BASE} from MNI to Diffusion space..."
      echo "Input: $INPUT_FILE"
      echo "Output: $OUTPUT_FILE"
      echo "Reference: $DIFF_REF_IMAGE"
      echo "Matrix: $MNI_TO_DIFF_MAT"

      FS_file="${SUBJECT_FS_DIR}/mri/brain.mgz"
      mri_vol2vol \
        --mov "$INPUT_FILE" \
        --targ "$FS_file" \
        --interp nearest \
        --reg "$anatorig2diff_dat" --no-save-reg \
        --o "$OUTPUT_FILE"
    done # End hemisphere loop
  fi # End midline tract check
done # End tract list loop