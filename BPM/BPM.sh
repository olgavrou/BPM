#!/bin/bash

#--- BPM.sh -----------------------------------------------------------
# 
# This script is where the application starts
#
# Arguments: 
# 1. Input.txt file
#
#----------------------------------------------------------------------

input=${1}

########## Parse the input to get the details ##########

query=`awk '/query_file/{print $2;}' $input`
geneMap=`awk '/gene_map/{print $2;}' $input`
rawDatabase=`awk '/raw_database/{print $2;}' $input`
readyDatabase=`awk '/ready_database/{print $2;}' $input`
option=`awk '/option/{print $2;}' $input`
email=`awk '/email/{print $2;}' $input`

################################################################################
#                                                                              #
#                               functions                                      #
#                                                                              #
################################################################################

Exit(){
	status=${1}
	case $status in
	1|2) echo "early stage errors, please check the files you provided, your connection to the grid and your proxy certificate"
	       exit
	;;
	3) echo "The Grid is not working, please try again later"
	   exit
	;;
	4) 
	   echo "Something is wrong with the Grid" 
	   exit
	;;
	5) echo "The parametric jobs can't run. Please check for valid proxy"
	   exit
	;;
	0) 
	echo "Report Generated at: `date`" >> Report.txt
	echo "Thank you." >> Report.txt
	;;
	esac
	if [[ ! -z $email ]]; then
                mail -s "Your Job Report From HellasGrid" $email < Report.txt
        fi
	
        mv Report.txt Output_$timestamp
	exit
}

################################################################################
#                                                                              #
#                   	Check for correct input                                #
#                                                                              #
################################################################################

##### if any data are empty, exit with exit code = "1" #####
if [[ $option == 5 ]]; then
	if [[ -z "$rawDatabase" && -z "$readyDatabase" ]] || [[ -z "$geneMap" ]]; then
		echo "Wrong input file"
		Exit 1
	fi
	# selections are given, check if they are present
	ishereRaw=$( ls | grep -w "$rawDatabase" )
	ishereRe=$( ls | grep -w "$readyDatabase" )
	ishereG=$( ls | grep -w "$geneMap" )
	if [[ -z $ishereRaw && -z $ishereRe ]] || [[ -z $ishereG ]]; then
		echo "Files are missing"
		Exit 1
	fi
else
	if [[ -z "$query" || -z "$geneMap" ]] || [[ -z "$rawDatabase" && -z "$readyDatabase" ]]; then
		echo "Wrong input file"
		Exit 1
	fi
	# selections are given, check if they are present
	ishereRaw=$( ls | grep -w "$rawDatabase" )
        ishereRe=$( ls | grep -w "$readyDatabase" )
        ishereG=$( ls | grep -w "$geneMap" )
	ishereQ=$( ls | grep -w "$query" )
	if [[ -z $ishereRaw && -z $ishereRe ]] || [[ -z $ishereG || -z $ishereQ ]]; then
		echo "Files are missing"
                Exit 1
 	fi
fi

###  Make All Scripts Executable

chmod +x MasterScript.sh JobScript.sh SecondJobScript.sh tools/* HandleJobs/* ParseOutput/* MakeFiles/*



################################################################################
#                                                                              #
#                          Call MasterScript                                   #
#                                                                              #
################################################################################

case "$option" in

1|2|3|4|5) echo "Getting Started"
    timestamp=$(date +"%Y%m%d%H%M%S")
    mkdir SessionFolder_$timestamp
   ./MasterScript.sh $input $timestamp
   exitstatus=$?
   Exit $exitstatus
   ;;
*) echo "Option Not supported"
   Exit 1
   ;;
esac
