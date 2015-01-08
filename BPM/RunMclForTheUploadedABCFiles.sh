#!/bin/bash

date

/bin/hostname -f
lcg-cr --version

# first argument is the number of the uploaded abc files
# second argument is the name of the files I want to concatenate "output" or "phyl"
# "output" means simple abc file while "phyl" means abc file for phylogenetic profiles
abcNum=${1}
fileType=${2}

export LCG_CATALOG_TYPE=lfc
export LFC_HOST=lfc.isabella.grnet.gr
export LCG_GFAL_INFOSYS=bdii.isabella.grnet.gr:2170
export LCG_GFAL_VO=see

echo "abc num: $abcNum"
echo "file type: $fileType"
# get the abc files and concatenate them
for i in `seq 1 $abcNum`
do
	lcg-cp lfn:/grid/see/olgavrou/$fileType$i.tar.gz file:$fileType$i.tar.gz
	# untar them
	tar -zxvf $fileType$i.tar.gz
	rm $fileType$i.tar.gz
done

untaredNum=$(ls | grep "$fileType" -c)
echo "$abcNum"
echo "$untaredNum"
if [[ $untaredNum != $abcNum ]]; then
	echo "didn't download correctly all the files"
	echo "Check if All Uploaded"
	exit
else
	# all abc files collected so concatenate them
	cat $fileType*.abc | sort > Output.abc
	
	# get and install mcl
	wget http://micans.org/mcl/src/mcl-14-137.tar.gz
	tar -zxvf mcl-14-137.tar.gz
   	cd mcl-14-137
  	./configure --prefix=$HOME
   	make install
	cd -
	
	# get files from bin
	cp $HOME/bin/mcl .

	# run mcl
	time ./mcl Output.abc --abc -o Out$fileType.mcl

	if [[ $fileType == "phyl" ]]; then
		# we want to return the phyl profile AND the mcl of the phyl profile
		tar -zcvf outmcl.tar.gz Out$fileType.mcl Output.abc
	else
		# tar the output 
		tar -zcvf outmcl.tar.gz Out$fileType.mcl
		echo "done"
	fi
fi

date
