#!/bin/bash 

#-- GenerateReport.sh ----------------------------------------------- 
#
# This script generates an output report
# the report contains the input file and other useful information
#
# Arguments:
# 1. Program instance's timestamp
#
#--------------------------------------------------------------------


timestamp=${1}
sf=SessionFolder_$timestamp

################################################################################
#                                                                              #
#                         Create the report                                    #
#                                                                              #
################################################################################

outputFolder=Output_$timestamp
echo " "
echo "Input selections: " >> Report.txt
echo " "
awk '/query_file/{print;}' $sf/Input.txt >> Report.txt
awk '/gene_map/{print;}' $sf/Input.txt >> Report.txt
awk '/raw_database/{print;}' $sf/Input.txt >> Report.txt
awk '/ready_database/{print;}' $sf/Input.txt >> Report.txt
awk '/option/{print;}' $sf/Input.txt >> Report.txt
awk '/I_or_E/{print;}' $sf/Input.txt >> Report.txt
awk '/F_or_C/{print;}' $sf/Input.txt >> Report.txt
echo " "
echo "Session Folder is: $sf"
echo "Output Folder is: $outputFolder"
echo "Session Folder is: $sf" >> Report.txt
echo " "
option=$( awk '/option/{print $2;}' "$sf/Input.txt" )
if [[ $option == 1 || $option == 5 ]]; then
	numJobs=$( sed '1!d' "$sf/Info" )
	qNum=$( grep ">" -c `sed '2!d' "$sf/Info"` )
	dbNum=$( grep ">" -c `sed '3!d' "$sf/Info"` )
else
	numJobs=$( sed '1!d' "$sf/Info" ) 
	qNum=$( grep ">" -c `sed '3!d' "$sf/Info"` ) 
	dbNum=$( grep ">" -c `sed '4!d' "$sf/Info"` ) 
fi
echo "query file has $qNum sequences" >> Report.txt
echo "database file has $dbNum sequences" >> Report.txt
echo " "

echo "$numJobs parametric jobs ran " >> Report.txt                   
echo " "        

case $option in	
	1) clusters=$( wc -l < "$outputFolder"/"Outsimple.mcl") 
	   echo "Generated simple mcl output with $clusters clusters" >> Report.txt
	;;
	2|5) echo "Generated phylogenetic profile " >> Report.txt
	;;
	3) echo "Generated phylogenetic profile and its mcl clustering" >> Report.txt
	   echo " " >> Report.txt	
	clusters=$( wc -l < "$outputFolder"/"Outphyl.mcl")
	echo "mcl of phylogenetic profiles has $clusters clusters" >> Report.txt
	;;
	4) echo "Generated phylogenetic profile and its mcl clustering, along with simple mcl clustering " >> Report.txt
	   clusters=$( wc -l < "$outputFolder"/"Outsimple.mcl")
	   echo "Simple mcl has $clusters clusters" >> Report.txt
	   clusters=$( wc -l < "$outputFolder"/"Outphyl.mcl")
	   echo "mcl of phylogenetic profiles has $clusters clusters" >> Report.txt
	;;
esac

