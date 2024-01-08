#!/bin/bash
#generte bucket with all files first
#generate project 

export project_id="devops-279708"
export project_num="121526584309"
#set default project 
gcloud config set project $project_id
#enable the default Compute Engine service account.
gcloud iam service-accounts enable --project devops-279708 $project_num-compute@developer.gserviceaccount.com
gcloud projects add-iam-policy-binding $project_id --member=serviceAccount:$project_num-compute@developer.gserviceaccount.com --role=roles/editor
#grant the roles/editor IAM role to the service account.
gcloud iam service-accounts enable --project $project_id $project_num-compute@developer.gserviceaccount.com
#grant user access credentials to terraform 
gcloud auth application-default login
#enable VM connection to your cluster by using ssh with os-login at project level
gcloud compute project-info add-metadata --metadata enable-oslogin=TRUE
#clone the Cloud HPC Toolkit GitHub repository
cd ~ && git clone https://github.com/GoogleCloudPlatform/hpc-toolkit.git
cd hpc-toolkit/ && make 
./ghpc create ~/GCP_slurm_installation/hpc-slurm-utap.yaml -w --vars project_id=$project_id && ./ghpc deploy hpc-small-utap


   
