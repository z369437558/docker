# Dockerfile

# 设置基础镜像
FROM nvidia/cuda:12.0.1-runtime-ubuntu20.04

# 设置工作目录
WORKDIR /app

# 复制当前目录内容到工作目录
COPY . /app/

# 复制服务账号密钥文件到容器中
COPY service-account.json /app/service-account.json

# 禁用交互式前端
ENV DEBIAN_FRONTEND=noninteractive

# 更新包列表并安装 Python 和 pip 以及必要的工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    build-essential \
    wget \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 安装 CUDA Toolkit
RUN apt-get update && apt-get install -y --no-install-recommends \
    cuda-toolkit-12-0 \
    && rm -rf /var/lib/apt/lists/*

# 安装 cuDNN
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcudnn8=8.9.1.*-1+cuda12.0 \
    libcudnn8-dev=8.9.1.*-1+cuda12.0 \
    && rm -rf /var/lib/apt/lists/*

# 设置环境变量
ENV PATH /usr/local/cuda-12.0/bin${PATH:+:${PATH}}
ENV LD_LIBRARY_PATH /usr/local/cuda-12.0/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# 验证 CUDA 和 cuDNN 安装
RUN nvcc --version && \
    python3 -c "import ctypes; ctypes.CDLL('libcudnn.so'); print('cuDNN installed successfully')"

# 安装 Python 依赖
RUN pip3 install -r requirements.txt

# 设置 Google Cloud 应用默认凭据
ENV GOOGLE_APPLICATION_CREDENTIALS="/app/service-account.json"

# 暴露端口 8000
EXPOSE 8000

# 启动 Gunicorn 服务器
CMD ["gunicorn", "app:app", "-c", "gunicorn.conf.py"]
