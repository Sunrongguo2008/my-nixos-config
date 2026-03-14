# 编辑此配置文件以定义应安装在您系统上的内容。帮助信息可在 configuration.nix(5) 手册页、https://search.nixos.org/options 以及 NixOS 手册 (`nixos-help`) 中找到。
{ config, lib, pkgs, inputs, pkgs-stable, ... }:
# <- 这个函数签名是必需的

{
  imports = [
    # 基础系统配置
    ./mod/s-base.nix

    # 硬件配置（由 nixos-generate-config 生成）
    ./mod/s-hardware.nix
    
    # 系统界面配置
    ./mod/s-desktop.nix
    
    # 服务和用户配置
    ./mod/s-service.nix

    # 程序和包配置
    ./mod/s-packages.nix
  ];

  # 请注意：所有配置项已分离到各自的模块文件中
  # 主配置文件仅负责导入模块
  
  # 允许非自由软件
  nixpkgs.config.allowUnfree = true;
  
  # 启用 Flatpak
  services.flatpak.enable = true;
}
# <- 这里结束整个模块的属性集
