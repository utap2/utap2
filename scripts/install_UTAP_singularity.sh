#!/bin/bash

#initialize devel parameters
TEST=None
DEVELOPMENT=None
UTAP_CODE=None
INTERNAL_OUTPUT=None
DEMO_SITE=None
INTERNAL_USERS=None
EMAIL_USE_TLS="TLS_USE_IN_MAIL\=False"
EMAIL_PORT=25



#get required and optional parameters files as input 
while getopts a:b: option
do
 case "${option}"
 in
   a) export required_parameters=${OPTARG};; 
   b) export optional_parameters=${OPTARG};;
   \?) echo "Invalid option: -$OPTARG" >&2;;
 esac
done

#check if required parameters file exist
if [ -z "${required_parameters}" ];
then 
  echo "ERROR: missing required_parameters file"
  exit
fi

#check if optional parameters file exist
if [ -z "${optional_parameters}" ];
then 
  echo "ERROR: missing optional_parameters file"
  exit
fi


sed -i 's/[[:space:]]*=[[:space:]]*/=/g'  ${required_parameters} 
sed -i 's/[[:space:]]*=[[:space:]]*/=/g'  ${optional_parameters} 
sed -i 's/^[[:space:]]*//g' ${required_parameters} 
sed -i 's/^[[:space:]]*//g' ${optional_parameters}

#parse all parameters - remove spaces, special characters and check if parameter exist
file="${required_parameters}"
while read -r line; 
do 
  [ -z "$line" ] &&  continue;
  [[ "$line" =~ ^#.*$ ]] && continue;
  var=`sed -n -e 's/=.*//p' <<< "$line"`
  value=`sed -n -e 's/^.*=//p' <<< "$line"`
  if [[ "$value" = *"None"* ]]; then  
      echo "None value for required setting $var"
      exit 
  fi   
  if [ -z "${value}" ];
    then 
      echo "missing value for required setting $var"
      exit
  fi
done < "$file"

#merge all paresed parameters together
cat ${required_parameters} ${optional_parameters} > all_parameters 
echo -e "\n" >> all_parameters 
sed -i -e 's/\r.*//g' all_parameters
source all_parameters


#HOME_DIR_HOST_SSH=$HOME
#export SSH_DIR=$HOME_DIR_HOST_SSH/.ssh
#export SSH_DIR_DOCKER=/host_authorized_keys
#cp -r $SSH_DIR $HOST_MOUNT/UTAP_HOME_DIR


##functions



get_dir_df() {
  param="$1"
  dir_df=`df -P -T $2 |  awk -F' ' 'NR==1 { for (i=1; i<=NF; i++) if ($i ~ /'"${param}"*'/) col=i } { print $col }' - | head -2 | tail -1`
  if [ "$param" = "Avail" ];
  then  
    dir_df=${dir_df%.*}
  fi
  echo $dir_df
} 
  

get_max_resources () {
  hosts=`bqueues -l $CLUSTER_QUEUE | grep HOSTS | cut -d " " -f2-`
  max_resources=$(expr 0 + 0)
  for host in $hosts
  do 
    if [[ $host == *"/" ]]; then
      parsed_host=${host::-1}
      nodes=`bmgroup | grep $parsed_host | cut -d " " -f2-`
      for node in $nodes 
      do 
        resources=`lshosts -w $node | awk -F' ' 'NR==1 { for (i=1; i<=NF; i++) if ($i ~ /'$1'/) col=i } { print $col }' - | head -2 | tail -1 | sed 's|G| |g' -`
        resources=${resources%.*}
        if [ "$max_resources" -lt "$resources" ]; then
          max_resources=$resources 
        fi
      done
    else
        resources=`lshosts -w $host | awk -F' ' 'NR==1 { for (i=1; i<=NF; i++) if ($i ~ /'$1'/) col=i } { print $col }' - | head -2 | tail -1 | sed 's|G| |g' -`
        resources=${resources%.*}
        if [ $max_resources -lt $resources ]; then
          max_resources=$resources 
        fi
    fi
  done
  echo $max_resources
}

check_dir () {
if [ ! -d "$1" ]; then  
 echo "ERROR: $1 does not exist."; 
 exit
fi 

}


override_param () {
  sed -i "s/$1=.*/$1='${2//\//\\/}'/" all_parameters

}

validate_param () {
if [ "$1" != 0 ] && [ "$1" != 1 ] && [ "$1" != "None" ]; then  
 echo "ERROR: invalid value given for parameter $2, valid values are: 0, 1 and None"; 
 exit
fi 
}

run_utap () {
  if [ "$1" = "instance" ]
  then
    echo "starting instance installation"     
    export IMAGE_PATH="$HOST_MOUNT/utap.SIF"  #change after testing 
    export GENOMES_MNT=$GENOMES_DIR
    export HOST_MOUNT_MNT=$HOST_MOUNT
    export INTERNAL_MNT=$INTERNAL_OUTPUT
    export DB_MNT=$DB_PATH
    export CONDA_MNT=$CONDA
    export UTAP_MNT=$UTAP_CODE
    if [ "$RUN_SANDBOX" != "None" ]; then
      echo "installing UTAP sandbox from instance image"
      export run_UTAP="singularity instance stop utap-staging; singularity build --fakeroot --writable-tmpfs utap.SIF Singularity.def && sleep 20; singularity build --sandbox utap.sandbox utap.SIF" #change after testing
    else
      export run_UTAP="singularity instance stop utap-staging; singularity build --fakeroot --writable-tmpfs utap.SIF Singularity.def && sleep 20; singularity instance start --writable-tmpfs utap.SIF utap-staging" #change after testing
    fi
    #modify Singularity.def file
    cp Singularity_sed.def Singularity.def
    sed -ibak -e "s@_CONDA_DIR@$CONDA_DIR@g" -e "s@_GENOMES_DIR@$GENOMES@g" -e "s@_CONDA_PATH@$MAIN_CONDA@g" -e "s@_DEVELOPMENT@$DEVELOPMENT@g" -e "s@_HOST_MOUNT@$HOST_MOUNT@g"  -e "s@_DB_PATH@$DB_PATH@g" Singularity.def  
  else 
    echo "starting sandbox installation"
    export IMAGE_PATH="$HOST_MOUNT/utap.sandbox"  #change after testing
    export CONDA_MNT="/mnt/conda"
    export GENOMES_MNT="/mnt/genomes"
    export HOST_MOUNT_MNT="/mnt/host_mount"
    export INTERNAL_MNT="/mnt/internal_output"
    export DB_MNT="/mnt/utap_db"
    export UTAP_MNT="/opt/utap"
    override_param DB_PATH "$DB_MNT"
    override_param GENOMES_DIR "$GENOMES_MNT"
    override_param HOST_MOUNT "$HOST_MOUNT_MNT"
    #echo "DB_PATH=$DB_MNT" >> all_parameters
    #echo "GENOMES_DIR=$GENOMES_MNT" >> all_parameters
    #echo "HOST_MOUNT=$HOST_MOUNT_MNT"  >> all_parameters
    #echo "INTERNAL_OUTPUT=$INTERNAL_MNT" >> all_parameters
    if [ "$FAKEROOT" = 1 ]; then
      export run_UTAP="singularity build --sandbox utap.sandbox utap_latest.sif && source singularity_variables && singularity exec --writable --fakeroot utap.sandbox service postfix start && singularity exec --writable utap.sandbox bash /opt/run_UTAP_sandbox.sh" #change after testing
    else
      export run_UTAP="singularity build --sandbox utap.sandbox utap_latest.sif && source singularity_variables && singularity exec --writable utap.sandbox bash /opt/run_UTAP_sandbox.sh" #change after testing
    fi   
  fi
  
  #crete mount points from the host to singularity image
  export SINGULARITY_MOUNTS="$HOST_MOUNT:$HOST_MOUNT_MNT"
  
  export SINGULARITY_MOUNTS="$GENOMES_DIR:$GENOMES_MNT,$SINGULARITY_MOUNTS"
  
  
  if [ -d "$INTERNAL_OUTPUT" ]
  then
      override_param INTERNAL_OUTPUT "$INTERNAL_MNT"
      SINGULARITY_MOUNTS="$INTERNAL_OUTPUT:$INTERNAL_MNT,$SINGULARITY_MOUNTS"
  fi
  
  if [ -d "$UTAP_CODE" ]
  then
      override_param UTAP_CODE "$UTAP_MNT" 
      SINGULARITY_MOUNTS="$UTAP_CODE:$UTAP_MNT,$SINGULARITY_MOUNTS"
  fi
  
  
  if [ -d "$CONDA" ]
  then
    override_param MAIN_CONDA "$CONDA_MNT"
  fi
  
          
  export SINGULARITY_ALL_MOUNTS="$HOST_MOUNT/apache2/run:/var/run/apache2,/$HOST_MOUNT/apache2/logs:/var/log/apache2,$DB_PATH:$DB_MNT,$SINGULARITY_MOUNTS"
  echo "IMAGE_PATH=$IMAGE_PATH" >> all_parameters
  echo "SINGULARITY_MOUNTS=$SINGULARITY_MOUNTS" >> all_parameters
  

  
  touch $HOST_MOUNT/singularity_variables
  echo "export  SINGULARITY_BIND=\"$SINGULARITY_ALL_MOUNTS\"" > $HOST_MOUNT/singularity_variables
  source $HOST_MOUNT/singularity_variables
  
  #create utap container
  #eval $SINGULARITY_HOST_COMMAND
  eval $run_UTAP
  
}

##validation for all parameters :

#validate testing parameter
validate_param "$TEST" "TEST"

#validate development parameter
validate_param "$DEVELOPMENT" "DEVELOPMENT"

#validate ngsplot parameter
validate_param "$RUN_NGSPLOT" "RUN_NGSPLOT"

#validate internal users parameter
validate_param "$INTERNAL_USERS" "INTERNAL_USERS"

#validate GCP parameter 
validate_param "$GCP" "GCP"


if [ $GCP = 1 ];  then  # use the function, save the code
  bash ~/data/install_UTAP_GCP.sh
  wait $!
fi

#check if DEMO installation
validate_param "$DEMO_SITE" "DEMO_SITE"
if [ "$DEMO_SITE" = 1 ]; then # It is demo site
  echo "You are installing demo version of UTAP"
  echo "DEMO_SITE=\"DEMO_SITE\=True\"" >> all_parameters
else
  echo "DEMO_SITE=\"DEMO_SITE\=False\"" >> all_parameters
fi 


#check if USER exists 
user_exists=$(id -u $USER > /dev/null 2>&1; echo $?)
if [ $user_exists != 0 ];  then  # use the function, save the code
  echo "ERROR: The user $USER not found"
  exit
fi

override_param USER "$USER" 
 
#check if DNS HOST exists. if not provided then user IPv4 adress
if [ "$DNS_HOST" = "None" ]; then 
  IPv4=`hostname -I |  cut -d " " -f1`
  export DNS_HOST=$IPv4
fi
export DNS_HOST=`echo $DNS_HOST | sed 's~http[s]*://~~g'`
override_param DNS_HOST "$DNS_HOST" 



#check if INSTITUTE_NAME exists. 
if [ "$INSTITUTE_NAME" = "None" ]; then 
  export INSTITUTE_NAME="" 
fi
override_param INSTITUTE_NAME "$INSTITUTE_NAME" 


#check if HOST_MOUNT exists 
check_dir "$HOST_MOUNT" 

#check if HOST_HOME_DIR exists 
check_dir "$HOST_HOME_DIR"

#check HOST_MOUNT permissions 
chmod  +rwx $HOST_MOUNT || (echo "ERROR: USER $USER doesn't have permissions to $HOST_MOUNT directory" && exit)

#check HOST_MOUNT contains sufficient space
host_mount_size=`get_dir_df "Avail" "$HOST_MOUNT"`
if [ "$host_mount_size" -lt 100000000 ];
then
  echo "There is not enough space on HOST_MOUNT $HOST_MOUNT directory for UTAP installation"
#  exit
fi

#check if the provided MAIL_SERVER is responding 
if [ "$MAIL_SERVER" = "None" ]; then
   override_param MAIL_SERVER "localhost"
fi


#check if mail address is valid
if [[ $REPLY_EMAIL =~ '(.+)@(.+)' ]] ; then
    echo "REPLY_EMAIL $REPLY_EMAIL address is not valid";
    exit
else 
  if [[ $REPLY_EMAIL = *"gmail.com" ]] ; then
    EMAIL_USE_TLS="TLS_USE_IN_MAIL\=True"
    EMAIL_PORT="587"
    override_param MAIL_SERVER "smtp.gmail.com"
    if [[ $MAIL_PASSWORD = *"None"* ]] || [[ $MAIL_PASSWORD = "" ]] ; then 
      echo "ERROR: if gmail address is specified, you must provide gmail app password"
      exit
    fi
  else
     if [ $MAIL_PASSWORD = "None" ]; then  
       override_param MAIL_PASSWORD ""
     fi 
  fi 
fi


#check if HOST_APACHE_PORT is open
netstat -tulpn | grep :$HOST_APACHE_PORT && (echo "port allready in use please specify another port from 1024 through 49151" && exit)
if [ $HOST_APACHE_PORT = "9000" ] ; then
 echo "ERROR: port 9000 is used for mail server, plese specify a different port"
 exit
fi 


#set MAX_MEMORY and MAX_CORES if not provided 
if [ "$MAX_MEMORY" = "None" ]; then 
    if [ "$CLUSTER_TYPE" = "lsf" ]; then
      {
        max_mem=`get_max_resources "maxmem"`
        max_mem=${max_mem%.*}
      } || {echo "ERROR: failed setting MAX_MEMORY , please set it manually" && exit}
    else 
    {
      echo "Warning: MAX_MEMORY is not defined, setting MAX_MEMORY as the host max memory available" 
      max_mem=`awk '/MemFree/ { printf "%.0f \n", $2/1024 }' /proc/meminfo`
      } || {echo "ERROR: failed setting MAX_MEMORY , please set it manually" && exit }
    fi
    export MAX_MEMORY=$((max_mem-50)) 
fi

if [ "$MAX_CORES" = "None" ]; then 
    if [ "$CLUSTER_TYPE" = "lsf" ]; then
      {
        max_cpu=`get_max_resources "ncpus"`
        max_cpu=${max_cpu%.*}
      } || {echo "ERROR: failed setting  MAX_CORES, please it them manually" && exit}
    else 
    {
      echo "Warning: MAX_CORES is not defined, setting MAX_CORES as the host max cores available" 
      max_cpu=`grep -c ^processor /proc/cpuinfo`
      max_cpu=$(expr "$max_cpu" + 0)
      max_mem=`awk '/MemFree/ { printf "%.0f \n", $2/1024 }' /proc/meminfo`
      } || {echo "ERROR: failed setting  MAX_CORES, please set it manually" && exit }
    fi   
    export MAX_CORES=$((max_cpu-5)) 
fi

if [ ! -f  $HOST_HOME_DIR/.ssh/id_rsa.pub ]; then
  ssh-keygen -t rsa -N "" -f $HOST_HOME_DIR/.ssh/id_rsa
fi	
cat $HOST_HOME_DIR/.ssh/id_rsa.pub >> $HOST_HOME_DIR/.ssh/authorized_keys
chmod 700 $HOST_HOME_DIR/.ssh
chmod 600 $HOST_HOME_DIR/.ssh/*


#set singularity commands on the host
if [ "$SINGULARITY_HOST_COMMAND" = "None" ]; then
  singularity --version || module load singularity || module load Singularity || (echo "ERROR: no singularity found on the host" && exit)
else
  eval $SINGULARITY_HOST_COMMAND
fi


#check if specify UTAP DB path, if not create one 
if [ ! -d "$DB_PATH" ]; then  
  mkdir -p "$HOST_MOUNT/UTAP_DB" 
  export DB_PATH="$HOST_MOUNT/UTAP_DB"
  override_param DB_PATH "$DB_PATH"
fi 

#check if  GENOMES_DIR path exist
check_dir "$GENOMES_DIR"
GENOMES='mkdir -p $SINGULARITY_ROOTFS'
GENOMES="$GENOMES$GENOMES_DIR"


if [ -d "$CONDA" ];
then
    echo "You are installing UTAP that runs with external conda environment on the host" 
    CONDA_DIR='mkdir -p $SINGULARITY_ROOTFS'
    CONDA_DIR="$CONDA_DIR$CONDA"
    export MAIN_CONDA=$CONDA
    echo "RUN_LOCAL_HOST_CONDA=\"RUN_LOCAL_HOST_CONDA\=True\"" >> all_parameters    
else
   echo "You are installing UTAP that runs local conda environment inside the image"   
   CONDA_DIR=""
   export MAIN_CONDA=/opt/miniconda3/envs/utap
   echo "RUN_LOCAL_HOST_CONDA=\"RUN_LOCAL_HOST_CONDA\=False\"" >> all_parameters 
fi
echo "MAIN_CONDA=$MAIN_CONDA" >> all_parameters



#set cluster resources and commands
 
if [ "$CLUSTER_TYPE" != "local" ]; then
  singularity exec --bind $HOST_MOUNT:/mnt/host_mount $HOST_MOUNT/utap_latest.sif $MAIN_CONDA/bin/python $MAIN_CONDA/lib/python3.10/site-packages/ngs-snakemake/cluster_scripts/cluster_type.py "$CLUSTER_TYPE" "/mnt/host_mount" ||  (echo "ERROR: failed to create cluster commands file" && exit)
  source "$HOST_MOUNT/cluster_commands.py"  
  if [ "$GCP" = 1 ]; then
    if [ "$GCP_BUCKET" != "None" ]; then
      export  SINGULARITY_CLUSTER_COMMAND="df -h | grep $HOME/data || gcsfuse --file-mode 775 $GCP_BUCKET $HOME/data && module load singularity;"
    else
      export  SINGULARITY_CLUSTER_COMMAND="module load singularity;"
    fi
    echo "SINGULARITY_CLUSTER_COMMAND=\"$SINGULARITY_CLUSTER_COMMAND\"" >> all_parameters   
  fi
  if [ -n "$cluster_wraper" ]; then
    export cluster_exe="$cluster_exe $cluster_wraper"
  fi
  echo "RUN_LOCAL=\"RUN_LOCAL\=False\"" >> all_parameters
  echo "You are installing UTAP that run on $CLUSTER_TYPE cluster"
  if [ "$SINGULARITY_CLUSTER_COMMAND" = "None" ]; then
    #$cluster_exe bash -c "(module load Singularity && echo 'SINGULARITY_CLUSTER_COMMAND=\"module load Singularity;\"' >> all_parameters) || (module load singularity && echo 'SINGULARITY_CLUSTER_COMMAND=\"module load singularity;\"' >> all_parameters) || (singularity --version && echo 'SINGULARITY_CLUSTER_COMMAND=\"\"' >> all_parameters) || (touch $HOST_MOUNT/cluster_singularity_error)" 
    $cluster_exe /bin/bash -c "
if module load Singularity; then
     echo 'SINGULARITY_CLUSTER_COMMAND=\"module load Singularity;\"' >> all_parameters
elif module load singularity; then
     echo 'SINGULARITY_CLUSTER_COMMAND=\"module load singularity;\"' >> all_parameters
elif singularity --version; then
     echo 'SINGULARITY_CLUSTER_COMMAND=\"\"' >> all_parameters
else
    touch $HOST_MOUNT/cluster_singularity_error
fi
"
  else
    $cluster_exe /bin/bash -c  "
if ! $SINGULARITY_CLUSTER_COMMAND then
    touch $HOST_MOUNT/cluster_singualrity_error
fi
"
  fi
  if [  "$CLUSTER_QUEUE" = "None" ]; then  
    export CLUSTER_QUEUE=""
    override_param CLUSTER_QUEUE $CLUSTER_QUEUE
  else  
    if [ "$cluster_queues" != "None" ]; then
      eval "$cluster_queues $CLUSTER_QUEUE" || (echo "Warning: could not find the defined cluster queue $CLUSTER_QUEUE, the default cluster queue will be used" && export CLUSTER_QUEUE="" && override_param CLUSTER_QUEUE $CLUSTER_QUEUE)
    fi    
  fi
else
  echo "You are installing UTAP that runs on the local server"
  echo "RUN_LOCAL=\"RUN_LOCAL\=True\"" >> all_parameters
  if [ "$CLUSTER_QUEUE" != "None" ]; then
    echo "WARNING: cluster type is local but CLUSTER_QUEUE is not None" 
  fi
fi



#check if  SINGULARITY_TMP_DIR path exist, if not set one

if [ ! -d "$SINGULARITY_TMP_DIR" ]; then  
  export SINGULARITY_TMP_DIR="/tmp"
fi 

export SINGULARITY_TMPDIR=$SINGULARITY_TMP_DIR


#create utap folders
mkdir -p $HOST_MOUNT/{logs-utap,parameters_files,reports,utap-output/admin,utap-output/.python-eggs,apache2/run,apache2/logs,UTAP_HOME_DIR}
touch $HOST_MOUNT/jobs_status.txt


export SERVER_NAME=`hostname`
export PRIMARYGRP=`id -gn <<< $USER`



#add additional parameters that are not specify by the user
echo "HOST_MOUNT_CLUSTER=$HOST_MOUNT" >> all_parameters
#echo "DNS_HOST=$DNS_HOST" >> all_parameters
echo "SERVER_NAME=$SERVER_NAME" >> all_parameters
echo "PRIMARYGRP=$PRIMARYGRP" >> all_parameters
echo 'HOME=$HOST_MOUNT/UTAP_HOME_DIR' >> all_parameters
#echo "HOST_HOME_DIR=$HOST_HOME_DIR" >> all_parameters
#echo "DB_PATH=$DB_PATH" >> all_parameters
echo "TEST=$TEST" >> all_parameters
echo "DEVELOPMENT=$DEVELOPMENT" >> all_parameters
#echo "UTAP_CODE=$UTAP_CODE" >> all_parameters
#echo "INTERNAL_OUTPUT=$INTERNAL_OUTPUT" >> all_parameters
echo "INTERNAL_USERS=$INTERNAL_USERS" >> all_parameters
#echo "GENOMES_DIR=$GENOMES_DIR" >> all_parameters
echo "EMAIL_PORT=$EMAIL_PORT" >> all_parameters
echo "EMAIL_USE_TLS=$EMAIL_USE_TLS" >> all_parameters






#If fakeroot, singularity container will be built from definition file otherwise singularity container will be built from sandbox and mounts points are created
validate_param "$FAKEROOT" "FAKEROOT"
if [ "$FAKEROOT" = "None" ]; then 
  cat /etc/subuid | grep `id -u` && export FAKEROOT=1 || export FAKEROOT=0
fi



if [ "$FAKEROOT" = 1 ];
then
  echo "user has fakeroot privileges, installing utap instance"
  type=`get_dir_df "Type" "$SINGULARITY_TMPDIR"`
  size=`get_dir_df "Avail" "$SINGULARITY_TMPDIR"`
  if [[ "$type" != *"nfs"* ]] && [[ "$type" != *"gpfs"* ]] && [ 40000000  -lt "$size" ];
  then 
    run_utap "instance" || run_utap "sandbox"  || echo "ERROR: failed to install UTAP sandbox, please contact UTAP team at utap@weizmann.ac.il"
  else 
    echo "insufficient disk space or disk is mounted as gpfs or nfs at $SINGULARITY_TMPDIR, $HOST_MOUNT will be used as temp dir for utap installation"
    export SINGULARITY_TMPDIR=$HOST_MOUNT
    type=`get_dir_df "Type" "$SINGULARITY_TMPDIR"`
    size=`get_dir_df "Avail" "$SINGULARITY_TMPDIR"`
    if [[ "$type" != *"nfs"* ]] && [[ "$type" != *"gpfs"* ]] && [ 40000000  -lt "$size" ];
    then 
      run_utap "instance" || run_utap "sandbox"  || echo "ERROR: failed to install UTAP sandbox, please contact UTAP team at utap@weizmann.ac.il"
    else 
      echo "insufficient disk space or disk is mounted as gpfs or nfs at $SINGULARITY_TMPDIR, installing utap sandbox"
      run_utap "sandbox"  || echo "ERROR: failed to install UTAP sandbox, please contact UTAP team at utap@weizmann.ac.il"
    fi
  fi
else
  echo "user hasn't fakeroot privileges , installing utap sandbox"
  run_utap "sandbox"  || echo "ERROR: failed to install UTAP sandbox, please contact UTAP team at utap@weizmann.ac.il"
fi










