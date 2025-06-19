#!/bin/bash
# This wrapper script identifies subjects for TRACULA MNI to Diffusion transformation
# and submits jobs for those that need it.

# Set base directory
DTI_DIR=/mindhive/evlab/Shared/diffusionzeynep/

# --- Configuration for the job list file ---
JOB_LIST_NAME="subjects_for_tracula_transform"
SUBJECT_LIST_FILE="${DTI_DIR}/${JOB_LIST_NAME}.txt"
TRANSFORMATION_SCRIPT="run_tracula_vol_2_vol_subject.sh" # The script that does the work

# Overwrite flag: if "true", all non-bad subjects will be added to the list.
overwrite="false"

echo "Starting subject identification for TRACULA transformation."
echo "Job list will be created at: ${SUBJECT_LIST_FILE}"
if [ "$overwrite" = true ]; then
    echo "Mode: Overwrite is enabled. All valid subjects will be processed."
else
    echo "Mode: Checking for existing output before adding subjects."
fi

# --- Initialize the subject list file ---
# Clear previous file and add the header
printf "%s,%s\n" "row" "subject_name" > "$SUBJECT_LIST_FILE"
LINE_COUNT=0

# List of subjects to skip
bad_sub=(sub007 sub072 sub106 sub124 sub126 sub135 sub136 sub138 sub148 sub159 sub163 sub171 sub172 sub190 sub195 sub199 sub202 sub210 sub234 sub254 sub311 sub540 sub541)

# Define a representative transformed file to check for completion
CHECK_TRACT="lh.unc_AS_avg33_mni_bbr"
CHECK_SUFFIX="path.pd.in_orig.nii.gz"

# --- Iterate through subject directories ---
while read -r subject_dir; do
    subject_name=$(basename "$subject_dir")

    # Skip subjects in the bad list
    if [[ " ${bad_sub[@]} " =~ " ${subject_name} " ]]; then
        echo "Skipping bad subject: ${subject_name}"
        continue
    fi

    # Optional: Remove IsRunning.trac file if it exists
    file_to_remove="${DTI_DIR}/${subject_name}/trc/${subject_name}/scripts/IsRunning.trac"
    if [ -f "$file_to_remove" ]; then
        echo "Removing leftover IsRunning.trac file for ${subject_name}"
        rm "$file_to_remove"
    fi

    # --- Check if the transformation should be run ---
    SUBJECT_TRANSFORMED_CHECK_FILE="${DTI_DIR}/${subject_name}/trc/${subject_name}/dpath/${CHECK_TRACT}/${CHECK_SUFFIX}"
    add_subject=false

    if [ "$overwrite" = true ]; then
        add_subject=true
    elif [ ! -f "$SUBJECT_TRANSFORMED_CHECK_FILE" ]; then
        add_subject=true
        echo "Output not found for ${subject_name}. Adding to list."
    else
        echo "Output already exists for ${subject_name}. Skipping."
    fi

    if [ "$add_subject" = true ]; then
        LINE_COUNT=$((LINE_COUNT + 1))
        printf "%d,%s\n" "$LINE_COUNT" "$subject_name" >> "$SUBJECT_LIST_FILE"
    fi

done < <(find "$DTI_DIR" -maxdepth 1 -type d -name "sub*")

echo "-----------------------------------------------------"
echo "Finished checking all subjects."
echo "Total subjects to process: ${LINE_COUNT}"
echo "-----------------------------------------------------"

# --- Submit Jobs ---
if [ "$LINE_COUNT" -gt 0 ]; then
    echo "Submitting ${LINE_COUNT} jobs using ${TRANSFORMATION_SCRIPT}..."

    # Set batching parameters based on the number of jobs
    if [ "$LINE_COUNT" -lt 200 ]; then
        echo "Submitting all jobs at once."
        max_running=$LINE_COUNT
        max_queue=$LINE_COUNT
        batch_size=0
    else
        echo "Submitting in batches."
        max_running=175
        max_queue=200
        batch_size=25
    fi

    # submit-many-jobs <num_jobs> <max_running> <max_queue> <batch_size> <script> <args_for_script...>
    nohup /cm/shared/admin/bin/submit-many-jobs $LINE_COUNT $max_running $max_queue $batch_size $TRANSFORMATION_SCRIPT "$SUBJECT_LIST_FILE" &
    echo "Job submission command sent to background."
else
    echo "No subjects require transformation. No jobs submitted."
fi