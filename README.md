# slurmInDockerRebuild

# Base On: https://github.com/SciDAS/slurm-in-docker/blob/master/base/Dockerfile

## Idea: use ubuntu rebuild slurm with version 24.11.5

## Steps

1. 

```shell
sudo apt-get update
sudo apt-get install -y build-essential devscripts debhelper fakeroot

dpkg-buildpackage -b -us -uc
```

### if error :

```shell
dpkg-checkbuilddeps: Error: Unmet build dependencies: 
  debhelper (>= 12)
  dh-exec
  hdf5-helpers
  libcurl4-openssl-dev
  libdbus-1-dev
  libfreeipmi-dev
  libgtk2.0-dev
  libhdf5-dev
  libhttp-parser-dev
  libhwloc-dev
  libipmimonitoring-dev
  libjson-c-dev
  libjwt-dev
  liblua5.3-dev
  liblz4-dev
  libmariadb-dev | libmysqlclient-dev
  libmunge-dev
  libpam0g-dev
  libperl-dev
  libpmix-dev
  librdkafka-dev
  librrd-dev
  libyaml-dev
  man2html-base
  po-debconf
  
```

### then

```shell
sudo apt-get update
sudo apt-get install -y \
  debhelper dh-exec \
  hdf5-helpers libcurl4-openssl-dev libdbus-1-dev libfreeipmi-dev \
  libgtk2.0-dev libhdf5-dev libhttp-parser-dev libhwloc-dev \
  libipmimonitoring-dev libjson-c-dev libjwt-dev liblua5.3-dev \
  liblz4-dev libmariadb-dev libmunge-dev libpam0g-dev libperl-dev \
  libpmix-dev librdkafka-dev librrd-dev libyaml-dev \
  man2html-base po-debconf

```

Under GUI System give .dirs .installs files +x permissions, must remove them.(Please notice if your file system is NTFS exFAT, chmod -x does not work as well, only ext4 is supported)

To prove: 

find debian -type f -name "*.dirs"

find debian -type f -name "*.install"

DO:

find debian -type f -name "*.\<every type contains error\>" -exec chmod -x {} \; 

--------------

```docker build -t test .```

```docker run -it test```

```root@xxxx:/packages# slurmd --version ```

if see slurm 24.11.5 then a basic image is done!







