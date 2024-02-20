#!/bin/bash
# Requirments: 
#An acoount 
#A billing account
#A project connected the billing account  


#Genarate a project an associate it to a billing account  
#export project_id="utap-$TIME_STEMP"
#gcloud projects create $project_id
#wait $!

override_optional_param () {
  sed -i "s/$1=.*/$1='${2//\//\\/}'/" ~/utap2/scripts/optional_parameters.conf
} 


#get project id as parameter, and bucket name if exist
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



# Check if bucket name is provided 
if [ -z "$bucket_name" ]; then
  export TIME_STEMP=`date +"%d-%m-%Y-%H-%M-%S"`
  export bucket_name="utap-data-$TIME_STEMP"
  gcloud storage buckets create gs://$bucket_name --project=$project_id --default-storage-class=STANDARD --location=us-central1  --uniform-bucket-level-access
  wait $!
fi

export project_num=`gcloud projects describe  $project_id --format="value(projectNumber)"`


echo "project id: $project_id, project num: $project_num, bucket name: $bucket_name" 

#override_optional_param "GCP" "1"
override_optional_param "GCP_BUCKET" "$bucket_name"
#override_optional_param "MAIL_PASSWORD" "zhytvkqzokgoarsl"
#override_optional_param "CLUSTER_TYPE" "slurm"

#set default project 
#gcloud auth login - you are allready authenticated with gcloud when running inside the Cloud Shell and so do not need to run this command.
gcloud config set project $project_id

#grant user access credentials to terraform 
gcloud auth application-default login

#enable VM connection to your cluster by using ssh with os-login at project level
gcloud compute project-info add-metadata --metadata enable-oslogin=TRUE


#Grant required roles to your user account
#grant the roles/storage.admin role
gcloud projects add-iam-policy-binding $project_id \
  --member="user:$USER_EMAIL" \
  --role='roles/storage.admin'
#Grant the roles/viewer role
gcloud projects add-iam-policy-binding $project_id \
  --member="user:$USER_EMAIL" \
  --role='roles/viewer'
#Grant the roles/resourcemanager.projectIamAdmin role
gcloud projects add-iam-policy-binding $project_id \
  --member="user:$USER_EMAIL" \
  --role='roles/resourcemanager.projectIamAdmin'
#Grant the roles/cloudbuild.builds.editor role
gcloud projects add-iam-policy-binding $project_id \
  --member="user:$USER_EMAIL" \
  --role='roles/cloudbuild.builds.editor'




#Grant required roles to the Compute Engine service account
#enable the default Compute Engine service account.
gcloud iam service-accounts enable --project $project_id $project_num-compute@developer.gserviceaccount.com
gcloud projects add-iam-policy-binding $project_id --member=serviceAccount:$project_num-compute@developer.gserviceaccount.com --role=roles/editor

#grant the roles/editor IAM role to the service account.
gcloud iam service-accounts enable --project $project_id $project_num-compute@developer.gserviceaccount.com

#enable storage transfer service account iams 
gcloud projects add-iam-policy-binding $project_id --member=serviceAccount:project-$project_num@storage-transfer-service.iam.gserviceaccount.com --role=roles/storage.objectAdmin
gcloud projects add-iam-policy-binding $project_id --member=serviceAccount:project-$project_num@storage-transfer-service.iam.gserviceaccount.com --role=roles/owner

#grant the roles/compute.storageAdmin role
gcloud projects add-iam-policy-binding $project_id \
  --member="serviceAccount:$project_num-compute@developer.gserviceaccount.com" \
  --role='roles/compute.storageAdmin'


#if you're importing an image, grant the roles/storage.objectViewer role
gcloud projects add-iam-policy-binding $project_id \
  --member="serviceAccount:$project_num-compute@developer.gserviceaccount.com" \
  --role='roles/storage.objectViewer'
  
#if you're exporting an image, grant the roles/storage.objectAdmin role
gcloud projects add-iam-policy-binding $project_id \
  --member="serviceAccount:$project_num-compute@developer.gserviceaccount.com" \
  --role='roles/storage.objectAdmin'


#grant the roles/compute.admin role to the Cloud Build service account. 
gcloud projects add-iam-policy-binding $project_id \
   --member="serviceAccount:$project_num@cloudbuild.gserviceaccount.com" \
   --role='roles/compute.admin'

#grant the roles/iam.serviceAccountUser role
gcloud projects add-iam-policy-binding $project_id \
   --member="serviceAccount:$project_num@cloudbuild.gserviceaccount.com" \
   --role='roles/iam.serviceAccountUser'
   
#grant the roles/iam.serviceAccountTokenCreator role
gcloud projects add-iam-policy-binding $project_id \
   --member="serviceAccount:$project_num@cloudbuild.gserviceaccount.com" \
   --role='roles/iam.serviceAccountTokenCreator'

#grant the roles/compute.networkUser role
gcloud projects add-iam-policy-binding $project_id \
   --member="serviceAccount:$project_num@cloudbuild.gserviceaccount.com" \
   --role='roles/compute.networkUser'
   

gcloud storage cp ~/utap2/scripts/* gs://$bucket_name

#download all installation files from dors4 to bucket, this option takes very long time and only available if transfer data service is functional
mkdir "$HOME/data" && gcsfuse -o rw -file-mode=777 -dir-mode=777 --implicit-dirs $bucket_name "$HOME/data"

export utap_login=$(gcloud compute images list | grep "utap-login")
export utap_controller=$(gcloud compute images list | grep "utap-controller")

if [ -z "$utap_login" ] && [ -z "$utap_controller" ]; then
    echo "downloading and transffering images to Google cloud, this is going to take very long time"
    curl "https://dors4.weizmann.ac.il/utap/UTAP_installation_files/GCP_slurm_cluster/utap-login-latest.vmdk" | gsutil -h "Cache-Control: no-cache, max-age=0" cp - gs://$bucket_name/utap-login-latest.vmdk &
    curl "https://dors4.weizmann.ac.il/utap/UTAP_installation_files/GCP_slurm_cluster/utap-controller-latest.vmdk" | gsutil -h "Cache-Control: no-cache, max-age=0" cp - gs://$bucket_name/utap-controller-latest.vmdk &
    wait 
    #convert vmdk files to bootable images availble on GCP (public images are also availble but can only be stored in private account)
    gcloud compute images import utap-controller --source-file gs://$bucket_name/utap-controller-latest.vmdk --timeout=24h &
    gcloud compute images import utap-login --source-file gs://$bucket_name/utap-login-latest.vmdk --timeout=24h &
    wait
fi

#wget -nH -nc -P ~/data/genomes https://dors4.weizmann.ac.il/utap/UTAP_genomes/All_genomes/*  && wget -nH -nc -P ~/data https://dors4.weizmann.ac.il/utap/UTAP_installation_files/GCP_slurm_cluster/utap-controller-latest.vmdk && wget -nH -nc -P ~/data https://dors4.weizmann.ac.il/utap/UTAP_installation_files/GCP_slurm_cluster/utap-login-latest.vmdk 

#transfer all installation files from dors4 to bucket using data tansfer service 
#gcloud transfer jobs create https://dors4.weizmann.ac.il/utap/data_transfer_tsv_files/tsv.txt gs://$bucket_name
#data_id=`gcloud transfer jobs list | grep NAME | head -n 1 | awk '{print $2}'`
#gcloud transfer jobs monitor $data_id


#clone the Cloud HPC Toolkit GitHub repository - not in use
#sed -i "s/project_id: .*/project_id: '${project_id//\//\\/}'/" ~/utap2/GCP_installation_scripts/hpc-slurm-utap.yaml
#cd ~ && git clone https://github.com/GoogleCloudPlatform/hpc-toolkit.git
#cd hpc-toolkit/ && make 
#./ghpc create -w ~/utap2/GCP_installation_scripts/hpc-slurm-utap.yaml && ./ghpc deploy hpc-utap

#clone the Cloud SchedMD  GitHub repository and install slurm cluster with terraform
cd ~ && git clone https://github.com/utap2/slurm-gcp.git
sed -i "s/project_id = .*/project_id = \"${project_id//\//\\/}\"/" ~/slurm-gcp/terraform/slurm_cluster/examples/slurm_cluster/simple_cloud_utap/example.tfvars
sed -i "s/PROJECT_ID/${project_id//\//\\/}/" ~/slurm-gcp/terraform/slurm_cluster/examples/slurm_cluster/simple_cloud_utap/main.tf
sed -i "s/BUCKET_NAME/${bucket_name//\//\\/}/" ~/slurm-gcp/terraform/slurm_cluster/examples/slurm_cluster/simple_cloud_utap/main.tf
cd ~/slurm-gcp/terraform/slurm_cluster/examples/slurm_cluster/simple_cloud_utap
terraform init && terraform validate && terraform apply -var-file=example.tfvars || (echo "ERROR installing GCP Slurm cluster")
wait
STATUS=$?
if [ $STATUS -ne 0 ]; then
    echo "Error: One or more processes failed with exit status $STATUS"
    exit $STATUS
fi
sleep 100
#copy ssh files from host to login VM 
export USER_LOGIN=`gcloud compute os-login describe-profile --format json|jq -r '.posixAccounts[].username'`
export LOGIN_IP=`gcloud compute instances list --sort-by=~creationTimestamp --format="value(EXTERNAL_IP)" | head -n 1`
rm ~/.ssh/known_hosts
ssh -i ~/.ssh/google_compute_engine -o StrictHostKeyChecking=no -l $USER_LOGIN $LOGIN_IP "mkdir ~/.ssh;"
scp -i ~/.ssh/google_compute_engine ~/.ssh/google_compute_engine "$USER_LOGIN"@"$LOGIN_IP":.ssh/id_rsa
scp -i ~/.ssh/google_compute_engine ~/.ssh/google_compute_engine.pub "$USER_LOGIN"@"$LOGIN_IP":.ssh/id_rsa.pub
ssh -i  ~/.ssh/google_compute_engine  "$USER_LOGIN"@"$LOGIN_IP" "mkdir -p ~/data && gcsfuse -o rw -file-mode=777 -dir-mode=777 --debug_fuse_errors  --debug_fuse --debug_fs --debug_gcs --implicit-dirs \"$bucket_name\" ~/data && bash data/install_UTAP_singularity.sh -a data/required_parameters.conf -b data/optional_parameters.conf"
wait
sed -i 's/\r$//'  ~/utap2/scripts/optional_parameters.conf
source  ~/utap2/scripts/optional_parameters.conf
echo "UTAP has been installed successfully. Please visit the site http://$LOGIN_IP:$HOST_APACHE_PORT"
#enter login VM
#export GOOGLE_CLOUD_PROJECT=`gcloud config list --format 'value(core.project)'`
#export REGION=`gcloud config list --format 'value(compute.region)'`
#export ZONE=`gcloud config list --format 'value(compute.zone)'`
#export LOGIN_VM=`gcloud compute instances list --sort-by=~creationTimestamp --format="value(NAME)" | grep login | head -n 1`
#gcloud compute ssh --zone "us-central1-a" "$LOGIN_VM" --project "$GOOGLE_CLOUD_PROJECT"
