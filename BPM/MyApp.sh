#!/bin/bash -x

# The input is the Input.txt file

input=${1}

########## Parse the input to get the details ##########

query=`awk '/query_file/{print $2;}' $input`
geneMap=`awk '/gene_map/{print $2;}' $input`
rawDatabase=`awk '/raw_database/{print $2;}' $input`
readyDatabase=`awk '/ready_database/{print $2;}' $input`
option=`awk '/option/{print $2;}' $input`

########################################################

##### if any data are empty, exit with exit code = "1" #####

if [[ -z "$query" ]]
then
	echo "empty query, exit"
	exit 1
elif [[ -z "$geneMap" ]]
then 
	echo "empty gene map, exit"
	exit 1
elif [[ -z "$rawDatabase" && -z "$readyDatabase" ]]
then
	echo "no database given, exit"
  	exit 1
elif [[ -z "$option" ]]
then 
  	echo "no desired output is specified, exit"
  	exit 1
fi

###################################################################

######## depending on the input, call the desired script ##########

case "$option" in

1) echo "Simple mcl clustering"
   ./BasicScript.sh $input
   ;;
2) echo "Simple phylogenetic profile"
  ./BasicScript.sh $input
  ;;
3) echo "Phylogenetic Profile and its mcl clustering"
   ./BasicScript.sh $input
   ;;
4) echo "Do It All"
   ./BasicScript.sh $input
  ;;
*) echo "Option Not supported"
   exit 1
   ;;
esac
