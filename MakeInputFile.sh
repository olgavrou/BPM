#!/bin/bash

# This script will concatenate the fasta files in the given folder
# to create one database fasta file
# first argument is the folder where the data resides 
#

folder=${1}

cat $folder/* > database.faa

#check to see if the file was created and if not exit with status 2
created=$(ls | grep database.faa)
if [[ -z $created ]]; then
	exit 2
fi
