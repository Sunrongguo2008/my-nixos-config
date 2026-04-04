# 基础系统配置模块
# 包含系统启动、内核、网络、时区等基本配置
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  # 启用 Nix Flakes 功能
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # 使用 CachyOS 内核（性能优化版）
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;
  #boot.kernelPackages = pkgs.linuxPackages_latest;

  # GRUB 引导加载器配置
  boot.loader.grub = {
    enable = true; # 启用 GRUB
    device = "nodev"; # 安装到 ESP 分区
    efiSupport = true; # 启用 EFI 支持
    useOSProber = true; # 检测其他操作系统
    gfxmodeEfi = "1920x1020"; # 设置引导界面分辨率
    theme = inputs.nixos-grub-themes.packages.${pkgs.stdenv.hostPlatform.system}.nixos; # 使用自定义主题
  };
  boot.loader.grub.configurationLimit = 10; # 保留最近 10 个引导配置
  boot.loader.efi.canTouchEfiVariables = true; # 允许修改 EFI 变量
/*boot.kernelParams=[
# Force early console output to both VGA :
"earlyprintk=vga,keep"
"earlyprintk=ttyS0,115200,keep"
"earlycon"
"keep_bootcon"
# Print absolutely everything
"debug"
"ignore_loglevel"
#Disable quiet boot if you have it enabl # Ensure "quiet" is NOT in your kernelPara
];
*/
  # Nix 垃圾回收配置
  nix.gc = {
    automatic = true; # 自动运行垃圾回收
    dates = "weekly"; # 每周运行一次
    options = "--delete-older-than 7d"; # 删除 7 天前的包
  };
  services.fstrim = {
    enable = true;
    interval = "monthly";
  };
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };
  # 自动优化 Nix 存储（去重）
  nix.settings.auto-optimise-store = true;
  nix.optimise.automatic = true;

  # 网络配置
  networking.hostName = "my-nixos"; # 设置主机名
  networking.networkmanager.enable = true; # 启用 NetworkManager

  # 本地化设置
  time.timeZone = "Asia/Shanghai"; # 设置时区
  i18n.defaultLocale = "zh_CN.UTF-8"; # 设置默认语言环境

  # 系统状态版本（用于兼容性）
  system.stateVersion = "25.05";

  # Nix 二进制缓存配置（国内镜像加速）
  nix.settings.substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store?priority=10" # 清华大学镜像
    "https://mirrors.ustc.edu.cn/nix-channels/store?priority=5" # 中科大镜像
    "https://cache.nixos.org/" # 官方源
    "https://attic.xuyh0120.win/lantian" # CachyOS 内核缓存
    "https://noctalia.cachix.org" # Noctalia 包缓存
  ];
  nix.settings.trusted-public-keys = [
    "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" # CachyOS 内核公钥
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" # Noctalia 包公钥
  ];
}
