#!/bin/bash

# first argument is the file/folder that I want to remove from the grid storage elements

remove=${1}

export LCG_CATALOG_TYPE=lfc
export LFC_HOST=lfc.isabella.grnet.gr
export LCG_GFAL_INFOSYS=bdii.isabella.grnet.gr:2170
export LCG_GFAL_VO=see

lcg-del -a lfn:/grid/see/olgavrou/$remove 2>&1
if [ $? == 0 ]; then
	echo "removed"
else 
	echo "not removed"
fi 
