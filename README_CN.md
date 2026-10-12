# Selene

[English](README.md) | [简体中文](README_CN.md)

<p align="center"><img src="docs/branding/selene-tvos-icon-master.png" width="480" alt="Selene app icon"></p>

面向 **Apple TV** 的开源游戏串流客户端，基于 Moonlight 生态。通过 Sunshine 串流电脑游戏与桌面，提供适合 Siri Remote 和 tvOS 原生手柄导航的界面。

**开发中。** 暂无公开安装包或 TestFlight 发行版，需要使用 Xcode 自行构建与签名。实际测试情况见[验证记录](docs/SELENE_VERIFICATION.md)。

![Selene 设置](docs/verification/selene-settings.png)

## 功能

- **为 Apple TV 设计：** 遥控器焦点导航、单一电脑到应用入口、焦点恢复、现代设置、小封面，以及英语、简体中文和繁体中文。
- **串流画质：** 360p 至 4K、2K／3K 与自定义分辨率；H.264／HEVC、按能力启用 AV1 硬解、支持时使用 HDR10，以及立体声／5.1／7.1 音频。
- **高码率：** 0.5–800 Mbps 指定输入、带拒绝提示的实时主机请求、独立的实际接收码率统计，以及可选的上下限自适应码率。**800 Mbps 是配置上限，不是稳定吞吐承诺。**
- **串流菜单：** 返回打开菜单，再次返回继续串流；性能统计、键盘快捷键、主动文本输入、可配置快捷项，以及独立的断开和二次确认关闭应用操作。
- **画面与性能：** 保持比例或拉伸、九宫格对齐和偏移、统计位置、质量提醒，以及支持硬件上的原生插帧、延迟降级和实际生成帧诊断。
- **手柄工具：** 本地输入测试、独立摇杆死区、中心校准，以及可调整指针和滚动速度的会话鼠标模式。普通断开时发送 Win+L 为可选功能，默认关闭。
- **主机控制：** 根据主机公布的档位确认调整 Windows 显示缩放，执行主机提供的命令；Foundation 专属显示器排列与仅控制会话需主动开启；可重新连接应用保存的串流设置，保留电脑应用运行。
- **隐私与帮助：** 设备、请求和实际协商能力报告，操作指南，本地诊断二维码，验证后的设置备份与恢复，以及可选的前台重新连接。
- **实验性麦克风转发：** tvOS 17 及以上通过连续互通选择 iPhone 或 iPad 麦克风；需主动授权、主机协商，默认静音，以 48 kHz 单声道 Opus 转发。

## 限制与验证

当前串流路径不支持 Dolby Vision、Dolby Atmos 或高度声道，AV1 不提供软件解码。未开放实时分辨率／HDR 切换、主机渲染比例和采集显示器选择；保存串流设置后可使用“主机控制 → 应用设置并重新连接”。

主机扩展取决于安装的 Foundation Sunshine 版本。显示器排列是请求，不代表已确认 Windows 实际排列；命令接受也不代表操作完成。麦克风转发需要连接连续互通设备及主机麦克风扩展，不采集遥控器麦克风。原生插帧需要支持的 Apple 硬件及 tvOS 26 以上版本。

代码和自动测试与真机验收分别记录。新主机控制、麦克风及音频路径、持续 HDR、高码率性能和手柄行为仍需 Apple TV 验证。详见[验证记录](docs/SELENE_VERIFICATION.md)及[平台功能评估](docs/ANDROID_MENU_ROADMAP.md)。目前没有公开安装包或 TestFlight 发行渠道。

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

使用 Siri Remote 移动与选择。串流时按返回/Menu 键打开串流对话框；“断开串流”保留电脑应用运行，“断开串流并关闭应用”同时请求主机关闭应用。连接的手柄在界面中使用 tvOS 原生焦点，在串流时提供游戏输入。通过齿轮进入设置。

## 来源与致谢

直接代码基础是 [VoidLink](https://github.com/The-Fried-Fish/VoidLink-previously-moonlight-zwm)，后者源自 [Moonlight iOS/tvOS](https://github.com/moonlight-stream/moonlight-ios)。保留原作者版权声明和[上游 README](docs/UPSTREAM_README.md)。

其他参考包括 [Moonlight Android](https://github.com/moonlight-stream/moonlight-android)、[Moonlight Qt](https://github.com/moonlight-stream/moonlight-qt)、[Moonlight Embedded](https://github.com/moonlight-stream/moonlight-embedded)、历史项目 [Moonlight Chrome](https://github.com/moonlight-stream/moonlight-chrome)、[Moonlight Common C](https://github.com/moonlight-stream/moonlight-common-c) 和 [Moonlight V+](https://github.com/qiin2333/moonlight-vplus)。固定版本的协议子模块采用上游 [VoidLink C 分支](https://github.com/TrueZhuangJia/voidlink-c)。

Selene 是独立社区项目，参考关系不代表官方关联或认可。

## 许可证与贡献

沿用 [GPLv3](LICENSE.txt)，依赖保留各自许可证。欢迎贡献与可复现的问题反馈，请说明设备型号、tvOS 与主机版本、串流设置和复现步骤。公开证据前移除私人地址与配对码。
