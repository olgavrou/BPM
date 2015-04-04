CONTENTS OF THIS FILE
---------------------
   
 * Introduction
 * Requirements
 * Installation
 * Execution
 * Example
 * Folder Structure
 
----------------
 INTRODUCTION
----------------

BPM (BLAST - Phylogenetic Profile - MCL) is a distributed modular application 
for sequence alignment, phylogenetic profiling and clustering of protein sequences, 
by utilizing the European Grid Infrastructure. 
Specifically, the application comprises three main components; 
(a) BLAST alignment 
(b) construction of phylogenetic profiles based on the produced alignment scores and 
(c) clustering of entities using the MCL algorithm. 
These modules have been selected as they represent a common aspect of a vast majority 
of bionformatics workflows. It is important to note that the modules can be combined independently, 
and ultimately provide 4 different modes of operation.

 * Submit bug reports and feature suggestions: olgavrou@gmail.com
 
--------------- 
 REQUIREMENTS
---------------

In order for the application to run, the user needs to have an account 
at HellasGrid (National Grid Infrastructure). 
Further instructions can be found here: https://access.hellasgrid.gr

--------------- 
 INSTALLATION
---------------

The scripts lying in the BPM folder must be uploaded to the HellasGrid User Interface and decompressed.
The BPM.sh script must be executable (chmod +x BPM.sh).

--------------- 
 EXECUTION
---------------

* Input:

  The input required should be in the BPM folder, at the same level with the Input.txt file.

  <b>A.</b> The input data that are reqired are:
  
      1. Database file: a fasta file/files with the protein sequences that will consist the database of the protein alignment
        If one fasta file is provided it may either be compressed or not.
        If more than one fasta files are provided, they should all be in one folder (compressed folder or not)
        
      2. Query File: a fasta file with the protein sequences that will consist the query of the protein alignment
        It may either be compressed or not.
        NOTE: in the case of an all-vs-all run, this file may be omitted
        
      3. Genome map: a file that contains the genome identifiers whoes proteins consist the database.
        It may either be compressed or not.
    
    e.g. 
    
         Genome map : BAMY-XXX
    
         Database file: >BAMY-XXX-01
                        <protein sequence>
                        >BAMY-XXX-02
                        <protein sequence>
                        
         Protein file:  >leuA
                        <protein sequence>

  <b>B.</b> Configuration file:
  
      The file Input.txt that is provided must be configured.
      It consists of the following fields:
      

        <b>query_file:</b> <the exact name of the query file, as it is uploaded in the user interface, e.g. query.tar.gz> [if option is 5, this will be ignored]
        <b>gene_map:</b> <the exact name of the gene map file, as it is uploaded in the user interface, e.g. List.txt>
        <b>raw_database:</b> <this field should be filled, if the database is provided as a folder with more than one fasta files; the exact name of the folder should be provided, e.g. Database.tar.gz>
        <b>ready_database:</b> <this field should be filled, if the database is provided as one fasta file; the exact name of this file should be provided, e.g. database.faa>
        <b>option:</b> 5 
            # Option: 1 for only mcl clustering (the query file will be split for each job to process)
            # Option: 2 for only phylogenetic profile (the database file will be split for each job to process)
            # Option: 3 for phylogenetic profile and the mcl clustering of the phyl. prof. (the database file will be split for each job to process)
            # Option: 4 for all the above outputs (the database file will be split for each job to process)
            # Option: 5 for all-vs-all (the query file will be split for each job to process) 

            # I for Identity or E for E-value (choose the output of blastp)
        <b>I_or_E:</b> I
  
            # F for binary or C for extended phylogenetic profiles (choose the type of phylogenetic profiles that will be constructed)
        <b>F_or_C:</b> C

            # enter your email address if you wish to be informed via email that the application is done
        email: olgavrou@gmail.com
        
        NOTE: either raw_database or ready_database should be defined

* Preparation: 
   
   <b>A.</b> Proxy

         A valid proxy should be obtained in order for the application to run on HellasGrid.
         The "proxy-tools" command is recommended for obtaining a my-proxy certificate, 
         and for the voms-proxy to be automatically renewed.

   <b>B.</b> Screen
   
         It is advised that the application runs in screen mode, to avoid the application from being aborted
         due to connectivity issues.
         
         
   
* Execution:
      
      Run the application like so:

      <b>   ./BPM.sh Input.txt </b>
      
      A folder named SessionFolder_<timestamp> will be created at the same level as the Input.txt file.
      
      DO NOT delete or modify the folder or it's contents while the application is running. It will be deleted
      when the application has completed.
      
      
* Output:
   
      A folder named Output_timestamp will be created at the same level as the Input.txt file. The database file,
      query file, genome map file, will be copied there. 

      The application output will be stored there, with a report containing information about the instance that ran.
      The report will be sent via email, if an email address is specified.

      The output can be:
      
         Outsimple.mcl : it contains the clusters from the MCL execution, based on the BLAST output
         Outphyl.mcl   : it contains the clusters from the MCL execution, based on the phylogenetic profiles
         PhylogeneticProfiles.txt : it contains the phylogenetic profiles of the query proteins

      The output may be further processed by the scripts in the ParseOutput folder.
      
      Use the CleanUP.sh script in the tools folder, to delete all the files that are stored at the Storage Elements
      of HellasGrid. The files consist of the blast outputs, the phylogenetic profiles and the mcl clusters.
      Usage: tools/CleanUp.sh timestamp
      
      Use the Download.sh script in the tools folder to download all the files that are stored at the Storage Elements
      of HellasGrid. The files consist of the blast outputs, the phylogenetic profiles and the mcl clusters. 
      They will be stored at a folder that the user specifies (will be created if it doesn't exist).
      Usage: tools/Download.sh timestamp foldername
      
      
      NOTE: timestamp is the beginning timestamp of each application run. It is used for the
      SessionFolder_timestamp, the Output_timestamp folder, and to store the outputs at the Storage Elements 
      of HellasGrid. Use it to clean up or download the produced files, and to track different executions.


--------------- 
 EXAMPLE
---------------

In the folder Example.tar.gz, you will find an example of a query, database and genome file.
The Input.txt file is configured to accept these files as an input.
In the folders testcase1.tar.gz and testcase2.tar.gz, you can find examples of the
generated output.


------------------ 
 FOLDER STRUCTURE
------------------

You can view the folder structure in the FolderStructure.txt file


