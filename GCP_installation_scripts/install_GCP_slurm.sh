#!/bin/bash
# Requirments: 
#An acoount 
#A billing account
#A project connected the billing account  


# Genarate a project an associate it to a billing account  
#export project_id="utap-$TIME_STEMP"
#gcloud projects create $project_id
#wait $!

override_optional_param () {
  sed -i "s/$1=.*/$1='${2//\//\\/}'/" ~/utap2/scripts/optional_parameters.conf
} 



# Get project id as parameter, and bucket name if exist. 
# The bucket will contain all UTAP installation files (genomes are already found in the controller image together with UTAP installation as utap.sandbox )
while getopts "b:i:" option; do
  case "${option}" in
    i) export project_id=${OPTARG};;
    b) export bucket_name=${OPTARG};;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done


# Check if project id is provided
if [ -z "$project_id" ]; then
  echo "Error: Missing required project id"
  exit 1
fi



# Check if bucket name is provided, if not, create one 
if [ -z "$bucket_name" ]; then
  export TIME_STEMP=`date +"%d-%m-%Y-%H-%M-%S"`
  export bucket_name="utap-data-$TIME_STEMP"
  gcloud storage buckets create gs://$bucket_name --project=$project_id --default-storage-class=STANDARD --location=us-central1  --uniform-bucket-level-access
  wait $!
fi

# Get project number
export project_num=`gcloud projects describe  $project_id --format="value(projectNumber)"`


echo "project id: $project_id, project num: $project_num, bucket name: $bucket_name" 



# Set default project 
#gcloud auth login - you are allready authenticated with gcloud when running inside the Cloud Shell and so do not need to run this command.
gcloud config set project $project_id

# Grant user access credentials to terraform 
gcloud auth application-default login

# Enable VM connection to your cluster by using ssh with os-login at project level
gcloud compute project-info add-metadata --metadata enable-oslogin=TRUE


# Grant required roles to your user account
# Grant the roles/storage.admin role
gcloud projects add-iam-policy-binding $project_id \
  --member="user:$USER_EMAIL" \
  --role='roles/storage.admin'
# Grant the roles/viewer role
gcloud projects add-iam-policy-binding $project_id \
  --member="user:$USER_EMAIL" \
  --role='roles/viewer'
# Grant the roles/resourcemanager.projectIamAdmin role
gcloud projects add-iam-policy-binding $project_id \
  --member="user:$USER_EMAIL" \
  --role='roles/resourcemanager.projectIamAdmin'
# Grant the roles/cloudbuild.builds.editor role
gcloud projects add-iam-policy-binding $project_id \
  --member="user:$USER_EMAIL" \
  --role='roles/cloudbuild.builds.editor'




# Grant required roles to the Compute Engine service account
# Enable the default Compute Engine service account.
gcloud iam service-accounts enable --project $project_id $project_num-compute@developer.gserviceaccount.com
gcloud projects add-iam-policy-binding $project_id --member=serviceAccount:$project_num-compute@developer.gserviceaccount.com --role=roles/editor

#  Grant the roles/editor IAM role to the service account.
gcloud iam service-accounts enable --project $project_id $project_num-compute@developer.gserviceaccount.com

# Enable storage transfer service account iams 
gcloud projects add-iam-policy-binding $project_id --member=serviceAccount:project-$project_num@storage-transfer-service.iam.gserviceaccount.com --role=roles/storage.objectAdmin
gcloud projects add-iam-policy-binding $project_id --member=serviceAccount:project-$project_num@storage-transfer-service.iam.gserviceaccount.com --role=roles/owner

# Grant the roles/compute.storageAdmin role
gcloud projects add-iam-policy-binding $project_id \
  --member="serviceAccount:$project_num-compute@developer.gserviceaccount.com" \
  --role='roles/compute.storageAdmin'


# If you're importing an image, grant the roles/storage.objectViewer role
gcloud projects add-iam-policy-binding $project_id \
  --member="serviceAccount:$project_num-compute@developer.gserviceaccount.com" \
  --role='roles/storage.objectViewer'
  
# If you're exporting an image, grant the roles/storage.objectAdmin role
gcloud projects add-iam-policy-binding $project_id \
  --member="serviceAccount:$project_num-compute@developer.gserviceaccount.com" \
  --role='roles/storage.objectAdmin'


# Grant the roles/compute.admin role to the Cloud Build service account. 
gcloud projects add-iam-policy-binding $project_id \
   --member="serviceAccount:$project_num@cloudbuild.gserviceaccount.com" \
   --role='roles/compute.admin'

# Grant the roles/iam.serviceAccountUser role
gcloud projects add-iam-policy-binding $project_id \
   --member="serviceAccount:$project_num@cloudbuild.gserviceaccount.com" \
   --role='roles/iam.serviceAccountUser'
   
# Grant the roles/iam.serviceAccountTokenCreator role
gcloud projects add-iam-policy-binding $project_id \
   --member="serviceAccount:$project_num@cloudbuild.gserviceaccount.com" \
   --role='roles/iam.serviceAccountTokenCreator'

# Grant the roles/compute.networkUser role
gcloud projects add-iam-policy-binding $project_id \
   --member="serviceAccount:$project_num@cloudbuild.gserviceaccount.com" \
   --role='roles/compute.networkUser'
   



# Fuse google bucket to ~/data on google shell 
mkdir "$HOME/data" && gcsfuse -o rw -file-mode=777 -dir-mode=777 --implicit-dirs $bucket_name "$HOME/data"

# If the project doesn’t already contain UTAP custom images for the login and controller nodes: utap-login-slurm-simple-latest and utap-controller-slurm-simple-latest respectively then you will have to download  the images from dors4 and import them to your google project
export utap_login=$(gcloud compute images list | grep "utap-login")
export utap_controller=$(gcloud compute images list | grep "utap-controller")

if [ -z "$utap_login" ] && [ -z "$utap_controller" ]; then
    echo "downloading and transffering images to Google cloud, this is going to take very long time"
    curl "https://dors4.weizmann.ac.il/utap/UTAP_installation_files/GCP_slurm_cluster/utap-login-slurm-simple-final.tar.gz" | gsutil -h "Cache-Control: no-cache, max-age=0" cp - gs://$bucket_name/utap-login-slurm-simple-final.tar.gz  &
    curl "https://dors4.weizmann.ac.il/utap/UTAP_installation_files/GCP_slurm_cluster/utap-controller-slurm-simple-final.tar.gz" | gsutil -h "Cache-Control: no-cache, max-age=0" cp - gs://$bucket_name/utap-controller-slurm-simple-final.tar.gz &
    wait 
    #export compressed raw images files to bootable images availble on GCP 
    gcloud compute images create utap-controller-slurm-simple-final --source-uri gs://$bucket_name/utap-controller-slurm-simple-final.tar.gz
    gcloud compute images create utap-login-slurm-simple-final --source-uri gs://$bucket_name/utap-login-slurm-simple-final.tar.gz
    #gcloud compute images import utap-controller --source-file gs://$bucket_name/utap-controller-slurm-simple-final.tar.gz --timeout=24h &
    #gcloud compute images import utap-login --source-file gs://$bucket_name/utap-login-slurm-simple-final.tar.gz --timeout=24h &
    wait
fi

# Not in use - VMDK files are larger then compressed raw tar.gz images and downloadng them takes longer, therefore VMDK images are not used for the installation
#wget -nH -nc -P ~/data/genomes https://dors4.weizmann.ac.il/utap/UTAP_genomes/All_genomes/*  && wget -nH -nc -P ~/data https://dors4.weizmann.ac.il/utap/UTAP_installation_files/GCP_slurm_cluster/utap-controller-final.vmdk && wget -nH -nc -P ~/data https://dors4.weizmann.ac.il/utap/UTAP_installation_files/GCP_slurm_cluster/utap-login-final.vmdk 

# Transfer all installation files from dors4 to bucket using data tansfer service - not in use since google transfer service from dors4 to google bucket is very slow - 3GB per hour
#gcloud transfer jobs create https://dors4.weizmann.ac.il/utap/data_transfer_tsv_files/tsv.txt gs://$bucket_name
#data_id=`gcloud transfer jobs list | grep NAME | head -n 1 | awk '{print $2}'`
#gcloud transfer jobs monitor $data_id


# Clone the Cloud HPC Toolkit GitHub repository - not in use
#sed -i "s/project_id: .*/project_id: '${project_id//\//\\/}'/" ~/utap2/GCP_installation_scripts/hpc-slurm-utap.yaml
#cd ~ && git clone https://github.com/GoogleCloudPlatform/hpc-toolkit.git
#cd hpc-toolkit/ && make 
#./ghpc create -w ~/utap2/GCP_installation_scripts/hpc-slurm-utap.yaml && ./ghpc deploy hpc-utap

# Clone the Cloud SchedMD  GitHub repository
cd ~ && git clone https://github.com/utap2/slurm-gcp.git

# Change the project id in the relevant slurm-gcp files. 
sed -i "s/project_id = .*/project_id = \"${project_id//\//\\/}\"/" ~/slurm-gcp/terraform/slurm_cluster/examples/slurm_cluster/simple_cloud_utap/example.tfvars
sed -i "s/PROJECT_ID/${project_id//\//\\/}/" ~/slurm-gcp/terraform/slurm_cluster/examples/slurm_cluster/simple_cloud_utap/main.tf
sed -i "s/BUCKET_NAME/${bucket_name//\//\\/}/" ~/slurm-gcp/terraform/slurm_cluster/examples/slurm_cluster/simple_cloud_utap/main.tf

# Install slurm cluster with terraform
cd ~/slurm-gcp/terraform/slurm_cluster/examples/slurm_cluster/simple_cloud_utap
terraform init && terraform validate && terraform apply -var-file=example.tfvars || (echo "ERROR installing GCP Slurm cluster")
wait
STATUS=$?
if [ $STATUS -ne 0 ]; then
    echo "Error: One or more processes failed with exit status $STATUS"
    exit $STATUS
fi
sleep 100 # wait for slurm cluster to be configured 


export USER_LOGIN="$USER""_gmail_com"
export LOGIN_IP=`gcloud compute instances list --sort-by=~creationTimestamp --format="value(EXTERNAL_IP)" | head -n 1`

# Override parameters in optional_parametrs.conf and copy the modified files to the bucket
#override_optional_param "GCP" "1"
override_optional_param "GCP_BUCKET" "$bucket_name"
override_optional_param "DNS_HOST" "$LOGIN_IP"
#override_optional_param "MAIL_PASSWORD" "zhytvkqzokgoarsl"
#override_optional_param "CLUSTER_TYPE" "slurm"
gcloud storage cp ~/utap2/scripts/* gs://$bucket_name

# Copy ssh files from the host - google shell to login node 
printf 'Y\n' | gcloud compute ssh --zone "us-central1-a" "simple-login-l0-001" --project $project_id &
sleep 10
ssh -i ~/.ssh/google_compute_engine -o StrictHostKeyChecking=no -l $USER_LOGIN $LOGIN_IP "mkdir ~/.ssh;"
scp -i ~/.ssh/google_compute_engine ~/.ssh/google_compute_engine "$USER_LOGIN"@"$LOGIN_IP":.ssh/id_rsa
scp -i ~/.ssh/google_compute_engine ~/.ssh/google_compute_engine.pub "$USER_LOGIN"@"$LOGIN_IP":.ssh/id_rsa.pub

# Mount bucket to $HOME/data on the login node. The bucket will contain all UTAP installation files (genomes are already found in the controller image together with UTAP installation as utap.sandbox ) and run UTAP
ssh -i  ~/.ssh/google_compute_engine  "$USER_LOGIN"@"$LOGIN_IP" "mkdir -p ~/data && mkdir -p ~/singularity/mnt/session/ && gcsfuse -o rw -file-mode=777 -dir-mode=777 --debug_fuse_errors  --debug_fuse --debug_fs --debug_gcs --implicit-dirs \"$bucket_name\" ~/data && bash data/install_UTAP_singularity.sh -a data/required_parameters.conf -b data/optional_parameters.conf"

# Show the user the login URL to UTAP
sed -i 's/\r$//'  ~/utap2/scripts/optional_parameters.conf
source  ~/utap2/scripts/optional_parameters.conf
echo "UTAP has been installed successfully. Please visit the site http://$LOGIN_IP:$HOST_APACHE_PORT"

# Enter login node
#export GOOGLE_CLOUD_PROJECT=`gcloud config list --format 'value(core.project)'`
#export REGION=`gcloud config list --format 'value(compute.region)'`
#export ZONE=`gcloud config list --format 'value(compute.zone)'`
#export LOGIN_VM=`gcloud compute instances list --sort-by=~creationTimestamp --format="value(NAME)" | grep login | head -n 1`
#gcloud compute ssh --zone "us-central1-a" "$LOGIN_VM" --project "$GOOGLE_CLOUD_PROJECT"
