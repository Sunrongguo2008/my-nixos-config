#!/usr/bin/env bash
# Claude API 代理管理脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/.proxy.pid"
LOG_FILE="$HOME/.local/state/claude-api-proxy.log"

mkdir -p "$(dirname "$LOG_FILE")"

start() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "❌ 代理已在运行 (PID: $PID)"
            return 1
        fi
    fi

    echo "🚀 启动 Claude API 代理..."
    nohup nix-shell -p "python3.withPackages (ps: [ ps.aiohttp ])" \
        --run "cd $SCRIPT_DIR && python3 api_proxy_enhanced.py" \
        > "$LOG_FILE" 2>&1 &

    PID=$!
    echo $PID > "$PID_FILE"
    sleep 2

    if ps -p "$PID" > /dev/null 2>&1; then
        echo "✅ 代理已启动 (PID: $PID)"
        echo "🌐 Web UI: http://localhost:17428"
        echo "📋 日志: $LOG_FILE"
    else
        echo "❌ 启动失败，查看日志: $LOG_FILE"
        rm -f "$PID_FILE"
        return 1
    fi
}

stop() {
    if [ ! -f "$PID_FILE" ]; then
        echo "❌ 代理未运行"
        return 1
    fi

    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "🛑 停止代理 (PID: $PID)..."
        kill "$PID"
        rm -f "$PID_FILE"
        echo "✅ 代理已停止"
    else
        echo "⚠️  进程不存在，清理 PID 文件"
        rm -f "$PID_FILE"
    fi
}

status() {
    if [ ! -f "$PID_FILE" ]; then
        echo "❌ 代理未运行"
        return 1
    fi

    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "✅ 代理正在运行 (PID: $PID)"
        echo ""
        echo "🌐 Web UI: http://localhost:17428"
        echo ""
        echo "📊 渠道统计:"
        curl -s http://localhost:17428/_stats 2>/dev/null | python3 -m json.tool || echo "无法获取统计信息"
    else
        echo "❌ 代理未运行（但 PID 文件存在）"
        rm -f "$PID_FILE"
        return 1
    fi
}

logs() {
    if [ ! -f "$LOG_FILE" ]; then
        echo "❌ 日志文件不存在: $LOG_FILE"
        return 1
    fi
    tail -f "$LOG_FILE"
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 2
        start
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "命令:"
        echo "  start    - 启动代理（后台运行）"
        echo "  stop     - 停止代理"
        echo "  restart  - 重启代理"
        echo "  status   - 查看状态和统计"
        echo "  logs     - 查看实时日志"
        exit 1
        ;;
esac
