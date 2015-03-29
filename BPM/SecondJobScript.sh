#!/bin/bash -x

#-- SecondJobScript.sh --------------------------------------------------------------------------------------
#
# This script makes phylogenetic profiles or runs mcl, according to "option" and "fileType" parameters
# 
# Arguments:
# 1. The number of the uploaded abc files
# 2. The name of the files I want to concatenate, "output" or "phyl"
# 	"output" means simple abc file while "phyl" means abc file for phylogenetic profiles
# 3. The User Name
# 4. The selected program option
# 5. Instance timestamp
# 6. I_or_E for mcl
#
#------------------------------------------------------------------------------------------------------------

date +"%Y%m%d %T"

/bin/hostname -f
lcg-cr --version


abcNum=${1}
fileType=${2}
userName=${3}
option=${4}
timestamp=${5}
I_or_E=${6}

echo "$userName"
export LFC_HOST=`lcg-infosites --vo see lfc`
export LCG_CATALOG_TYPE=lfc
export LCG_GFAL_VO=see

################################################################################
#                                                                              #
#                     Download files and MCL                                   #
#                                                                              #
################################################################################

echo "abc num: $abcNum"
echo "file type: $fileType"
# get the abc files and concatenate them
#if [[ $fileType != "phyl" || $option != 5 ]]; then
	for i in `seq 1 $abcNum`
	do
		lcg-cp lfn:/grid/see/$userName/BPM_$timestamp/$fileType$i.tar.gz file:$fileType$i.tar.gz
		if [[ $? != 0 ]]; then
			lcg-ls lfn:/grid/see/$userName/BPM_$timestamp/$fileType$i.tar.gz
			if [[ $? == 0 ]]; then
			# its there, try again
			lcg-cp lfn:/grid/see/$userName/BPM_$timestamp/$fileType$i.tar.gz file:$fileType$i.tar.gz
			else
				echo "$i" > failed
			fi
		fi
		# untar them
		tar -zxvf $fileType$i.tar.gz
		rm $fileType$i.tar.gz
	done
	
	untaredNum=$(ls | grep "$fileType" -c)
	echo "$abcNum"
	echo "$untaredNum"
	if [[ $untaredNum != $abcNum ]]; then
		echo "didn't download correctly all the files, some failed:"
		cat failed
		exit
	else
		echo "cat and maybe sort"
		date +"%Y%m%d %T"
		# all abc files collected so concatenate them
		if [[ $option == 1 || $option == 5 ]]; then
			cat $fileType*.abc  > Output.abc
		else
			cat $fileType*.abc | sort > Output.abc
		fi
		echo "done cat"
		date +"%Y%m%d %T"
#		if [[ $fileType == "output" || $option == 3 || $option == 4 ]]; then # option 5 has mcl of simple output but not of phyl profile
			# get and install mcl
			wget http://micans.org/mcl/src/mcl-latest.tar.gz
		
	        	folder="mcl-latest.tar.gz"
	        	mkdir tmpdir
	        	mv $folder tmpdir
	        	cd tmpdir
	        	tar -zxvf $folder
	        	mv $folder ..
	        	dataFolder=$(ls)
	        	mv $dataFolder ..
	        	cd ..
	        	rm -rf tmpdir
			
	   		cd $dataFolder
	  		./configure --prefix=$HOME
	   		make install
			cd -
			
			# get files from bin
			cp $HOME/bin/mcl .
			cp $HOME/bin/mcxload .
			
			if [[ $I_or_E == "E" && $fileType == "output" ]]; then
				# run mcl
				time ./mcxload -abc Output.abc --stream-mirror --stream-neg-log10 -o out.mci --write-binary
				time ./mcl out.mci -use-tab out.tab -o tempMcl 
			else
                        	#time ./mcxload -abc Output.abc -o out.mci --write-binary
				#time ./mcl out.mci -o tempMcl 
				#time ./mcl Output.abc --abc -o tempMcl
				time ./mcxload -abc Output.abc --stream-mirror -o out.mci -write-tab out.tab --write-binary
				time ./mcl out.mci -use-tab out.tab -o tempMcl
			fi
			# remove the clusters with only one element
			awk '{if(NF >=2 ){print}}' tempMcl > tempMcl2	
			# insert arithmetic id for every cluster
			awk '{print ">"NR,$0}' tempMcl2 > Out$fileType.mcl
			
			date +"%Y%m%d %T"
		fi
#	fi
#fi

################################################################################
#                                                                              #
#           Download files and complete Phylogenetic Profiles                  #
#                                                                              #
################################################################################

if [[ $fileType == "phyl" ]]; then
	if [[ $option == 5 ]]; then
		echo "option 5 split query making phyl prof"
		date +"%Y%m%d %T"
		# download the PhylProf# files and concatnate them
		for i in `seq 1 $abcNum`
		do
		        lcg-cp lfn:/grid/see/$userName/BPM_$timestamp/PhylProf$i.tar.gz file:PhylProf$i.tar.gz
			if [[ $? != 0 ]]; then
                        	lcg-ls lfn:/grid/see/$userName/BPM_$timestamp/PhylProf$i.tar.gz
                        	if [[ $? == 0 ]]; then
                        		# its there, try again
                           		lcg-cp lfn:/grid/see/$userName/BPM_$timestamp/PhylProf$i.tar.gz file:PhylProf$i.tar.gz
                        	else
                                	echo "$i" >> failed
                        	fi
                	fi

		        # untar them
		        tar -zxvf PhylProf$i.tar.gz
		        rm PhylProf$i.tar.gz
		done
		untaredNum=$(ls | grep "PhylProf" -c)
		echo "$abcNum"
		echo "$untaredNum"
		if [[ $untaredNum != $abcNum ]]; then	
			echo "could not get all the phylogenetic profiles"
		else
			cat PhylProf* > PhylogeneticProfile.txt
			echo "done making phyl prof"
		fi
		echo "done making phyl prof"
		date +"%Y%m%d %T"
	else
		echo "making phyl prof"
		date +"%Y%m%d %T"
		# we want to return the phyl profile AND the mcl of the phyl profile
		cat Output.abc | cut -f 1 > tmp
		awk '!a[$0]++' tmp >> querySequences
		rm tmp
		t=$(grep -m 1 -f querySequences Output.abc | cut -f 1)
		grep "$t" Output.abc | cut -f 2 | sed 's/^//' | tr '\n' ' ' > genomes
		echo -e "`cat genomes`\n" > PhylogeneticProfile.txt
		while read line; do
			grep -w "^$line" Output.abc | cut -f 3 | sed 's/^//' | tr '\n' ' ' > tmp
      			echo "$line `cat tmp`"  >> PhylogeneticProfile.txt
       			rm tmp
		done < querySequences
		echo "done making phyl prof"
		date +"%Y%m%d %T"
	fi
fi

################################################################################
#                                                                              #
#                           Upload output                                      #
#                                                                              #
################################################################################

chmod +x Upload.sh
if [[ $fileType == "output" ]]; then
	mv Out$fileType.mcl Outsimple.mcl
	tar -zcvf resultssimple.tar.gz Outsimple.mcl
	./Upload.sh resultssimple.tar.gz $userName $timestamp
else	
	case "$option" in
	
	2|5) tar -zcvf resultsphyl.tar.gz PhylogeneticProfile.txt
	     ./Upload.sh resultsphyl.tar.gz $userName $timestamp
	   ;;
	3|4) mv Out$fileType.mcl Outphyl.mcl
	     tar -zcvf resultsphyl.tar.gz Outphyl.mcl PhylogeneticProfile.txt
	     ./Upload.sh resultsphyl.tar.gz $userName $timestamp
	   ;;
	esac	
	echo "done"
fi


date +"%Y%m%d %T"
