# Bước 2: Cấu hình Moodle làm OAuth2 Provider cho JupyterHub

Để JupyterHub có thể sử dụng cơ chế đăng nhập một lần (SSO) bằng tài khoản Moodle của học sinh, chúng ta cần biến Moodle thành một OAuth2 Identity Provider (IdP). 

Tài liệu này hướng dẫn cài đặt và cấu hình plugin OAuth2 Provider trên Moodle.

---

## 1. Chuẩn bị file Plugin
Bạn có sẵn file plugin OAuth2 trong thư mục cụm cũ tại:
[oauth_gn4.zip](file:///c:/Users/20521/Desktop/admin/EduCluster/oauth_gn4.zip)

Hãy tải hoặc sao chép file này về máy tính cá nhân để chuẩn bị upload lên giao diện quản trị Moodle.

---

## 2. Cài đặt OAuth2 Plugin trên Moodle
1.  Truy cập vào trang quản trị Moodle của bạn tại `http://192.168.33.3:30080`.
2.  Đăng nhập bằng tài khoản quản trị `admin` / `SGPAIp@ssw0rd`.
3.  Di chuyển đến mục: **Site administration** > **Plugins** > **Install plugins**.
4.  Kéo thả file `oauth_gn4.zip` vào khung **ZIP package** và click chọn **Install plugin from the ZIP file**.
5.  Thực hiện theo các bước xác nhận trên màn hình của Moodle để hoàn tất việc cài đặt plugin (nếu hệ thống yêu cầu nâng cấp cơ sở dữ liệu, hãy click chọn **Upgrade Moodle database now**).

---

## 3. Tạo Client OAuth2 dành cho JupyterHub
Sau khi cài đặt thành công, tiến hành đăng ký JupyterHub với Moodle:

1.  Truy cập vào: **Site administration** > **Server** > **OAuth provider settings** > **Add new client**.
2.  Cấu hình các thông số sau:
    *   **Name/ID**: `JupyterHub`
    *   **Client ID**: `JupyterHub`
    *   **Redirect URI / Callback URL**: 
        `https://login3.gpucluster.sutd.edu.sg/hub/oauth_callback`
        *(Đây là địa chỉ HTTPS công khai của JupyterHub sau khi Apache2 reverse proxy)*
3.  Nhấp nút **Save changes** (Lưu thay đổi).
4.  Hệ thống sẽ hiển thị một chuỗi ký tự ngẫu nhiên đại diện cho **Client Secret** (hoặc `client_token`). 
5.  Hãy sao chép (copy) và lưu lại mã **Client Secret** này. Chúng ta sẽ điền nó vào cấu hình Helm của JupyterHub ở bước sau.

---

Sau khi đã lưu lại Client ID (`JupyterHub`) và Client Secret từ bước này, vui lòng chuyển tiếp sang [Bước 3: Triển khai JupyterHub trên Kubernetes](file:///c:/Users/20521/Desktop/admin/New_config/03_deploy_jupyterhub.md).
