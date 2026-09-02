# Overview
Horovod using openmpi (4.1.4) to start singularity (3.5.3) container at nodes.

# Configuration
Headnode:
  - Install openmpi with options. Current openmpi version at `/app/openmpi/4.1.4-sing-pbs`

    ```bash
    ./configure --prefix=/app/openmpi/4.1.4-sing-pbs --enable-orterun-prefix-by-default --with-verbs --without-cuda --disable-getpwuid
    ```
GPU nodes:
  - Disable firewall: `systemctl stop firewalld`
  - export openmpi path: `export PATH=/app/openmpi/4.1.4-sing-pbs/bin:$PATH`
    
# Horovod test
## Singularity image - single node
```bash
$ qsub -I -l select=1:mem=10GB:ncpus=5:ngpus=1,walltime=1:00:00 -q dev
$ singularity exec --nv /app/singularity/images/tensorflow_21.02-tf2-py3.sif bash
Singularity> wget https://raw.githubusercontent.com/horovod/horovod/v0.19.0/examples/tensorflow2_synthetic_benchmark.py
Singularity> horovodrun -np 1 python3 tensorflow2_synthetic_benchmark.py
```
Or
```bash
Singularity> mpirun -np 1 --map-by node --bind-to socket  python3 hvd1/test1.py
Singularity> mpirun -np 8 --map-by node --bind-to socket  python3 hvd1/test1.py
horovodrun -np 2 -H sutd-hpc-gn2:2 -p 22 python3 tensorflow2_synthetic_benchmark.py  ->work, interactive???
```

## Singularity image - multi nodes
```bash
$ qsub -I -l select=2:ncpus=40:ngpus=8:mpiprocs=8,walltime=1:00:00 -q blackout1
$ singularity exec --nv /app/singularity/images/tensorflow_21.02-tf2-py3.sif bash
Singularity> wget https://raw.githubusercontent.com/horovod/horovod/v0.19.0/examples/tensorflow2_synthetic_benchmark.py
Singularity> horovodrun -np 16 python3 tensorflow2_synthetic_benchmark.py
```

run_hvd_gloo_gpu.sh
```python
#!/bin/bash
set -x
cur_host=`hostname`
node_gpu???cd
for node in `cat $PBS_NODEFILE | uniq`
do
    if [[ ${node} == ${cur_host} ]]
    then
        host_flag="${node}:${node_gpu}"
    else
        host_flag="${host_flag},${node}:${node_gpu}"
    fi
done
horovodrun -np ${PBS_NGPUS} --gloo -H ${host_flag} -p 22 python3 tensorflow2_synthetic_benchmark.py
```
```bash
horovodrun -np 16 -H 172.16.0.14:8,172.16.0.18:8 --gloo -p 22 python3 tensorflow2_synthetic_benchmark.py -> not work
horovodrun -np 16 -H sutd-hpc-gn2:8,sutd-hpc-gn5:8 python3 tensorflow2_synthetic_benchmark.py
```

# MPI backend:
```bash
--mca pml ob1 --mca btl tcp,self --mca btl_tcp_if_include bond0 \
singularity exec --nv /app/singularity/images/tensorflow_20.02-tf2-py3.simg \
```
Option1:
```bash
qsub -I -l select=2:ncpus=40:ngpus=8:mpiprocs=8,walltime=1:00:00 -q blackout1
singularity exec --nv /app/singularity/images/tensorflow_20.02-tf2-py3.simg bash
mpirun  -bind-to none -map-by slot  -x NCCL_DEBUG=INFO  --mca btl_openib_warn_default_gid_prefix 0 python3 tensorflow2_synthetic_benchmark.py
```
Option2:
```bash
qsub -I -l select=2:ncpus=40:ngpus=8:mpiprocs=8,walltime=1:00:00 -q blackout1
/Apps/openmpi-4.0.3_pbs_sif_cuda/bin/mpirun -N 16 \
    -bind-to none -map-by slot \
    -x NCCL_DEBUG=INFO \
    --mca btl_openib_warn_default_gid_prefix 0 \
    singularity exec --nv /app/singularity/images/tensorflow_20.02-tf2-py3.simg \
    python /home/users/uat/multinode/hvdtest.py
```
Option3:
```bash
qsub -I -l select=2:ncpus=40:ngpus=8:mpiprocs=8,walltime=1:00:00 -q blackout1
mpirun -n 80 \
    --mca pml ob1 --mca btl tcp,self --mca btl_tcp_if_include bond0 \
    singularity exec --nv /app/singularity/images/tensorflow_20.02-tf2-py3.simg \
    python3 /home/users/andy/tensorflow2_synthetic_benchmark.py
```

```bash
https://www.open-mpi.org/faq/?category=openfabrics#ompi-over-roce
mpirun --mca btl openib,self,vader --mca btl_openib_cpc_include rdmacm \
    --mca btl_openib_ipaddr_include "172.0.0.0/8" ...
mpirun --mca pml ob1 --mca btl openib,self,vader \
    --mca btl_openib_cpc_include rdmacm --mca btl_openib_rroce_enable 1 ...
```

Show NCCL debug info:
    `-x NCCL_DEBUG=INFO`
Running option:
```bash
-x NCCL_IB_HCA=mlx5_bond_0 -x NCCL_IB_CUDA_SUPPORT=1
-x NCCL_IB_GID_INDEX=3 -x NCCL_CHECKS_DISABLE=1 -x NCCL_IB_DISABLE=0 
```

## Horovod examples
https://opus.nci.org.au/display/DAE/Pytorch+using+Horovod
https://github.com/horovod/horovod/tree/master/examples/pytorch
https://github.com/horovod/horovod/tree/master/examples/tensorflow2


## Pytorch
### Setup horovod at user home directory
```bash
qsub -I -l select=1:ncpus=5,walltime=1:00:00 -q dev
singularity exec --nv /app/singularity/images/pytorch_21.02-py3.sif bash
Singularity> HOROVOD_GPU_OPERATIONS=NCCL HOROVOD_WITH_MPI=1 /opt/conda/bin/pip install --no-cache-dir horovod[pytorch]
Singularity> HOROVOD_GPU_OPERATIONS=NCCL HOROVOD_WITH_MPI=1 pip install horovod[tensorflow,keras,pytorch]
export PATH=/home/users/andy/.local/bin:$PATH
Singularity> horovodrun --check-build
```

```bash
Horovod v0.25.0:

Available Frameworks:
    [ ] TensorFlow
    [X] PyTorch
    [ ] MXNet

Available Controllers:
    [X] MPI
    [X] Gloo

Available Tensor Operations:
    [X] NCCL
    [ ] DDL
    [ ] CCL
    [X] MPI
    [X] Gloo
```

### Run multinode training using pytorch singularity container
```bash
$ qsub mpi-sing-hvd-pytorch-mnist.pbs
$ qsub mpi-sing-hvd-pytorch-benchmark.pbs
```

Reinstall if checking and dont have the feature needed
```bash
Singularity> pip uninstall horovod
Singularity> HOROVOD_GPU_OPERATIONS=NCCL /opt/conda/bin/pip install --no-cache-dir horovod[pytorch]

Singularity> HOROVOD_GPU_OPERATIONS=NCCL HOROVOD_WITH_MPI=1 pip install --no-cache-dir horovod[pytorch]
Singularity> HOROVOD_GPU_OPERATIONS=NCCL HOROVOD_WITH_MPI=1 /opt/conda/bin/pip install --no-cache-dir horovod[pytorch]
export PATH=/home/users/andy/.local/bin/:$PATH

Singularity> horovodrun -np 16 python3 tensorflow2_synthetic_benchmark.py

module load python/3.8.12
HOROVOD_GPU_OPERATIONS=NCCL HOROVOD_WITH_MPI=1 pip install --user horovod[tensorflow,keras,pytorch]
```
Remove pip packages:

List installed packages with 
```bash
pip3 list --user
pip3 uninstall --user <package> to remove specific packages.
pip3 uninstall -r requirement.txt -y
```

# Conda
```bash
conda create -n hvd python==3.8
/home/users/andy/.conda/envs/hvd/bin/pip config set global.target /home/users/andy/.conda/envs/hvd/lib/python3.8/site-packages/
export PATH=/home/users/andy/.conda/envs/hvd/bin/:$PATH
export PYTHONPATH=/home/users/andy/.conda/envs/hvd/lib/python3.8/site-packages/:$PYTHONPATH
HOROVOD_GPU_OPERATIONS=NCCL HOROVOD_WITH_MPI=1 /home/users/andy/.conda/envs/hvd/bin/pip install horovod[pytorch]
```

To use the spec file to create an identical environment on the same machine or another machine:
```bash
conda create -n myenv --file file.txt
```

To use the spec file to install its listed packages into an existing environment:
```bash
conda install -n myenv --file file.txt

conda env list

conda list
conda list -n horovod
```
Removing an environment
To remove an environment, in your terminal window or an Anaconda Prompt, run:
```bash
conda remove --name hvd --all
```
```bash
-mca plm_base_verbose 5 --debug-daemons
```
