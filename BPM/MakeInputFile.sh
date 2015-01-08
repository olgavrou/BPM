#!/bin/bash

#
# first argument is the folder where the data resides (decompressed folder) 
# second argument is the map of genomes with their file names
#

folder=${1}
map=${2}

##############functions#########################################
Unzip(){
# takes the name of the zipped file or folder as an input and decompresses it
        folder=${1}
        mkdir tmpdir
        mv $folder tmpdir
        cd tmpdir
        if [[ "$folder" == *".zip" ]]; then
                unzip $folder
        elif [[ "$folder" == *".tar"  ]]; then
                tar -xvf $folder
        elif [[ "$folder" == *".tar.gz" ]]; then
                tar -zxvf $folder
	elif [[ "$folder" == *".gz" ]]; then
                gunzip $folder
        else
                echo "Not compressed"
                dataFolder=$folder
                mv $folder ..
                cd ..
                rm -rf tmpdir
                return 0
        fi

        mv $folder ..
        dataFolder=$(ls)
        mv $dataFolder ..
        cd ..
        rm -rf tmpdir
}

geneNum=$(wc -l < $map)

while read line; do 
   	geneFile=$(echo "$line" | cut -f 1)
   	geneID=$(echo "$line" | cut -f 2)
 	awk ' 
     	BEGIN{
       		count=0;
		databaseFile="database.faa";
       		    
     	}
  	{ 
		if($0 ~ />/){
     			FS=">"; 
     			$0=$0;
     			printf("%s%.6d \t%s\n", ">'$geneID'-01-",count,$2) >> databaseFile;
     			count++;
   		}
   		else{
     			print $0 >> databaseFile;
   		}
 	} ' $folder/$geneFile  
done < $map
rm tmp

#check to see if the file was created and if not exit with status 2
created=$(ls -ltr | tail -1 | grep database.faa)
if [[ -z $created ]]; then
	echo "database from raw data was not created, exit"
	exit 2
fi
