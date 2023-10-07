#!/bin/bash

# Initialize variables
data_dir=""
use_testing_set=false

# Parse command line options
while getopts ":t" opt; do
  case $opt in
    t)
      use_testing_set=true
      echo "Using testing set."
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Shift command line options to access the directory argument
shift $((OPTIND-1))

# Check if a directory argument is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 [-t] <directory>"
  exit 1
fi

# Assign the directory argument
data_dir="$1"
echo "Data directory: $data_dir"

# Check if the directory exists
if [ ! -d "$data_dir" ]; then
  echo "Error: Directory '$data_dir' does not exist."
  exit 1
fi

# Determine the list of files to process based on the -t flag
if [ "$use_testing_set" = true ]; then
  # Use filter.sh output and prepend the data directory path
  echo "Using testing set files."
  files_to_process=($(./filter.sh "$data_dir" | sed 's/^/'"$data_dir"'\/data\//'))
else
  # Use all .csv files in the data/ directory
  echo "Using all .csv files in the data/ directory."
  files_to_process=("$data_dir"/data/*.csv)
fi

# Create the output directory if it doesn't exist
output_dir="$data_dir/out"
mkdir -p "$output_dir"
echo "Output directory: $output_dir"

for file in "${files_to_process[@]}"; do
    # Extract the route name from the file path
    route_name=$(basename "$file" .csv)

    # Use awk to calculate the mean duration (last column) from each CSV file with decimal values
    mean_duration_seconds=$(awk -F ',' 'NR > 1 {sum += $(NF-2) - $1; count++} END {if (count > 0) printf "%.1f", sum / count}' "$file")
    
    # Remove the decimal part by casting to an integer
    mean_duration_seconds_int=${mean_duration_seconds%.*}


    # Convert the mean duration to HOURS:MINUTES:SECONDS format
    hours=$((mean_duration_seconds_int / 3600))
    minutes=$(( (mean_duration_seconds_int % 3600) / 60 ))
    seconds=$((mean_duration_seconds_int % 60))

    # Format the mean duration as HOURS:MINUTES:SECONDS, ignoring milliseconds
    formatted_mean_duration=$(printf "%02d:%02d:%02d" "$hours" "$minutes" "$seconds")
    
    # Print the result
    echo "Mean duration for route '$route_name': $formatted_mean_duration"
done

# Print completion message
# echo "Processing complete. Results are stored in $output_dir/duration.csv and $output_dir/engine.csv."
