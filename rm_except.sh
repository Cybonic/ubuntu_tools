#!/bin/bash

# Check if the number of arguments is correct
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <pattern> <target_path>"
    exit 1
fi

pattern="$2"
target_path="$1"

# Check if the target path exists
if [ ! -d "$target_path" ]; then
    echo "Error: Target path '$target_path' does not exist."
    exit 1
fi

# Change directory to the target path
cd "$target_path" || exit

# Get a list of folders in the target directory
folders=$(find . -maxdepth 1 -type d -printf "%f\n")

# Loop through the folders
for folder in $folders; do
    # Check if the folder does not match the pattern
    if ! [[ "$folder" =~ $pattern ]]; then
        # Delete the folder
        echo "Deleting $folder..."
        rm -rf "$folder"
    fi
done

echo "Deletion complete."
