# 服务和用户配置模块
# 包含用户账户、音频、打印、虚拟化、网络服务等配置
{ config, lib, pkgs, ... }:

{
  # 用户账户配置
  users.users.s = {
    isNormalUser = true;        # 普通用户权限
    # 密码哈希（已加密）
    hashedPassword =
      "$y$j9T$eJOCdJZjbt/LvqqyuZQbr.$lcqOsbxDkM2DrC4CyH7yRYl7IexRfkBLuzVIkbbEbeB";
    extraGroups = [
      "wheel"      # 管理员权限组
      "docker"     # Docker 权限组
      "libvirtd"   # 虚拟化管理权限组
      "kvm"        # KVM 虚拟化权限组
      "video"      # 视频设备访问权限
      "greeter"    # 登录管理器权限组
    ];
    shell = pkgs.zsh;
    packages = with pkgs; [ tree ];  # 为用户安装的额外包
  };
  # 将用户 s 添加到 docker 组（另一种方式）
  users.extraGroups.docker.members = [ "s" ];

  # 音频服务（使用 PipeWire 替代 PulseAudio）
  services.pipewire = {
    enable = true;              # 启用 PipeWire
    pulse.enable = true;        # 启用 PulseAudio 兼容层
  };

  # 打印服务（CUPS）
  services.printing.enable = true;  # 启用打印服务
  services.printing.drivers = with pkgs; [
    hplip    # HP 打印机驱动
    # 为特定 HP 打印机安装 PPD 文件
    (pkgs.writeTextDir "share/cups/model/hp-laserjet_pro_mfp_m126a.ppd"
      (builtins.readFile ../data/hp-laserjet_pro_mfp_m126a.ppd))
  ];

  # 声明式打印机配置
  hardware.printers = {
    ensurePrinters = [{
      name = "HP_LaserJet_Pro_MFP_M126a";  # 打印机名称
      deviceUri = "usb://HP/LaserJet%20Pro%20MFP%20M126a?serial=CNBKM9S8XF&interface=1"; # USB 设备地址
      model = "hp-laserjet_pro_mfp_m126a.ppd";  # 使用的 PPD 文件
      ppdOptions = { PageSize = "A4"; };  # 默认页面大小
    }];
    ensureDefaultPrinter = "HP_LaserJet_Pro_MFP_M126a";  # 设置为默认打印机
  };

  # KDE Connect（设备连接工具）
  programs.kdeconnect.enable = true;

  # 虚拟化服务配置
  virtualisation.libvirtd = {
    enable = true;              # 启用 libvirt 服务
    qemu = {
      package = pkgs.qemu_kvm;  # 使用 QEMU-KVM 包
      swtpm.enable = true;      # 启用软件 TPM（用于 Windows 11）
      runAsRoot = false;        # 不以 root 权限运行
      verbatimConfig = ''       # QEMU 额外配置
        user = "s"
      '';
    };
  };
  programs.virt-manager.enable = true;  # 启用 Virtual Machine Manager GUI
  virtualisation.docker.enable = true;  # 启用 Docker
  virtualisation.docker.storageDriver = "btrfs";  # Docker 存储驱动
  virtualisation.vmware.host.enable = true;  # 启用 VMware 主机支持

  # SSH 服务配置
  services.openssh = {
    enable = true;              # 启用 SSH 服务
    settings = {
      PasswordAuthentication = true;  # 允许密码认证
      PermitRootLogin = "no";         # 禁止 root 直接登录
    };
  };

  # Steam 游戏平台配置
  programs.steam = {
    enable = true;              # 启用 Steam
    # 为 Steam 功能开放防火墙端口
    remotePlay.openFirewall = true;             # 远程播放
    dedicatedServer.openFirewall = true;        # 专用服务器
    localNetworkGameTransfers.openFirewall = true; # 局域网游戏传输
  };

  # Linyaps（Linux 应用商店）
  services.linyaps.enable = true;

  # Mihomo 服务
  services.mihomo = {
    enable = true;
    tunMode = true;  # 启用 TUN 模式权限（全局代理必需）

    # 使用 metacubexd 或 yacd 作为 Web 界面
    webui = pkgs.metacubexd;  # 现代界面，推荐
    # webui = pkgs.yacd;       # 经典界面，备选

    # 配置文件路径（见下文生成方式）
    configFile = "/etc/mihomo/config.yaml";
  };

  environment.etc."mihomo/config.yaml" = {
    source = ../conf/mihomo.yaml;
  };

  # 防火墙（已禁用 - 注意安全性）
  networking.firewall = {
    enable = false;

    # 信任 TUN 设备，允许流量通过
    trustedInterfaces = [ "Mihomo" ];

    # 禁用反向路径过滤（RPFilter），防止 TUN 流量被丢弃
    checkReversePath = false;

    # 如果使用的是 TProxy 模式而非 TUN，需要放行对应端口
    # allowedUDPPorts = [ 7894 ];  # 根据你的 tproxy-port 调整
  };

  # 确保内核支持 TUN
  boot.kernelModules = [ "tun" ];

  # GVFS（GNOME 虚拟文件系统）- 用于文件管理器访问特殊位置
  services.gvfs.enable = true;
}
