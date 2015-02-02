
###############################################################################################
# These scripts are made for the user to extract information from the BPM program output.
# The output is mcl files that contain clusters of proteins and/or genomes,
# and files that containt phylogenetic profiles						      
###############################################################################################



"1. GetClusters.sh"
-first argument: a genome or protein identifier (e.g. BAMY-XXX or BAMY-XXX-01-000289)
-second argument: the mcl file that contains the clusters with their numeric id's
-output: a file <Identifier>_clusters.txt that contains the numeric id's of the cluster/clusters that the genome or protein belong to
-e.g. ./GetClusters.sh "BAMY-XXX" Out.mcl

"2. ClustersWithNumElements.sh"
-first argument: the mcl file that contains the clusters with their numeric id's
-second argument: a number of desired elements in a cluster
-output: a file Clusters<Number>.txt that contains the numeric id's of the cluster/clusters that have exactly that number of elements 
-e.g. ./ClustersWithNumElements.sh Out.mcl 15

"3. OneOrganismClusters.sh"
-first argument: the mcl file that contains the clusters with their numeric id's
-second argument: the gene map tha was used in the BPM program, that contains a list of the genome identifiers of the database sequences
-output: a file OneOrganismClusters.txt that contains the numeric id's of the clusters that have elements that belong only to one organism/genome
-e.g. ./OneOrganismClusters.sh Out.mcl genomeList
-output e.g.: gene1:
	      cluster1
	      cluster2
	      gene2:
	      gene3:
	      cluster3

"4. ClusterElements.sh"
-first argument: the mcl file that contains the clusters with their numeric id's
-second argument: a cluster id
-output: a file Cluster<clusterID>.txt that contains the elements of the specific cluster
-e.g. ./ClusterElements Out.mcl 5

"5. ClusterSequences.sh"
-first argument: a cluster id
-second argument: the mcl file that contains the clusters with their numeric id's
-third argument: the FASTA file that contains the protein sequences that where clustered, or the FASTA file that contains the protein sequences of the genomes that where clustered
-fourth argument (optional): a second FASTA file that contains protein sequences
-output: a file Cluster<clusterID>Sequences.fasta that contains the sequences of the elements that belong to the specific cluster. If the cluster contains genome, then the output file will contain the protein sequences that belong to each genome.
-e.g. ./ClusterSequences.sh 5 Out.mcl bacillus.faa

"6. ClusterPhylProfiles.sh"
-first argument: the mcl file that contains the clusters with their numeric id's. Clusters of proteins are required, and not clusters of genomes.
-second argument: the file that contains the phylogenetic profiles of the proteins that where clustered
-third argument: a cluster id
-output: a file Cluster<clusterID>ElementsPhylProf.txt that contains the phylogenetic profiles of the elements that belong to the specific cluster
-e.g. ./ClusterPhylProfiles.sh Out.mcl PhylogeneticProfiles.txt 5

"7. SpecificPhylogeneticProfile.sh"
-first argument: the file that contains the phylogenetic profiles of the proteins that where clustered
-second argument: the protein identifier whose phylogenetic profile will be selected
-output: a file <proteinID>PhylogeneticProfile.txt that contains the phylogenetic profile of the specific protein
-e.g. ./SpecificPhylogeneticProfile.sh PhylogeneticProfiles.txt "BCER-ZKX-01-003514"

"8. ClustersWithUniqueElements.sh"
-first argument: the mcl file that contains the clusters with their numeric id's
-second argument: the gene map that was used in the BPM program, that contains a list of the genome identifiers of the database sequences
-output: a file UniqueElementClusters.txt that contains the numeric id's of the clusters that dont have more than one elements of the same organism, i.e. there are no two (or more) elements from the same organism in the listed clusters
-e.g. ./ClustersWithUniqueElements.sh Out.mcl genomeList
note: this script can take more than an hour to run for large input files

"9. ClustersWithUniqueElementsFormEveryGenome.sh"
-first argument: the mcl file that contains the clusters with their numeric id's
-second argument: the gene map that was used in the BPM program. that contains a list of the genome identifiers of the database sequences
-output: a file UniqueElementFromEachGeneClusters.txt that contains the numeric id's of the clusters that have EXACTLY ONE element from EACH gene in the gene map list
-e.g. ./ClustersWithUniqueElementsFormEveryGenome.sh Out.mcl genomeList


