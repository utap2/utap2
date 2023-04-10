
Installation
############

*Support:* utap@weizmann.ac.il


Requirements
============

The application can be installed on a Linux server that supports cluster commands like qsub (pbs cluster), or bsub (lsf cluster).

The host server and/or each compute node in the relevent queue(s) requires ~40G of RAM memory.

The server requires the following:

* docker version >= 17
* miniconda version 2

You must set up a user (not root, and referred to below as "USER") with write permission in the miniconda environment and in the HOST_MOUNT folder (see below), that can run cluster commands and docker.

Its user id must be above 103; USER can belong to effective group with group id above 108.

USER requires a .ssh folder in its home directory. 
Create it with the command:  ssh-keygen -t rsa

The "USER" should then do the following:


Create a directory for UTAP software and its output
===================================================

Note: Since user output data will be written in this folder, please verify that you have sufficient disk space -  approximately 400G per analysis.
::

   HOST_MOUNT=<the relevant path>
   mkdir $HOST_MOUNT
   cd $HOST_MOUNT


Download the metadata
---------------------
The meta-data folder contains the genomes and annotation files. You can download it using your browser from our google-drive or via ftp as noted below, and then unpack it in the $HOST_MOUNT folder.
::


   #Download the zipped folder into $HOST_MOUNT folder:
   wget http://utap-demo.weizmann.ac.il/reports/utap-meta-data-v1.0.7.tar.gz -P $HOST_MOUNT
   
   cd $HOST_MOUNT
   tar -xzvf utap-meta-data-v1.0.7.tar.gz


Create conda environments
-------------------------
**If you install the system on local server and don't use a compute cluster for running, skip this section.**
The environment requires ~29G of disk.
::

   conda create -y --name utap r-essentials r-base=3.3.2
   conda activate utap
   # Install packages in the utap environment:
   # Run the script in this file in your shell:
   export CONDA_DIR=YOUR_CONDA_DIR # For example: CONDA_DIR=/home/user/miniconda2
   $HOST_MOUNT/utap-meta-data/installation/install-conda-packages-transcriptome.sh >& $HOST_MOUNT/utap-meta-data/installation/conda-install-transcriptome.stdout
   conda deactivate

   conda create -y --name utap-chromatin
   conda activate utap-chromatin
   export CONDA_DIR=YOUR_CONDA_DIR # For example: CONDA_DIR=/home/user/miniconda2
   $HOST_MOUNT/utap-meta-data/installation/install-conda-packages-chromatin.sh >& $HOST_MOUNT/utap-meta-data/installation/conda-install-chromatin.stdout
   conda deactivate

   conda create -y -n utap-py35 python=3.5 anaconda
   conda activate utap-py35
   conda install -y -c bioconda snakemake==3.13.3
   conda deactivate

Create genomes
==============

Extract the genomes to fasta format and create a Star index of the genomes (requires ~200GB of disk during the building process, reduced to ~135GB once the build completes and temporary files are removed):

Extract genome files
--------------------
::

    $HOST_MOUNT/utap-meta-data/softwares/bin/twoBitToFa $HOST_MOUNT/utap-meta-data/2bit_genomes/hg19.2bit $HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg19/gemone_hg19.fa
    $HOST_MOUNT/utap-meta-data/softwares/bin/twoBitToFa $HOST_MOUNT/utap-meta-data/2bit_genomes/hg38.2bit $HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg38/gemone_hg38.fa
    $HOST_MOUNT/utap-meta-data/softwares/bin/twoBitToFa $HOST_MOUNT/utap-meta-data/2bit_genomes/mm10.2bit $HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/gemone_mm10.fa
    $HOST_MOUNT/utap-meta-data/softwares/bin/twoBitToFa $HOST_MOUNT/utap-meta-data/2bit_genomes/danRer10.2bit $HOST_MOUNT/utap-meta-data/genomes/Danio_rerio/UCSC/danRer10/gemone_danRer10.fa
    $HOST_MOUNT/utap-meta-data/softwares/bin/twoBitToFa $HOST_MOUNT/utap-meta-data/2bit_genomes/tair11-araport.2bit $HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/ARAPORT/tair11/gemone_tair11-araport.fa
    $HOST_MOUNT/utap-meta-data/softwares/bin/twoBitToFa $HOST_MOUNT/utap-meta-data/2bit_genomes/tair10.2bit $HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/NCBI/tair10/gemone_tair10.fa
    $HOST_MOUNT/utap-meta-data/softwares/bin/twoBitToFa $HOST_MOUNT/utap-meta-data/2bit_genomes/sl3.2bit $HOST_MOUNT/utap-meta-data/genomes/Solanum_lycopersicum/SGN/sl3/gemone_sl3.fa

Build the STAR index
--------------------
The commands listed below take ~1 hour per genome. They run on 30 threads (you can change that number by modifying the --runTreadN parameter), and consume RAM memory as follows:

* hg19:       29,918 MB
* hg38:       30,574 MB
* mm10:       27,532 MB
* danRer10:   23,523 MB
* tair11:     4,301 MB
* tair10:     4,282 MB
* sl3:        17,663 MB

::

    $HOST_MOUNT/utap-meta-data/softwares/bin/STAR --runThreadN 30 --runMode genomeGenerate --genomeDir $HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg19/STAR_index/ --genomeFastaFiles $HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg19/gemone_hg19.fa
    $HOST_MOUNT/utap-meta-data/softwares/bin/STAR --runThreadN 30 --runMode genomeGenerate --genomeDir $HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg38/STAR_index/ --genomeFastaFiles $HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg38/gemone_hg38.fa
    $HOST_MOUNT/utap-meta-data/softwares/bin/STAR --runThreadN 30 --runMode genomeGenerate --genomeDir $HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/STAR_index/ --genomeFastaFiles $HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/gemone_mm10.fa
    $HOST_MOUNT/utap-meta-data/softwares/bin/STAR --runThreadN 30 --runMode genomeGenerate --genomeDir $HOST_MOUNT/utap-meta-data/genomes/Danio_rerio/UCSC/danRer10/STAR_index/ --genomeFastaFiles $HOST_MOUNT/utap-meta-data/genomes/Danio_rerio/UCSC/danRer10/gemone_danRer10.fa
    $HOST_MOUNT/utap-meta-data/softwares/bin/STAR --runThreadN 30 --runMode genomeGenerate --genomeDir $HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/ARAPORT/tair11/STAR_index/ --genomeFastaFiles $HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/ARAPORT/tair11/gemone_tair11-araport.fa
    $HOST_MOUNT/utap-meta-data/softwares/bin/STAR --runThreadN 30 --runMode genomeGenerate --genomeDir $HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/NCBI/tair10/STAR_index/ --genomeFastaFiles $HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/NCBI/tair10/gemone_tair10.fa
    $HOST_MOUNT/utap-meta-data/softwares/bin/STAR --runThreadN 30 --runMode genomeGenerate --genomeDir $HOST_MOUNT/utap-meta-data/genomes/Solanum_lycopersicum/SGN/sl3/STAR_index/ --genomeFastaFiles $HOST_MOUNT/utap-meta-data/genomes/Solanum_lycopersicum/SGN/sl3/gemone_sl3.fa


Build the BOWTIE2 index
-----------------------
The commands listed below take ~1 hour per genome and consume ~15g RAM memory.

::

    CONDA=/your/path/to/miniconda2/folder
    $CONDA/envs/utap-chromatin/bin/bowtie2-build $HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg19/gemone_hg19.fa $HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg19/BOWTIE2_index/hg19
    $CONDA/envs/utap-chromatin/bin/bowtie2-build $HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg38/gemone_hg38.fa $HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg38/BOWTIE2_index/hg38
    $CONDA/envs/utap-chromatin/bin/bowtie2-build $HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/gemone_mm10.fa $HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/BOWTIE2_index/mm10


After extracting the fasta files and building the index, you can delete the fasta and .2bit files:

::

   rm $HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg19/gemone_hg19.fa
   rm $HOST_MOUNT/utap-meta-data/genomes/Homo_sapiens/UCSC/hg38/gemone_hg38.fa
   rm $HOST_MOUNT/utap-meta-data/genomes/Mus_musculus/UCSC/mm10/gemone_mm10.fa
   rm $HOST_MOUNT/utap-meta-data/genomes/Danio_rerio/UCSC/danRer10/gemone_danRer10.fa
   rm $HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/ARAPORT/tair11/gemone_tair11-araport.fa
   rm $HOST_MOUNT/utap-meta-data/genomes/Arabidopsis_thaliana/NCBI/tair10/gemone_tair10.fa
   rm $HOST_MOUNT/utap-meta-data/genomes/Solanum_lycopersicum/SGN/sl3/gemone_sl3.fa
   rm $HOST_MOUNT/utap-meta-data/2bit_genomes/*

Run UTAP
========

Pull UTAP image from the public repository
------------------------------------------
::

   docker pull refaelkohen/utap



For running UTAP on a local server, execute the following command (all parameters all mandatory), which will create a Docker container called "utap".

::

   $HOST_MOUNT/utap-meta-data/installation/utap-install.sh -a DNS_HOST -b HOST_MOUNT -c REPLY_EMAIL -d MAIL_SERVER -e HOST_APACHE_PORT -g ADMIN_PASS -h USER -i INSTITUTE_NAME -j DB_PATH -k MAX_UPLOAD_SIZE -m MAX_CORES -n local

For running UTAP on a compute cluster run the command:
::

   $HOST_MOUNT/utap-meta-data/installation/utap-install.sh -a DNS_HOST -b HOST_MOUNT -c REPLY_EMAIL -d MAIL_SERVER -e HOST_APACHE_PORT -g ADMIN_PASS -h USER -i INSTITUTE_NAME -j DB_PATH -k MAX_UPLOAD_SIZE -m MAX_CORES -n CLUSTER_TYPE -o CLUSTER_QUEUE -p RESOURCES_PARAMS -q CONDA



After the run, you can access the application using the address: http://DNS_HOST:HOST_APACHE_PORT (according to your choices for values of these parameters)

You can run the command in the background and close the terminal.

Parameters
----------

-a DNS_HOST             DNS address of the host server.

                        **For example:** http://servername.ac.il or servername.ac.il

-b HOST_MOUNT           Mount point from the docker on the host (full path of the folder).

                        This is the folder that contains the utap-meta-data folder.

                        All input and output data for all of the users will be written into this folder.

-c REPLY_EMAIL          Support email for users. Users can reply to this email.



-d MAIL_SERVER          Domain name of the mail server

                        **For example:** mg.weizmann.ac.il

-e HOST_APACHE_PORT     Any available port on the host server for the Docker Apache.

                        **For example:** 8081

-f HOST_SSH_PORT        (Optional) Any available port on the host server for the Docker ssh server.

                        **For example:** 2222

-g ADMIN_PASS           Password of an admin in the djnago database

                        (the string can contain only A-Za-z0-9 characters without whitespaces).

-h USER                 user in host server that has permission to run cluster commands and write into the $HOST_MOUNT folder (cannot be root).

-i INSTITUTE_NAME       Your institute name or lab

                        (the string can contain only A-Za-z0-9 characters without whitespaces).


-j DB_PATH              Full path to the folder where the DB will be located.

                        $USER needs to have write permission for this folder.

                        The "DB_PATH" should not be under a mounted folder. The DB is very small, so it is will not create disk space problems.

                        **For example:** mkdir /utap-db; chown -R $USER/utap-db;

-k MAX_UPLOAD_SIZE      Maximum file/folder size that a user can upload at once (Megabytes).

                        **For example:** 314572800 (i.e. 300*1024*1024 = 314572800Mb = 300Gb)

-l PROXY_URL            (Optional) url of utap if you using with proxy. default: DNS_HOST:HOST_APACHE_PORT

-m MAX_CORES            Maximum cores in the host computer or in each node of the cluster

-n CLUSTER_TYPE         "local". The commands of the UTAP application will be run on the local server;

                        there is no need to supply the parameters: CLUSTER_QUEUE, CONDA, or AUTH_KEYS_FILE.


Additional parameters for installing on a cluster
-------------------------------------------------

-n CLUSTER_TYPE         Type of the cluster.

                        **For example:** lsf or pbs.

                        The commands will be sent to the cluster. Currently, UTAP supports LSF or PBS cluters.

-o CLUSTER_QUEUE        Queue name in the cluster. $USER must have permissions to run on this queue.

-p RESOURCES_PARAMS     Parameters for your cluster resources.

                        If the memory is per cpu, set mem=resources.mem_mb_per_thread,

                        If the memory is for all cpus of the job together, set mem=resources.mem_mb_total

                        Examples (be sure to use quotes exactly as shown below):

                        '-l select=1:ncpus={threads}:mem={resources.mem_mb_total}mb'

                        '-l mem={resources.mem_mb_total}mb,nodes=1:ppn={threads}'

                        '-n {threads} -R "rusage[mem={resources.mem_mb_per_thread}]" -R "span[hosts=1]"'

-q CONDA                Full path to root folder of miniconda.

                        **For example:** /miniconda2



**Important:**

A file called db.sqlite3 will be created within $DB_PATH folder.

The db.sqlite3 file is the database of the application; it contains user details, and links to results in the $HOST_MOUNT folder.

The $HOST_MOUNT folder contains all of the data for all of the users (input and output files).

The db.sqlite3 database and $HOST_MOUNT folder are located on the disk of the host server (out of the docker container).

When you stop/delete the "utap" container, the database and $HOST_MOUNT folder are not deleted.

**If there is a need to temporarily delete the docker, keep the database ("db.sqlite3") and the same $HOST_MOUNT folder. When you rerun the docker via the utap-install.sh script, you can use the existing database ("db.sqlite3") and $HOST_MOUNT folder.**
