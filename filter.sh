#!/bin/bash

if [ $# -ne 1 ]
then
  echo "Usage: $0 <dir>" >&2
  exit 1
fi

du -h $1/data/* |sed 's/\.\d*//g' |sed 's/K/000/g'| sort |head -n5
