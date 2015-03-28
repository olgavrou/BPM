#!/bin/bash

#-- Upload.sh -----------------------------------------------------------------
#
# This script uploads a specific file/folder that is given as an argument
# it uploads it to a folder with name BPM_timestampi, if timestamp is given
#
# Arguments:
# 1. file name to upload
# 2. username
# 3. timestamp [optional]
#
#------------------------------------------------------------------------------

upload=${1}
# user name
userName=${2}
timestamp=${3}

export LFC_HOST=`lcg-infosites --vo see lfc`
export LCG_CATALOG_TYPE=lfc
export LCG_GFAL_VO=see

storage_elements=(
  se01.grid.auth.gr
  se01.marie.hellasgrid.gr
  se01.afroditi.hellasgrid.gr
  se01.kallisto.hellasgrid.gr
  se01.ariagni.hellasgrid.gr
  se01.athena.hellasgrid.gr
  se02.athena.hellasgrid.gr
)


for j in ${storage_elements[@]}; do
	if [[ -z $timestamp ]]; then
  		lcg-cr -v -d $j -l lfn:/grid/see/$userName/$upload file:$upload > log  2>&1
	else
		lcg-cr -v -d $j -l lfn:/grid/see/$userName/BPM_$timestamp/$upload file:$upload > log  2>&1	
	fi
  	if [ $? == 0 ]; then
     		break;
  	fi
done

uploaded=$(grep guid -c log)
if [[ -z $uploaded ]]
then
	echo "files didn't upload"
	exit 3
fi

rm log
