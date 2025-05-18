#!/bin/bash
# This wrapper script identifies subjects for TRACULA MNI to Diffusion transformation
# based on the presence of the output files and submits jobs.

# Set base directories
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/
FS_DIR=/mindhive/evlab/u/Shared/SUBJECTS_FS/FS/ # This variable is not used in this script, keep if needed elsewhere

# Get threshold from argument (if used in submit-many-jobs)
threshold=$1 # This threshold variable is not used in the logic below, keep if needed

echo "Starting subject identification for TRACULA transformation..."

# --- Configuration for the job list file ---
# This file will list the subjects that need the transformation.
probtrackX_labels_="subjects_for_tracula_transform" # Name for the job list file
SUBJECT_TRX_FILE="${DTI_DIR}/${probtrackX_labels_}.txt"

# Clear and recreate the subject list file
rm -f "$SUBJECT_TRX_FILE"
touch "$SUBJECT_TRX_FILE"
# Add header row expected by the transformation script
printf "%s,%s\n" "row" "subject_name" >> "$SUBJECT_TRX_FILE"

LINE_COUNT=0 # Counter for subjects added to the list

# List of subjects to skip (based on your original script)
bad_sub=(sub007 sub072 sub106 sub124 sub126 sub135 sub136 sub138 sub148 sub159 sub163 sub171 sub172 sub190 sub195 sub199 sub202 sub210 sub234 sub254 sub311 sub540 sub541)

# --- Transformation completion check settings ---
# Define a representative transformed file to check for.
# If this file exists, we assume the transformation is done for this subject.
# This should match the naming convention used in the transformation script.
# Choose ONE tract to check. Example: lh.unc_AS_avg33 transformed to diff space.
CHECK_TRACT="lh.unc_AS_avg33" # Base name of one tract
CHECK_SUFFIX="_diff_bbr.nii.gz" # Suffix indicating the target space and format

# Set overwrite flag for THIS wrapper script (determines if the check is bypassed)
overwrite="true" # Set to "true" to force adding all non-bad subjects to the list

echo "Checking for existing transformed files using: ${CHECK_TRACT}${CHECK_SUFFIX} as the indicator."


# Find all subject directories
# Using read -r to handle spaces safely, though sub* names usually don't have them
while read -r subject_dir; do
    # Extract subject name from the full path
    # Removes the DTI_DIR prefix and any trailing slash
    subject_name=$(basename "$subject_dir")

    # Skip subjects in the bad list
    if [[ " ${bad_sub[@]} " =~ " ${subject_name} " ]]; then
      echo "Skipping bad subject: ${subject_name}"
      continue
    fi

    # Define the expected path to the check file for this subject
    SUBJECT_TRANSFORMED_CHECK_FILE="${DTI_DIR}/${subject_name}/trc/${subject_name}/dpath/${CHECK_TRACT}${CHECK_SUFFIX}"

    # --- Check if the transformation is already done for this subject ---
    if [ "$overwrite" = true ]; then
        # If overwrite is true in the wrapper, add the subject regardless of existing output
        echo "Overwrite is true. Adding ${subject_name} to the list regardless of existing output."
        LINE_COUNT=$((LINE_COUNT + 1))
        printf "%d,%s\n" "$LINE_COUNT" "$subject_name" >> "$SUBJECT_TRX_FILE"
    else
        # If overwrite is false, check if the expected transformed file exists
        if [ ! -f "$SUBJECT_TRANSFORMED_CHECK_FILE" ]; then
            # If the transformed file is NOT found, add the subject to the list
            echo "Transformed file not found for ${subject_name}: ${SUBJECT_TRANSFORMED_CHECK_FILE}"
            echo "Adding ${subject_name} to the list for transformation."
            LINE_COUNT=$((LINE_COUNT + 1))
            printf "%d,%s\n" "$LINE_COUNT" "$subject_name" >> "$SUBJECT_TRX_FILE"
        else
            # If the transformed file IS found, skip this subject
            echo "Transformed file already exists for ${subject_name}: ${SUBJECT_TRANSFORMED_CHECK_FILE} - Skipping."
        fi
    fi

    # Optional: Remove the IsRunning.trac file if it exists (based on your original script)
    # This might be needed if previous trac-all runs were interrupted.
    file_to_remove="${DTI_DIR}/${subject_name}/trc/${subject_name}/scripts/IsRunning.trac"
    if [ -f "$file_to_remove" ]; then
        echo "Removing IsRunning.trac file: ${file_to_remove}"
        rm "$file_to_remove"
    fi

done < <(find "$DTI_DIR" -maxdepth 1 -type d -name "sub*")

echo "Finished checking all subject directories."
echo "Total subjects added to ${SUBJECT_TRX_FILE} for transformation: ${LINE_COUNT}"

# --- Setup for Calling the Transformation Script ---
# The script called here is the one that performs the actual MNI to Diffusion transformation
# for a single subject (the script we modified in the previous step).
# Make sure you have saved that transformation script (e.g., as run_tracula_transform_subject.sh)
# and update the variable below to match its actual name.
TRANSFORMATION_SCRIPT="run_tracula_mni2diff_subject.sh" # <-- **Change this to the actual name of your transformation script file**
echo $LINE_COUNT
run_val=0 # Submit jobs if at least this many subjects need processing (set to 1 to require at least one)
if [ "$LINE_COUNT" -gt "$run_val" ]; then
  echo "Submitting ${LINE_COUNT} transformation jobs using ${TRANSFORMATION_SCRIPT}..."
  # Use submit-many-jobs to launch the transformation script for each subject listed in $SUBJECT_TRX_FILE.
  # submit-many-jobs <num_jobs> <max_running> <max_queue> <args_to_script...> <script_name>
  # The transformation script expects the path to the subject list file ($SUBJECT_TRX_FILE) as its first argument.

  if [ "$LINE_COUNT" -lt 200 ]; then
     echo "Less than 200 jobs (${LINE_COUNT}). Submitting all jobs at once (up to max_running/max_queue limits)."
     # Assuming transformation script takes GRAND_FILE as $1
     # Pass the SUBJECT_TRX_FILE path as the argument to the transformation script.
     nohup /cm/shared/admin/bin/submit-many-jobs "$LINE_COUNT" "$LINE_COUNT" "$LINE_COUNT" "$SUBJECT_TRX_FILE" "$TRANSFORMATION_SCRIPT" &
  else
      echo "200 or more jobs (${LINE_COUNT}). Submitting in batches."
      # Assuming transformation script takes GRAND_FILE as $1
      # submit-many-jobs num_jobs max_running max_queue first_arg second_arg ... script_name
      # Adjust batching numbers (175, 200, 25) as appropriate for your cluster
      nohup /cm/shared/admin/bin/submit-many-jobs "$LINE_COUNT" 175 200 "$SUBJECT_TRX_FILE" "$TRANSFORMATION_SCRIPT" &
  fi
else
  echo "No subjects require transformation ($LINE_COUNT). No jobs submitted."
fi