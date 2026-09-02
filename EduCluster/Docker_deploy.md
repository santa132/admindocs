# Docker Workflow Guide

# 1. Pull an Image
```bash
# Example: pull an existing image from Docker Hub
docker pull <image_name>
```
# 2. Create a Dockerfile
Create a Dockerfile in your project directory and define the image.
```bash
# Example dockerfile
FROM pytorch/pytorch:2.2.0-cuda11.8-cudnn8-runtime

WORKDIR /app

COPY start.sh train.py test_pytorch.py /app/

RUN chmod +x start.sh

RUN pip install --no-cache-dir torch numpy torchvision poutyne

CMD ["bash", "./start.sh"]
```

# 3.1 Build 
## Build Docker Image
```bash
# Build with a local tag
docker build -t mytrain:v1 .
```
## Build and tag for Docker Hub
```bash
docker build -t <docker_hub_repo>/my-pytorch-app:latest .
```
# 4. Run Docker Container
```bash
# Run container in terminal and remove it after exit
docker run --rm mytrain:v1
```

# 5. Run container with GPU support and interactive terminal

```bash
docker run -it --rm --gpus all <docker_hub_repo>/my-pytorch-app:latest bash start.sh
```

# 6. List All Docker Images
```bash
docker images
```
# 7. Tag Docker Image
```bash
docker tag mnist-pytorch:v1 <docker_hub_repo>/mnist-pytorch:v1
```
# 8. Push Docker Image to Docker Hub

Create a Docker Hub account.

Login to Docker Hub:

```bash
docker login
```
Push the image:

```bash
docker push <docker_hub_repo>/mnist-pytorch:v1
```
# 9. Stop/Kill Docker Containers
```bash

docker kill <PID> 
```