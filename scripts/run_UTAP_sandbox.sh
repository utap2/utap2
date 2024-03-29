#!/bin/bash

cp /mnt/host_mount/{install_UTAP_image.sh,update-db.sh} /opt/
cp /mnt/host_mount/all_parameters /opt/settings
export cluster_commands=/mnt/host_mount/cluster_commands.py
if [ -f "$cluster_commands" ]; then
    cp "$cluster_commands" /opt/miniconda3/envs/utap/lib/python3.10/site-packages/ngs-snakemake/cluster_scripts/
fi
cp /mnt/host_mount/ports.conf /etc/apache2/ports.conf

chmod +x /opt/update-db.sh
chmod +x /opt/install_UTAP_image.sh
chmod +x /opt/settings/all_parameters
chmod +rwx /etc/apache2/ports.conf
set -a 
source /opt/settings/all_parameters
source /opt/install_UTAP_image.sh
set +a 
export HOME=$HOST_MOUNT/UTAP_HOME_DIR
export PATH=/opt/miniconda3/envs/ngsplot/bin:/opt/miniconda3/envs/utap/bin:/opt/miniconda3/envs/utap:$PATH
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

/bin/bash -c "source $HOST_MOUNT/UTAP_HOME_DIR/.bashrc"
if [ $DEVELOPMENT = "None" ]; then 
  service apache2 start 
else 
  /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py runserver --insecure 0.0.0.0:2000
fi
nohup /opt/miniconda3/envs/utap-Django/bin/python /opt/utap/manage.py update_status >> $HOST_MOUNT/update_status.txt & 
