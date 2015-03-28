#!/bin/bash

#-- MakeInputFile.sh ----------------------------------------------------------
# 
# This script will concatenate the fasta files in the given folder
# to create one database fasta file
# It is called from the MasterScript.sh, so the folder is decompressed 
#
# Arguments:
# 1. The folder where the data resides 
#
#------------------------------------------------------------------------------

folder=${1}
if [[ -d $folder ]]; then
	cat $folder/* > database.faa
else
	exit 2
fi
#check to see if the file was created and if not exit with status 2
created=$(ls | grep database.faa)
if [[ -z $created ]]; then
	exit 2
fi
