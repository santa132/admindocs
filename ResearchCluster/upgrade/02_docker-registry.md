# Installing Docker registry in the local HPC
## Install Docker
Follow this link: https://docs.docker.com/engine/install/centos/

### Uninstall old versions
```bash
yum remove docker docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
```

### Install using the repository
```bash
yum install -y yum-utils

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

- Start Docker
```bash
systemctl start docker
```

## Set up hostname
- Open `hosts` file
```bash
vi /etc/hosts
```
- Add the hostname
```bash
192.168.33.30     aimc.registry
192.168.33.30     hub.aimc.local
```
- Create and/or open the `daemon.json` file
```bash
vi /etc/docker/daemon.json
```
- Add `insecure-registries`
```bash
{
    "insecure-registries" : ["hub.aimc.local:5000","aimc.registry:5000"]
}
```

## Install Docker registry
### Run a local registry
```bash
docker run -d -p 5000:5000 --restart=always --name registry -v /mnt/data/local-registry:/var/lib/registry registry:2.7.0
```

### Copy an image from Docker Hub to your registry
- Pull `ubuntu:22.04` image from Docker Hub
```bash
docker pull ubuntu:22.04
```

- Tag the image as `aimc.registry:5000/ubuntu:22.04`
```bash
docker tag ubuntu:22.04 aimc.registry:5000/ubuntu:22.04
```

- Push the image to the local registry running at `aimc.registry:5000`
```bash
docker push aimc.registry:5000/ubuntu:22.04
```

- Remove the locally-cached `aimc.registry:5000/ubuntu:22.04`
```bash
docker image remove ubuntu:22.04
docker push aimc.registry:5000/ubuntu:22.04
```

### Stop a local registry
```bash
docker container stop registry && docker container rm -v registry
```

## Setup on the **execution node**
- Open `hosts` file
```bash
vi /etc/hosts
```
- Add the hostname
```bash
192.168.33.30     aimc.registry
192.168.33.30     hub.aimc.local
```
- Create and/or open the `daemon.json` file
```bash
vi /etc/docker/daemon.json
```
- Add `insecure-registries`
```bash
{
    "insecure-registries" : ["hub.aimc.local:5000","aimc.registry:5000"]
}
```

### Restart Docker
```bash
systemctl restart docker
```

### Pull `aimc.registry:5000/ubuntu:22.04` image from the local registry.
```bash
docker pull aimc.registry:5000/ubuntu:22.04
```

- Remove the image
```bash
docker image remove aimc.registry:5000/ubuntu:22.04
```