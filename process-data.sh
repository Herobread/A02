#!/bin/bash

# Initialize variables
DATA_DIR=""
USE_TESTING_SET=false

# for loading spinner
i=1
sp="/-\|"

# Parse command line options
while getopts ":t" opt; do
  case $opt in
  t)
    USE_TESTING_SET=true
    echo "Using testing set."
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    exit 1
    ;;
  esac
done

# Shift command line options to access the directory argument
shift $((OPTIND - 1))

# Check if a directory argument is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 [-t] <directory>"
  exit 1
fi

DATA_DIR="$1"
echo "Data directory: $DATA_DIR"

# Check if the directory exists
if [ ! -d "$DATA_DIR" ]; then
  echo "Error: Directory '$DATA_DIR' does not exist."
  exit 1
fi

# Determine the list of files to process based on the -t flag
if [ "$USE_TESTING_SET" = true ]; then
  # Use filter.sh output and prepend the data directory path
  echo "Using testing set files."
  FILES_TO_PROCESS=($(./filter.sh "$DATA_DIR" | sed 's/^/'"$DATA_DIR"'\/data\//'))
else
  # Use all .csv files in the data/ directory
  echo "Using all .csv files in the data/ directory."
  FILES_TO_PROCESS=("$DATA_DIR"/data/*.csv)
fi

# Create the output directory if it doesn't exist
OUTPUT_DIR="$DATA_DIR/out"
mkdir -p "$OUTPUT_DIR"
echo "Output directory: $OUTPUT_DIR"

# Create the CSV file with headers
echo "route,duration" >"$OUTPUT_DIR/duration.csv"

echo -n "  Calculating mean time of travelling"

# Calculate mean time of travelling
for FILE in "${FILES_TO_PROCESS[@]}"; do
  # Loading spinner to improve user expirience
  printf "\r${sp:i++%${#sp}:1}"

  # Extract the route name from the file path
  ROUTE_NAME=$(basename "$FILE" .csv)

  # calculate the mean duration from each CSV file with decimal values
  MEAN_DURATION_SECONDS=$(awk -F ',' 'NR > 1 {sum += $(NF-2) - $1; count++} END {if (count > 0) printf "%.1f", sum / count}' "$file")

  # Remove the decimal part by casting to an integer
  MEAN_DURATION_SECONDS_INT=${MEAN_DURATION_SECONDS%.*}

  # Format the mean duration as HOURS:MINUTES:SECONDS, ignoring milliseconds using date
  formatted_mean_duration=$(date -u -d @$MEAN_DURATION_SECONDS_INT +'%H:%M:%S')

  # Write the data to the CSV file
  echo "$ROUTE_NAME,$formatted_mean_duration" >>"$OUTPUT_DIR/duration.csv"
done

echo -ne "\rFinished calculating mean time of travelling\n"

# Create an associative array to store the total fuel for each VEHICLE_ID
declare -A TOTAL_FUEL

echo -n "  Calculating fuel usage"

# Calculating fuel usage
for FILE in "${FILES_TO_PROCESS[@]}"; do
  # Loading spinner to improve user expirience
  printf "\r${sp:i++%${#sp}:1}"
  if [ -e "$FILE" ]; then
    # Use a flag to skip the first row (header)
    skip_header=true

    while IFS=',' read -r -a line; do
      if [ "$skip_header" = true ]; then
        skip_header=false
        continue
      fi

      # Extract the VEHICLE_ID and fuel values
      VEHICLE_ID="${line[-2]}"
      FUEL="${line[-1]}"

      # Check if fuel is a numeric value
      if [[ "$FUEL" =~ ^[0-9]+$ ]]; then
        # Check if the VEHICLE_ID is already in the associative array
        if [ -n "${TOTAL_FUEL[$VEHICLE_ID]}" ]; then
          # Add the fuel value to the total
          TOTAL_FUEL["$VEHICLE_ID"]=$((TOTAL_FUEL["$VEHICLE_ID"] + FUEL))
        else
          # Initialize the total fuel for this VEHICLE_ID
          TOTAL_FUEL["$VEHICLE_ID"]=$FUEL
        fi
      else
        echo "Skipping line with non-numeric fuel value: $FUEL for $VEHICLE_ID"
      fi
    done <"$FILE"
  else
    echo "File '$FILE' does not exist."
  fi
done

# Create the CSV file to store fuel usage data for every vehicle
echo "id,fuel" >"$OUTPUT_DIR/engine.csv" # Header row

# Write the total fuel data to the CSV file
for VEHICLE_ID in "${!TOTAL_FUEL[@]}"; do
  echo "$VEHICLE_ID,${TOTAL_FUEL[$VEHICLE_ID]}" >>"$OUTPUT_DIR/engine.csv"
done

echo -ne "\rFinished calculating fuel usage\n"

echo "Data has been written to '$OUTPUT_DIR/engine.csv' and '$OUTPUT_DIR/duration.csv'."
