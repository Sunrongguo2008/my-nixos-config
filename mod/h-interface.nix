# Home 界面配置模块
# 包含光标、GTK、Qt、VSCode 等图形界面相关配置
{ config, lib, pkgs, ... }:

{
  # 鼠标光标配置
  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;
  };

  # GTK 配置
  gtk = {
    enable = true;
    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3";
    };
    gtk4.theme = config.gtk.theme;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus";
    };
    font = {
      name = "Noto Sans";
      package = pkgs.noto-fonts;
      size = 11;
    };

    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
  };

  #[适配DMS/noctalia] 监听系统深浅色并同步 GTK3 主题，确保 Nemo 等 GTK3 应用跟随切换。
  systemd.user.services.gtk3-theme-sync = {
    Unit = {
      Description = "Sync GTK3 theme with color-scheme";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      Restart = "always";
      RestartSec = 1;
      ExecStart = "${pkgs.writeShellScript "gtk3-theme-sync" ''
        set -eu

        gsettings_bin="${pkgs.glib}/bin/gsettings"
        ready=0

        for ((i = 1; i <= 30; i++)); do
          if "$gsettings_bin" get org.gnome.desktop.interface color-scheme >/dev/null 2>&1; then
            ready=1
            break
          fi
          sleep 1
        done

        if [ "$ready" -ne 1 ]; then
          echo "gtk3-theme-sync: gsettings color-scheme unavailable" >&2
          exit 1
        fi

        sync_theme() {
          local color_scheme target_theme current_theme

          color_scheme="$("$gsettings_bin" get org.gnome.desktop.interface color-scheme 2>/dev/null || true)"
          color_scheme="$(printf '%s' "$color_scheme" | tr -d "'")"
          if [ "$color_scheme" = "prefer-dark" ]; then
            target_theme="adw-gtk3-dark"
          else
            target_theme="adw-gtk3"
          fi

          current_theme="$("$gsettings_bin" get org.gnome.desktop.interface gtk-theme 2>/dev/null || true)"
          current_theme="$(printf '%s' "$current_theme" | tr -d "'")"
          if [ "$current_theme" != "$target_theme" ]; then
            "$gsettings_bin" set org.gnome.desktop.interface gtk-theme "$target_theme" >/dev/null
          fi
        }

        sync_theme

        "$gsettings_bin" monitor org.gnome.desktop.interface color-scheme | while IFS= read -r _; do
          sync_theme
        done
      ''}";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  home.sessionVariables = {
    # Qt5 使用 qt5ct，Qt6 使用 qt6ct。
    QT_QPA_PLATFORMTHEME = "qt5ct";
    QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
  };

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    custom_palette=false
    icon_theme=Papirus
    standard_dialogs=default
    style=adwaita

    [Fonts]
    fixed="Noto Sans Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
    general="Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"

    [Interface]
    activate_item_on_single_click=1
    buttonbox_layout=0
    cursor_flash_time=1000
    dialog_buttons_have_icons=1
    double_click_interval=400
    gui_effects=@Invalid()
    keyboard_scheme=2
    menus_have_icons=true
    show_shortcuts_in_context_menus=true
    stylesheets=@Invalid()
    toolbutton_style=4
    underline_shortcut=1
    wheel_scroll_lines=3

    [SettingsWindow]
    geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\0\0\0\0\0\0\0\x3H\0\0\x3\xf5\0\0\0\0\0\0\0\0\0\0\x3H\0\0\x3\xf5\0\0\0\0\0\0\0\0\x6\xab\0\0\0\0\0\0\0\0\0\0\x3H\0\0\x3\xf5)

    [Troubleshooting]
    force_raster_widgets=1
    ignored_applications=@Invalid()
  '';

  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    custom_palette=false
    icon_theme=Papirus
    standard_dialogs=default
    style=adwaita

    [Fonts]
    fixed="Noto Sans Mono,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
    general="Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"
  '';

  # KDE 应用（如 Dolphin）优先读取 kdeglobals 的图标主题配置。
  xdg.configFile."kdeglobals".text = ''
    [Icons]
    Theme=Papirus
  '';

  # VSCode 配置
  programs.vscode = {
    enable = true;
    package = (pkgs.vscode.override {
      commandLineArgs = [
        "--enable-features=UseOzonePlatform,WaylandIME"
        "--ozone-platform=wayland"
        "--ozone-platform-hint=auto"
        #"--gtk-version=3"
        "--enable-wayland-ime"
      ];
    });
  };

  # MIME 应用配置
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "app.zen_browser.zen.desktop";
      "x-scheme-handler/http" = "app.zen_browser.zen.desktop";
      "x-scheme-handler/https" = "app.zen_browser.zen.desktop";
      "x-scheme-handler/about" = "app.zen_browser.zen.desktop";
      "x-scheme-handler/unknown" = "app.zen_browser.zen.desktop";
    };
  };

  # 桌面条目配置
  xdg.desktopEntries.nvim = {
    name = "Neovim";
    genericName = "Text Editor";
    exec = "kitty nvim %F";
    terminal = false; # 因为我们已经在 exec 中指定了 kitty
    categories = [ "Application" "Utility" "TextEditor" ];
    mimeType = [ "text/plain" "text/markdown" ];
  }; # [INFO]让neovim wrappper 默认用kitty打开
}
