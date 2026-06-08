# Home 核心配置模块
# 包含用户信息、Shell、服务与配置文件链接
{ config, lib, pkgs, inputs, ... }:

let
  conf-dir = "${config.home.homeDirectory}/nixos/conf";
in
{
  # 用户基本信息
  home.username = "s";
  home.homeDirectory = "/home/s";

  # 设置状态版本（与 NixOS 版本保持一致）
  home.stateVersion = "25.05";

  # 会话变量配置
  home.sessionVariables = {
    TERMINAL = "kitty"; # 设置默认终端
  };

    # 将 fish 作为 shell，但不把 fish 作为登录 shell 以防止问题
  programs.bash = {
    enable = true;
    initExtra = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  # Polkit GNOME 服务（用于 Niri 等桌面环境）
  services.polkit-gnome.enable = true;

  # GNOME 密钥环服务
  services.gnome-keyring.enable = true;

  # Mango 配置变更后自动 reload_config
  systemd.user.services.mango-reload-config = {
    Unit = {
      Description = "Reload Mango config on changes";
    };

    Service = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/mmsg -d reload_config";
    };
  };

  systemd.user.paths.mango-reload-config = {
    Unit = {
      Description = "Watch Mango config directory for changes";
    };

    Path = {
      PathChanged = "${config.home.homeDirectory}/.config/mango";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # 配置文件链接
  home.file.".zshrc" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/zshrc";
  };

  home.file.".zshenv" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/zshenv";
  };

  home.file.".zimrc" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/zimrc";
  };

  home.file.".local/share/zimfw/zimfw.zsh" = {
    force = true;
    source = "${pkgs.zimfw}/zimfw.zsh";
  };

  home.file.".config/fish/config.fish" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/fish.fish";
  };


  home.file.".config/starship.toml" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/starship.toml";
  };

  home.file.".config/niri/config.kdl" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/niri.kdl";
  };

    home.file.".config/fastfetch/config.jsonc" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/fastfetch.jsonc";
  };

  home.file.".config/mango" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/mango";
  };

    home.file.".config/Code/User/settings.json" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/vscode.json";
};

  # kitty 终端配置（默认终端，TERMINAL=kitty）
  home.file.".config/kitty/kitty.conf" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/kitty.conf";
  };

  # git 用户配置（user/email + gh credential helper）
  home.file.".gitconfig" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/gitconfig";
  };

  # Claude Code 全局设置（settings.local.json 留给本机私有权限，不软链）
  home.file.".claude/settings.json" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/claude/claude-settings.json";
  };

  # Claude Code 状态栏脚本（被 settings.json 的 statusLine.command 引用）
  home.file.".claude/statusline.sh" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/claude/claude-statusline.sh";
  };

  # OpenCode 全局配置
  home.file.".config/opencode/opencode.jsonc" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink
      "${conf-dir}/opencode.jsonc";
  };

}
