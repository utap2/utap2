#!/bin/bash



if [ "$SINGULARITY_CLUSTER_COMMAND" = "None" ]
then
	export SINGULARITY_CLUSTER_COMMAND=""
else
	export SINGULARITY_CLUSTER_COMMAND="$SINGULARITY_CLUSTER_COMMAND;"
fi



if [ "$FAKEROOT" = "FALSE" ]
then
  if [ "$CONDA" != "None" ]; then  #external conda env entered as input
    export MAIN_CONDA="/mnt/conda"
    RUN_LOCAL_HOST_CONDA="RUN_LOCAL_HOST_CONDA\=True";
    echo "You are installing UTAP that runs with external conda environment on the host" 
  else #no external conda env entered as input, the conda env inside the image will used
    RUN_LOCAL_HOST_CONDA="RUN_LOCAL_HOST_CONDA\=False";
    export MAIN_CONDA=/opt/miniconda3/envs/utap
    echo "You are installing UTAP that runs local conda environment inside the image"
  fi 
  export DB_PATH="/mnt/utap_db"
  export GENOMES_DIR="/mnt/genomes"
  export HOST_MOUNT="/mnt/host_mount"
  export INTERNAL_OUTPUT="/mnt/internal_output"
else 
  if [ "$CONDA" != "None" ]; then  #external conda env entered as input
    export MAIN_CONDA=$CONDA
    RUN_LOCAL_HOST_CONDA="RUN_LOCAL_HOST_CONDA\=True";
    echo "You are installing UTAP that runs with external conda environment on the host" 
  else #no external conda env entered as input, the conda env inside the image will used
    RUN_LOCAL_HOST_CONDA="RUN_LOCAL_HOST_CONDA\=False";
    export MAIN_CONDA=/opt/miniconda3/envs/utap
    echo "You are installing UTAP that runs local conda environment inside the image"
   fi
fi




if [ "$CLUSTER_TYPE" = "lsf" ]; then
  export CLUSTER_EXE=bsub
  echo "You are installing UTAP that run on cluster"
  RUN_LOCAL="RUN_LOCAL\=False";
  
elif [ "$CLUSTER_TYPE" = "pbs" ]; then
  echo "You are installing UTAP that run on cluster"
  RUN_LOCAL="RUN_LOCAL\=False";
  export CLUSTER_EXE=qsub
else
  export CLUSTER_EXE=""
  echo "You are installing UTAP that runs on the local server"
  RUN_LOCAL="RUN_LOCAL\=True"
fi


if [ "$DEMO_SITE" != "None" ]; then # It is demo site
  echo "You are installing demo version of UTAP"
  DEMO_SITE="DEMO_SITE\=True"
else
  DEMO_SITE="DEMO_SITE\=False"
fi 

DB_PATH=$DB_PATH"/db.sqlite3"
WEIZMANN_EMAIL="utap@weizmann.ac.il" # Our email for notifications
NOTIFICATION_EMAILS="$REPLY_EMAIL,$WEIZMANN_EMAIL"




RSCRIPT=$MAIN_CONDA/bin/Rscript #Need upload environment of conda
BIOUTILS_PACKAGE=$MAIN_CONDA
SNAKEFILE_PACKAGE=$MAIN_CONDA
R_LIB_PATHS=$MAIN_CONDA/lib/R/library
SNAKEMAKE_EXE=$MAIN_CONDA/bin/snakemake
CUTADAPT_EXE=$MAIN_CONDA/bin/cutadapt
FASTQC_EXE=$MAIN_CONDA/bin/fastqc
STAR_EXE=$MAIN_CONDA/bin/STAR
SAMTOOLS_EXE=$MAIN_CONDA/bin/samtools
GS_EXE=$MAIN_CONDA/bin/gs
BOWTIE1_EXE=$MAIN_CONDA/bin/bowtie
HOMER_EXE=$MAIN_CONDA/bin/homer
BEDGRAPH_TO_BIGWIG=$MAIN_CONDA/bin/bedGraphToBigWig
BEDCLIP=$MAIN_CONDA/bin/bedClip
MULTIQC_EXE=$MAIN_CONDA/bin/multiqc
BOWTIE2_EXE=$MAIN_CONDA/bin/bowtie2
PICARD_EXE=$MAIN_CONDA/bin/picard
IGVTOOLS_EXE=$MAIN_CONDA/bin/igvtools
MACS2_EXE=$MAIN_CONDA/bin/macs2
BEDTOOLS_EXE=$MAIN_CONDA/bin/bedtools
HTSEQ_COUNT_EXE=$MAIN_CONDA/bin/htseq-count
BCL2FASTQ_EXE=$MAIN_CONDA/bin/bcl2fastq

#these are old software versions which are not compatible with python3.10 in main conda and are instlled in another conda env calles ngsplot 
MACS_EXE=/opt/miniconda3/envs/ngsplot/bin/macs 
TOPHAT_EXE=/opt/miniconda3/envs/ngsplot/bin/tophat
if [ "$RUN_NGSPLOT" != "None" ]; then # Run ngsplot
  NGS_PLOT_EXE='\"export PATH=/opt/miniconda3/envs/ngsplot/bin:$PATH; /opt/miniconda3/envs/ngsplot/bin/ngs.plot.r\"'
else
  NGS_PLOT_EXE=""
fi
PEAKSPLITTER_EXE='java -jar /opt/local_program/PeakSplitter_Java/PeakSplitter.jar'
CELLRANGER_EXE=$INTERNAL_OUTPUT/bioservices/services/cellranger-5.0.0/cellranger
#KENTUTILS_EXE='module load kentUtils;'
#PYTHON_EXE='module load python/bio-2.7.13;'
#JRE_EXE='module load jre;'
#IGVTOOLS_EXE_FOR_RIBOSEQ='module load IGVTools/2.3.26;'
#Addional softwars for chromatin pipelines (ATAC-seq and Chip-seq): - for now not installed inside docker. So cannot be run locally.
#JAVA_EXE=$CONDA/envs/utap-chromatin/bin/java




printf "Input variables in utap_install_image.sh:\n=====================================\nDNS_HOST: $DNS_HOST\nHOST_MOUNT: $HOST_MOUNT\nREPLY_EMAIL: $REPLY_EMAIL\nMAIL_SERVER: $MAIL_SERVER\nSERVER_NAME: $SERVER_NAME\nUSER: $USER\nPRIMARYGRP: $PRIMARYGRP\nPRIMARYGRP_ID: $PRIMARYGRP_ID\nUSERID: $USERID\nUSER_GROUPS: $USER_GROUPS\nGUD_GROUPS: $GID_GROUPS\nHOST_APACHE_PORT: $HOST_APACHE_PORT\nHOME: $HOME\nINSTITUTE_NAME: $INSTITUTE_NAME\nCLUSTER_TYPE: $CLUSTER_TYPE\nCLUSTER_QUEUE: $CLUSTER_QUEUE\nCLUSTER_RESOURCES_PARAMS: $CLUSTER_RESOURCES_PARAMS\nMAX_CORES $MAX_CORES\nDB_PATH: $DB_PATH\nCONDA: $CONDA\nMAX_UPLOAD_SIZE: $MAX_UPLOAD_SIZE\nINTERNAL_OUTPUT: $INTERNAL_OUTPUT\nINTERNAL_USERS: $INTERNAL_USERS\nLDAP_CERTIFICATE: $LDAP_CERTIFICATE\nPROXY_URL: $PROXY_URL\nDEMO_SITE: $DEMO_SITE\nRUN_NGSPLOT: $RUN_NGSPLOT\n\n==============\n"




#For job submission by the cluster need to change the servername in the container like the host

#sed "s/SERVER_NAME/$SERVER_NAME/" /etc/apache2/sites-available/SERVER_NAME.conf | sed "s/HOST_MOUNT/${HOST_MOUNT//\//\\/}/" > /etc/apache2/sites-available/SERVER_NAME.conf.tmp
sed "s/SERVER_NAME/$SERVER_NAME/" /etc/apache2/apache2.conf.sed | sed "s/USER_SED/$USER/" | sed "s/GROUP_SED/$PRIMARYGRP/" | sed "s/HOST_MOUNT/${HOST_MOUNT//\//\\/}/" > /etc/apache2/apache2.conf



#bsub requires user that exists on the host with the same home directory on the host(not root):

#The loop in this section is not relevant, because in last version we create user only with effective group (only one group), because we use with ssh for running jobs on the cluster.
#for g in $(echo $GID_GROUPS|sed "s/,/ /g"); do
#  gname=$(getent group $g | cut -f1 -d:)
#  gid=$(getent group $g | cut -f2 -d:)
#  if [ "$gid" ]; then
#    echo "User $USER cannot belong to group id $gid. This group id already exists in the docker."
#    #exit
#  fi;
#  if [ "$gname" ]; then
#    echo "User $USER cannot belong to group id $gname. This group name already exists in the docker."
#    #exit
#  fi;
#  addgroup --force-badname --gid $g  $USER_GROUPS; #TODO:In this version we suppose that $USER_GROUPS contain only one group (effective group). Need to remove this irrelevant group
#done
#
#useradd  --groups $USER_GROUPS --gid $PRIMARYGRP_ID --shell /bin/bash --uid $USERID  --home-dir $HOME $USER
#echo "$USER:1234" | chpasswd

PYTHON_EGGS=$HOST_MOUNT/utap-output/.python-eggs
CONDA_ENV=$MAIN_CONDA/bin
CONDA_ROOT="$(echo $MAIN_CONDA | awk -F miniconda '{print $1 "miniconda" $2 -f1}')"



sed -i "s/PYTHON_EGG_CACHE_SED/${PYTHON_EGGS//\//\\/}/" /root/.bashrc
sed -i "s/CONDA_SED/${CONDA_ROOT//\//\\/}/" /root/.bashrc
sed -i "s/CONDA_ENV_SED/${CONDA_ENV//\//\\/}/" /root/.bashrc
sed -i "s/PYTHON_EGG_CACHE_SED/${PYTHON_EGGS//\//\\/}/" /etc/apache2/envvars
sed -i "s/CONDA_SED/${CONDA_ROOT//\//\\/}/" /etc/apache2/envvars
sed -i "s/CONDA_ENV_SED/${CONDA_ENV//\//\\/}/" /etc/apache2/envvars



#sudo to $USER
#sed -i "s/USER_SED/$USER/" /etc/sudoers.d/sudoers

#######################   UTAP   ######################################

#change UTAP code location 
if [ $UTAP_CODE != "None" ]; then 
  mv /opt/utap/ /opt/utap.bak
  ln -s $UTAP_CODE /opt/
fi


#Change the code of the settings file:

sed "s/HOST_MOUNT=PROJECT_ROOT/HOST_MOUNT='${HOST_MOUNT//\//\\/}'/" /opt/utap/analysis/backend/settings_base_template.py | sed "s/'PIPELINE_SERVER'/'$DNS_HOST'/" | sed "s/'NOTIFICATION_INTERNAL_MAILING_LIST_SED_TEMPLATE'/'$NOTIFICATION_EMAILS'/" | sed "s/DEMO_SITE\=False/$DEMO_SITE/" | sed "s/RUN_LOCAL\=True/$RUN_LOCAL/"  | sed "s/RUN_LOCAL_HOST_CONDA\=True/$RUN_LOCAL_HOST_CONDA/"  | sed "s/'INSTITUTE_NAME'/'${INSTITUTE_NAME//\//\\/}'/" | sed "s/'CLUSTER_QUEUE'/'$CLUSTER_QUEUE'/" | sed "s/'DB_PATH'/'${DB_PATH//\//\\/}'/" | sed "s/'MAIL_SERVER'/'$MAIL_SERVER'/" | sed "s/'PIPELINE_SERVER_PORT_SED'/$HOST_APACHE_PORT/" | sed "s/'BIOUTILS_PACKAGE'/'${BIOUTILS_PACKAGE//\//\\/}'/" | sed "s/'SNAKEFILE_PACKAGE'/'${SNAKEFILE_PACKAGE//\//\\/}'/" | sed "s/'CONDA_ROOT'/'${CONDA_ROOT//\//\\/}'/" | sed "s/'GS_EXE'/'${GS_EXE//\//\\/}'/" | sed "s/'RSCRIPT'/'${RSCRIPT//\//\\/}'/" | sed "s/'R_LIB_PATHS'/'${R_LIB_PATHS//\//\\/}'/" | sed "s/'CUTADAPT_EXE'/'${CUTADAPT_EXE//\//\\/}'/" | sed "s/'FASTQC_EXE'/'${FASTQC_EXE//\//\\/}'/" | sed "s/'STAR_EXE'/'${STAR_EXE//\//\\/}'/" | sed "s/'SAMTOOLS_EXE'/'${SAMTOOLS_EXE//\//\\/}'/" | sed "s/'NGS_PLOT_EXE'/'${NGS_PLOT_EXE//\//\\/}'/" | sed "s/'HTSEQ_COUNT_EXE'/'${HTSEQ_COUNT_EXE//\//\\/}'/" | sed "s/'CLUSTER_EXE'/'${CLUSTER_EXE//\//\\/}'/" | sed "s/'SNAKEMAKE_EXE'/'${SNAKEMAKE_EXE//\//\\/}'/" | sed "s/'BCL2FASTQ_EXE'/'${BCL2FASTQ_EXE//\//\\/}'/" | sed "s/'CELLRANGER_EXE'/'${CELLRANGER_EXE//\//\\/}'/" | sed "s/'JAVA_EXE'/'${JAVA_EXE//\//\\/}'/" | sed "s/'MULTIQC_EXE'/'${MULTIQC_EXE//\//\\/}'/" | sed "s/'BOWTIE2_EXE'/'${BOWTIE2_EXE//\//\\/}'/" | sed "s/'PICARD_EXE'/'${PICARD_EXE//\//\\/}'/" | sed "s/'IGVTOOLS_EXE'/'${IGVTOOLS_EXE//\//\\/}'/" | sed "s/'MACS2_EXE'/'${MACS2_EXE//\//\\/}'/" | sed "s/'BEDTOOLS_EXE'/'${BEDTOOLS_EXE//\//\\/}'/" | sed "s/'IGVTOOLS_EXE_FOR_RIBOSEQ'/'${IGVTOOLS_EXE_FOR_RIBOSEQ//\//\\/}'/" | sed "s/'JRE_EXE'/'${JRE_EXE//\//\\/}'/" | sed "s/'PYTHON_EXE'/'${PYTHON_EXE//\//\\/}'/" | sed "s/'PEAKSPLITTER_EXE'/'${PEAKSPLITTER_EXE//\//\\/}'/" | sed "s/'HOMER_EXE'/'${HOMER_EXE//\//\\/}'/" | sed "s/'KENTUTILS_EXE'/'${KENTUTILS_EXE//\//\\/}'/" | sed "s/'BOWTIE1_EXE'/'${BOWTIE1_EXE//\//\\/}'/" | sed "s/'MACS_EXE'/'${MACS_EXE//\//\\/}'/" | sed "s/'TOPHAT_EXE'/'${TOPHAT_EXE//\//\\/}'/" | sed "s/'MAX_UPLOAD_SIZE'/${MAX_UPLOAD_SIZE}/" | sed "s/'USER_CLUSTER'/'${USER}'/" | sed "s/'CLUSTER_TYPE'/'${CLUSTER_TYPE}'/" | sed "s/'CLUSTER_RESOURCES_PARAMS'/'${CLUSTER_RESOURCES_PARAMS}'/" | sed "s/'MAX_CORES'/'${MAX_CORES}'/" | sed "s/'MAX_MEMORY'/'${MAX_MEMORY}'/" | sed "s/'PROXY_URL'/'${PROXY_URL//\//\\/}'/" | sed "s/'SINGULARITY_CLUSTER_COOMAND'/'${SINGULARITY_CLUSTER_COMMAND//\//\\/}'/" | sed "s@'IMAGE_PATH'@'${IMAGE_PATH}'@" | sed "s@'SINGULARITY_MOUNTS'@'${SINGULARITY_MOUNTS}'@" | sed "s/'BEDGRAPH_TO_BIGWIG'/'${BEDGRAPH_TO_BIGWIG//\//\\/}'/" | sed "s/'BEDCLIP'/'${BEDCLIP//\//\\/}'/" > /opt/utap/analysis/backend/settings_base.py


if [ $INTERNAL_USERS != "None" ]; then # if not empty variable - it is internal users
  cp /opt/utap/analysis/backend/settings_internal_template.py /opt/utap/analysis/backend/settings.py
else #external users
  cp /opt/utap/analysis/backend/settings_external_template.py /opt/utap/analysis/backend/settings.py
fi

#chown -R $USER:$PRIMARYGRP_ID /opt/bbcu-ngs-pipelines/utap/ #Enable to $USER to run makemigrations collectstatic
chmod -R 777 /opt/utap/ #Executable permission after collectstatic (need js to be executable ?)
chmod 777 /opt/update-db.sh

# Update DB with the genomes and annotations:
echo "Start build database of Djnago"
/opt/update-db.sh -a $HOST_MOUNT -b $REPLY_EMAIL -c $ADMIN_PASS -d $TEST -e $INTERNAL_USERS -f $GENOMES_DIR

mkdir -p $HOST_MOUNT/utap-output/.python-eggs
echo yes | /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py collectstatic



#######################################################################


#if [ $LDAP_CERTIFICATE != "None" ]; then # if not empty variable - it is internal users
#  sed -i "s/CERTIFICATE_FILE_SED/${LDAP_CERTIFICATE//\//\\/}/" /etc/ldap/ldap.conf
#fi



#smtp server:

sed "s/REPLY_EMAIL/$REPLY_EMAIL/" /etc/ssmtp/ssmtp.conf | sed "s/MAIL_SERVER/$MAIL_SERVER/" | sed "s/SERVER_NAME/$SERVER_NAME/" > /etc/ssmtp/ssmtp.conf.sed
sed "s/REPLY_EMAIL/$REPLY_EMAIL/" /etc/ssmtp/revaliases > /etc/ssmtp/revaliases.sed
mv -f /etc/ssmtp/ssmtp.conf.sed /etc/ssmtp/ssmtp.conf
mv -f /etc/ssmtp/revaliases.sed /etc/ssmtp/revaliases


cp /root/{.bashrc,.profile}  $HOME
chmod 777 $HOME/.bashrc
#chown $USER:$PRIMARYGRP_ID $HOME/.bashrc
source $HOME/.bashrc


################################
#if [ $CLUSTER_TYPE != "local" ]; then
#  echo |ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa
#  cp -r /root/.ssh $HOME
#  chmod -R 777 $HOME/.ssh
#  #coping container RSA key to the host authorized_keys
#  if [ $CONDA != "None" ]; then # Not empty variable
#    echo "coping ssh folder"
#    cat $HOME/.ssh/id_rsa.pub >> $SSH_DIR_DOCKER/authorized_keys
#    cat $HOME/.ssh/id_rsa.pub >> $SSH_DIR_DOCKER/authorized_keys2
#  fi
#fi
####################################


if [ $CLUSTER_TYPE != "local" ]; then
  if [ ! -f  $HOST_HOME_DIR/.ssh/id_rsa.pub ]; then
    ssh-keygen -t rsa -N "" -f $HOST_HOME_DIR
  fi	
	cat $HOST_HOME_DIR/.ssh/id_rsa.pub >> $HOST_HOME_DIR/.ssh/authorized_keys
	chmod 700 $HOST_HOME_DIR/.ssh
	chmod 600 $HOST_HOME_DIR/.ssh/*
fi

chmod 777 /etc/apache2/ports.conf
cp  /etc/apache2/ports.conf /etc/apache2/ports.conf.sed
sed "s/HOST_APACHE_PORT/$HOST_APACHE_PORT/" /etc/apache2/ports.conf.sed > /etc/apache2/ports.conf

echo "UTAP installation on image is done"
