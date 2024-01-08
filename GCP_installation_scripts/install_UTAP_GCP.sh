#!/bin/bash
#export bucket_name="utap-data-devops-279708"
#gcsfuse --file-mode 775 $bucket_name "$HOME/data"
sudo yum update
# Install basic tools for compiling
sudo yum groupinstall -y 'Development Tools'
# Ensure EPEL repository is available
sudo yum install -y epel-release
# Install RPM packages for dependencies
sudo yum install -y libseccomp-devel squashfs-tools cryptsetup wget git
sudo yum install -y rpm-build wget golang
#Install Go - singularity language 
cd ~ && wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
sudo chown lindner_jordana_gmail_com -R /opt/apps/
mkdir -p /opt/apps/singularity_v3.8.3 
mkdir -p  /opt/apps/modulefiles/singularity
touch /opt/apps/modulefiles/singularity/v3.8.3.lua
cd /opt/apps/
git clone https://github.com/hpcng/singularity.git
cd singularity && ./mconfig --only-rpm
make -C builddir rpm RPMPREFIX=/opt/apps/singularity_v3.8.3
sudo rpm -ivh ~/rpmbuild/RPMS/x86_64/singularity-3.8.*.x86_64.rpm 
echo 'singularity_install="/opt/apps/singularity_v3.8.3"
prepend_path("PATH", singularity_install.."/bin")
prepend_path("LD_LIBRARY_PATH", singularity_install.."/lib")
prepend_path("MANPATH", singularity_install.."/share/man")' >  /opt/apps/modulefiles/singularity/v3.8.3.lua
#Create soft links to the bucket:
mkdir -p data/utap-output/
mkdir -p data/logs-utap/
ln -s ~/data/genomes/ genomes
ln -s ~/data/install_UTAP_image.sh
ln -s ~/data/optional_parameters.conf
ln -s ~/data/ports.conf
ln -s ~/data/required_parameters.conf
ln -s ~/data/run_UTAP_sandbox.sh
ln -s ~/data/Singularity_sed.def
ln -s ~/data/update-db.sh
ln -s ~/data/utap-output
ln -s ~/data/logs-utap
ln -s ~/data/install_UTAP_singularity.sh
ln -s ~/data/utap_latest.sif
#cp  data/utap_latest.sif $HOME
