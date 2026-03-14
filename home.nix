# Home Manager 配置文件
# 该文件整合了各个模块化的配置
{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    # 核心配置（用户信息、Shell、服务、配置文件链接）
    ./mod/h-core.nix

    # 图形界面和应用程序配置
    ./mod/h-interface.nix

    # 包配置（用户安装的软件包）
    ./mod/h-packages.nix
  ];

  # 请注意：所有配置项已分离到各自的模块文件中
  # 主配置文件仅负责导入模块
}
