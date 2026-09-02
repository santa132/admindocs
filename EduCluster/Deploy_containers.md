# Deploy Containers on worker node

## Create Docker Image
- Follow instructions in the **Docker Section** to build the required image.
- Then, you need to push your image to Docker Hub so that the worker nodes can pull the image locally.
---

## Create YAML File to Deploy Image
- Define a Kubernetes Job or Deployment YAML that launches containers using the image specified in the YAML file.
```bash
apiVersion: batch/v1
kind: Job
metadata:
  name: train-job-8cons-ven5
  namespace: default
spec:
  parallelism: 8      # Number of parallel containers
  completions: 8      # Total contaners need to be finished
  template:
    metadata:
      labels:
        app: train-job-ven5
    spec:
      nodeSelector:
        kubernetes.io/hostname: aimc-ven5
      containers:
      - name: train-app
        image: <docker_hub_repo>/my-pytorch-app:latest # Change docker hub repo
        resources:
          requests:
            cpu: "4"
            memory: "20Gi"
            nvidia.com/gpu: 1
          limits:
            cpu: "4"
            memory: "25Gi"
            nvidia.com/gpu: 1
      restartPolicy: Never
```
---

## Apply yaml file
```bash
kubectl apply -f <file> -n <namespace> 
```

## List all Jobs's name
```bash
kubectl get jobs -n <namespace>
```

---

## Describe a Specific Job
```bash
kubectl describe job <Job_name> -n <namespace>
```

---

## List All Containers of a Node
```bash
kubectl get pods -n <namespace> -l job-name=<Job_name> -o wide
```
