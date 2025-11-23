#!/bin/bash

# 设置默认端口
PORT=${PORT:-8080}

# 生成 code-server 配置文件
cat > ~/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:${PORT}
cert: false
EOF

# 配置 code-server 认证
if [ -z "$PASSWORD" ]; then
  echo "auth: none" >> ~/.config/code-server/config.yaml
  echo "Starting code-server on port ${PORT} without password..."
else
  echo "auth: password" >> ~/.config/code-server/config.yaml
  echo "password: $PASSWORD" >> ~/.config/code-server/config.yaml
  echo "Starting code-server on port ${PORT} with password..."
fi

# 启动 supervisord
exec supervisord -n
