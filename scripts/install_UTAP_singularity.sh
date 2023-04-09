#!/bin/bash

while getopts a:b: option
do
 case "${option}"
 in
   a) export required_parameters=${OPTARG};; 
   b) export optional_parameters=${OPTARG};;
   \?) echo "Invalid option: -$OPTARG" >&2;;
 esac
done


if [ -z "${required_parameters}" ];
then 
  echo "ERROR: missing required_parameters file"
fi

if [ -z "${optional_parameters}" ];
then 
  echo "ERROR: missing optional_parameters file"
fi


sed -i 's/[[:space:]]*=[[:space:]]*/=/g'  ${required_parameters} 
sed -i 's/[[:space:]]*=[[:space:]]*/=/g'  ${optional_parameters} 
sed -i 's/^[[:space:]]*//g' ${required_parameters} 
sed -i 's/^[[:space:]]*//g' ${optional_parameters}

for line in `cat required_parameters`
do 
  if [ "$line" != "" ] || [ "$line" != "#"* ];
    then
    var=`sed -n -e 's/=.*//p' <<< "$line"`
    value=`sed -n -e 's/^.*=//p' <<< "$line"`
    if [ -z "${value}" ];
      then 
      echo "missing value for required setting $var"
    fi
  fi
done


cat ${required_parameters} ${optional_parameters} > all_parameters
sed -i -e 's/\r.*//g' all_parameters
source all_parameters


mkdir -p $HOST_MOUNT/{logs-utap,parameters_files,reports,utap-output/admin,apache2/run,apache2/logs,UTAP_HOME_DIR,UTAP_DB}
touch $HOST_MOUNT/jobs_status.txt


#create empty directoy to mounts apache2 logs directories from container 
mkdir -p $HOST_MOUNT/apache2/run
mkdir -p $HOST_MOUNT/apache2/logs




#HOME_DIR_HOST_SSH=$HOME
#export SSH_DIR=$HOME_DIR_HOST_SSH/.ssh
#export SSH_DIR_DOCKER=/host_authorized_keys
#cp -r $SSH_DIR $HOST_MOUNT/UTAP_HOME_DIR

if [ "$HOST_HOME_DIR" = "None" ];
  then 
   export HOST_HOME_DIR=$HOME
fi

if [ "$DB_PATH" = "None" ];
  then 
   export DB_PATH="$HOST_MOUNT/UTAP_DB"
fi


if [ "$GENOMES_DIR" = "None" ]
then
  export GENOMES_DIR=$HOST_MOUNT/genomes
  
fi

if [ "$SINGULARITY_TMP_DIR" != "None" ]
then
	export SINGULARITY_TMPDIR=$SINGULARITY_TMP_DIR
fi



if [ "$SINGULARITY_HOST_COMMAND" = "None" ]
then
  export SINGULARITY_HOST_COMMAND=""
fi



if [ "$FAKEROOT" = "TRUE" ]
then 
  export IMAGE_PATH=$HOST_MOUNT/utap-update-test.SIF #change after testing 
  export GENOMES_MNT=$GENOMES_DIR
  export HOST_MOUNT_MNT=$HOST_MOUNT
  export INTERNAL_MNT=$INTERNAL_OUTPUT
  export DB_MNT=$DB_PATH
  export CONDA_MNT=$CONDA
  export run_UTAP="singularity instance stop utap-update-test; singularity build --fakeroot --writable-tmpfs utap-update-test.SIF Singularity.def && sleep 20; singularity instance start --writable-tmpfs utap-update-test.SIF utap-update-test" #change after testing
else 
  export IMAGE_PATH=$HOST_MOUNT/utap_1.10.3_v6.sandbox #change after testing 
  export CONDA_MNT="/mnt/conda"
  export GENOMES_MNT="/mnt/genomes"
  export HOST_MOUNT_MNT="/mnt/host_mount"
  export INTERNAL_MNT="/mnt/internal_output"
  export DB_MNT="/mnt/utap_db"
  export run_UTAP="singularity build --sandbox utap_1.10.3_v6.sandbox utap-1.10.3_v6.BASE.sif" #change after testing 
fi

export SINGULARITY_MOUNTS="$HOST_MOUNT:$HOST_MOUNT_MNT"


if [ "$INTERNAL_OUTPUT" != "None" ]
then
    SINGULARITY_MOUNTS="$INTERNAL_OUTPUT:$INTERNAL_MNT,$SINGULARITY_MOUNTS"
fi

if [ "$CONDA" != "None" ]
then
    CONDA_DIR='mkdir -p $SINGULARITY_ROOTFS'
    CONDA_DIR="$CONDA_DIR$CONDA"
    SINGULARITY_MOUNTS="$CONDA:$CONDA_MNT,$SINGULARITY_MOUNTS"
    CONDA_PATH=$CONDA
else
   CONDA_DIR=""
   CONDA_PATH=/opt/miniconda3/envs/utap 
fi

if [ ! -d "$GENOMES_DIR" ]; then
   echo "ERROR, no genomes directory provided!"
fi


GENOMES='mkdir -p $SINGULARITY_ROOTFS'
GENOMES="$GENOMES$GENOMES_DIR"
SINGULARITY_MOUNTS="$GENOMES_DIR:$GENOMES_MNT,$SINGULARITY_MOUNTS"



export DNS_HOST=`echo $DNS_HOST | sed 's~http[s]*://~~g'`
export SERVER_NAME=`hostname`
export PRIMARYGRP=`id -gn <<< $USER`
export SINGULARITY_ALL_MOUNTS="$HOST_MOUNT/apache2/run:/var/run/apache2,/$HOST_MOUNT/apache2/logs:/var/log/apache2,$DB_PATH:$DB_MNT,$SINGULARITY_MOUNTS"
#export SINGULARITY_ALL_MOUNTS="$DB_PATH:$DB_PATH,$SINGULARITY_MOUNTS"




echo "export DNS_HOST=$DNS_HOST" >> all_parameters
echo "export SERVER_NAME=$SERVER_NAME" >> all_parameters
echo "export PRIMARYGRP=$PRIMARYGRP" >> all_parameters
echo "export HOME=$HOST_MOUNT/UTAP_HOME_DIR" >> all_parameters
echo "export SINGULARITY_MOUNTS=$SINGULARITY_MOUNTS" >> all_parameters
echo "export HOST_HOME_DIR=$HOST_HOME_DIR" >> all_parameters
echo "export IMAGE_PATH=$IMAGE_PATH" >> all_parameters
echo "export DB_PATH=$DB_PATH" >> all_parameters
echo "export GENOMES_DIR=$GENOMES_DIR" >> all_parameters




cp Singularity_sed.def Singularity.def
sed -ibak -e "s@_CONDA_DIR@$CONDA_DIR@g" -e "s@_GENOMES_DIR@$GENOMES@g" -e "s@_CONDA_PATH@$CONDA_PATH@g" -e "s@_DEVELOPMENT@$DEVELOPMENT@g" -e "s@_HOST_MOUNT@$HOST_MOUNT@g"  -e "s@_DB_PATH@$DB_PATH@g" Singularity.def




touch $HOST_MOUNT/singularity_variables
echo "export  SINGULARITY_BIND=\"$SINGULARITY_ALL_MOUNTS\"" > $HOST_MOUNT/singularity_variables
source $HOST_MOUNT/singularity_variables

eval $SINGULARITY_HOST_COMMAND
eval $run_UTAP
