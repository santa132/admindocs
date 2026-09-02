# Bước 1: Triển khai Moodle và MariaDB trên Kubernetes (aimc-hn3)

Tài liệu này hướng dẫn bạn cách triển khai hệ thống học tập Moodle cùng cơ sở dữ liệu MariaDB trên cụm Kubernetes mới (`aimc-hn3` tại IP `192.168.33.3`).

---

## 1. Chuẩn bị node vật lý (Untaint Node)
Vì cụm Kubernetes `aimc-hn3` hiện tại là cụm **Single-Node** (chỉ có duy nhất 1 node đóng vai trò control-plane), Kubernetes theo mặc định sẽ chặn không cho lập lịch chạy các Pod ứng dụng thông thường trên node này. 

Bạn cần chạy lệnh sau để gỡ bỏ hạn chế này (untaint):
```bash
kubectl taint nodes aimc-hn3 node-role.kubernetes.io/control-plane-
```

---

## 2. Chuẩn bị thư mục lưu trữ trên Local Storage (/moodle)
Do Moodle và MariaDB của Bitnami chạy dưới quyền của user không phải root (UID `1001`), bạn cần tạo các thư mục lưu trữ trên phân vùng ổ đĩa cục bộ đã mount (`/moodle` thuộc `/dev/sda1`) và gán quyền sở hữu thích hợp cho UID này để tránh lỗi **Permission Denied** khi container ghi dữ liệu.

Chạy các lệnh sau trên server `aimc-hn3`:
```bash
# Tạo các thư mục lưu trữ cho cơ sở dữ liệu và dữ liệu Moodle
sudo mkdir -p /moodle/moodle_db
sudo mkdir -p /moodle/moodle_data

# Gán quyền sở hữu cho user Bitnami (UID 1001)
sudo chown -R 1001:1001 /moodle/moodle_db /moodle/moodle_data
sudo chmod -R 775 /moodle/moodle_db /moodle/moodle_data
```

---

## 3. Triển khai tài nguyên lên Kubernetes
Chúng ta đã chuẩn bị sẵn file manifest Kubernetes chứa các định nghĩa PV, PVC, Deployments và Services cho MariaDB và Moodle tại:
`c:\Users\20521\Desktop\admin\New_config\moodle-k8s-manifests.yaml` (hoặc [moodle-k8s-manifests.yaml](file:///c:/Users/20521/Desktop/admin/New_config/moodle-k8s-manifests.yaml)).

Chạy lệnh sau để triển khai:
```bash
kubectl apply -f moodle-k8s-manifests.yaml
```

---

## 4. Kiểm tra trạng thái triển khai
Chạy lệnh sau để theo dõi quá trình khởi chạy của các container:
```bash
kubectl get pods -n moodle -w
```
Đợi cho đến khi cả 2 pod `moodle-db-...` và `moodle-...` chuyển sang trạng thái `Running`.

Bạn cũng có thể xem chi tiết cổng dịch vụ được mở trên các node (NodePort):
```bash
kubectl get svc -n moodle
```
Kết quả hiển thị dịch vụ `moodle-service` sẽ ánh xạ cổng `8080` của container ra cổng `30080` của node vật lý.

---

## 5. Truy cập và kiểm tra giao diện Moodle
Sau khi các Pod ở trạng thái `Running`, bạn mở trình duyệt web và truy cập vào địa chỉ:
*   **Địa chỉ:** `http://192.168.33.3:30080`
*   **Tài khoản quản trị mặc định (Admin):**
    *   **Username:** `admin`
    *   **Password:** `SGPAIp@ssw0rd` *(Hãy đổi mật khẩu này ngay sau khi đăng nhập thành công)*

Tiếp tục chuyển sang [Bước 2: Cấu hình OAuth2 Provider trong Moodle](file:///c:/Users/20521/Desktop/admin/New_config/02_moodle_oauth_config.md) để chuẩn bị tích hợp với JupyterHub.
