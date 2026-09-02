# Installation
```bash
https://www.open-mpi.org/software/ompi/v4.1/
https://www.open-mpi.org/faq/?category=building
tar xf openmpi-<version>.tar.bz2
cd openmpi-<version>
./configure --prefix=<path> [...options...] 2>&1 | tee config.out
./configure --prefix=/app/openmpi/4.1.4 --enable-orterun-prefix-by-default --with-verbs -> current config
./configure --prefix=/app/openmpi/4.1.4-sing-pbs --enable-orterun-prefix-by-default --with-verbs --without-cuda --disable-getpwuid
./configure --prefix=/Apps/openmpi-4.0.3_pbs_sif_cuda --with-cuda --with-tm=/opt/pbs --with-singularity=/Apps/singularity-3.5.3
make -j $nproc all 2>&1 | tee make.out
make install 2>&1 | tee install.out
```
## Configure options:
--with-tm
# Testing 
## MPI at native OS
```bash
qsub -I -l select=2:ncpus=20:ngpus=8:mpiprocs=20,walltime=1:00:00 -q blackout1

mpirun -np 40 singularity exec /app/singularity/images/tensorflow_22.06-tf2-py3.sif mpi-hello

mpirun -bind-to none -map-by slot --mca btl_openib_warn_default_gid_prefix 0 -np 40 -H sutd-hpc-gn2,sutd-hpc-gn5 mpi-hello
mpirun -bind-to none -map-by slot --mca btl_openib_warn_default_gid_prefix 0 -np 40 -H 172.16.0.14,172.16.0.18  mpi-hello
mpirun -bind-to none -map-by slot --mca btl_openib_warn_default_gid_prefix 0 -np 40 -H 172.16.0.14,172.16.0.18 singularity exec /app/singularity/images/tensorflow_20.02-tf2-py3.simg /home/users/andy/mpi/mpihello
mpirun -N 16 \
    -bind-to none -map-by slot \
    -x NCCL_DEBUG=INFO \
    --mca btl_openib_warn_default_gid_prefix 0 \
    singularity exec --nv /app/singularity/images/tensorflow_20.02-tf2-py3.simg \
    python /home/users/uat/multinode/hvdtest.py
```

### Running options:
- `--mca btl tcp,self`
- `--mca pml ob1 --mca btl tcp,self --mca btl_tcp_if_include bond0` ->OK for multinode simple mpi script
- `-bind-to none -map-by slot --mca btl_openib_warn_default_gid_prefix 0`
- `--prefix /app/openmpi/4.1.4-sing-pbs`

`export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/app/openmpi/4.1.4-sing-pbs/lib/`
Debug: `--mca btl_base_verbose 100`
## MPI using PBS

/Apps/openmpi-4.0.3/bin/mpicc -o mpi_hello mpi_hello.c

```c
#include <mpi.h>
#include <stdio.h>

int main(int argc, char** argv) {
  // Initialize the MPI environment. The two arguments to MPI Init are not
  // currently used by MPI implementations, but are there in case future
  // implementations might need the arguments.
  MPI_Init(NULL, NULL);

  // Get the number of processes
  int world_size;
  MPI_Comm_size(MPI_COMM_WORLD, &world_size);

  // Get the rank of the process
  int world_rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

  // Get the name of the processor
  char processor_name[MPI_MAX_PROCESSOR_NAME];
  int name_len;
  MPI_Get_processor_name(processor_name, &name_len);

  // Print off a hello world message
  printf("Hello world from processor %s, rank %d out of %d processors\n",
         processor_name, world_rank, world_size);

  // Finalize the MPI environment. No more MPI calls can be made after this
  MPI_Finalize();
}
```

qsub mpitest.pbs
```bash
#!/bin/bash

#PBS -N mpitest
#PBS -q blackout1
#PBS -l select=2:ncpus=40:mem=4G:mpiprocs=40
#PBS -j oe
#PBS -o output.log

echo $PBS_NODEFILE
cat $PBS_NODEFILE | wc -l
module load openmpi/4.0.3
echo $PATH
cd /home/users/andy/mpi-fred
mpirun --mca btl tcp,self -np 8 --hostfile $PBS_NODEFILE ./mpi_hello
```

Error:
```bash
A process or daemon was unable to complete a TCP connection
to another process:
  Local host:    SUTD-hpc-gn5
  Remote host:   SUTD-hpc-gn2
This is usually caused by a firewall on the remote host. Please
check that any firewall (e.g., iptables) has been disabled and
try again.
------------------------------------------------------------
--------------------------------------------------------------------------
ORTE was unable to reliably start one or more daemons.
This usually is caused by:
...
```