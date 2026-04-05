# Home Manager 包配置模块
# 包含用户安装的各种软件包
{ pkgs, ... }:

let
  qqWithX11 = pkgs.qq.overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/qq \
        --set XMODIFIERS "@im=fcitx" \
        --set GTK_IM_MODULE "fcitx" \
        --add-flags "--enable-features=UseOzonePlatform --ozone-platform=x11"
    '';
  });

in
{
  # 通过 home.packages 安装一些常用的软件
  # 这些软件将仅在当前用户下可用，不会影响系统级别的配置
  # 建议将所有 GUI 软件，以及与 OS 关系不大的 CLI 软件，都通过 home.packages 安装
  home.packages = with pkgs; [
    # 如下是我常用的一些命令行工具，你可以根据自己的需要进行增删
    yazi # 终端文件管理

    # 压缩工具
    zip
    xz
    unzip
    p7zip

    # 实用工具
    ripgrep # 递归搜索目录中的正则表达式模式
    jq # 轻量级灵活的命令行 JSON 处理器
    yq-go # YAML 处理工具 https://github.com/mikefarah/yq
    lsd # 现代化的 'ls' 替代品
    fzf # 命令行模糊查找工具
    zoxide # 目录跳转工具，类似 autojump/z.lua

    # 网络工具
    aria2 # 轻量级多协议和多源命令行下载工具

    # 杂项工具
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg
    ffmpeg
    poppler # 用于 PDF 预览

    # Nix 相关工具
    # 提供 `nom` 命令，功能类似 `nix` 但输出更详细的日志
    nix-output-monitor

    btop # htop/nmon 的替代品
    iotop # IO 监控工具
    iftop # 网络监控工具

    # 系统工具
    sysstat
    lm_sensors # 用于 'sensors' 命令
    ethtool
    pciutils # lspci
    usbutils # lsusb

    # niri
    libnotify
    nwg-look
    xdg-desktop-portal-gtk
    nautilus
    code-nautilus
    nautilus-open-any-terminal
    gnome-keyring
    #quickshell 已经在 dms 中配置了 qs-flake
    matugen
    wl-clipboard
    cliphist
    adw-gtk3
    libsForQt5.qt5ct
    kdePackages.qt6ct

    obsidian
    ayugram-desktop
    localsend
    vivaldi
    vivaldi-ffmpeg-codecs
    wpsoffice-cn
    qqWithX11
    flameshot
    cmatrix
    cava # 音频可视化
    sl # 小火车
    gcr # Provides org.gnome.keyring.SystemPrompter

    # neovim
    neovim
    fzf
    lazygit
    ripgrep
    fd
    tree-sitter
    # neovim 的 LSP
    nodejs_24
    pnpm
    cargo
    rustc
    go
    python3
    # neovim 的 LSP
    vmware-workstation
    libreoffice-qt-fresh
    kdePackages.ark
    nemo # 文件管理器
    gedit # 文本编辑器
    loupe # 图片查看器
    adwaita-qt
    adwaita-qt6
    nil # 用于 vscode 的 nix 语法纠错
    nixd # 用于 vscode 的 nix 语法纠错
    protonplus # Steam Proton 版本管理工具
    lutris # 游戏管理器
    nixfmt

    # 虚拟化
    virtualbox

    starship
    zimfw # 提供 zimfw.zsh 脚本本体
  ];
}
