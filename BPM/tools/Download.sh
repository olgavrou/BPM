#!/bin/bash

#-- Download.sh -------------------------------------------------------------------- 
#
# This script is made for downloading the users uploaded files
# 
# Arguments:
# 1. The timestamp of the program instance, whose data we are going to download 
# 2. The folder in which the data will be stored
#
#-----------------------------------------------------------------------------------

timestamp=${1}
toStore=${2}

if [[ -z $toStore ]]; then
	echo "Please specify a file for the files to be stored"
	exit
fi

mkdir $toStore

# initialize some parameters
export LFC_HOST=`lcg-infosites --vo see lfc`
export LCG_CATALOG_TYPE=lfc
export LCG_GFAL_VO=see

echo "This may take a while"

lcg-ls lfn:/grid/see/`whoami`/BPM_$timestamp/ > .filecontents
if [[ $? != 0 ]]; then
        echo "BPM_$timestamp folder unreachable"  
        exit
fi

# download
while read line; do
	echo "........"
	lcg-cp lfn:/grid/see/`whoami`/BPM_$timestamp/$line file:$toStore/$line
done < .filecontents
rm .filecontents
