#!/usr/bin/env nix-shell
#! nix-shell -i bash -p "python3.withPackages (ps: [ ps.aiohttp ])"

# Claude API 故障转移代理启动脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "================================================"
echo "  Claude API 故障转移代理"
echo "================================================"
echo ""
echo "🚀 启动中..."
echo "📂 工作目录: $SCRIPT_DIR"
echo "🌐 Web UI: http://localhost:17428"
echo "📊 统计 API: http://localhost:17428/_stats"
echo ""
echo "按 Ctrl+C 停止服务"
echo "================================================"
echo ""

python3 api_proxy_enhanced.py
