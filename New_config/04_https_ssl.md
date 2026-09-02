# Bước 4: Cài đặt HTTPS và Apache2 Reverse Proxy

Tài liệu này hướng dẫn bạn thiết lập **Apache2** làm reverse proxy trên server `aimc-hn3`, tạo **chứng chỉ SSL tự ký (Self-Signed Certificate)** cho tên miền `login3.gpucluster.sutd.edu.sg`, và kích hoạt giao thức HTTPS cho cả Moodle và JupyterHub.

## Kiến trúc tổng quan

```
Người dùng (Trình duyệt)
        |
        |  https://login3.gpucluster.sutd.edu.sg:8888/moodle
        |  https://login3.gpucluster.sutd.edu.sg/
        |
  +--------------------------+
  |  Apache2 (trên aimc-hn3) |   <-- Terminate SSL ở đây
  |  Port 443  (HTTPS)       |
  |  Port 8888 (HTTPS)       |
  +--------------------------+
        |                  |
        | :30000           | :30080
        |                  |
  +------------+    +-----------+
  | JupyterHub |    |  Moodle   |   <-- NodePort bên trong Kubernetes
  | (port 80)  |    | (port 80) |
  +------------+    +-----------+
```

---

## 1. Cài đặt Apache2

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install apache2 -y

# Kích hoạt các module cần thiết cho reverse proxy và SSL
sudo a2enmod ssl proxy proxy_http rewrite headers proxy_wstunnel
sudo systemctl enable apache2
sudo systemctl start apache2
```

---

## 2. Tạo chứng chỉ SSL tự ký (Self-Signed Certificate)

Vì đây là hệ thống nội bộ dùng trong trường học, chứng chỉ tự ký là đủ.

### 2.1 Tạo thư mục lưu trữ chứng chỉ
```bash
sudo mkdir -p /etc/ssl/aimc
cd /etc/ssl/aimc
```

### 2.2 Tạo file cấu hình SAN (Subject Alternative Names) cho domain

```bash
sudo tee /etc/ssl/aimc/local.ext > /dev/null <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = login3.gpucluster.sutd.edu.sg
IP.1 = 192.168.33.3
EOF
```

### 2.3 Tạo Certificate Authority (CA) riêng
```bash
# Tạo CA private key
sudo openssl genrsa -out /etc/ssl/aimc/CA.key -des3 2048
# (nhập passphrase khi được yêu cầu, ví dụ: SGPAIp@ssw0rd)

# Tạo CA certificate (hiệu lực 5 năm)
sudo openssl req -x509 -new -nodes -key /etc/ssl/aimc/CA.key \
  -sha256 -days 1825 \
  -out /etc/ssl/aimc/CA.pem \
  -subj "/C=SG/ST=Singapore/L=Singapore/O=SUTD/OU=AIMC/CN=AIMC-CA/emailAddress=aimc_support@sutd.edu.sg"
```

### 2.4 Tạo chứng chỉ cho server `login3.gpucluster.sutd.edu.sg`
```bash
# Tạo server private key
sudo openssl genrsa -out /etc/ssl/aimc/local.key 2048

# Tạo Certificate Signing Request (CSR)
sudo openssl req -new -key /etc/ssl/aimc/local.key \
  -out /etc/ssl/aimc/local.csr \
  -subj "/C=SG/ST=Singapore/L=Singapore/O=SUTD/OU=AIMC/CN=login3.gpucluster.sutd.edu.sg/emailAddress=aimc_support@sutd.edu.sg"

# Ký CSR bằng CA key (hiệu lực 10 năm)
sudo openssl x509 -req \
  -in /etc/ssl/aimc/local.csr \
  -CA /etc/ssl/aimc/CA.pem \
  -CAkey /etc/ssl/aimc/CA.key \
  -CAcreateserial \
  -days 3650 -sha256 \
  -extfile /etc/ssl/aimc/local.ext \
  -out /etc/ssl/aimc/local.crt

# Tạo bản key không có passphrase (để Apache2 không cần nhập mật khẩu khi khởi động)
sudo openssl rsa -in /etc/ssl/aimc/local.key -out /etc/ssl/aimc/local.decrypted.key
```

### 2.5 Đăng ký CA certificate vào hệ thống
Thao tác này giúp các máy client trong cùng mạng (sau khi import CA.pem) có thể tin tưởng chứng chỉ này mà không bị cảnh báo.
```bash
sudo cp /etc/ssl/aimc/CA.pem /usr/local/share/ca-certificates/AIMC-CA.crt
sudo update-ca-certificates
```

---

## 3. Cấu hình Apache2 làm Reverse Proxy

### 3.1 Tạo Virtual Host cho Moodle (Port 8888 - HTTPS)

```bash
sudo tee /etc/apache2/sites-available/moodle-ssl.conf > /dev/null <<'EOF'
Listen 8888

<VirtualHost *:8888>
    ServerName login3.gpucluster.sutd.edu.sg

    # SSL Configuration
    SSLEngine on
    SSLCertificateFile    /etc/ssl/aimc/local.crt
    SSLCertificateKeyFile /etc/ssl/aimc/local.decrypted.key

    # Reverse Proxy → Moodle NodePort 30080
    ProxyPreserveHost On
    RequestHeader set X-Forwarded-Proto "https"
    RequestHeader set X-Forwarded-Port "8888"

    ProxyPass        /moodle http://127.0.0.1:30080/moodle
    ProxyPassReverse /moodle http://127.0.0.1:30080/moodle

    # Redirect root to Moodle
    RedirectMatch ^/$ /moodle

    ErrorLog ${APACHE_LOG_DIR}/moodle_error.log
    CustomLog ${APACHE_LOG_DIR}/moodle_access.log combined
</VirtualHost>
EOF
```

### 3.2 Tạo Virtual Host cho JupyterHub (Port 443 - HTTPS)

```bash
sudo tee /etc/apache2/sites-available/jupyterhub-ssl.conf > /dev/null <<'EOF'
<VirtualHost *:443>
    ServerName login3.gpucluster.sutd.edu.sg

    # SSL Configuration
    SSLEngine on
    SSLCertificateFile    /etc/ssl/aimc/local.crt
    SSLCertificateKeyFile /etc/ssl/aimc/local.decrypted.key

    # Reverse Proxy → JupyterHub NodePort 30000
    ProxyPreserveHost On
    RequestHeader set X-Forwarded-Proto "https"

    # Handle WebSocket connections (cần thiết cho Jupyter terminals và notebooks)
    RewriteEngine on
    RewriteCond %{HTTP:UPGRADE} ^WebSocket$ [NC]
    RewriteCond %{HTTP:CONNECTION} Upgrade [NC]
    RewriteRule /(.*) ws://127.0.0.1:30000/$1 [P,L]

    ProxyPass        / http://127.0.0.1:30000/
    ProxyPassReverse / http://127.0.0.1:30000/

    ErrorLog ${APACHE_LOG_DIR}/jupyterhub_error.log
    CustomLog ${APACHE_LOG_DIR}/jupyterhub_access.log combined
</VirtualHost>
EOF
```

### 3.3 Kích hoạt các Virtual Host và khởi động lại Apache2

```bash
# Vô hiệu hóa site mặc định (nếu có)
sudo a2dissite 000-default.conf

# Kích hoạt hai site mới
sudo a2ensite moodle-ssl.conf
sudo a2ensite jupyterhub-ssl.conf

# Kiểm tra cấu hình Apache2 trước khi restart
sudo apache2ctl configtest

# Nếu output là "Syntax OK" thì restart Apache2
sudo systemctl restart apache2

# Kiểm tra trạng thái
sudo systemctl status apache2
```

---

## 4. Mở Firewall (nếu cần)

Nếu server đang bật UFW firewall, hãy mở các cổng cần thiết:
```bash
sudo ufw allow 443/tcp
sudo ufw allow 8888/tcp
sudo ufw reload
sudo ufw status
```

---

## 5. Kiểm tra kết nối

Mở trình duyệt và kiểm tra:

| Dịch vụ | URL |
|---|---|
| Moodle | `https://login3.gpucluster.sutd.edu.sg:8888/moodle` |
| JupyterHub | `https://login3.gpucluster.sutd.edu.sg` |

> [!NOTE]
> Lần đầu truy cập, trình duyệt sẽ hiện cảnh báo **"Your connection is not private"** do chứng chỉ là Self-Signed (không được ký bởi CA công khai). Nhấn **"Advanced" → "Proceed to login3.gpucluster.sutd.edu.sg"** để tiếp tục.
>
> Để loại bỏ cảnh báo này trên máy tính cá nhân, hãy import file `/etc/ssl/aimc/CA.pem` vào danh sách Trusted Root Certificates của trình duyệt / hệ điều hành.

---

## 6. Cập nhật lại JupyterHub sau khi HTTPS hoạt động

Sau khi xác nhận HTTPS hoạt động tốt, nếu cần cập nhật bất kỳ cấu hình nào trong `jupyterhub-values-new.yaml`, chạy lại lệnh:

```bash
helm upgrade --cleanup-on-fail \
  --install hub jupyterhub/jupyterhub \
  --namespace hub \
  --create-namespace \
  --values jupyterhub-values-new.yaml \
  --version 2.0.0
```
