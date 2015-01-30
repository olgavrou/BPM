#!/bin/bash

numJobs=${1}
option=${2}
timefolderParametric=${3}
timefolderSimple=${4}

#### functions ####
Time(){
	# argument is a file with two time stamps
	# echoes the time difference between the two timestamps in hours
	day=$(awk '{if(NR==1){print; exit;}}' $1 | cut -d" " -f 1)
	day1=$(awk '{if(NR==2){print;exit;}}' $1 | cut -d" " -f 1)
	tim=$(awk '{if(NR==1){print; exit;}}' $1 | cut -d" " -f 2)
	tim1=$(awk '{if(NR==1){print; exit;}}' $1 | cut -d" " -f 2)
	t=$(date -d "201210$day $tim" +%s)
	t1=$(date -d "201210$day1 $tim1" +%s)
	diff=$(expr $t1 - $t)
	diff=$((diff))
}
###################
Time $timefolderParametric
echo "$numJobs parametric jobs ran in $diff hours" >> Report.txt

Time $timefolderSimple
# which is the output folder?
outputFolder=$(ls | sort -nr | grep -m 1 "MyOutput")

case $option in
	1) clusters=$( wc -l < "$outputFolder"/"Outsimple.mcl") 
	   echo "Generated simple mcl output in $diff minutes, with $clusters clusters" >> Report.txt
	;;
	2|5) echo "Generated phylogenetic profile in $diff minutes" >> Report.txt
	;;
	3) echo "Generated phylogenetic profile and its mcl clustering in $diff minutes" >> Report.txt
	clusters=$( wc -l < "$outputFolder"/"Outphyl.mcl")
	echo "mcl of phylogenetic profiles has $clusters clusters" >> Report.txt
	;;
	4) echo "Generated phylogenetic profile and its mcl clustering, along with simple mcl clustering in $diff minutes" >> Report.txt
	   clusters=$( wc -l < "$outputFolder"/"Outsimple.mcl")
	   echo "Simple mcl has $clusters clusters" >> Report.txt
	   clusters=$( wc -l < "$outputFolder"/"Outphyl.mcl")
	   echo "mcl of phylogenetic profiles has $clusters clusters" >> Report.txt
	;;
esac

#rm $timefolderParametric $timefolderSimple
