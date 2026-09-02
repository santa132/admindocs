FROM nvcr.io/nvidia/isaac-sim:5.1.0

LABEL maintainer="AI Platform"
LABEL description="Isaac Sim 5.1 + Jupyter Stack + PyTorch + Sionna - Cluster Optimized with Legacy Startup Hooks"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG NB_USER=jovyan
ARG NB_UID=1000
ARG NB_GID=100

ENV DEBIAN_FRONTEND=noninteractive

# =============================================================================
# 1. OS PACKAGES & LEGACY DEPENDENCIES
# =============================================================================
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash curl wget git ca-certificates sudo tini locales \
    gcc g++ build-essential cmake ninja-build \
    libgl1 libglib2.0-0t64 libxext6 libsm6 libxrender1 \
    fonts-liberation pandoc run-one \
    # VNC / Desktop
    dbus-x11 xorg xfce4 xfce4-panel xfce4-session \
    xfce4-settings xubuntu-icon-theme firefox htop \
    && apt-get remove -y xfce4-screensaver light-locker 2>/dev/null || true \
    && rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# =============================================================================
# 2. USER PROVISIONING & PERMISSIONS
# =============================================================================
RUN usermod -l ${NB_USER} ubuntu || true && \
    usermod -g ${NB_GID} ${NB_USER} || true && \
    usermod -d /home/${NB_USER} -m ${NB_USER} || true && \
    groupmod -n ${NB_USER} ubuntu || true && \
    # >>> [SỬA LỖI TẠI ĐÂY]: Ép shell mặc định của jovyan sang bash thay vì /bin/sh mặc định
    usermod -s /bin/bash ${NB_USER} && \
    usermod -u 21234 isaac-sim && \
    groupmod -g 21234 isaac-sim && \
    usermod -aG 21234 ${NB_USER} && \
    mkdir -p /home/${NB_USER} /workspace && \
    chown -R ${NB_UID}:${NB_GID} /home/${NB_USER} /isaac-sim /workspace

# >>> [SỬA LỖI TẠI ĐÂY]: Định nghĩa biến môi trường SHELL để JupyterLab gọi đúng bash
ENV SHELL=/bin/bash

# =============================================================================
# 3. NFS OPTIMIZATION (OMNIVERSE TO /tmp) & X11 STORAGE
# =============================================================================
RUN mkdir -p /tmp/nvidia/cache /tmp/nvidia/data /tmp/nvidia/config /tmp/nvidia/source && \
    chown -R ${NB_UID}:${NB_GID} /tmp/nvidia

# >>> FIX 1: Tạo trước thư mục X11 socket và cấp quyền tối cao để giải quyết lỗi "Cannot create /tmp/.X11-unix"
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

ENV OMNI_USER_DATA_DIR=/tmp/nvidia/data
ENV OMNI_USER_CONFIG_DIR=/tmp/nvidia/config
ENV OMNI_CACHE_DIR=/tmp/nvidia/cache
ENV OMNI_USER_SOURCE_DIR=/tmp/nvidia/source

ENV XDG_CACHE_HOME=/tmp/nvidia/cache
ENV XDG_CONFIG_HOME=/tmp/nvidia/config
ENV XDG_DATA_HOME=/tmp/nvidia/data

# =============================================================================
# 4. PYTHON PACKAGES (NATIVE ISAAC-SIM) - KHÔNG CÀI ĐÈ PYTORCH
# =============================================================================
RUN /isaac-sim/python.sh -m pip install --upgrade pip setuptools wheel && \
    # Chỉ cài Sionna và các công cụ làm việc, để mặc định PyTorch/Torchvision của NVIDIA
    # >>> [SỬA LỖI TẠI ĐÂY]: Thêm gói 'terminado' để jupyter map shell ra web chuẩn chỉnh
    /isaac-sim/python.sh -m pip install \
    sionna \
    numpy scipy pandas matplotlib plotly tqdm ipykernel \
    jupyterlab notebook nbclassic jupyterhub terminado

# =============================================================================
# 5. TRANSPARENT PYTHON/JUPYTER WRAPPERS
# =============================================================================
# Đè lệnh python/python3 hệ thống
RUN echo -e '#!/bin/bash\nexec /isaac-sim/python.sh "$@"' > /usr/local/bin/python3 && \
    chmod +x /usr/local/bin/python3 && \
    ln -sf /usr/local/bin/python3 /usr/local/bin/python

# Đè lệnh jupyter 
RUN echo -e '#!/bin/bash\nexec /isaac-sim/python.sh -m jupyter "$@"' > /usr/local/bin/jupyter && \
    chmod +x /usr/local/bin/jupyter

# Đè lệnh jupyterhub-singleuser cho KubeSpawner
RUN echo -e '#!/bin/bash\nexec /isaac-sim/python.sh -m jupyterhub.singleuser "$@"' > /usr/local/bin/jupyterhub-singleuser && \
    chmod +x /usr/local/bin/jupyterhub-singleuser

# =============================================================================
# 6. LEGACY STARTUP SCRIPTS & HOOKS INTEGRATION
# =============================================================================
# Tạo lại cấu trúc các thư mục chứa Script Hooks cũ của Cluster
RUN mkdir -p /usr/local/bin/start-notebook.d /usr/local/bin/before-notebook.d /etc/jupyter

# Copy toàn bộ file cấu hình và script khởi động cũ của bạn vào lại Image
COPY run-hooks.sh start.sh /usr/local/bin/
COPY start-notebook.py start-notebook.sh start-singleuser.py start-singleuser.sh /usr/local/bin/
COPY jupyter_server_config.py docker_healthcheck.py /etc/jupyter/

# Chuyển đổi tệp cấu hình cho Notebook App giống file cũ
RUN sed -re "s/c.ServerApp/c.NotebookApp/g" /etc/jupyter/jupyter_server_config.py > /etc/jupyter/jupyter_notebook_config.py && \
    chmod +x /usr/local/bin/run-hooks.sh /usr/local/bin/start.sh /usr/local/bin/start-notebook.sh /usr/local/bin/start-singleuser.sh

# Đồng bộ phân quyền cho toàn bộ hệ thống thư mục đích
RUN ln -s /workspace/.nvidia-omniverse /tmp/nvidia/config/.nvidia-omniverse || true && \
    chown -R ${NB_UID}:${NB_GID} /isaac-sim /workspace /home/${NB_USER} /usr/local/bin /etc/jupyter

# =============================================================================
# 7. CONTAINER ORCHESTRATION CONFIG (ENTRYPOINT & CMD)
# =============================================================================
ENTRYPOINT ["tini", "-g", "--"]

ENV JUPYTER_PORT=8888
EXPOSE 8888

CMD ["start-notebook.sh"]

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD /etc/jupyter/docker_healthcheck.py || exit 1

USER ${NB_UID}
WORKDIR /workspace