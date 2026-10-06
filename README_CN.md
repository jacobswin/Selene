# Selene

[English](README.md) | [简体中文](README_CN.md)

<p align="center"><img src="docs/branding/selene-icon-master.png" width="480" alt="Selene app icon"></p>

面向 **Apple TV** 的开源游戏串流客户端，基于 Moonlight 生态。通过 Sunshine 串流电脑游戏与桌面，提供适合 Siri Remote 和 tvOS 原生手柄导航的界面。

**开发中。** 暂无公开安装包或 TestFlight 发行版，需要使用 Xcode 自行构建与签名。实际测试情况见[验证记录](docs/SELENE_VERIFICATION.md)。

![Selene 设置](docs/verification/selene-settings.png)

## 功能

- tvOS 原生焦点、单一电脑→应用入口，以及退出设置或串流后的焦点恢复。
- 现代双栏设置页，左侧分类获得焦点后立即显示内容。
- 分辨率支持 720p、1080p、2K（2560×1440）、3K（3200×1800）、4K，以及设备范围内的自定义偶数宽高。
- 英语、简体中文、繁体中文与应用内语言选择；其他系统语言回退为英语。
- 最高 **800 Mbps** 可配置码率，支持超过 150 Mbps 的自定义值。这是配置上限，**不保证稳定网络吞吐**。
- 遥控器可操作码率数字键盘；当前码率不高于 200 Mbps 时每次增减 10 Mbps，高于 200 Mbps 时每次增减 25 Mbps。
- H.264、HEVC；主机、解码器和显示设备支持时，通过 HEVC Main10 使用 HDR10。
- 始终显示 AV1，只有硬解检测通过才可选择，不提供 AV1 软件解码。
- 立体声、5.1、7.1，实际输出取决于主机和音频设备。

当前串流路径**不支持 Dolby Vision 或 Dolby Atmos**。HDR10 不等于 Dolby Vision，Opus 解码后的多声道 PCM 不等于 Atmos。2.1、5.1.2、7.1.4 未实现为可选输出布局。高码率 4K60、持续 HDR 播放和实际音频输出仍需真机验证。

## 构建与安装

需要 macOS、**Xcode 26 或更新版本**，以及 **tvOS 16 或更新版本**。当前开发使用 Xcode 27。

```sh
git clone --recurse-submodules https://github.com/jacobswin/Selene.git
cd Selene
open Selene.xcodeproj
```

1. 选择 **Selene** Scheme 和主要 Selene tvOS Target。
2. 在 **Signing & Capabilities** 中开启自动签名，选择自己的开发团队。如有需要，使用自己的唯一 Bundle ID。
3. 在 Xcode 的 **Devices and Simulators** 中配对 Apple TV，选为运行目标并运行。4K 模拟器可检查界面，不能证明真机解码或 HDR 能力。

不签名的编译检查：

```sh
bash BuildScripts/build-tvos.sh Debug
```

详细步骤见[构建与配对](docs/BUILDING.md)。升级现有开发安装时保持原 Bundle ID，以保留配对和设置。

## 连接与操作

在电脑上运行 Sunshine。当前开发使用 [Foundation Sunshine](https://github.com/AlkaidLab/foundation-sunshine)，尚未验证与所有 Sunshine 版本的兼容性。

选择发现的电脑，或通过 **+** 添加地址。选择电脑配对，将 Selene 显示的 PIN 输入 Sunshine 配对页面。选择已配对电脑后直接进入应用列表，**Desktop** 作为普通应用保留。

使用 Siri Remote 移动与选择，通过返回/Menu 键返回。连接的手柄在界面中使用 tvOS 原生焦点，在串流时提供游戏输入。通过齿轮进入设置。

## 来源与致谢

直接代码基础是 [VoidLink](https://github.com/The-Fried-Fish/VoidLink-previously-moonlight-zwm)，后者源自 [Moonlight iOS/tvOS](https://github.com/moonlight-stream/moonlight-ios)。保留原作者版权声明和[上游 README](docs/UPSTREAM_README.md)。

其他参考包括 [Moonlight Android](https://github.com/moonlight-stream/moonlight-android)、[Moonlight Qt](https://github.com/moonlight-stream/moonlight-qt)、[Moonlight Embedded](https://github.com/moonlight-stream/moonlight-embedded)、历史项目 [Moonlight Chrome](https://github.com/moonlight-stream/moonlight-chrome)、[Moonlight Common C](https://github.com/moonlight-stream/moonlight-common-c) 和 [Moonlight V+](https://github.com/qiin2333/moonlight-vplus)。固定版本的协议子模块采用上游 [VoidLink C 分支](https://github.com/TrueZhuangJia/voidlink-c)。

Selene 是独立社区项目，参考关系不代表官方关联或认可。

## 许可证与贡献

沿用 [GPLv3](LICENSE.txt)，依赖保留各自许可证。欢迎贡献与可复现的问题反馈，请说明设备型号、tvOS 与主机版本、串流设置和复现步骤。公开证据前移除私人地址与配对码。
