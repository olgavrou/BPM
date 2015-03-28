#!/bin/bash

#-- RemoveFromSE.sh ------------------------------------------------------
# 
# This scripts removes a specific file from the grid
#
# Arguments:
# 1. The file/folder that I want to remove from the grid storage elements
#
#-------------------------------------------------------------------------


remove=${1}
# user name
userName=`whoami`

export LFC_HOST=`lcg-infosites --vo see lfc`
export LCG_CATALOG_TYPE=lfc
export LCG_GFAL_VO=see

lcg-del -a lfn:/grid/see/$userName/$remove/ # 2>/dev/null
