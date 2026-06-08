# Claude API 故障转移代理 - NixOS 部署完成

## ✅ 已完成的工作

### 1. NixOS 服务配置
- ✅ 创建了服务模块: `~/nixos/mod/s-claude-proxy.nix`
- ✅ 已添加到主配置: `~/nixos/configuration.nix`
- ✅ 美化的代理程序: `~/nixos/conf/claude/api_proxy_enhanced.py`

### 2. 配置文件位置
```
~/nixos/
├── configuration.nix           # 已添加导入
├── mod/
│   └── s-claude-proxy.nix     # 服务定义
└── conf/
    └── claude/
        ├── api_proxy_enhanced.py      # 增强代理（美化版）
        ├── channels_config.json       # 渠道配置（自动生成）
        └── claude-settings.json       # Claude Code配置（暂未修改）
```

### 3. Web UI 美化
- ✅ 现代化深色主题设计
- ✅ 响应式布局
- ✅ 实时统计卡片
- ✅ 在线配置管理
- ✅ 自动刷新（30秒）

## 🚀 接下来的步骤

### 步骤 1: 提交配置到 Git（如果需要）

```bash
cd ~/nixos
git add mod/s-claude-proxy.nix
git add configuration.nix
git add conf/claude/api_proxy_enhanced.py
git commit -m "添加 Claude API 故障转移代理服务"
```

### 步骤 2: 重建 NixOS 配置

```bash
sudo nixos-rebuild switch
```

这会：
- 安装必要的 Python 包（aiohttp）
- 创建 systemd 用户服务
- 但**不会自动启动**（需要手动启动）

### 步骤 3: 启动服务

```bash
# 启动服务
systemctl --user start claude-api-proxy

# 查看状态
systemctl --user status claude-api-proxy

# 启用开机自启（可选）
systemctl --user enable claude-api-proxy

# 查看日志
journalctl --user -u claude-api-proxy -f
```

### 步骤 4: 访问 Web UI

打开浏览器访问: **http://localhost:17428**

在 Web UI 中：
1. 点击 "⚙️ 渠道配置" 标签
2. 编辑现有渠道或添加新渠道
3. 点击 "💾 保存配置"

### 步骤 5: 配置 Claude Code（稍后）

现在先不改 Claude Code 配置，等代理测试稳定后再修改。

## 🔧 服务管理命令

```bash
# 启动
systemctl --user start claude-api-proxy

# 停止
systemctl --user stop claude-api-proxy

# 重启
systemctl --user restart claude-api-proxy

# 查看状态
systemctl --user status claude-api-proxy

# 开机自启
systemctl --user enable claude-api-proxy

# 取消自启
systemctl --user disable claude-api-proxy

# 实时日志
journalctl --user -u claude-api-proxy -f

# 查看最近日志
journalctl --user -u claude-api-proxy -n 50
```

## 📊 监控和调试

### 查看统计信息
```bash
curl -s http://localhost:17428/_stats | python3 -m json.tool
```

### 查看配置
```bash
curl -s http://localhost:17428/_config | python3 -m json.tool
```

### 检查服务是否运行
```bash
systemctl --user is-active claude-api-proxy
```

### 检查端口占用
```bash
ss -tlnp | grep :17428
```

## 🎨 Web UI 特性

### 美化设计
- 🌙 现代深色主题
- 📱 响应式设计
- ✨ 流畅动画效果
- 🎯 直观的用户界面

### 功能
- 📊 **统计信息** - 实时查看渠道成功/失败次数
- ⚙️ **渠道配置** - 在线添加/编辑/删除渠道
- 🎛️ **启用/禁用** - 快速切换渠道状态
- 💾 **实时保存** - 修改立即生效
- 🔄 **自动刷新** - 统计每30秒自动更新

## 🐛 故障排除

### 服务启动失败

1. 查看详细日志：
```bash
journalctl --user -u claude-api-proxy -n 100 --no-pager
```

2. 检查 Python 环境：
```bash
which python3
python3 -c "import aiohttp; print('aiohttp OK')"
```

3. 手动测试运行：
```bash
cd ~/nixos/conf/claude
python3 api_proxy_enhanced.py
```

### 端口被占用

```bash
# 查找占用进程
ss -tlnp | grep :17428

# 或
lsof -i :17428

# 停止旧进程
pkill -f api_proxy
```

### 配置文件权限

```bash
# 确保文件可读
chmod 644 ~/nixos/conf/claude/channels_config.json

# 确保脚本可执行
chmod +x ~/nixos/conf/claude/api_proxy_enhanced.py
```

## 📝 注意事项

1. **配置文件位置**: 
   - 渠道配置会自动生成在 `~/nixos/conf/claude/channels_config.json`
   - 首次运行会创建默认配置

2. **日志位置**: 
   - systemd journal（使用 journalctl 查看）
   - 不会生成单独的日志文件

3. **自动重启**: 
   - 服务配置了自动重启（10秒延迟）
   - 崩溃后会自动恢复

4. **开机自启**: 
   - 需要手动启用: `systemctl --user enable claude-api-proxy`
   - 默认不自启

## 🎉 下一步

1. **现在**: 运行 `sudo nixos-rebuild switch` 部署配置
2. **然后**: 启动服务并访问 Web UI
3. **测试**: 在 Web UI 中配置你的 API 渠道
4. **稳定后**: 修改 Claude Code 配置指向代理

---

**端口**: 17428  
**Web UI**: http://localhost:17428  
**配置**: ~/nixos/conf/claude/channels_config.json
