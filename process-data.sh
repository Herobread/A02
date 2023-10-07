#!/bin/bash

# Initialize variables
data_dir=""
use_testing_set=false

# for loading spinner
i=1
sp="/-\|"

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

# Create the CSV file with headers
echo "route,duration" > "$output_dir/duration.csv"

echo -n "  Calculating mean time of travelling"

# Calculate mean time of travelling
for file in "${files_to_process[@]}"; do
    # Loading spinner to improve user expirience
    printf "\r${sp:i++%${#sp}:1}"

    # Extract the route name from the file path
    route_name=$(basename "$file" .csv)

    # calculate the mean duration from each CSV file with decimal values
    mean_duration_seconds=$(awk -F ',' 'NR > 1 {sum += $(NF-2) - $1; count++} END {if (count > 0) printf "%.1f", sum / count}' "$file")
    
    # Remove the decimal part by casting to an integer
    mean_duration_seconds_int=${mean_duration_seconds%.*}

    # Format the mean duration as HOURS:MINUTES:SECONDS, ignoring milliseconds using date
    formatted_mean_duration=$(date -u -d @$mean_duration_seconds_int +'%H:%M:%S')
    
    # Write the data to the CSV file
    echo "$route_name,$formatted_mean_duration" >> "$output_dir/duration.csv"
done

echo -ne "\rFinished calculating mean time of travelling\n"


# Create an associative array to store the total fuel for each vehicle_id
declare -A total_fuel

echo -n "  Calculating fuel usage"

# Calculating fuel usage
for file in "${files_to_process[@]}"; do
  # Loading spinner to improve user expirience
  printf "\r${sp:i++%${#sp}:1}"
  if [ -e "$file" ]; then
    # Use a flag to skip the first row (header)
    skip_header=true

    while IFS=',' read -r -a line; do
      if [ "$skip_header" = true ]; then
        skip_header=false
        continue
      fi

      # Extract the vehicle_id and fuel values
      vehicle_id="${line[-2]}"  
      fuel="${line[-1]}"        


      # Check if fuel is a numeric value
      if [[ "$fuel" =~ ^[0-9]+$ ]]; then
        # Check if the vehicle_id is already in the associative array
        if [ -n "${total_fuel[$vehicle_id]}" ]; then
          # Add the fuel value to the total
          total_fuel["$vehicle_id"]=$((total_fuel["$vehicle_id"] + fuel))
        else
          # Initialize the total fuel for this vehicle_id
          total_fuel["$vehicle_id"]=$fuel
        fi
      else
        echo "Skipping line with non-numeric fuel value: $fuel for $vehicle_id"
      fi
    done < "$file"
  else
    echo "File '$file' does not exist."
  fi
done

# Create the CSV file to store fuel usage data for every vehicle
echo "id,fuel" > "$output_dir/engine.csv"  # Header row

# Write the total fuel data to the CSV file
for vehicle_id in "${!total_fuel[@]}"; do
  echo "$vehicle_id,${total_fuel[$vehicle_id]}" >> "$output_dir/engine.csv"
done

echo -ne "\rFinished calculating fuel usage\n"

echo "Data has been written to '$output_dir/engine.csv' and '$output_dir/duration.csv'."
