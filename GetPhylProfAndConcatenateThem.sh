#!/bin/bash

# first argument is the number of files I am going to collect and concatenate
# second argument is the query file
abcNum=${1}
query=${2}

export LCG_CATALOG_TYPE=lfc
export LFC_HOST=lfc.isabella.grnet.gr
export LCG_GFAL_INFOSYS=bdii.isabella.grnet.gr:2170
export LCG_GFAL_VO=see

# get the abc files and concatenate them
for i in `seq $abcNum`
do
        lcg-cp lfn:/grid/see/olgavrou/phyl$i.tar.gz file:phyl$i.tar.gz
        # untar them
        tar -zxvf phyl$i.tar.gz
        rm phyl$i.tar.gz
done

untaredNum=$(ls | grep "phyl" | grep ".abc" -c)
echo "$abcNum"
echo "$untaredNum"
if [[ $untaredNum != $abcNum ]]; then
        echo "didn't download correctly all the files"
        echo "Check if All Uploaded"
        exit
else
	cat phyl*.abc | sort > PhylogeneticProfile.abc
	echo "output ready"
fi
rm -rf phyl*.abc
