FROM nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update
RUN apt-get install -y curl wget git vim nano sudo build-essential cmake pkg-config zip  unzip tar ca-certificates gnupg lsb-release htop supervisor gzip lsof

RUN mkdir -p /var/log/supervisor

# 安装 Clash
RUN mkdir -p /opt/clash && \
    cd /opt/clash && \
    wget https://github.com/MetaCubeX/mihomo/releases/download/v1.18.10/mihomo-linux-amd64-v1.18.10.gz && \
    gzip -d mihomo-linux-amd64-v1.18.10.gz && \
    mv mihomo-linux-amd64-v1.18.10 clash && \
    chmod +x clash && \
    mkdir -p /root/.config/clash

RUN apt-get install -y python3 python3-pip
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN /root/.local/bin/uv python install 3.12

# Python 环境变量
ENV PATH="/root/.local/bin:${PATH}"
ENV PYTHON_VERSION=3.12

RUN  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
RUN apt-get install -y nodejs
RUN npm install -g yarn pnpm n

# Node.js 环境变量
ENV NODE_ENV=development
ENV NPM_CONFIG_PREFIX=/root/.npm-global
ENV PATH="${NPM_CONFIG_PREFIX}/bin:${PATH}"

RUN apt-get install -y golang-go

# Go 环境变量
ENV GOPATH=/root/go
ENV GOROOT=/usr/lib/go
ENV PATH="${GOPATH}/bin:${GOROOT}/bin:${PATH}"
ENV GO111MODULE=on
ENV GOPROXY=https://goproxy.cn,direct

# Clash 代理环境变量 (可通过 docker-compose 覆盖)
ENV HTTP_PROXY=""
ENV HTTPS_PROXY=""
ENV ALL_PROXY=""
ENV NO_PROXY="localhost,127.0.0.1"

RUN apt-get install -y openjdk-21-jdk maven gradle

RUN apt-get install -y  cargo rustc

# Rust 环境变量
ENV RUSTUP_HOME=/root/.rustup
ENV CARGO_HOME=/root/.cargo
ENV PATH="${CARGO_HOME}/bin:${PATH}"

WORKDIR /root/workspace

RUN curl -fsSL https://code-server.dev/install.sh | sh
RUN mkdir -p ~/.config/code-server && \
    echo "bind-addr: 0.0.0.0:8080" > ~/.config/code-server/config.yaml && \
    echo "cert: false" >> ~/.config/code-server/config.yaml

# 允许在不安全的上下文中使用 Web 功能
ENV VSCODE_PROXY_URI=""

# 安装 code-server 必备插件
RUN code-server --install-extension ms-python.python
RUN code-server --install-extension ms-python.autopep8
RUN code-server --install-extension ms-ceintl.vscode-language-pack-zh-hans
RUN code-server --install-extension kamikillerto.vscode-colorize
RUN code-server --install-extension batisteo.vscode-django
RUN code-server --install-extension hediet.vscode-drawio
RUN code-server --install-extension dbaeumer.vscode-eslint
RUN code-server --install-extension pomdtr.excalidraw-editor
RUN code-server --install-extension vscjava.vscode-java-pack
RUN code-server --install-extension seyyedkhandon.firacode
RUN code-server --install-extension mhutchie.git-graph
RUN code-server --install-extension github.copilot
RUN code-server --install-extension github.github-vscode-theme
RUN code-server --install-extension golang.go
RUN code-server --install-extension donjayamanne.python-extension-pack
# 添加启动脚本
ADD start-code-server.sh /usr/local/bin/start-code-server.sh
RUN chmod +x /usr/local/bin/start-code-server.sh

# 添加 supervisor 配置
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 配置 volumes 用于持久化数据
VOLUME ["/root/workspace"]                  # 工作空间
VOLUME ["/root/.config/code-server"]        # code-server 配置
VOLUME ["/root/.config/clash"]              # Clash 配置
VOLUME ["/root/.ssh"]                       # SSH 密钥
VOLUME ["/root/.local/share/code-server"]   # code-server 扩展和数据
VOLUME ["/root/.cache"]                     # pip、go、rust 等工具的缓存
VOLUME ["/root/.npm"]                       # npm 缓存
VOLUME ["/root/.pnpm-store"]                # pnpm 缓存
VOLUME ["/root/.yarn"]                      # yarn 缓存
VOLUME ["/root/.m2"]                        # Maven 仓库缓存
VOLUME ["/root/.gradle"]                    # Gradle 缓存
VOLUME ["/root/.cargo"]                     # Cargo 缓存
VOLUME ["/root/go/pkg"]                     # Go 包缓存

EXPOSE 8080 7890 7891 9090

ENTRYPOINT ["/usr/local/bin/start-code-server.sh"]