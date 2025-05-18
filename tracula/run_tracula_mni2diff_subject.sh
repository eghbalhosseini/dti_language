#!/bin/bash
#SBATCH -n 1 # one core
#SBATCH -t 8:00:00
#SBATCH --mem=10G
GRAND_FILE=$1
OVERWRITE='false' # or 'true'
#
# DTI_DIR variable is not strictly used in the core logic below,
# but keep it if needed elsewhere in your script.
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/

if [ -n "$SLURM_ARRAY_TASK_ID" ]; then
  JID=$SLURM_ARRAY_TASK_ID    # Taking the task ID in a job array as an input parameter.
else
  JID=$2       # Taking the task ID as an input parameter.
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

# Check if a subject was found
if [ -z "$SUBJ" ]; then
    echo "Error: Subject not found for JID $JID in ${GRAND_FILE}"
    exit 1
fi

echo "Processing subject: ${SUBJ}"

HOMEDIR=/mindhive/evlab/Shared/diffusionzeynep/
SUBJECT_TRACULA_DIR="${HOMEDIR}/${SUBJ}/trc/${SUBJ}" # Base TRACULA output for the subject
XFMS_DIR="${SUBJECT_TRACULA_DIR}/dmri/xfms"
MNI_TO_DIFF_MAT="${XFMS_DIR}/mni2diff.bbr.mat"

# Define a reference image in the target (corrected diffusion) space
# Using the diffusion brain mask as a reference is usually robust
DIFF_REF_IMAGE="${SUBJECT_TRACULA_DIR}/dlabel/diff/aparc+aseg_mask.bbr.nii.gz"

# --- Load necessary modules ---
# Ensure these match your system's module names and paths
module add openmind/freesurfer
module add openmind/fsl/5.0.6
# module add openmind/miniconda/3.18.3-python2 # Only if needed for other parts not shown

# Check if required directories and matrix exist
if [ ! -d "$SUBJECT_TRACULA_DIR" ]; then
    echo "Error: Subject TRACULA directory not found: $SUBJECT_TRACULA_DIR"
    exit 1
fi
if [ ! -d "$XFMS_DIR" ]; then
    echo "Error: xfms directory not found: $XFMS_DIR"
    exit 1
fi
if [ ! -f "$MNI_TO_DIFF_MAT" ]; then
    echo "Error: MNI to Diff matrix not found: $MNI_TO_DIFF_MAT"
    # Check if the inverse (diff to MNI) exists - might need to create mni2diff.mat
    if [ -f "${XFMS_DIR}/diff2mni.bbr.mat" ]; then
        echo "Found diff2mni.bbr.mat. You may need to manually invert it to create mni2diff.bbr.mat."
    fi
    exit 1
fi
if [ ! -f "$DIFF_REF_IMAGE" ]; then
    echo "Error: Diffusion reference image not found: $DIFF_REF_IMAGE"
    echo "Cannot define output space grid without a reference. Check trac-all output."
    exit 1
fi


# --- Optional: Run trac-all -path if not already done ---
# Comment out the line below if you are SURE trac-all -path has completed successfully
# trac-all -path -c ${CONFIG_FILE}
# Check if the -path step completed successfully before proceeding
# You might want a more robust check based on log file contents or expected output files

echo "Starting transformation of TRACULA tracts from MNI to Diffusion space..."

# List of tract base names (without hemisphere or space suffix)
# Add/remove tracts here as needed based on your TRACULA atlas
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

# Loop through each hemisphere and tract
HEMISPHERES=("lh" "rh")

for TRACT_BASE in "${TRACT_LIST[@]}"; do
  # Handle midline tracts (fmajor, fminor) which don't have hemisphere prefix
  if [[ "$TRACT_BASE" == "fmajor_PP_avg33" || "$TRACT_BASE" == "fminor_PP_avg33" ]]; then
      HEMI_PREFIX=""
      INPUT_TRACT_DIR="${SUBJECT_TRACULA_DIR}/dpath/${TRACT_BASE}_mni_bbr"
      INPUT_FILE="${INPUT_TRACT_DIR}/path.pd.nii.gz" # Assuming this is the MNI volume
      OUTPUT_FILE="${SUBJECT_TRACULA_DIR}/dpath/${TRACT_BASE}_diff_bbr.nii.gz" # Output in diffusion space
  else
      # Handle hemispheric tracts
      for HEMI in "${HEMISPHERES[@]}"; do
          HEMI_PREFIX="${HEMI}."
          INPUT_TRACT_DIR="${SUBJECT_TRACULA_DIR}/dpath/${HEMI_PREFIX}${TRACT_BASE}_mni_bbr"
          INPUT_FILE="${INPUT_TRACT_DIR}/path.pd.nii.gz" # Assuming this is the MNI volume
          OUTPUT_FILE="${SUBJECT_TRACULA_DIR}/dpath/${HEMI_PREFIX}${TRACT_BASE}_diff_bbr.nii.gz" # Output in diffusion space

          # Check if input file exists for this hemisphere/tract
          if [ ! -f "$INPUT_FILE" ]; then
              echo "Warning: Input file not found for ${HEMI_PREFIX}${TRACT_BASE}: $INPUT_FILE - Skipping."
              continue # Skip to the next hemisphere/tract
          fi

          # Check if output file exists and if not overwriting
          if [ -f "$OUTPUT_FILE" ] && [ "$OVERWRITE" != "true" ]; then
              echo "Output file already exists for ${HEMI_PREFIX}${TRACT_BASE}: $OUTPUT_FILE - Skipping."
              continue # Skip to the next hemisphere/tract
          fi

          echo "Transforming ${HEMI_PREFIX}${TRACT_BASE} from MNI to Diffusion space..."
          echo "Input: $INPUT_FILE"
          echo "Output: $OUTPUT_FILE"
          echo "Reference: $DIFF_REF_IMAGE"
          echo "Matrix: $MNI_TO_DIFF_MAT"

          # Use FSL's applywarp to apply the affine transformation
          # --ref specifies the target space's reference image
          # --in specifies the input image (MNI space)
          # --out specifies the output image (Diffusion space)
          # --premat specifies the affine matrix to apply BEFORE the warp field (we only have a matrix)
          # --interp specifies interpolation (e.g., nearest, linear, cubic)
          # For probability maps/masks, nearest neighbor or linear are common.
          # Nearest neighbor is good if you want to preserve discrete values or mask boundaries.
          # Linear is better for smoother interpolation if values are continuous probabilities.
          # Choose based on the nature of path.nii.gz
          applywarp --ref="$DIFF_REF_IMAGE" \
                    --in="$INPUT_FILE" \
                    --out="$OUTPUT_FILE" \
                    --premat="$MNI_TO_DIFF_MAT" \
                    --interp=trilinear # Or nearest neighbor depending on path.nii.gz content


          if [ $? -eq 0 ]; then
              echo "Successfully transformed ${HEMI_PREFIX}${TRACT_BASE}."
          else
              echo "Error transforming ${HEMI_PREFIX}${TRACT_BASE}."
              # Optionally, add exit 1 here if you want the job to fail on the first error
          fi

      done # End hemisphere loop
  fi # End midline tract check
done # End tract list loop

echo "Transformation script finished for subject ${SUBJ}."