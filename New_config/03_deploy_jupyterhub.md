# Bước 3: Triển khai JupyterHub trên Kubernetes (aimc-hn3)

Tài liệu này hướng dẫn bạn cách thiết lập hệ thống lưu trữ động (Dynamic Provisioner), tạo thư mục chia sẻ chung và deploy JupyterHub bằng Helm chart tích hợp với cổng xác thực Moodle đã tạo ở các bước trước.

---

## 1. Cấu hình Storage Class động (Rancher Local Path Provisioner)
Để tự động tạo thư mục lưu trữ cá nhân (home directory `/home/jovyan`) cho mỗi học sinh khi họ đăng nhập, chúng ta cần một StorageClass động. Vì là cụm Single-Node và có sẵn NAS tại `/mnt/nas`, giải pháp tối ưu và nhẹ nhàng nhất là sử dụng **Rancher Local Path Provisioner** trỏ trực tiếp vào thư mục `/mnt/nas/jupyterhub-users`.

### 1.1 Cài đặt Local Path Provisioner:
Chạy lệnh sau trên Node `aimc-hn3`:
```bash
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.30/deploy/local-path-storage.yaml
```

### 1.2 Thay đổi đường dẫn lưu trữ về NAS:
Theo mặc định, provisioner này lưu tại `/opt/local-path-provisioner`. Hãy chuyển đường dẫn này về thư mục NAS của bạn:
1.  Tạo thư mục trên NAS và gán quyền:
    ```bash
    sudo mkdir -p /mnt/nas/jupyterhub-users
    sudo chmod 777 /mnt/nas/jupyterhub-users
    ```
2.  Chỉnh sửa ConfigMap cấu hình của Local Path Provisioner:
    ```bash
    kubectl edit cm local-path-config -n local-path-storage
    ```
3.  Tìm đến đoạn cấu hình đường dẫn `"paths": ["/opt/local-path-provisioner"]` và sửa thành:
    ```json
    "paths": ["/mnt/nas/jupyterhub-users"]
    ```
    Lưu và thoát (nếu dùng vi/vim thì nhấn `Esc` rồi gõ `:wq`).

---

## 2. Tạo Thư mục chia sẻ dùng chung (SharedFolder)
Học sinh cần có một thư mục chung để xem tài liệu học tập hoặc nộp bài. Chúng ta sẽ tạo một Persistent Volume (PV) và Persistent Volume Claim (PVC) trỏ đến `/mnt/nas/jupyterhub-shared` trên host.

### 2.1 Tạo thư mục trên Host:
```bash
sudo mkdir -p /mnt/nas/jupyterhub-shared
sudo chmod 777 /mnt/nas/jupyterhub-shared
```

### 2.2 Định nghĩa file manifest tạo PV/PVC:
Tạo file `jupyterhub-shared-pvc.yaml` với nội dung sau:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: hub
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jupyterhub-shared-folder-pv
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  local:
    path: /mnt/nas/jupyterhub-shared
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - aimc-hn3
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jupyterhub-shared-folder-volume
  namespace: hub
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: local-storage
  resources:
    requests:
      storage: 100Gi
```

### 2.3 Áp dụng vào Kubernetes:
```bash
kubectl apply -f jupyterhub-shared-pvc.yaml
```

---

## 3. Triển khai JupyterHub thông qua Helm Chart

### 3.1 Cài đặt Helm (nếu chưa có):
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 3.2 Chuẩn bị file cấu hình `jupyterhub-values-new.yaml`:
Mở file [jupyterhub-values-new.yaml](file:///c:/Users/20521/Desktop/admin/New_config/jupyterhub-values-new.yaml):
1.  Đảm bảo thay thế giá trị của `client_secret` ở dòng 16 bằng mã **Client Secret** bạn đã copy từ Moodle ở **Bước 2**.
2.  Kiểm tra lại IP `192.168.33.3` trong các URL xem đã khớp với IP Node của bạn chưa.

### 3.3 Đăng ký repo Helm của JupyterHub và deploy:
Chạy chuỗi lệnh sau để tiến hành cài đặt:
```bash
# Thêm repo Helm chính thức của JupyterHub
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo update

# Triển khai JupyterHub vào namespace 'hub'
helm upgrade --cleanup-on-fail \
  --install hub jupyterhub/jupyterhub \
  --namespace hub \
  --create-namespace \
  --values jupyterhub-values-new.yaml \
  --version 2.0.0
```

---

## 4. Kiểm tra hoạt động hệ thống

1.  Kiểm tra các Pod trong namespace `hub`:
    ```bash
    kubectl get pods -n hub
    ```
    Chờ các pod `hub-...` và `proxy-...` chuyển sang trạng thái `Running`.
2.  Mở trình duyệt và truy cập:
    `http://192.168.33.3:30000`
3.  Click chọn nút đăng nhập. Hệ thống sẽ tự động chuyển hướng (Redirect) bạn sang giao diện xác thực của Moodle (`http://192.168.33.3:30080`).
4.  Sau khi nhập tài khoản Moodle thành công và nhấn **Authorize**, Moodle sẽ redirect bạn quay trở lại JupyterHub và tự động tạo (spawn) máy chủ Notebook cá nhân cho bạn (với các tùy chọn CPU Server đã thiết lập).
