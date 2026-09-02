
# Singularity
https://docs.sylabs.io/guides/3.6/admin-guide/installation.html

## Install Dependencies
On Red Hat Enterprise Linux or CentOS install the following dependencies:
```
$ sudo yum update -y && \
     sudo yum groupinstall -y 'Development Tools' && \
     sudo yum install -y \
     openssl-devel \
     libuuid-devel \
     libseccomp-devel \
     wget \
     squashfs-tools \
     cryptsetup
```

## Install Go
```
$ export VERSION=1.13.5 OS=linux ARCH=amd64 && \
    wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \
    sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && \
    rm go$VERSION.$OS-$ARCH.tar.gz
```
Then, set up your environment for Go.

```
$ echo 'export GOPATH=${HOME}/go' >> ~/.bashrc && \
    echo 'export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin' >> ~/.bashrc && \
    source ~/.bashrc
```

## Download Singularity from a release
You can download Singularity from one of the releases. To see a full list, visit the GitHub release page. After deciding on a release to install, you can run the following commands to proceed with the installation.

```
$ export VERSION=3.6.4 && # adjust this as necessary \
    wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-${VERSION}.tar.gz && \
    tar -xzf singularity-${VERSION}.tar.gz && \
    cd singularity
```

Or download
```
$ wget https://github.com/singularityware/singularity/releases/download/v3.5.3/singularity-3.5.3.tar.gz
$ tar -xzvf singularity-3.5.3.tar.gz
```

## Installation
```
$ cd singularity
$ ./mconfig --prefix=/opt/singularity && \
    make -C ./builddir && \
    sudo make -C ./builddir install
```

# Python
```bash
export PYTHON_VERSION=3.7.7
export PYTHON_MAJOR=3
curl -O https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
tar -xvzf Python-${PYTHON_VERSION}.tgz
cd Python-${PYTHON_VERSION}
./configure \
    --prefix=/opt/python/${PYTHON_VERSION} \
    --enable-shared \
    --enable-ipv6 \
    LDFLAGS=-Wl,-rpath=/opt/python/${PYTHON_VERSION}/lib,--disable-new-dtags

make
sudo make install
```

## Install pip
Install pip into the version of Python that you just installed:

Terminal
```bash
curl -O https://bootstrap.pypa.io/get-pip.py
sudo /opt/python/${PYTHON_VERSION}/bin/python${PYTHON_MAJOR} get-pip.py
```

## Re-Install 3.8.12 to fix SSL error when install horovod using pip
```bash
(HOROVOD_GPU_OPERATIONS=NCCL HOROVOD_WITH_MPI=1 pip install --user horovod[tensorflow,keras,pytorch])
wget https://www.python.org/ftp/python/3.8.12/Python-3.8.12.tar.xz
tar xvf Python-3.8.12.tar.xz
cd Python-3.8.12
./configure --enable-optimizations --prefix=/app/python/3.8.12/
make altinstall
```

Cmake
```bash
wget https://github.com/Kitware/CMake/releases/download/v3.24.2/cmake-3.24.2-linux-x86_64.tar.gz
tar zxvf cmake-3.*
cd cmake-3.*
./bootstrap --prefix=/usr/local
make -j$(nproc)
make install
cmake --version
```

Error: Can not find CUDA things (System use CUDA at the container)

# Environment module
## Installation app
### Install lua & TCL module
Install prerequisites
You will need the following RPM packages installed on both your master and your compute nodes.
```bash
lua

lua-devel

lua-posix

lua-filesystem

tcl/tcl-devel
```

### Install Lmod
Download the latest version of LMOD
```bash
wget https://github.com/TACC/Lmod/archive/7.8.21.tar.gz
tar xvzf 7.8.21.tar.gz
```

Configure and install LMOD

We will install LMOD into our /app/lmod folder.
```bash
cd Lmod-7.8.21
./configure --prefix=/app/lmod
make pre-install
```

Create necessary symbolic links as root user

The reason we are using make pre-install and not make install is that the latter would try to create symbolic links at locations which require root rights.

Instead we will be doing these links manually. Exit the install user session with exit and create the following symbolic links as root:

go to `/app/lmod/lmod/` and create a symbolic link for the current version
```bash
cd /data/opt/apps/lmod/
ln -s 7.8.21 lmod

module support for bash
ln -s /app/lmod/lmod/init/profile /etc/profile.d/z00_lmod.sh

module support for csh
ln -s /app/lmod/lmod/init/cshrc /etc/profile.d/z00_lmod.csh
```

### Clone and config NGC environment module
```bash
https://github.com/NVIDIA/ngc-container-environment-modules
```

## Install and config at node
```bash
yum install tcl-devel.x86_64
yum install Lmod
```

Add NGC container module path in /etc/profile
```bash
export NGC_SINGULARITY_MODULE=none
export NGC_IMAGE_DIR=/app/singularity/images
```

Copy the module 
```bash
cp ca /etc/profile.d/
source ~/.bashrc
```

Check module path
```bash
echo $MODULEPATH
```
