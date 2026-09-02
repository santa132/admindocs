# JyputerHub installation
## Kubernetes storage:
- Reference: https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner#with-helm
- Config file: located at ehn1 at /mnt/nfs-ehn1/EduCluster
```bash
sudo mkdir /mnt/nfs

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=172.16.0.15 \
    --set nfs.path=/mnt/nfs-ehn1/

kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

- Check:
```bash
kubectl get storageclass
```

- Change the ReclaimPolicy
```bash
kubectl get storageclass nfs-client -o yaml > storage-config.yaml
```
- Edit a `reclaimPolicy` field to `Retain`, and update the config
```bash
kubectl replace -f storage-config.yaml --force
```

## Create a shared storage
### Dataset
- Create a config file
```bash
nano pvc-shared-dataset.yaml
```
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jupyterhub-shared-dataset
spec:
  accessModes:
    - ReadOnlyMany
  resources:
    requests:
      storage: 512Gi

```
- Create PVC for the shared folder
```bash
kubectl apply -f pvc-shared-dataset.yaml --namespace=hub
```

### Shared folder
- Create a config file
```bash
nano pvc-shared-large-folder.yaml
```
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jupyterhub-shared-large-volume
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1024Gi
```
- Create PVC for the shared folder
```bash
kubectl apply -f pvc-shared-large-folder.yaml --namespace=hub
```

## Install JupyterHub Helm chart
- Config file:
  - `client_secret`: `client_token` of OAuth Plugin in Moodle
  - Change the IP and port appropriately
  - In `Authenticator/admin_users`, list of accounts which have the admin permission.
```yaml
hub:
  revisionHistoryLimit:
  config:
    GenericOAuthenticator:
      client_id: JupyterHub
      client_secret: 98e400a9505e553e9274cde8dc4a9680c37a668c11c8f1f2
      oauth_callback_url: http://login2.gpucluster.sutd.edu.sg/hub/oauth_callback
      authorize_url: http://login2.gpucluster.sutd.edu.sg:8888/moodle/local/oauth/login.php?client_id=jupyterhub&response_type=code
      token_url: http://login2.gpucluster.sutd.edu.sg:8888/moodle/local/oauth/token.php
      userdata_url: http://login2.gpucluster.sutd.edu.sg:8888/moodle/local/oauth/user_info.php
      #userdata_method: "GET"
      scope:
        - user_info
    Authenticator:
      admin_users:
        - admin
    JupyterHub:
      authenticator_class: generic-oauth
  networkPolicy:
    enabled: false

#proxy:
#  https:
#    enabled: true
#    hosts:
#      - 192.168.33.15
#    letsencrypt:
#      contactEmail: aimc_support@sutd.edu.sg

# singleuser relates to the configuration of KubeSpawner which runs in the hub
# pod, and its spawning of user pods such as jupyter-myusername.
singleuser:
  allowPrivilegeEscalation: false
  storage:
    type: dynamic
    static:
      pvcName:
      subPath: "{username}"
    capacity: 100Gi
    homeMountPath: /home/jovyan
    dynamic:
      storageClass:
      pvcNameTemplate: claim-{username}{servername}
      volumeNameTemplate: volume-{username}{servername}
      storageAccessModes: [ReadWriteOnce]
    extraVolumes:
      - name: jupyterhub-shared
        persistentVolumeClaim:
          claimName: jupyterhub-shared-large-volume
      - name: jupyterhub-dataset
        persistentVolumeClaim:
          claimName: jupyterhub-shared-dataset
    extraVolumeMounts:
      - name: jupyterhub-shared
        mountPath: /home/jovyan/shared
      - name: jupyterhub-dataset
        mountPath: /home/jovyan/datasets
        readOnly: true
  image:
    name: aimc.registry:5000/ai-container
    tag: "1.0-pytorch"
  startTimeout: 3600
  profileList:
    # - display_name: "Regular GPU Server"
    #   description: "Notebook server with access to a 8GB vGPU, 2 CPUs, 12GB RAM"
    #   profile_options:
    #     image:
    #       display_name: Image
    #       choices:
    #         base:
    #           display_name: Base
    #           kubespawner_override:
    #             image: "aimc.registry:5000/ai-container:1.1-base"
    #         tensorflow:
    #           display_name: Tensorflow 2
    #           kubespawner_override:
    #             image: "aimc.registry:5000/ai-container:1.0-tf2"
    #         pytorch:
    #           display_name: Pytorch
    #           default: true
    #           kubespawner_override:
    #             image: "aimc.registry:5000/ai-container:1.0-pytorch"
    #   kubespawner_override:
    #     mem_guarantee: 12G
    #     mem_limit: 16G
    #     cpu_guarantee: 2
    #     cpu_limit: 4
    #     extra_resource_limits:
    #       nvidia.com/gpu: "1"
    #     node_selector:
    #       nvidia.com/gpu.product: GRID-V100DX-8Q
    - display_name: "Large GPU Server"
      description: "Notebook server with access to a 16GB vGPU, 4 CPUs, 24GB RAM"
      profile_options:
        image:
          display_name: Image
          choices:
            base:
              display_name: Base
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.1-base"
            tensorflow:
              display_name: Tensorflow 2
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.0-tf2"
            pytorch:
              display_name: Pytorch
              default: true
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.0-pytorch"
      kubespawner_override:
        mem_guarantee: 24G
        mem_limit: 28G
        cpu_guarantee: 4
        cpu_limit: 6
        extra_resource_limits:
          nvidia.com/gpu: "1"
        node_selector:
          nvidia.com/gpu.product: GRID-V100DX-16Q

    - display_name: "Extra Large GPU Server"
      description: "Notebook server with access to a Tesla V100 32GB GPU, 10 CPUs, 48GB RAM"
      profile_options:
        image:
          display_name: Image
          choices:
            base:
              display_name: Base
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.1-base"
            tensorflow:
              display_name: Tensorflow 2
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.0-tf2"
            pytorch:
              display_name: Pytorch
              default: true
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.0-pytorch"
      kubespawner_override:
        mem_guarantee: 48G
        mem_limit: 52G
        cpu_guarantee: 10
        cpu_limit: 16
        extra_resource_limits:
          nvidia.com/gpu: "1"
        node_selector:
          nvidia.com/gpu.product: Tesla-V100-SXM2-32GB

    - display_name: "Courses"
      description: "Notebook server supported for the SUTD courses"
      profile_options:
        image:
          display_name: Image
          choices:
            mlops:
              display_name: "50.055 - MLOps"
              default: true
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.0-pytorch"
            ai4health:
              display_name: "01.116 - AI for Healthcare"
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.0-pytorch"
            ai-pytorch:
              display_name: "50.021 - AI - Pytorch"
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.0-pytorch"
            ai-tf:
              display_name: "50.021 - AI - Tensorflow 2"
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.0-tf2"
            mr-pytorch:
              display_name: "50.047 - Mobile Robotics - Pytorch"
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.0-pytorch"
            mr-tf:
              display_name: "50.047 - Mobile Robotics - Tensorflow 2"
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.0-tf2"
            cds-pytorch:
              display_name: "50.038 - CDS - Pytorch"
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.0-pytorch"
            cds-tf:
              display_name: "50.038 - CDS - Tensorflow 2"
              kubespawner_override:
                image: "aimc.registry:5000/ai-container:1.0-tf2"
      kubespawner_override:
        mem_guarantee: 24G
        mem_limit: 28G
        cpu_guarantee: 4
        cpu_limit: 6
        extra_resource_limits:
          nvidia.com/gpu: "1"
        node_selector:
          nvidia.com/gpu.product: GRID-V100DX-16Q

    # - display_name: "Base image"
    #   description: "Base image with 2/4 cores, 1 vGPU (8/16GB), 100GB storage, and 12/24G memory"
    #   default: true
    # - display_name: "Base image 2"
    #   description: "Base image with 2/4 cores, 1 vGPU (8/16GB), 100GB storage, 12/24G memory, and VSCode"
    #   kubespawner_override:
    #     image: minht57/aimc-image:0.4-aibase-vnc-ubuntu20.04
  cpu:
    limit: 4
    guarantee: 2
  memory:
    limit: 28G
    guarantee: 12G
  extraResource:
    limits: 
      # "nvidia.com/gpu": "1"
      ephemeral-storage: '5Gi'
    guarantees: 
      # "nvidia.com/gpu": "1"
      ephemeral-storage: '5Gi'
  cmd: jupyterhub-singleuser
  networkPolicy:
    enabled: false

scheduling:
  userScheduler:
    enabled: false

cull:
  enabled: true
  users: false # --cull-users
  adminUsers: true # --cull-admin-users
  timeout: 7200 # --timeout
  every: 600 # --cull-every
  concurrency: 10 # --concurrency
  maxAge: 14400 # --max-age
```

- Install JupyterHub using Helm chart
```bash
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update
helm upgrade --cleanup-on-fail   --install hub jupyterhub/jupyterhub   --namespace hub   --create-namespace   --values config.yaml --version 2.0
```

- The output should be
```bash
### Post-installation checklist

  - Verify that created Pods enter a Running state:

      kubectl --namespace=hub get pod

    If a pod is stuck with a Pending or ContainerCreating status, diagnose with:

      kubectl --namespace=hub describe pod <name of pod>

    If a pod keeps restarting, diagnose with:

      kubectl --namespace=hub logs --previous <name of pod>

  - Verify an external IP is provided for the k8s Service proxy-public.

      kubectl --namespace=hub get service proxy-public

    If the external ip remains <pending>, diagnose with:

      kubectl --namespace=hub describe service proxy-public

  - Verify web based access:

    You have not configured a k8s Ingress resource so you need to access the k8s
    Service proxy-public directly.

    If your computer is outside the k8s cluster, you can port-forward traffic to
    the k8s Service proxy-public with kubectl to access it from your
    computer.

      kubectl --namespace=hub port-forward service/proxy-public 8080:http

    Try insecure HTTP access: http://localhost:8080
```

- Config `apache2`
  - Create a new file
    ```bash
    sudo vi /etc/apache2/sites-available/jupyterhub.conf
    ```

  - Check port of JupyterHub
    ```bash
    kubectl get services -n hub
    ```
  - The output should be
    ```bash
    aimc@aimc-en1:~$ kubectl get services -n hub
    NAME           TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
    hub            ClusterIP      10.110.122.85    <none>        8081/TCP       3d4h
    proxy-api      ClusterIP      10.103.58.117    <none>        8001/TCP       3d4h
    proxy-public   LoadBalancer   10.109.161.235   <pending>     80:30669/TCP   3d4h
    ```
  
  - Copy content and change the appropriate port (port displayed at the `proxy-public` service)
    ```bash
    <VirtualHost *:*>
        ProxyPreserveHost On
    
        RewriteEngine on
        RewriteCond %{HTTP:UPGRADE} ^WebSocket$ [NC]
        RewriteCond %{HTTP:CONNECTION} ^Upgrade$ [NC]
        RewriteRule .* ws://192.168.33.15:30669%{REQUEST_URI} [P] 

        ProxyPass / http://192.168.33.15:30669/
        ProxyPassReverse / http://192.168.33.15:30669/
        ProxyRequests on
        RequestHeader set X-Forwarded-Proto "http"

        ServerName localhost
    </VirtualHost>
    ```
  - Enable site
    ```bash
    sudo a2ensite jupyterhub.conf
    sudo a2enmod proxy_http
    sudo a2enmod rewrite
    sudo a2enmod headers
    ```
  
  - Restart `apache2`
    ```bash
    sudo systemctl restart apache2
    ```
