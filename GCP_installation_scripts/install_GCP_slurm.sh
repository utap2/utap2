#!/bin/bash
# Generate bucket with all files first
# Generate project
# Get required and optional parameters files as input
while getopts "b:i:n:" option; do
  case "${option}" in
    i) export project_id=${OPTARG};;
    n) export project_num=${OPTARG};;
    b) export bucket_name=${OPTARG};;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

echo $project_id $project_num

#set default project 
gcloud config set project $project_id
#enable the default Compute Engine service account.
gcloud iam service-accounts enable --project $project_id $project_num-compute@developer.gserviceaccount.com
gcloud projects add-iam-policy-binding $project_id --member=serviceAccount:$project_num-compute@developer.gserviceaccount.com --role=roles/editor
#grant the roles/editor IAM role to the service account.
gcloud iam service-accounts enable --project $project_id $project_num-compute@developer.gserviceaccount.com
#grant user access credentials to terraform 
gcloud auth application-default login
#enable VM connection to your cluster by using ssh with os-login at project level
gcloud compute project-info add-metadata --metadata enable-oslogin=TRUE
#clone the Cloud HPC Toolkit GitHub repository
#sed -i "s/project_id: .*/project_id: '${project_id//\//\\/}'/" ~/utap2/GCP_installation_scripts/hpc-slurm-utap.yaml
#cd ~ && git clone https://github.com/GoogleCloudPlatform/hpc-toolkit.git
#cd hpc-toolkit/ && make 
#./ghpc create -w ~/utap2/GCP_installation_scripts/hpc-slurm-utap.yaml && ./ghpc deploy hpc-utap
#clone the Cloud SchedMD  GitHub repository
git clone https://github.com/SchedMD/slurm-gcp.git
sed -i "s/project_id = .*/project_id = \"${project_id//\//\\/}\"/" ~/utap2/GCP_installation_scripts/example.tfvars
sed -i "s/bucket_name = .*/bucket_name = \"${bucket_name//\//\\/}\"/" ~/utap2/GCP_installation_scripts/example.tfvars
cp ~/utap2/GCP_installation_scripts/example.tfvars ~/slurm-gcp/terraform/slurm_cluster/examples/slurm_cluster/simple_cloud
cp ~/utap2/GCP_installation_scripts/main_terrform.tf ~/slurm-gcp/terraform/slurm_cluster/examples/slurm_cluster/simple_cloud/main.tf
cd ~/slurm-gcp/terraform/slurm_cluster/examples/slurm_cluster/simple_cloud/ 
terraform init && terraform validate && terraform apply -var-file=example.tfvars || (echo "ERROR installing GCP Slurm cluster" && exit)
export USER_LOGIN=`gcloud compute os-login describe-profile --format json|jq -r '.posixAccounts[].username'`
export LOGIN_IP=`gcloud compute instances describe hpcutap-login-i56oilhq-001  --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone us-central1-a`
scp -i ~/.ssh/google_compute_engine ~/.ssh/google_compute_engine "$USER_LOGIN"@"$LOGIN_IP":.ssh/id_rsa
scp -i ~/.ssh/google_compute_engine ~/.ssh/google_compute_engine.pub "$USER_LOGIN"@"$LOGIN_IP":.ssh/id_rsa.pub
export GOOGLE_CLOUD_PROJECT=`gcloud config list --format 'value(core.project)'`
export REGION=`gcloud config list --format 'value(compute.region)'`
export ZONE=`gcloud config list --format 'value(compute.zone)'`
export LOGIN_VM=`gcloud compute instances list --sort-by creation_time | grep NAME | head -n 2 | grep login | awk '{print $2}'`
gcloud compute ssh --zone "us-central1-a" "$LOGIN_VM" --project "$GOOGLE_CLOUD_PROJECT"
   
