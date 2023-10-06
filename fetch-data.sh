#!/bin/bash

set -e

# check arguments
if [ $# -ne 2 ]; then
  echo "Error: expected 2 arguments" >&2
  exit
fi

# get values into easier to understand constants
DIRECTORY="$1"
BASE_URL="$2"

# Ensure that BASE_URL ends with a trailing /
if [[ ! "$BASE_URL" =~ /$ ]]; then
  BASE_URL="${BASE_URL}/"
fi

FILE_LIST_URL="${BASE_URL}filelist.txt"

# Check if the directory exists, and if not, create it
if [ ! -d "$DIRECTORY" ]; then
  mkdir -p "$DIRECTORY"
fi

cd "$DIRECTORY" || exit 1

# Check if filelist.txt already exists
if [ -f "filelist.txt" ]; then
  read -p "The file 'filelist.txt' already exists. Do you want to overwrite it? (Y/n): " response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Download aborted."
    exit 0
  fi
fi

# Create the 'data' and 'out' subdirectories or clear their contents
if [ -d "data" ]; then
  echo "Clearing contents of 'data' directory..."
  rm -rf data/*
else
  mkdir data
fi

if [ -d "out" ]; then
  echo "Clearing contents of 'out' directory..."
  rm -rf out/*
else
  mkdir out
fi

# Download the filelist.txt from the FILE_LIST_URL
if ! wget "$FILE_LIST_URL"; then
  echo "Error: Failed to download 'filelist.txt' from '$FILE_LIST_URL'" >&2
  exit 1
fi

# Read the list of files from filelist.txt and download each one
while IFS= read -r file; do
  # Replace spaces with %20 in the filename
  encoded_file=$(echo "$file" | sed 's/ /%20/g')
  
  # Construct the full URL for the file
  full_file_url="${BASE_URL}${encoded_file}"

  # Download the file to the 'data' directory
  if ! wget "$full_file_url" -P data/; then
    echo "Error: Failed to download '$file' from '$full_file_url'" >&2
  fi
done < filelist.txt

rm -f filelist.txt