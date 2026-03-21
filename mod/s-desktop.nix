# 系统界面配置模块
# 包含桌面环境、字体渲染与输入法配置
{ config, lib, pkgs, inputs, ... }:

{
  # 启用 Hyprland 窗口管理器（Wayland）
  programs.hyprland.enable = true;
  programs.hyprland.withUWSM = true; # 使用 UWSM（Unified Wayland Session Manager）

  programs.niri.enable = true;
  programs.mango.enable = true;

  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      mango = {
        prettyName = "Mango(UWSM)";
        comment = "Mango compositor managed by UWSM";
        binPath = "/run/current-system/sw/bin/mango"; 
      };
    };
  };

  # 会话环境变量配置
  environment.sessionVariables = {
    # 为 Hyprland 插件设置路径
    HYPR_PLUGIN_DIR = pkgs.symlinkJoin {
      name = "hyprland-plugins";
      paths = with pkgs.hyprlandPlugins; [
        #hyprexpo # Hyprland Expo 插件（类似 macOS Mission Control）
        #hyprscrolling # Hyprland 滚动插件
      ];
    };

    # Wayland 相关设置（提示 Electron 应用使用 Wayland）
    NIXOS_OZONE_WL = "1";
    LIBVA_DRIVER_NAME = "iHD";

    # Qt 应用的输入法模块设置
    QT_IM_MODULE = "fcitx";

    # Qt5 使用 qt5ct，Qt6/KDE 应用使用 qt6ct（含 Dolphin）。
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ intel-media-driver ];
  };

  # XDG 门户配置（提供安全的 Wayland 服务访问）
  xdg.portal = {
    enable = true;
    extraPortals = [
      #pkgs.xdg-desktop-portal-gnome  # GNOME 门户实现
      #pkgs.xdg-desktop-portal-gtk    # GTK 门户实现
      pkgs.kdePackages.xdg-desktop-portal-kde # KDE 门户实现
    ];

    # Niri 的门户配置
    config.niri = {
      default = [ "gnome" "gtk" ]; # 默认使用 GNOME 或 GTK 门户
      # 指定文件选择器使用 KDE 门户
      "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
    };
  };

  # Tuigreet 终端登录管理器配置
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # 使用 tuigreet 作为登录界面
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --remember \
            --cmd niri-session \
            --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions:${config.services.displayManager.sessionData.desktops}/share/xsessions
        '';
        user = "s"; # 登录用户
      };
    };
  };

  # 禁用传统 X11 服务器（因为我们使用 Wayland）
  services.xserver.enable = false;

  # 禁用其他桌面管理器（避免冲突）
  services = {
    desktopManager.plasma6.enable = false; # 禁用 KDE Plasma 6
    desktopManager.gnome.enable = false; # 禁用 GNOME 桌面
  };

  # 系统字体配置
  fonts = {
    packages = with pkgs; [
      noto-fonts                 # Google Noto 字体（基础拉丁字符）
      noto-fonts-cjk-sans       # Noto Sans CJK 字体（无衬线中文字体）
      noto-fonts-cjk-serif      # Noto Serif CJK 字体（衬线中文字体）
      lxgw-wenkai-screen        # 适合屏幕阅读的文楷字体
      maple-mono.NF-CN          # Maple Mono 字体（带 Nerd Fonts 图标的等宽字体）
      nerd-fonts.monaspace      # gitHub 上的 Monaspace 字体（带 Nerd Fonts 图标的等宽字体）
      inputs.nix-wpsoffice-cn.packages.${stdenv.hostPlatform.system}.chinese-fonts # WPS Office 中文字体
      # 安装自定义本地字体
      (runCommand "Mi-Sans" { } ''
        mkdir -p $out/share/fonts/opentype
        cp ${../data/MiSans-Regular.otf} $out/share/fonts/opentype/
      '')
    ];

    # 字体渲染配置
    fontconfig = {
      antialias = true;          # 启用字体抗锯齿
      hinting.enable = true;     # 启用字体微调
      # 设置默认字体族
      defaultFonts = {
        emoji = [ "Noto Color Emoji" ];      # 表情符号字体
        monospace = [ "FiraCode Nerd Font" ]; # 等宽字体（带图标）
        sansSerif = [ "Noto Sans CJK SC" ];   # 无衬线字体（简体中文）
        serif = [ "Noto Serif CJK SC" ];      # 衬线字体（简体中文）
      };
    };
  };

  # Fcitx5 输入法框架配置
  i18n.inputMethod = {
    enable = true;              # 启用输入法
    type = "fcitx5";           # 使用 Fcitx5 输入法框架
    fcitx5 = {
      waylandFrontend = true;   # 启用 Wayland 前端支持
      addons = with pkgs; [
        rime-data      # Rime 输入法引擎数据
        fcitx5-rime    # Fcitx5 的 Rime 插件
      ];
    };
  };
}
