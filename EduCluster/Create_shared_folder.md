# JupyterHub Setup & Upgrade

## Requirement
- Kubernetes cluster running
- Helm installed


---

## 1. Create and Apply Shared Folder Config
Create PVC for JupyterHub with name: **jupyterhub-shared-folder-volume**

```bash
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jupyterhub-shared-folder-volume
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Gi
```
Then apply configuration file:
```bash
kubectl apply -f <shared_folder_config>.yaml -n <namespace>
# Check to make sure PVC create successfully
kubectl get pvc -n <namespace>
```
---

## 2. Delete PVC
Delete the created PVC (if reset is needed):
```bash
kubectl delete pvc jupyterhub-shared-folder-volume -n <namespace>
```

---

## 3. Upgrade JupyterHub with Edited Config
Upgrade JupyterHub with the modified configuration file **jupyterhub-full-values_edited.yaml**:
```bash
# jupyterhub-full-values_edited.yaml file
    extraVolumes:
    - name: jupyterhub-shared-folder
      persistentVolumeClaim:
        claimName: jupyterhub-shared-folder-volume
    extraVolumeMounts:
    - mountPath: /home/jovyan/SharedFolder
      name: jupyterhub-shared-folder
    homeMountPath: /home/jovyan
```

```bash
helm upgrade --cleanup-on-fail   --install hub jupyterhub/jupyterhub   --namespace hub   --create-namespace   --values jupyterhub-full-values_edited.yaml   --version 2.0
```

---

## 4. Restart Deployment
Restart deployment to apply changes:

```bash
kubectl rollout restart deployment hub -n hub
```
