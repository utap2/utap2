
Installation
############

*Support:* utap@weizmann.ac.il


Requirements
============


The application should be installed on a Linux server.


If the server supports LSF or PBS cluster, it is recommended to run UTAP pipelines on the cluster in order to improve computational efficiency. Otherwise, if the server does not support LSF or PBS cluster, the UTAP pipelines will need to be executed locally.


The host server and/or each compute node in the relevant queue(s) requires ~40GB of RAM memory and ~25 GB available in temp folder (the default temp directory is /tmp but it can be modified with SINGULARITY_TMP_DIR in optional_parameters file below).

The server requires the following:
Singularity version > 3.10.4 

A user defined as “USER” (see below)  with “Fakeroot” privileges is required for building singularity image with singularity definition file, if you can’t acquire fakeroot privileges, an installation using sandbox container is possible, please see the bellow section “UTAP sandbox installation”.

The “USER” must have full permissions to HOST_MOUNT folder (see below) and to singularity commands.
If the application is run on cluster, the user is also required to have permissions to run cluster command 

The "USER" should then do the following:


Create a directory for UTAP software and its output
===================================================

Note: Since user output data will be written in this folder, please verify that you have sufficient disk space -  approximately 400G per analysis.
::

   HOST_MOUNT=<the relevant path>
   mkdir $HOST_MOUNT
   cd $HOST_MOUNT


Download the UTAP installation folder 
---------------------
The UTAP installation folder includes the following files:
  a.	install_UTAP_singularity.sh
  b.	optional_parameters.conf
  c.	ports.conf
  d.	required_parameters.conf
  e.	Singularity_sed.def
  f.	update-db.sh
  g.	utap_install_image.sh
  i.	run_UTAP_sandbox.sh

 You can download it using your browser or via ftp as noted below, and then unpack it in the $HOST_MOUNT folder.
::


   #Download the zipped folder into $HOST_MOUNT folder:
   wget ftp://dors.weizmann.ac.il/UTAP/UTAP_installation_files.tar.gz -P $HOST_MOUNT
   
   cd $HOST_MOUNT
    tar -xvzf UTAP_installation_files.tar.gz && mv UTAP_installation_files/* .


Download genomes indexes
-------------------------

The genomes folder includes human (hg38), mouse(mm10) and zebrafish(danRer11) genomes indexes, you can choose to download only one of them as noted below.
If you require a genome that is not supplied, please follow the instruction in the section “Generate new genome index and annotation file”.

You can download the genomes folder using your browser or via ftp as noted below, and then unpack it in the $HOST_MOUNT under genomes directoy. If you chose to download the genomes in a diffrent location,you have to overwrite the parameter GENOMES_DIR in the optional_prameters file.

In any case, if you are using multiple genomes, ensure that they are synchronized under the same directory using the rsync command as indicated below. 
::

    #Download the zipped folder into $HOST_MOUNT folder:
    #For Zebrafish genome:
    wget ftp://dors.weizmann.ac.il/UTAP/UTAP_genomes/Zebrafish.tar.gz
    tar -xvzf Zebrafish.tar.gz
    mkdir genomes
    rsync -a Mouse/* Human/* Zebrafish/* genomes/
    
    #For Mouse genome:
    wget ftp://dors.weizmann.ac.il/UTAP/UTAP_genomes/Mouse.tar.gz
    tar -xvzf Mouse.tar.gz
    mkdir genomes
    rsync -a Mouse/* genomes/
    
    #For Human genome:
    wget ftp://dors.weizmann.ac.il/UTAP/UTAP_genomes/Human.tar.gz
    tar -xvzf Human.tar.gz
    mkdir genomes;
    rsync -a Human/* genomes/
    
    #for combining all genomes together:
    rsync -a Human/* Mouse/* Zebrafish/*  genomes/



Run UTAP
========

Pull UTAP image from the public repository
------------------------------------------
::

   singularity pull library://utap2/test/utap:latest


Fill up all the parameters in files required_parameters.conf and optional_parameters.conf. 

All the parameters in the file required_parameters.conf are mandatory.
The parameters in the file optional_parameters.conf are not mandatory and are used to overwrite the existed default parameters in the file. 

All the parameters are described bellow under the sectio parameters.

For running UTAP run the command in the shell:

::

    cd $HOST_MOUNT
    
    ./install_UTAP_singularity.sh -a required_parameters -b optional_parameters
    


An image named utap.SIF (~7GB) will be generated in your $HOST_MOUNT directory with additonal folders and files required for UTAP run.

If "USER" has fakeroot privilleges, a utap instance will be lunched and after the run, you will be able to aceess the application using the address: 
http://DNS_HOST:HOST_APACHE_PORT or http://host_ip:8000 if the default values for DNS_HOST and HOST_APACHE_PORT were not changed.

If the "USER" lacks fakeroot privileges, then follow the steps in section "UTAP sandbox installation".


UTAP sandbox installation
------------------------------------------

This installation is for USER that doesn’t have fakeroot privilege.

**Make sure that the parameter FAKEROOT=FALSE in the optional_parameters file.

All the initial steps are like the ones described above.

After running the command:
 ./install_UTAP_singularity.sh -a required_parameters.conf -b optional_parameters.conf
as described above. 

a sandbox container named utap.sandbox will be generated in the $HOST_MOUNT folder.

Enter  utap.sandbox container and run the follwing commands in the shell:

::

    cd $HOST_MOUNT
    source singularity_variables
    singularity shell --writable utap.snadbox

run the script run_UTAP_sandbox.sh as described below:
::

    cd /opt
    ./run_UTAP_sandbox.sh


After the run, you can access the application using the address: http://DNS_HOST:HOST_APACHE_PORT or http://host_ip:8000 if the default values for DNS_HOST and HOST_APACHE_PORT were not changed.


Important:

A file called db.sqlite3 will be created within $DB_PATH folder.

The db.sqlite3 file is the database of the application; it contains user details, and links to results in the $HOST_MOUNT folder.

The $HOST_MOUNT folder contains all of the data for all of the users (input and output files).

The db.sqlite3 database and $HOST_MOUNT folder are located on the host serverand not inside the container. 
Therefore, ehen you stop/delete the "utap" container, the database and $HOST_MOUNT folder are not deleted.

If there is a need to temporarily delete the singularity, keep the database ("db.sqlite3") 

and the same $HOST_MOUNT folder. When you rerun the singularity via the install_UTAP_singularity.sh script, you can use the existing database ("db.sqlite3") and $HOST_MOUNT folder.


Parameters
==========

Required parameters
-------------------

HOST_MOUNT             
                       Mount point from the singularity on the host (full path of the folder).
                          
                       This is the folder that contains all UTAP installation files,
                          
                       All input and output data for all of the users will be written into this folder.


ADMIN_PASS              
                       Password of an admin in the djnago database
                        
                       (The password must contain at least one uppercase character, one lowercase character, and one digit)


MAX_CORES               
                       Maximum cores in the host computer or in each node of the cluster



MAX_MEMORY                                      
                       Maximum memory in MB in the host computer or in each node of the cluster 



Optional parameters
-------------------                        
                        
                        
                        
USER                   
                       User in host server that has permission to run cluster commands (if run with cluster), run singularity commands and write 

                       into the $HOST_MOUNT folder (user can have fakeroot permissions).

                       **The default is:** USER=$USER


DNS_HOST               
                       DNS address of the host server.

                       For example: http://servername.ac.il or servername.ac.il
                        
                       The default is the IPv4 address of the host server (can be obtained with the command 'hostname -I')


REPLY_EMAIL            
                       Support email for users. Users can reply to this email.
                      
                       Can only be used if the folowing parameter MAIL_SERVER is defined.
                      
                       **The default is:** REPLY_EMAIL=None


MAIL_SERVER            
                       Domain name of the mail server

                       **For example:** mg.weizmann.ac.il
                        
                       **The default is:**  REPLY_EMAIL= None


HOST_APACHE_PORT        
                        Any available port on the host server for the singularity Apache.

                        **For example:** 8080
                        
                        **The default is:** HOST_APACHE_PORT= 8000




INSTITUTE_NAME           
                        Your institute name or lab

                        (the string can contain only A-Za-z0-9 characters without whitespaces).

                        **The default is:** INSTITUTE_NAME =None



MAX_UPLOAD_SIZE          
                        Maximum file/folder size that a user can upload at once (Megabytes).

                        **For example:** 314572800 (i.e. 300*1024*1024 = 314572800Mb = 300Gb)

                        **The default is:** MAX_UPLOAD_SIZE =314572800



CONDA                   
                        Full path to root folder of miniconda.

                        A full miniconda3 env exist inside the container 

                        **For example:** /miniconda2

                        **The default is:** CONDA=None 
                        
                        When default parameter is used the environmet at /opt/miniconda3 inside the container will be used


TEST                    
                        Set to 1 if the container is for testing.

                        **The default is:** TEST=None 


DEVELOPMENT             
                        Set to 1 if the container is for development 

                        **The default is:** DEVELOPMENT=None


PROXY_URL              
                        URL of utap if you using with proxy. default: DNS_HOST:HOST_APACHE_PORT


UTAP_CODE              
                        The full path to the external UTAP code. 

                        Code exists inside the container.

                        **The default is:** UTAP_CODE=None 
                       
                        When default parameter is used the code at /opt/utap inside the container will be used


INTERNAL_OUTPUT        
                        Host internal output to be mounted 

                        **The default is:** INTERNAL_OUTPUT=None


DEMO_SITE              
                       Set to 1 if the container is for demo

                       **The default is:** DEMO_SITE=None



RUN_NGSPLOT           
                      Set to 1 if for running NGS-plot.

                      **The default is:** RUN_NGSPLOT=None


HOST_HOME_DIR        
                     The home USER home directory on the host 

                     **For example:** /home/username 

                     **The default is:** $HOME


INTERNAL_USERS       
                     Set to 1 if utap installation is for Weizmann users

                     **The default is:** INTERNAL_USERS=None 

DB_PATH              
                     Full path to the folder where the DB will be located.

                     $USER needs to have write permission for this folder.

                     The DB is very small, so it is will not create disk space problems.

                     **For example:** mkdir /utap-db; chown -R $USER/utap-db; 

                     **The default is:** DB_PATH=$HOST_MOUNT/UTAP_DB


GENOMES_DIR          
                     The full path to the genomes directory.

                     **The default is:** GENOMES_DIR =$HOST_MOUNT/genomes 


SINGULARITY_TMP_DIR           
                     Singularity uses a temporary directory to build the squashfs filesystem, and this temp space needs to be at least 25GB  

                     large to hold the entire resulting Singularity image.
 
                     If you use fakeroot privileges,  make sure that the tmp directory is  local and not NFS or GPFS mounted disc.

                     **The default is:** SINGULARITY_TMP_DIR=/tmp

FAKEROOT                      
                     Set to 1 If USER has fakeroot privileges.

                     **The default is:** FAKEROOT=1


SINGULARITY_HOST_COMMAND           Singularity command on the host 

                                   **for example:** if singularity is installed as module named Singularity on the host then the command will be :”ml                                       
                                   Singularity”

                                   **The default is:** SINGULARITY_HOST_COMMAND=None 



Additional optional parameters for installing on a cluster:




CLUSTER_TYPE         
                     Type of the cluster.

                     **For example:** lsf or pbs or local.

                     The commands will be sent to the cluster. Currently, UTAP supports LSF or PBS cluters.
                     
                     When "local" parameter is used , UTAP pipelines will be run on the local host inside the container.

                     **The default is:** CLUSTER_TYPE=local



CLUSTER_QUEUE           Queue name in the cluster. $USER  must have permissions to run on this queue. 

                        **The default is:** CLUSTER_QUEUE=None
                        

SINGULARITY_CLUSTER_COMMAND         Singularity command on the cluster 

                                    for example: if singularity is installed as module named Singularity on the cluster, then command will be :”ml                                           
                                    Singularity”

                                    **The default is:** SINGULARITY_CLUSTER_COMMAND=None 
                                    





