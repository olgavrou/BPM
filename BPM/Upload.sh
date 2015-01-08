#!/bin/bash

#
# this script uploads the file/folder that is given as an argument
#

upload=${1}

export LCG_CATALOG_TYPE=lfc
export LFC_HOST=lfc.isabella.grnet.gr
export LCG_GFAL_INFOSYS=bdii.isabella.grnet.gr:2170
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
  	lcg-cr -v -d $j -l lfn:/grid/see/olgavrou/$upload file:$upload >> log  2>&1
  	if [ $? == 0 ]; then
     		break;
  	fi
done

uploaded=$(grep guid -c log)
if [[ -z $uploaded ]]
then
	echo "files didn't upload"
	exit 4
fi

rm log
