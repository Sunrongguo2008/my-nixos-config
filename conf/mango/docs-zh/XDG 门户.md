---
title: XDG 门户 (XDG Portals)
description: 使用 XDG 门户设置屏幕共享、剪贴板、密钥环和文件选择器。
---

## 门户配置

你可以通过以下路径自定义门户设置：

- **用户配置（优先）：** `~/.config/xdg-desktop-portal/mango-portals.conf`
- **系统回退：** `/usr/share/xdg-desktop-portal/mango-portals.conf`

> **警告：** 如果你之前添加了 `dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wlroots` 到你的配置，请删除它。Mango 现在会自动处理这个。

## 屏幕共享

要启用屏幕共享（OBS、Discord、WebRTC），你需要 `xdg-desktop-portal-wlr`。

1. **安装依赖**

   `pipewire`、`pipewire-pulse`、`xdg-desktop-portal-wlr`

2. **可选：添加到自启动**

   在某些情况下，门户可能不会自动启动。你可以将其添加到自启动脚本以确保它启动：

   ```bash
   /usr/lib/xdg-desktop-portal-wlr &
   ```

3. **重启计算机** 以应用更改。

### 已知问题

- **窗口屏幕共享：** 某些应用程序可能在共享单个窗口时遇到问题。有关解决方法，请参阅 [#184](https://github.com/mangowm/mango/pull/184)。

- **屏幕录制卡顿：** 如果你在屏幕录制期间遇到卡顿，请参阅 [xdg-desktop-portal-wlr#351](https://github.com/emersion/xdg-desktop-portal-wlr/issues/351)。

## 剪贴板管理器

使用 `cliphist` 管理剪贴板历史。

**依赖：** `wl-clipboard`、`cliphist`、`wl-clip-persist`

**自启动配置：**

```bash
# 在应用程序关闭后保留剪贴板内容
wl-clip-persist --clipboard regular --reconnect-tries 0 &

# 监视剪贴板并存储历史
wl-paste --type text --watch cliphist store &
```

## GNOME 密钥环

如果你需要存储密码或秘密（例如用于 VS Code 或 Minecraft 启动器），安装 `gnome-keyring`。

**配置：**

将以下内容添加到 `~/.config/xdg-desktop-portal/mango-portals.conf`：

```ini
[preferred]
default=gtk
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.Screenshot=wlr
org.freedesktop.impl.portal.Secret=gnome-keyring
org.freedesktop.impl.portal.Inhibit=none
```

## 文件选择器

**依赖：** `xdg-desktop-portal`、`xdg-desktop-portal-gtk`

重启计算机一次以应用。
