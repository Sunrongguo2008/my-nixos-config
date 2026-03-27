---
title: Scratchpad
description: 管理隐藏的"scratchpad"窗口以便快速访问。
---

mangowm 支持两种类型的 scratchpad：标准池（类似 Sway）和命名 scratchpad。

## 标准 Scratchpad

任何窗口都可以发送到"scratchpad"堆，这会隐藏它。然后你可以循环浏览它们。

**键位绑定：**

```ini
# 将当前窗口发送到 scratchpad
bind=SUPER,i,minimized

# 切换（显示/隐藏）scratchpad
bind=ALT,z,toggle_scratchpad

# 从 scratchpad 检索窗口（恢复）
bind=SUPER+SHIFT,i,restore_minimized
```

---

## 命名 Scratchpad

命名 scratchpad 绑定到特定的键和应用程序。触发时，mangowm 将启动应用程序（如果未运行）或切换其可见性。

**1. 定义窗口规则**

你必须使用唯一的 `appid` 或 `title` 识别应用程序并将其标记为命名 scratchpad。应用程序必须支持在启动时设置自定义 appid 或标题。常见示例：

- `st -c my-appid` — 设置 appid
- `kitty -T my-title` — 设置窗口标题
- `foot --app-id my-appid` — 设置 appid

当你只想匹配一个字段时使用 `none` 作为占位符。

```ini
# 按 appid 匹配
windowrule=isnamedscratchpad:1,width:1280,height:800,appid:st-yazi

# 按标题匹配
windowrule=isnamedscratchpad:1,width:1000,height:700,title:kitty-scratch
```

**2. 绑定切换键**

格式：`bind=MOD,KEY,toggle_named_scratchpad,appid,title,command`

对于你不匹配的字段使用 `none`。

```ini
# 按 appid 匹配：启动运行 `yazi` 的 `st`，类别为 `st-yazi`
bind=alt,h,toggle_named_scratchpad,st-yazi,none,st -c st-yazi -e yazi

# 按标题匹配：启动窗口标题为 `kitty-scratch` 的 `kitty`
bind=alt,k,toggle_named_scratchpad,none,kitty-scratch,kitty -T kitty-scratch
```

---

## 外观

你可以相对于屏幕自定义 scratchpad 窗口的大小。

```ini
scratchpad_width_ratio=0.8
scratchpad_height_ratio=0.9
scratchpadcolor=0x516c93ff
```
