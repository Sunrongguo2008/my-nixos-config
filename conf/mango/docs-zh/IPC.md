---
title: IPC
description: 使用 mmsg 以编程方式控制 mangowm。
---

## 简介

mangowm 包含一个名为 `mmsg` 的强大 IPC（进程间通信）工具。这允许你查询窗口管理器的状态、监视事件并从外部脚本执行命令。

## 基本用法

`mmsg` 的通用语法为：

```bash
mmsg [-OTLq]
mmsg [-o <output>] -s [-t <tags>] [-l <layout>] [-c <tags>] [-d <cmd>,<arg1>,<arg2>,<arg3>,<arg4>,<arg5>]
mmsg [-o <output>] (-g | -w) [-OotlcvmfxekbA]
```

### 选项

| 标志 | 描述                                        |
| :--- | :------------------------------------------ |
| `-q` | 退出 mangowm。                              |
| `-g` | **获取**值（标签、布局、聚焦的客户端）。    |
| `-s` | **设置**值（切换标签、布局）。              |
| `-w` | **监视**模式（流式传输事件）。              |
| `-O` | 获取所有输出（显示器）信息。                |
| `-T` | 获取标签数量。                              |
| `-L` | 获取所有可用布局。                          |
| `-o` | 选择输出（显示器）。                        |
| `-t` | 获取/设置选中的标签（使用 `[+-^.]` 设置）。 |
| `-l` | 获取/设置当前布局。                         |
| `-c` | 获取聚焦客户端的标题和 appid。              |
| `-v` | 获取状态栏的可见性。                        |
| `-m` | 获取全屏状态。                              |
| `-f` | 获取浮动状态。                              |
| `-d` | **调度**一个内部命令。                      |
| `-x` | 获取聚焦客户端的几何形状。                  |
| `-e` | 获取最后聚焦的 layer 名称。                 |
| `-k` | 获取当前键盘布局。                          |
| `-b` | 获取当前键位绑定模式。                      |
| `-A` | 获取显示器的缩放因子。                      |

## 示例

### 标签管理

你可以使用 `-t` 标志配合 `-s`（设置）对标签执行算术运算。

```bash
# 切换到标签 1
mmsg -t 1

# 将标签 2 添加到当前视图（多视图）
mmsg -s -t 2+

# 从当前视图移除标签 2
mmsg -s -t 2-

# 切换标签 2
mmsg -s -t 2^
```

### 布局

以编程方式切换布局。布局代码：`S`（Scroller）、`T`（Tile）、`G`（Grid）、`M`（Monocle）、`K`（Deck）、`CT`（Center Tile）、`RT`（Right Tile）、`VS`（Vertical Scroller）、`VT`（Vertical Tile）、`VG`（Vertical Grid）、`VK`（Vertical Deck）、`TG`（TGMix）。

```bash
# 切换到 Scroller
mmsg -l "S"

# 切换到 Tile
mmsg -l "T"
```

### 调度命令

`config.conf` 键位绑定中可用的任何命令都可以通过 IPC 运行。

```bash
# 关闭聚焦的窗口
mmsg -d killclient

# 调整窗口大小 +10 宽度
mmsg -d resizewin,+10,0

# 切换全屏
mmsg -d togglefullscreen

# 禁用显示器电源
mmsg -d disable_monitor,eDP-1
```

### 监视和状态

使用 `-g` 或 `-w` 构建自定义状态栏或自动化脚本。

```bash
# 监视所有消息更改
mmsg -w

# 获取所有消息而不监视
mmsg -g

# 监视聚焦的客户端 appid 和标题
mmsg -w -c

# 获取所有可用输出
mmsg -O

# 获取所有标签消息
mmsg -g -t

# 获取当前聚焦的客户端消息
mmsg -g -c

# 获取当前键盘布局
mmsg -g -k

# 获取当前键位绑定模式
mmsg -g -b

# 获取当前显示器的缩放因子
mmsg -g -A
```

#### 标签消息格式

- 状态：0 → 无，1 → 活动，2 → 紧急

示例输出：

| 显示器 | 标签编号 | 标签状态 | 标签中的客户端 | 聚焦的客户端 |
| ------ | -------- | -------- | -------------- | ------------ |
| eDP-1  | tag 2    | 0        | 1              | 0            |

| 显示器 | 占用的标签掩码 | 活动的标签掩码 | 紧急的标签掩码 |
| ------ | -------------- | -------------- | -------------- |
| eDP-1  | 14             | 6              | 0              |

## 虚拟显示器

你可以创建无头输出用于屏幕镜像或远程桌面访问（例如 Sunshine/Moonlight）。

```bash
# 创建虚拟输出
mmsg -d create_virtual_output

# 配置它（设置分辨率）
wlr-randr --output HEADLESS-1 --pos 1920,0 --mode 1920x1080@60Hz

# 销毁所有虚拟输出
mmsg -d destroy_all_virtual_output
```
