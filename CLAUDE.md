# CLAUDE.md

This file provides guidance to Claude Code and Codex when working with code in this repository.

## 仓库概况

这是一个个人 NixOS 配置仓库（hostname `my-nixos`，用户 `s`），基于 Flakes + Home Manager 管理整机系统与用户环境。所有配置文件（.nix）使用中文注释。

## 常用命令

构建与切换系统：

```bash
# 应用配置（推荐使用 nh，仓库已安装）
sudo nh os switch /home/s/nixos -H my-nixos

# 或使用原生命令
sudo nixos-rebuild switch --flake /home/s/nixos#my-nixos

# 仅测试构建不切换
sudo nixos-rebuild test --flake /home/s/nixos#my-nixos

# 更新 flake inputs
nix flake update --flake /home/s/nixos
nix flake lock --update-input <input-name>   # 仅更新某一项

# 查看本次会拉哪些包
nixos-rebuild build --flake /home/s/nixos#my-nixos --dry-run
```

垃圾回收已配置为每周自动执行（保留 7 天）。手动清理：`sudo nh clean all` 或 `nix-collect-garbage -d`。

## 架构

入口：`flake.nix` → `configuration.nix`（NixOS 系统侧）+ `home.nix`（Home Manager 用户侧）。两个入口文件本身只做 import，**真正的配置都在 `mod/` 中**。

### 模块拆分约定

| 前缀 | 归属 | 用途 |
|---|---|---|
| `mod/s-*.nix` | NixOS 系统层 | 由 `configuration.nix` 导入 |
| `mod/h-*.nix` | Home Manager 用户层 | 由 `home.nix` 导入 |

具体模块：

- `s-base.nix` — 启动（GRUB + zen 内核）、Nix 设置（flakes、GC、国内镜像 substituters、cachy/garnix/noctalia 公钥）、网络、locale、btrfs autoScrub、`home-manager.backupCommand`（生成带时间戳的备份避免 `.bak` 冲突）
- `s-hardware.nix` — `nixos-generate-config` 生成的硬件配置
- `s-desktop.nix` — Wayland 合成器（Hyprland + Niri + Mango）、字体、Fcitx5、greetd/tuigreet、XDG portal、Qt 主题
- `s-service.nix` — 用户 `s`（已硬编码 `hashedPassword`）、PipeWire、CUPS（声明式 HP M126a 打印机）、libvirtd/Docker/VMware、SSH、Steam、Mihomo（TUN 模式代理）、hermes-agent
- `s-packages.nix` — 系统级软件包；内含 **`fastOptimizedStdenv`**（clang + LLD + `-O3 -flto=thin -march=native`），用于重新构建 `quickshell`、`mango`、`fastfetch` 等运行时敏感的包
- `h-core.nix` — 用户基本信息、shell（bash 自动 exec 到 fish）、Mango 配置变更监听 + 自动 `mmsg -d reload_config`、大量 `mkOutOfStoreSymlink` 把 `~/.config/*` 链接到 `conf/`
- `h-interface.nix` — GTK/Qt 主题、光标、VSCode（强制 Wayland）、`gtk3-theme-sync` 服务监听 `org.gnome.desktop.interface color-scheme` 并切换 `adw-gtk3` ↔ `adw-gtk3-dark`
- `h-packages.nix` — 用户级包

### 配置文件软链机制（重要）

`conf/` 目录下的文件（`niri.kdl`、`starship.toml`、`fish.fish`、`hermes-agent.yaml`、`mihomo.yaml` 等）通过 `mkOutOfStoreSymlink` 链接到 `~/.config/...`。这意味着：

- **直接编辑 `conf/` 中的文件会立刻生效**，无需 `nixos-rebuild`。
- 但 `mihomo.yaml` 例外：它通过 `environment.etc."mihomo/config.yaml".source` 引用，是系统层 store 路径，**改完必须 rebuild**。
- `conf/mango/` 目录被 `home.file` 整目录链接；`h-core.nix` 中的 `mango-reload-config` systemd path 监听该目录变化并自动 reload。

### Flake inputs 注意点

- 同时使用 `nixos-unstable` 与 `nixos-25.11` 稳定通道（`pkgs-stable` 通过 `specialArgs` 传递，但当前仅 `configuration.nix` 函数签名包含，未实际使用稳定包时无影响）。
- `nix-cachyos-kernel.overlays.pinned` 用于钉死内核版本，避免 patch 不匹配；当前实际使用 `linuxPackages_zen`（s-base.nix 中切换）。
- 对 `pkgsi686Linux.openldap` 关闭了 `doCheck`，因为 Lutris 多架构会拉 i686 openldap 触发 flaky 测试 `test017-syncreplication-refresh`；改动隔离在 i686，不影响 x86_64 缓存命中。
- `hermes-agent` 模块通过 `~/.hermes/config.yaml` 和 `~/.hermes/.env` 软链运行，**不要**在 `services.hermes-agent.settings` / `configFile` / `environmentFiles` 里设值，会破坏默认加载路径。
- `hermes-agent.env` 与 `conf/mango/noctalia.conf` 在 `.gitignore` 中（含密钥/本机派生内容）。

## 编辑约定

- 注释保持中文。模块内若新增可调参数，沿用现有"# 中文说明"风格。
- 不要随手把 `nix.gc` 关掉或改 `home-manager.backupCommand`——它解决了 home-manager 在 `.zshrc` 等链接上反复冲突的具体痛点。
- 防火墙 `networking.firewall.enable = false`（Mihomo TUN 模式所需），改动前看清 `trustedInterfaces` 与 `checkReversePath = false` 的依赖。
- 系统 `stateVersion = "25.05"`，不要随版本升级而修改。
