#!/bin/bash

set -e

# check arguments
if [ $# -ne 2 ]; then
  echo "Error: expected 2 arguments: directory and base url" >&2
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
echo "[Info] $(date)" > log.txt
echo "[Info] Downloading data from $FILE_LIST_URL into $DIRECTORY" >> log.txt

# Check if filelist.txt already exists
if [ -f "filelist.txt" ]; then
  read -p "[?] The file 'filelist.txt' already exists. Do you want to overwrite it? (Y/n): " response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "[Info] Download aborted: 'filelist.txt' already exists." | tee -a log.txt
    exit 0
  fi
fi

# Create the 'data' and 'out' subdirectories or clear their contents
if [ -d "data" ]; then
  echo "[Info] Clearing contents of 'data' directory..." | tee -a log.txt
  rm -rf data/*
else
  mkdir data
fi

if [ -d "out" ]; then
  echo "[Info] Clearing contents of 'out' directory..." | tee -a log.txt
  rm -rf out/*
else
  mkdir out
fi

# Download the filelist.txt from the FILE_LIST_URL
if ! wget "$FILE_LIST_URL"; then
  echo "[Error] Failed to download 'filelist.txt' from '$FILE_LIST_URL'" &>> log.txt
  exit 1
fi

# Read the list of files from filelist.txt and download each one
while IFS= read -r file; do
  # Replace spaces with %20 in the filename
  encoded_file=$(echo "$file" | sed 's/ /%20/g')
  
  # Construct the full URL for the file
  FULL_FILE_URL="${BASE_URL}${encoded_file}"

  echo "[Info] Downloading file from $FULL_FILE_URL" >> log.txt
  if ! wget "$FULL_FILE_URL" -P data/; then
    echo "[Error] Failed to download '$file' from '$FULL_FILE_URL'" &>> log.txt
    continue
  fi
  echo "[Info] Downloaded file from $FULL_FILE_URL" >> log.txt

done < filelist.txt

echo "[Info] Program finished" >> log.txt
echo "[Info] $(date)" >> log.txt

rm -f filelist.txt