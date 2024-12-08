#!/bin/bash
#export bucket_name="utap-data-devops-279708"
#gcsfuse --file-mode 775 $bucket_name "$HOME/data"
#sudo yum update
# Install basic tools for compiling
sudo yum groupinstall -y 'Development Tools'
## Install RPM packages for dependencies centos-7
#sudo yum install -y \
#   autoconf \
#   automake \
#   cryptsetup \
#   fuse3-devel \
#   git \
#   glib2-devel \
#   libseccomp-devel \
#   libtool \
#   runc \
#   squashfs-tools \
#   wget \
#   zlib-devel
#   
# Install RPM packages for dependencies rocky
sudo yum install -y \
   autoconf \
   automake \
   crun \
   cryptsetup \
   fuse3-devel \
   git \
   glib2-devel \
   libseccomp-devel \
   libtool \
   squashfs-tools \
   wget \
   zlib-devel
#
# Ensure EPEL repository is available
#sudo yum install -y epel-release
# Install RPM packages for dependencies
#sudo yum install -y libseccomp-devel squashfs-tools cryptsetup wget git
#sudo yum install -y rpm-build wget golang
#Install Go - singularity language 
last_version=$(curl -s -L -w '%{url_effective}' https://golang.org/dl/ |  grep 'download' | grep 'linux-amd64.tar.gz' | head -n 1 | cut -d'"' -f4)
sudo chown $USER -R /opt/apps/
sudo chmod 777 -R /opt/apps/
cd /opt/apps/ && wget https://go.dev/$last_version || (echo "ERROR downloading Go language' please download manually" && exit)  
cd /opt/apps/ && tar -xzf $(basename $last_version)
echo 'export PATH=$PATH:/opt/apps/go/bin' >> ~/.bashrc
source ~/.bashrc
mkdir -p /opt/apps/singularity_latest
mkdir -p /opt/apps/modulefiles/singularity
touch /opt/apps/modulefiles/singularity/latest.lua
cd /opt/apps/
git clone --recurse-submodules https://github.com/sylabs/singularity.git 
cd singularity && ./mconfig --prefix=/opt/apps/singularity_latest --localstatedir=$HOME
make -C ./builddir && sudo make -C ./builddir install
#make -C builddir rpm RPMPREFIX=/opt/apps/singularity_v3.8.3
#sudo rpm -ivh ~/rpmbuild/RPMS/x86_64/singularity-3.8.*.x86_64.rpm 
echo 'singularity_install="/opt/apps/singularity_latest"
prepend_path("PATH", singularity_install.."/bin")
prepend_path("LD_LIBRARY_PATH", singularity_install.."/lib")
prepend_path("MANPATH", singularity_install.."/share/man")' >  /opt/apps/modulefiles/singularity/latest.lua
#Create soft links to the bucket:
cd $HOME
mkdir -p ~/data/utap-output/
mkdir -p ~/data/logs-utap/
ln -s ~/data/genomes/ 
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
