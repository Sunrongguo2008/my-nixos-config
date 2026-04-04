# 程序和系统包配置模块
# 包含 Shell、系统工具、应用程序等配置
{
  config,
  lib,
  pkgs,
  inputs,
  stdenv,
  ...
}:

let
  # 仅对 quickshell 启用激进优化：clang + O3 + native + ThinLTO
  quickshellBase = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;

  # 共享的高性能编译 Stdenv（clang + LLD + O3 + ThinLTO）
  fastOptimizedStdenv =
    let
      clangWithLlvmBintools = pkgs.clangStdenv.override (old: {
        cc = old.cc.override {
          bintools = pkgs.llvmPackages.bintools;
        };
      });
      nativeTuned = pkgs.stdenvAdapters.impureUseNativeOptimizations clangWithLlvmBintools;
      thinLtoTuned = pkgs.stdenvAdapters.withCFlags [
        "-O3"
        "-pipe"
        "-flto=thin"
        "-march=native"
      ] nativeTuned;
    in
    pkgs.stdenvAdapters.addAttrsToDerivation {
      cmakeBuildType = "Release";
      NIX_CFLAGS_LINK = "-flto=thin -fuse-ld=lld";
    } thinLtoTuned;

  quickshellOptimized = quickshellBase.override {
    stdenv = fastOptimizedStdenv;
  };

  # Mango WM：在构建时尽可能优化运行速度
  mangoBase = inputs.mangowm.packages.${pkgs.stdenv.hostPlatform.system}.mango;
  mangoOptimized = (mangoBase.override { stdenv = fastOptimizedStdenv; }).overrideAttrs (old: {
    mesonFlags = (old.mesonFlags or [ ]) ++ [
      "-Db_lto=true"
      "-Db_lto_mode=thin"
    ];
  });

  # Fastfetch：在构建时尽可能优化运行速度
  fastfetchBase = pkgs.fastfetch;
  fastfetchOptimized = fastfetchBase.override { stdenv = fastOptimizedStdenv; };
in
{
  # DMS-Shell 配置（动态管理系统 Shell）
  programs.dms-shell = {
    enable = false;
    package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
    systemd = {
      enable = true; # 启用 systemd 服务
      restartIfChanged = true; # 配置变化时自动重启服务
    };

    # 核心功能启用
    enableSystemMonitoring = true; # 系统监控小部件
    enableVPN = true; # VPN 管理小部件
    enableDynamicTheming = true; # 动态主题（基于壁纸）
    enableAudioWavelength = true; # 音频可视化（Cava）
    enableCalendarEvents = false; # 日历集成（Khal）

    # Quickshell 包
    quickshell.package = quickshellOptimized;
    #quickshell.package =inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;
  };

  # Mango WM 使用优化构建
  programs.mango.package = mangoOptimized;

  programs.fish.enable = true;  # 启用 Fish Shell
  programs.fish.interactiveShellInit = ''
    ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
  '';

  # 启用 zsh，补全交给 zim 管理，避免重复 compinit
  programs.zsh = {
    enable = true;
    enableCompletion = false;
  };
  
  programs.starship.enable = true; # 启用 Starship Shell Prompt
  # DSearch 配置（快速搜索工具）
  programs.dsearch = {
    enable = true;

    package = pkgs.dsearch; # 使用的包

    systemd = {
      enable = true; # 启用 systemd 用户服务
      target = "default.target"; # 随用户会话启动
    };
  };

  # 系统包列表（全局可用的应用程序和工具）
  environment.systemPackages = with pkgs; [
    # KDE 工具
    kdePackages.discover # 发现和管理 Flatpak/Firmware 更新
    kdePackages.sddm-kcm # SDDM 配置模块
    kdePackages.partitionmanager # 分区管理器
    kdePackages.kdeconnect-kde # KDE Connect GUI

    # 开发和系统工具
    kdiff3 # 文件比较和合并工具
    hardinfo2 # 系统信息和基准测试
    vlc # 跨平台媒体播放器
    wayland-utils # Wayland 实用工具
    wl-clipboard # Wayland 剪贴板工具
    wget # 命令行下载工具
    curl # 命令行数据传输工具
    kitty # 现代终端模拟器
    git # 版本控制系统
    gh # GitHub 命令行工具
    xwayland-satellite # XWayland 增强工具
    appimage-run # AppImage 运行工具

    # 网络和代理工具
    nh # Nix 构建输出优化工具
    xhost # X11 访问控制
    mihomo # TUN 模式的代理工具
    fastfetchOptimized # 系统信息工具（优化构建）

    # 字体和图标
    nerd-fonts.symbols-only # Nerd Fonts 符号
    papirus-icon-theme # Papirus 图标主题

    # 多媒体和流媒体
    obs-studio # 视频录制和直播软件
    libvpl # Intel 视频处理库（OBS 编码）
    vpl-gpu-rt # Intel GPU 实时视频处理
    libavif # AVIF 图像格式支持
    libaom # AOMedia 视频编解码器

    # 开发工具
    gcc # GNU 编译器集合
    hugo # 静态网站生成器

    # 虚拟化工具
    virt-manager # 虚拟机管理器
    virt-viewer # 虚拟机显示客户端
    spice # SPICE 协议组件
    spice-gtk # SPICE GTK 客户端
    spice-protocol # SPICE 协议定义
    virtiofsd # VirtIO 文件系统守护进程

    # 网络工具
    iptables # IP 数据包过滤工具

    # 其他实用工具
    fbterm # Framebuffer 终端（TTY 中文显示）

    # 从 Inputs 安装的包
    inputs.hexecute.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Hyprland 插件
    #hyprlandPlugins.hyprexpo      # Hyprland Expo 插件
    #hyprlandPlugins.hyprscrolling # Hyprland 滚动插件

    # 创建 FHS 环境，以便在 NixOS 中运行非 NixOS 包
    (
      let
        base = pkgs.appimageTools.defaultFhsEnvArgs;
      in
      pkgs.buildFHSEnv (
        base
        // {
          name = "fhs";
          targetPkgs =
            pkgs:
            # pkgs.buildFHSEnv 只提供一个最小的 FHS 环境，缺少很多常用软件所必须的基础包
            # 所以直接使用它很可能会报错
            #
            # pkgs.appimageTools 提供了大多数程序常用的基础包，所以我们可以直接用它来补充
            (base.targetPkgs pkgs)
            ++ (with pkgs; [
              pkg-config # pkg-config 工具
              ncurses # ncurses 库（许多命令行应用需要）
              # 如果你的 FHS 程序还有其他依赖，把它们添加在这里
            ]);
          profile = "export FHS=1"; # 设置环境变量
          runScript = "bash"; # 启动脚本
          extraOutputsToInstall = [ "dev" ]; # 额外安装开发输出
        }
      )
    )
  ];

  # 排除不需要的 GNOME 包（减少系统占用）
  environment.gnome.excludePackages = (
    with pkgs;
    [
      atomix # 拼图游戏
      cheese # 摄像头工具
      epiphany # GNOME Web 浏览器
      geary # 邮件客户端
      gnome-characters # 字符映射表
      gnome-music # 音乐播放器
      gnome-console # 终端模拟器
      gnome-tour # GNOME 新手指南
      hitori # 数独游戏
      iagno # 围棋游戏
      tali # 骰子游戏
      totem # 视频播放器
    ]
  );

  # 排除不需要的 Plasma6 包（如果使用其他桌面环境）
  environment.plasma6.excludePackages = [
    # 这里可以添加需要排除的 Plasma6 包
    # kdePackages.elisa           # 简单音乐播放器
    # kdePackages.kdepim-runtime  # Akonadi 代理和资源
    # kdePackages.kmahjongg       # 麻将游戏
    # kdePackages.kmines          # 扫雷游戏
    # kdePackages.konversation    # IRC 客户端
    # kdePackages.kpat            # 纸牌游戏
    # kdePackages.ksudoku         # 数独游戏
    # kdePackages.ktorrent        # BitTorrent 客户端
  ];
}
