# Claude API 故障转移代理 - NixOS 集成版

## 📦 文件说明

```
~/nixos/
├── configuration.nix              # 主配置（已添加代理导入）
├── mod/
│   └── s-claude-proxy.nix        # 代理服务定义
└── conf/claude/
    ├── api_proxy_enhanced.py     # 增强代理（美化版）
    ├── channels_config.json      # 渠道配置（自动生成）
    ├── claude-settings.json      # Claude Code 配置
    ├── deploy.sh                 # 快速部署脚本
    ├── DEPLOYMENT_GUIDE.md       # 详细部署指南
    └── README.md                 # 本文件
```

## 🚀 快速开始

### 1. 部署到系统

```bash
cd ~/nixos/conf/claude
./deploy.sh
```

或手动：

```bash
sudo nixos-rebuild switch
```

### 2. 启动服务

```bash
systemctl --user start claude-api-proxy
```

### 3. 访问 Web UI

打开浏览器: **http://localhost:17428**

### 4. 配置渠道

在 Web UI 中：
- 点击 "⚙️ 渠道配置"
- 添加/编辑你的 API 渠道
- 点击 "💾 保存配置"

## 💻 常用命令

```bash
# 启动服务
systemctl --user start claude-api-proxy

# 停止服务
systemctl --user stop claude-api-proxy

# 重启服务
systemctl --user restart claude-api-proxy

# 查看状态
systemctl --user status claude-api-proxy

# 开机自启
systemctl --user enable claude-api-proxy

# 查看日志
journalctl --user -u claude-api-proxy -f
```

## 🎨 Web UI 特性

- 🌙 现代深色主题设计
- 📊 实时统计信息
- ⚙️ 在线配置管理
- 🔄 自动刷新（30秒）
- 💾 配置即时生效

## 📖 详细文档

查看 `DEPLOYMENT_GUIDE.md` 了解：
- 详细部署步骤
- 故障排除
- 配置说明
- 服务管理

## 🔗 相关链接

- Web UI: http://localhost:17428
- 端口: 17428
- 配置文件: ~/nixos/conf/claude/channels_config.json
