#!/bin/bash

# Initialize success messages
CFS_output=""
CFD_output=""
PERMISSION_output=""
DELETE_output=""
FILE_REMOVED_output=""

# Execute the SCP command to copy file to slave
CFS=$(scp protegeadm@ncias-q1744-v:${file_storage_path} ${local_path} && ls -la ${local_path}/${FILE_PARAM})

# Check if the output is empty
if [ -z "$CFS" ]; then
    echo "File was not copied to Jenkins slave"
    exit 1
else 
    CFS_output="File ${FILE_PARAM} was successfully copied to Jenkins slave"
fi

# Execute the SCP command to copy file to remote server
scp ${local_path}/${FILE_PARAM} ${remote_user}@${remote}:${virtuoso_path}

# Check if the file exists at the copied location on the remote server
CFD=$(ssh ${remote_user}@${remote} "if [ -f ${virtuoso_path}/${FILE_PARAM} ]; then echo 'exists'; fi")

# Check if the output is empty
if [ "$CFD" != "exists" ]; then
    echo "File ${FILE_PARAM} was not copied to server ${remote}"
    rm -f ${local_path}/${FILE_PARAM}
    exit 1
else 
    CFD_output="File ${FILE_PARAM} was successfully copied to server ${remote}"
fi

# Remove file from the Jenkins slave
rm -f ${local_path}/${FILE_PARAM}

# Verify if the file was deleted from Jenkins slave
if [ ! -f ${local_path}/${FILE_PARAM} ]; then
    DELETE_output="File ${FILE_PARAM} was successfully deleted from Jenkins slave"
else
    echo "Failed to delete file ${FILE_PARAM} from Jenkins slave"
    exit 1
fi

# Change file permission on the remote server
ssh ${remote_user}@${remote} "chmod 644 ${virtuoso_path}/${FILE_PARAM}"

# Verify if the permission was changed
PERMISSION=$(ssh ${remote_user}@${remote} "stat -c %a ${virtuoso_path}/${FILE_PARAM}")

if [ "$PERMISSION" == "644" ]; then
    PERMISSION_output="File permissions for ${FILE_PARAM} were successfully changed to 644"
else
    echo "Failed to change file permissions for ${FILE_PARAM}"
    exit 1
fi

# Run the script on the remote server
ssh ${remote_user}@${remote} "${script_path} ${FILE_PARAM} ${project_path} owl"
RUNSCRIPT_STATUS=$?

# Check if the script ran successfully
if [ $RUNSCRIPT_STATUS -eq 0 ]; then
    RUNSCRIPT_output="Script load_graph.sh ran successfully"
else
    echo "Script load_graph.sh failed to run"
    exit 1
fi

# Check the last 3 lines of the log file for the word "successfully"
LOGCHECK=$(ssh ${remote_user}@${remote} "tail -3 ${log_path} | grep -c successfully")

if [ "$LOGCHECK" -eq 2 ]; then
    LOGCHECK_output="Log file shows successfully"
    ssh ${remote_user}@${remote} "rm -f ${virtuoso_path}/${FILE_PARAM}"
    FILE_REMOVED=$(ssh ${remote_user}@${remote} "[ ! -f ${virtuoso_path}/${FILE_PARAM} ] && echo 'file removed'")
    
    # Check if the file was removed from server
    if [ "$FILE_REMOVED" == "file removed" ]; then
        FILE_REMOVED_output="${FILE_PARAM} was removed from ${remote}"
    else 
        echo "${FILE_PARAM} was not removed from ${remote}"
        exit 1
    fi
else
    echo "ERROR - Log file was terminated"
    ssh ${remote_user}@${remote} "rm -f ${virtuoso_path}/${FILE_PARAM}"
    FILE_REMOVED=$(ssh ${remote_user}@${remote} "[ ! -f ${virtuoso_path}/${FILE_PARAM} ] && echo 'file removed'")
    
    # Check if the file was removed from server
    if [ "$FILE_REMOVED" == "file removed" ]; then
        FILE_REMOVED_output="${FILE_PARAM} was removed from ${remote}"
    else 
        echo "${FILE_PARAM} was not removed from ${remote}"
        exit 1
    fi
    exit 1
fi

# Print all success messages at the end
echo "${CFS_output}"
echo "${CFD_output}"
echo "${DELETE_output}"
echo "${PERMISSION_output}"
echo "${RUNSCRIPT_output}"
echo "${LOGCHECK_output}"
echo "${FILE_REMOVED_output}"
