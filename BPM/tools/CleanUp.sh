#!/bin/bash

#-- CleanUp.sh -----------------------------------------------------------
#
# This script is made to cleanup the users uploaded files
# 
# Arguments:
# 1. if the given argument is A or a then the script will delete 
# 	all of the uploaded files created by the BPM folder
# 	in the /grid/see/<username>/BPM_<timestamp> lfn location
# 2. if a timestamp is given, it will delete the BPM_<timestamp> folder
#
#-------------------------------------------------------------------------

toDelete=${1}

# initialize some parameters
export LFC_HOST=`lcg-infosites --vo see lfc`
export LCG_CATALOG_TYPE=lfc
export LCG_GFAL_VO=see

echo "This may take a while"
if [[ $toDelete == "A" || $toDelete == "a" ]]; then
	echo "......."
	lcg-ls lfn:/grid/see/`whoami`/ > .uploadedlist 2>&1
	grep "BPM_" .uploadedlist > .tobedeleted
	rm .uploadedlist
else

	lcg-ls lfn:/grid/see/`whoami`/BPM_$toDelete/ > .tobedeleted 2>&1
fi
while read line; do
	lcg-del -a lfn:/grid/see/`whoami`/BPM_$toDelete/$line 2>&1
	echo "......."
done < .tobedeleted
# remove the folder
lfc-rm -r /grid/see/`whoami`/BPM_$toDelete/


rm -f .tobedeleted .delstatus .folderelements 
echo "Clean up is done, good bye"

