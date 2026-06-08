{ config, pkgs, ... }:

{
  # Claude API 故障转移代理服务
  systemd.user.services.claude-api-proxy = {
    description = "Claude API Failover Proxy with Web UI";
    after = [ "network.target" ];
    wantedBy = [ "default.target" ];

    serviceConfig = {
      Type = "simple";
      WorkingDirectory = "%h/nixos/conf/claude";
      ExecStart = "${pkgs.python3.withPackages(ps: [ ps.aiohttp ])}/bin/python3 %h/nixos/conf/claude/api_proxy_enhanced.py";
      Restart = "always";
      RestartSec = "10s";

      Environment = [
        "PYTHONUNBUFFERED=1"
      ];
    };
  };
}
