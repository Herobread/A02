#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <dir>" >&2
  exit 1
fi

# could be much smaller, that's where 1 mark was lost
du $1/data/* | sort -rn | head -n 5 | awk -F'/' '{print $NF}'
