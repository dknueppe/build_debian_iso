#!/bin/bash

wd=$(dirname $0)
output_dir=.

# test if "docker compose" works
docker compose >/dev/null 2>&1
returncode=$?
if [ $returncode -eq 0 ]; then
  COMPOSECMD="docker compose"
else
  COMPOSECMD="docker-compose"
fi
echo "We are going to use $COMPOSECMD"

rm -f $output_dir/seapath.iso
# removing the volume in case it exists from a precedent build operation
docker rm -f fai-setup 2>/dev/null
docker volume rm build_debian_iso_ext 2>/dev/null

set -ex

# Creating the NFSROOT
# Removing *.profile since we don't use them
# Removing 50-host-classes to prevent DEMO and FAIBASE to be added to the list of classes
# Adding the Bookworm basefiles to that we deploy a Debian v12 distro
# Patches /sbin/install_packages (bug in the process of being corrected upstream)
$COMPOSECMD -f $wd/docker-compose.yml run --rm fai-setup bash -c "\
    echo \"fai-setup -v -e -f \" && \
    fai-setup -v -e -f && \
    echo \"rm -f /ext/srv/fai/config/class/50-host-classes\" && \
    rm -f /ext/srv/fai/config/class/50-host-classes && \
    echo \"rm -f /ext/srv/fai/config/class/*.profile\" && \
    rm -f /ext/srv/fai/config/class/*.profile && \
    echo \"SED\" && \
    sed -i -e \"s|-f \\\"\\\$FAI_ROOT/usr/sbin/apt-cache|-f \\\"\\\$FAI_ROOT/usr/bin/apt-cache|\" /ext/nfsroot/sbin/install_packages && \
    sed -i -e \"s/ --allow-change-held-packages//\" /ext/nfsroot/sbin/install_packages && \
    echo \"wget -O /ext/srv/fai/config/basefiles/BOOKWORM64.tar.xz https://fai-project.org/download/basefiles/BOOKWORM64.tar.xz\" && \
    wget -O /ext/srv/fai/config/basefiles/BOOKWORM64.tar.xz https://fai-project.org/download/basefiles/BOOKWORM64.tar.xz"

# Starting the container to add stuff in it
$COMPOSECMD -f $wd/docker-compose.yml up --no-start fai-setup

# Adding the SEAPATH workspace
docker cp $wd/srv_fai_config/. fai-setup:/ext/srv/fai/config/

# Stopping the container after having added stuff in it
$COMPOSECMD -f $wd/docker-compose.yml down

# Creating the mirror
CLASSES="FAIBASE,DEBIAN,GRUB_EFI,SEAPATH_COMMON,SEAPATH_HOST,SEAPATH_DBG,SEAPATH_KERBEROS,SEAPATH_COCKPIT,WELOTEC"
$COMPOSECMD -f $wd/docker-compose.yml run --rm fai-setup bash -c "\
    cp /etc/fai/apt/keys/* /etc/apt/trusted.gpg.d/ &&\
    fai-mirror -c $CLASSES /ext/mirror"

# Creating the ISO
$COMPOSECMD -f $wd/docker-compose.yml run --rm fai-cd fai-cd -f -m /ext/mirror /ext/seapath.iso

# Retrieving the ISO from the volume
$COMPOSECMD -f $wd/docker-compose.yml up --no-start fai-setup
docker cp fai-setup:/ext/seapath.iso $output_dir/
$COMPOSECMD -f $wd/docker-compose.yml down --remove-orphans

# Removing the volume
docker volume rm build_debian_iso_ext
