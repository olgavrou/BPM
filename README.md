CONTENTS OF THIS FILE
---------------------
   
 * Introduction
 * Requirements
 * Installation
 * Execution
 
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

  A. The input data that are reqired are:
      1. Database file: a fasta file/files with the protein sequences that will consist the database of the protein alignment
        If one fasta file is provided it may either be compressed or not.
        If more than one fasta files are provided, they should all be in one folder (compressed folder or not)
      2. Query File: a fasta file with the protein sequences that will consist the query of the protein alignment
        It may either be compressed or not.
        NOTE: in the case of an all-vs-all run, this file may be omitted
      3. Genome map: a file that contains the genome identifiers whoes proteins consist the database.
        It may either be compressed or not.
    
    e.g. Genome map : BAMY-XXX
         Database file: >BAMY-XXX-01
                        <protein sequence>
                        >BAMY-XXX-02
                        <protein sequence>
         Protein file:  >leuA
                        <protein sequence>

  B. Configuration file:
      The file Input.txt that is provided must be configured.
      It consists of the following fields:

        query_file: <the exact name of the query file, as it is uploaded in the user interface, e.g. query.tar.gz> [if option is 5, this will be ignored]
        gene_map: <the exact name of the gene map file, as it is uploaded in the user interface, e.g. List.txt>
        raw_database: <this field should be filled, if the database is provided as a folder with more than one fasta files; the exact name of the folder should be provided, e.g. Database.tar.gz>
        ready_database: <this field should be filled, if the database is provided as one fasta file; the exact name of this file should be provided, e.g. database.faa>
        option: 5 
            # Option: 1 for only mcl clustering (the query file will be split for each job to process)
            # Option: 2 for only phylogenetic profile (the database file will be split for each job to process)
            # Option: 3 for phylogenetic profile and the mcl clustering of the phyl. prof. (the database file will be split for each job to process)
            # Option: 4 for all the above outputs (the database file will be split for each job to process)
            # Option: 5 for all-vs-all (the query file will be split for each job to process) 

            # I for Identity or E for E-value (choose the output of blastp)
        I_or_E: I
  
            # F for binary or C for extended phylogenetic profiles (choose the type of phylogenetic profiles that will be constructed)
        F_or_C: C

            # enter your email address if you wish to be informed via email that the application is done
        email: olgavrou@gmail.com







