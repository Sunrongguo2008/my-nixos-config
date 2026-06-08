#!/usr/bin/env python3
"""
Claude API 故障转移代理 - 美化增强版
带有现代化 Web UI 管理界面
"""

import asyncio
import json
import logging
import os
from pathlib import Path
from typing import List, Dict
from datetime import datetime
from aiohttp import web, ClientSession, ClientTimeout

# 配置
SCRIPT_DIR = Path(__file__).parent
CONFIG_FILE = SCRIPT_DIR / "channels_config.json"
PORT = 17428
REQUEST_TIMEOUT = 60

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def load_config():
    """加载配置文件"""
    if not CONFIG_FILE.exists():
        default_config = {
            "channels": [
                {
                    "name": "渠道1-慕远",
                    "base_url": "https://muyuan.do",
                    "api_key": "sk-qJnIQjZPqZSVXM4kdxxWgL7oLkWvobo8I1sQCCwg7VHVzT2k",
                    "enabled": True
                },
                {
                    "name": "渠道2-备用",
                    "base_url": "https://anyrouter.top",
                    "api_key": "sk-VqlC9BJGJ1gPerEfx6WETqZZ2KPS2pBvG24PU7Bl4LW6SlYC",
                    "enabled": True
                }
            ],
            "settings": {
                "port": PORT,
                "timeout_seconds": REQUEST_TIMEOUT,
                "log_level": "INFO"
            }
        }
        with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
            json.dump(default_config, f, indent=2, ensure_ascii=False)
        return default_config

    with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def save_config(config):
    """保存配置文件"""
    with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=2, ensure_ascii=False)


class APIProxy:
    def __init__(self):
        self.config = load_config()
        self.stats = {}
        self.init_stats()

    def init_stats(self):
        """初始化统计信息"""
        for channel in self.config['channels']:
            self.stats[channel['name']] = {
                "success": 0,
                "failure": 0,
                "last_used": None,
                "enabled": channel.get('enabled', True)
            }

    def reload_config(self):
        """重新加载配置"""
        self.config = load_config()
        self.init_stats()
        logger.info("配置已重新加载")

    def get_enabled_channels(self):
        """获取启用的渠道"""
        return [ch for ch in self.config['channels'] if ch.get('enabled', True)]

    async def proxy_request(self, request: web.Request) -> web.Response:
        """代理请求到多个 API 渠道"""
        path = request.path
        method = request.method

        try:
            body = await request.read()
            request_data = json.loads(body) if body else {}
        except Exception as e:
            logger.error(f"解析请求体失败: {e}")
            return web.json_response({"error": "Invalid request body"}, status=400)

        headers = dict(request.headers)
        headers.pop('Host', None)
        headers.pop('Content-Length', None)

        last_error = None
        timeout = ClientTimeout(total=REQUEST_TIMEOUT)
        enabled_channels = self.get_enabled_channels()

        if not enabled_channels:
            return web.json_response(
                {"error": "No enabled channels available"},
                status=503
            )

        async with ClientSession(timeout=timeout) as session:
            for channel in enabled_channels:
                channel_name = channel["name"]
                base_url = channel["base_url"].rstrip('/')
                api_key = channel["api_key"]
                full_url = f"{base_url}{path}"

                request_headers = headers.copy()
                request_headers['x-api-key'] = api_key
                request_headers['anthropic-version'] = request_headers.get('anthropic-version', '2023-06-01')

                try:
                    logger.info(f"尝试 {channel_name}: {method} {full_url}")

                    async with session.request(
                        method=method,
                        url=full_url,
                        headers=request_headers,
                        json=request_data if body else None
                    ) as resp:
                        response_body = await resp.read()

                        self.stats[channel_name]["success"] += 1
                        self.stats[channel_name]["last_used"] = datetime.now().isoformat()

                        logger.info(
                            f"✓ {channel_name} 成功 (状态: {resp.status}) "
                            f"[成功: {self.stats[channel_name]['success']}, "
                            f"失败: {self.stats[channel_name]['failure']}]"
                        )

                        return web.Response(
                            body=response_body,
                            status=resp.status,
                            headers=dict(resp.headers)
                        )

                except Exception as e:
                    self.stats[channel_name]["failure"] += 1
                    last_error = str(e)
                    logger.warning(
                        f"✗ {channel_name} 失败: {last_error} "
                        f"[成功: {self.stats[channel_name]['success']}, "
                        f"失败: {self.stats[channel_name]['failure']}]"
                    )
                    continue

        logger.error(f"所有 API 渠道都失败了。最后错误: {last_error}")
        return web.json_response(
            {
                "error": "All API channels failed",
                "last_error": last_error,
                "channels_tried": len(enabled_channels)
            },
            status=502
        )

    async def handle_stats(self, request: web.Request) -> web.Response:
        """API: 获取统计信息"""
        return web.json_response(self.stats)

    async def handle_config_get(self, request: web.Request) -> web.Response:
        """API: 获取配置"""
        return web.json_response(self.config)

    async def handle_config_update(self, request: web.Request) -> web.Response:
        """API: 更新配置"""
        try:
            new_config = await request.json()
            save_config(new_config)
            self.reload_config()
            return web.json_response({"status": "ok", "message": "配置已更新"})
        except Exception as e:
            logger.error(f"更新配置失败: {e}")
            return web.json_response({"status": "error", "message": str(e)}, status=400)

    async def handle_webui(self, request: web.Request) -> web.Response:
        """美化的 Web UI 管理界面"""
        html = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Claude API 故障转移代理 - 管理面板</title>
    <style>
        :root {
            --primary: #667eea;
            --primary-dark: #5568d3;
            --secondary: #764ba2;
            --success: #10b981;
            --danger: #ef4444;
            --warning: #f59e0b;
            --info: #3b82f6;
            --bg-primary: #0f172a;
            --bg-secondary: #1e293b;
            --bg-tertiary: #334155;
            --text-primary: #f1f5f9;
            --text-secondary: #cbd5e1;
            --border: #475569;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: var(--bg-primary);
            color: var(--text-primary);
            min-height: 100vh;
            line-height: 1.6;
        }

        .header {
            background: linear-gradient(135deg, var(--primary) 0%, var(--secondary) 100%);
            padding: 2rem;
            box-shadow: 0 4px 20px rgba(0,0,0,0.3);
        }

        .header-content {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .header h1 {
            font-size: 1.75rem;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 0.75rem;
        }

        .status-badge {
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
            padding: 0.5rem 1rem;
            background: rgba(255,255,255,0.2);
            border-radius: 2rem;
            font-size: 0.875rem;
            backdrop-filter: blur(10px);
        }

        .status-dot {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: var(--success);
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }

        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 2rem;
        }

        .tabs {
            display: flex;
            gap: 0.5rem;
            margin-bottom: 2rem;
            border-bottom: 2px solid var(--border);
        }

        .tab {
            padding: 1rem 1.5rem;
            background: none;
            border: none;
            color: var(--text-secondary);
            cursor: pointer;
            font-size: 1rem;
            font-weight: 500;
            transition: all 0.3s;
            border-bottom: 3px solid transparent;
        }

        .tab:hover { color: var(--text-primary); }
        
        .tab.active {
            color: var(--primary);
            border-bottom-color: var(--primary);
        }

        .tab-content { display: none; }
        .tab-content.active { display: block; }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 1.5rem;
            margin-bottom: 2rem;
        }

        .stat-card {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 1rem;
            padding: 1.5rem;
            transition: all 0.3s;
            position: relative;
            overflow: hidden;
        }

        .stat-card::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 4px;
            background: linear-gradient(90deg, var(--primary), var(--secondary));
        }

        .stat-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 24px rgba(0,0,0,0.3);
        }

        .stat-card-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1rem;
        }

        .stat-card h3 {
            font-size: 1.125rem;
            font-weight: 600;
            color: var(--text-primary);
        }

        .stat-status {
            padding: 0.25rem 0.75rem;
            border-radius: 1rem;
            font-size: 0.75rem;
            font-weight: 600;
        }

        .stat-status.enabled {
            background: rgba(16,185,129,0.2);
            color: var(--success);
        }

        .stat-status.disabled {
            background: rgba(239,68,68,0.2);
            color: var(--danger);
        }

        .stat-numbers {
            display: flex;
            gap: 2rem;
            margin: 1rem 0;
        }

        .stat-number {
            display: flex;
            flex-direction: column;
        }

        .stat-number .label {
            font-size: 0.75rem;
            color: var(--text-secondary);
            text-transform: uppercase;
            letter-spacing: 0.05em;
        }

        .stat-number .value {
            font-size: 2rem;
            font-weight: 700;
            margin-top: 0.25rem;
        }

        .stat-number.success .value { color: var(--success); }
        .stat-number.danger .value { color: var(--danger); }

        .stat-footer {
            font-size: 0.875rem;
            color: var(--text-secondary);
            margin-top: 1rem;
            padding-top: 1rem;
            border-top: 1px solid var(--border);
        }

        .channel {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 1rem;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
        }

        .channel-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1.5rem;
        }

        .channel-header h3 {
            font-size: 1.25rem;
            color: var(--primary);
        }

        .channel-actions {
            display: flex;
            align-items: center;
            gap: 1rem;
        }

        label {
            display: block;
            font-size: 0.875rem;
            font-weight: 600;
            color: var(--text-secondary);
            margin-top: 1rem;
            margin-bottom: 0.5rem;
        }

        input[type="text"],
        input[type="password"] {
            width: 100%;
            padding: 0.75rem;
            background: var(--bg-tertiary);
            border: 1px solid var(--border);
            border-radius: 0.5rem;
            color: var(--text-primary);
            font-size: 1rem;
            transition: all 0.3s;
        }

        input:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(102,126,234,0.1);
        }

        .switch {
            position: relative;
            display: inline-block;
            width: 52px;
            height: 28px;
        }

        .switch input { opacity: 0; width: 0; height: 0; }

        .slider {
            position: absolute;
            cursor: pointer;
            top: 0; left: 0; right: 0; bottom: 0;
            background-color: var(--border);
            transition: .3s;
            border-radius: 28px;
        }

        .slider:before {
            position: absolute;
            content: "";
            height: 20px; width: 20px;
            left: 4px; bottom: 4px;
            background-color: white;
            transition: .3s;
            border-radius: 50%;
        }

        input:checked + .slider { background-color: var(--primary); }
        input:checked + .slider:before { transform: translateX(24px); }

        .btn {
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 0.5rem;
            cursor: pointer;
            font-size: 0.875rem;
            font-weight: 600;
            transition: all 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 0.5rem;
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--primary), var(--secondary));
            color: white;
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 16px rgba(102,126,234,0.3);
        }

        .btn-danger {
            background: var(--danger);
            color: white;
        }

        .btn-danger:hover {
            background: #dc2626;
        }

        .btn-success {
            background: var(--success);
            color: white;
        }

        .btn-success:hover {
            background: #059669;
        }

        .button-group {
            display: flex;
            gap: 1rem;
            margin-top: 2rem;
        }

        .message {
            padding: 1rem 1.5rem;
            border-radius: 0.5rem;
            margin-bottom: 1.5rem;
            display: none;
            animation: slideIn 0.3s;
        }

        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(-10px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .message.success {
            background: rgba(16,185,129,0.1);
            border: 1px solid var(--success);
            color: var(--success);
        }

        .message.error {
            background: rgba(239,68,68,0.1);
            border: 1px solid var(--danger);
            color: var(--danger);
        }

        .message.show { display: block; }

        .info-box {
            background: var(--bg-secondary);
            border: 1px solid var(--border);
            border-radius: 1rem;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
        }

        .info-box h3 {
            color: var(--primary);
            margin-bottom: 1rem;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .info-box pre {
            background: var(--bg-tertiary);
            padding: 1rem;
            border-radius: 0.5rem;
            overflow-x: auto;
            margin: 1rem 0;
        }

        .info-box code {
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 0.875rem;
            color: var(--text-primary);
        }

        .info-box ul {
            list-style: none;
            padding-left: 0;
        }

        .info-box li {
            padding: 0.5rem 0;
            display: flex;
            align-items: center;
            gap: 0.5rem;
        }

        .info-box li:before {
            content: '→';
            color: var(--primary);
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="header">
        <div class="header-content">
            <h1>
                🚀 Claude API 故障转移代理
            </h1>
            <div class="status-badge">
                <span class="status-dot"></span>
                <span>运行中 | 端口 17428</span>
            </div>
        </div>
    </div>

    <div class="container">
        <div id="message" class="message"></div>

        <div class="tabs">
            <button class="tab active" onclick="switchTab('stats')">📊 统计信息</button>
            <button class="tab" onclick="switchTab('config')">⚙️ 渠道配置</button>
            <button class="tab" onclick="switchTab('docs')">📋 使用说明</button>
        </div>

        <!-- 统计信息 -->
        <div id="stats-content" class="tab-content active">
            <div id="stats-grid" class="stats-grid"></div>
            <button class="btn btn-primary" onclick="loadStats()">🔄 刷新统计</button>
        </div>

        <!-- 渠道配置 -->
        <div id="config-content" class="tab-content">
            <div id="channels-container"></div>
            <div class="button-group">
                <button class="btn btn-primary" onclick="addChannel()">➕ 添加渠道</button>
                <button class="btn btn-success" onclick="saveConfig()">💾 保存配置</button>
                <button class="btn btn-primary" onclick="loadConfig()">🔄 重新加载</button>
            </div>
        </div>

        <!-- 使用说明 -->
        <div id="docs-content" class="tab-content">
            <div class="info-box">
                <h3>🔧 配置 Claude Code</h3>
                <p>在 Claude Code 配置中设置：</p>
                <pre><code>ANTHROPIC_BASE_URL=http://localhost:17428
ANTHROPIC_AUTH_TOKEN=proxy-managed</code></pre>
            </div>

            <div class="info-box">
                <h3>📊 API 端点</h3>
                <ul>
                    <li><code>GET /_stats</code> - 获取统计信息</li>
                    <li><code>GET /_config</code> - 获取配置</li>
                    <li><code>POST /_config</code> - 更新配置</li>
                    <li><code>POST /v1/*</code> - Claude API 代理</li>
                </ul>
            </div>

            <div class="info-box">
                <h3>🎯 工作原理</h3>
                <p>当一个 API 渠道失败时，代理会自动尝试下一个启用的渠道，直到成功或所有渠道都失败。渠道按列表顺序依次尝试。</p>
            </div>
        </div>
    </div>

    <script>
        let config = null;

        function switchTab(tabName) {
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(t => t.classList.remove('active'));
            event.target.classList.add('active');
            document.getElementById(tabName + '-content').classList.add('active');

            if (tabName === 'stats') loadStats();
            if (tabName === 'config') loadConfig();
        }

        function showMessage(text, type = 'success') {
            const msg = document.getElementById('message');
            msg.textContent = text;
            msg.className = `message ${type} show`;
            setTimeout(() => msg.classList.remove('show'), 3000);
        }

        async function loadStats() {
            try {
                const response = await fetch('/_stats');
                const stats = await response.json();
                const container = document.getElementById('stats-grid');
                container.innerHTML = '';

                for (const [name, data] of Object.entries(stats)) {
                    const card = document.createElement('div');
                    card.className = 'stat-card';
                    const statusText = data.enabled === false ? 'disabled' : 'enabled';
                    const statusLabel = data.enabled === false ? '已禁用' : '运行中';
                    const lastUsed = data.last_used ? new Date(data.last_used).toLocaleString('zh-CN') : '未使用';
                    
                    card.innerHTML = `
                        <div class="stat-card-header">
                            <h3>${name}</h3>
                            <span class="stat-status ${statusText}">${statusLabel}</span>
                        </div>
                        <div class="stat-numbers">
                            <div class="stat-number success">
                                <span class="label">成功</span>
                                <span class="value">${data.success}</span>
                            </div>
                            <div class="stat-number danger">
                                <span class="label">失败</span>
                                <span class="value">${data.failure}</span>
                            </div>
                        </div>
                        <div class="stat-footer">
                            最后使用: ${lastUsed}
                        </div>
                    `;
                    container.appendChild(card);
                }
            } catch (error) {
                showMessage('加载统计失败: ' + error.message, 'error');
            }
        }

        async function loadConfig() {
            try {
                const response = await fetch('/_config');
                config = await response.json();
                renderChannels();
                showMessage('配置已加载');
            } catch (error) {
                showMessage('加载配置失败: ' + error.message, 'error');
            }
        }

        function renderChannels() {
            const container = document.getElementById('channels-container');
            container.innerHTML = '';

            config.channels.forEach((channel, index) => {
                const div = document.createElement('div');
                div.className = 'channel';
                div.innerHTML = `
                    <div class="channel-header">
                        <h3>渠道 ${index + 1}</h3>
                        <div class="channel-actions">
                            <label style="margin: 0; display: flex; align-items: center; gap: 0.5rem;">
                                <span style="font-size: 0.875rem;">启用</span>
                                <label class="switch">
                                    <input type="checkbox" ${channel.enabled ? 'checked' : ''}
                                           onchange="config.channels[${index}].enabled = this.checked">
                                    <span class="slider"></span>
                                </label>
                            </label>
                            <button class="btn btn-danger" onclick="removeChannel(${index})">删除</button>
                        </div>
                    </div>
                    <label>名称</label>
                    <input type="text" value="${channel.name}"
                           onchange="config.channels[${index}].name = this.value">

                    <label>API 地址</label>
                    <input type="text" value="${channel.base_url}"
                           onchange="config.channels[${index}].base_url = this.value">

                    <label>API Key</label>
                    <input type="password" value="${channel.api_key}"
                           onchange="config.channels[${index}].api_key = this.value">
                `;
                container.appendChild(div);
            });
        }

        function addChannel() {
            config.channels.push({
                name: '新渠道',
                base_url: 'https://api.example.com',
                api_key: 'sk-your-key',
                enabled: true
            });
            renderChannels();
        }

        function removeChannel(index) {
            if (confirm('确定要删除这个渠道吗？')) {
                config.channels.splice(index, 1);
                renderChannels();
            }
        }

        async function saveConfig() {
            try {
                const response = await fetch('/_config', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(config)
                });
                const result = await response.json();
                showMessage('✅ 配置保存成功！代理将使用新配置');
                loadStats();
            } catch (error) {
                showMessage('保存配置失败: ' + error.message, 'error');
            }
        }

        loadStats();
        setInterval(loadStats, 30000);
    </script>
</body>
</html>"""
        return web.Response(text=html, content_type='text/html')


async def create_app() -> web.Application:
    """创建 web 应用"""
    app = web.Application()
    proxy = APIProxy()

    app.router.add_route('*', '/v1/{tail:.*}', proxy.proxy_request)
    app.router.add_get('/_stats', proxy.handle_stats)
    app.router.add_get('/_config', proxy.handle_config_get)
    app.router.add_post('/_config', proxy.handle_config_update)
    app.router.add_get('/_ui', proxy.handle_webui)
    app.router.add_get('/', proxy.handle_webui)

    return app


def main():
    """启动代理服务器"""
    logger.info("=" * 60)
    logger.info("Claude API 故障转移代理 - 美化增强版")
    logger.info("=" * 60)
    logger.info(f"监听端口: {PORT}")
    logger.info(f"Web UI: http://localhost:{PORT}")
    logger.info(f"配置文件: {CONFIG_FILE}")
    logger.info("=" * 60)

    web.run_app(create_app(), host='127.0.0.1', port=PORT, print=None)


if __name__ == '__main__':
    main()
