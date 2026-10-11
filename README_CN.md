# Selene

[English](README.md) | [简体中文](README_CN.md)

<p align="center"><img src="docs/branding/selene-tvos-icon-master.png" width="480" alt="Selene app icon"></p>

面向 **Apple TV** 的开源游戏串流客户端，基于 Moonlight 生态。通过 Sunshine 串流电脑游戏与桌面，提供适合 Siri Remote 和 tvOS 原生手柄导航的界面。

**开发中。** 暂无公开安装包或 TestFlight 发行版，需要使用 Xcode 自行构建与签名。实际测试情况见[验证记录](docs/SELENE_VERIFICATION.md)。

![Selene 设置](docs/verification/selene-settings.png)

## 功能

- 可选紧凑封面、菜单快捷项配置、本地手柄输入测试与独立摇杆死区。
- App 内遥控器指南与诊断；电脑锁定需主动开启，默认关闭。
- tvOS 原生焦点、单一电脑→应用入口，以及退出设置或串流后的焦点恢复。
- 现代双栏设置页，左侧分类获得焦点后立即显示内容。
- 分辨率支持 360p、480p、720p、1080p、2K（2560×1440）、3K（3200×1800）、4K，以及设备范围内的自定义偶数宽高。
- 英语、简体中文、繁体中文与应用内语言选择；其他系统语言回退为英语。
- 最高 **800 Mbps** 可配置码率，支持超过 150 Mbps 的自定义值。这是配置上限，**不保证稳定网络吞吐**。
- 遥控器可操作码率数字键盘；当前码率不高于 200 Mbps 时每次增减 10 Mbps，高于 200 Mbps 时每次增减 25 Mbps。
- H.264、HEVC；主机、解码器和显示设备支持时，通过 HEVC Main10 使用 HDR10。
- 始终显示 AV1，只有硬解检测通过才可选择，不提供 AV1 软件解码。
- 立体声、5.1、7.1，实际输出取决于主机和音频设备。

- 深色串流菜单，提供实时码率、性能统计、键盘快捷操作和主动文本输入。
- 统一的设备、请求与实际协商能力报告，以及持久保存的画面比例、对齐和偏移。
- 可选自适应码率，支持上下限、网络丢帧/RTT 反馈、手动覆盖和主机拒绝处理；默认关闭，不覆盖保存的手动码率。

当前串流路径**不支持 Dolby Vision 或 Dolby Atmos**。HDR10 不等于 Dolby Vision，Opus 解码后的多声道 PCM 不等于 Atmos。2.1、5.1.2、7.1.4 未实现为可选输出布局。高码率 4K60、持续 HDR 播放和实际音频输出仍需真机验证。

## TODO

此清单只跟踪功能实现与 Bug 修复；清理和移除功能记录在验证文档中。🟢 已实现 · 🔴 待完成。绿色表示已实现；真机串流验证单独跟踪。Android 参考功能先评估 tvOS 与现有 Sunshine 协议的能力，再加入待办。

- 🟢 返回键打开串流对话框，不直接离开；提供继续串流、串流设置、断开串流、断开并关闭应用（需确认）。
- 🔴 在 Apple TV 验证新菜单：连续返回、设置往返、手柄/键盘输入、两种退出行为及原应用焦点恢复。
- 🟢 将实时码率和性能统计快捷控制放进串流菜单，保留主机拒绝提示与遥控器焦点操作。
- 🟢 增加 Alt+Tab、Windows、特殊按键及主动 tvOS 文本输入快捷入口；关闭菜单或断线时释放所有按键。
- 🔴 核实现有 Foundation Sunshine 是否支持串流中切换分辨率和 HDR；仅在协商支持时开放，否则明确要求重新连接。
- 🔴 核实主机键盘与 Windows DPI 控制；仅在现有主机协议提供可靠操作时加入。
- 🟢 增加视频能力报告：实际显示模式、硬解支持、HDR 状态与实际串流格式。
- 🟢 增加客户端自适应码率：上下限、网络丢帧/延迟反馈、手动覆盖及主机能力检测。
- 🟢 增加画面适配、对齐与水平/垂直偏移，支持重置，不改变请求的串流尺寸。
- 🟢 增加可选小封面与菜单快捷项显示配置，保留清晰的原生焦点效果。
- 🟢 增加可选低带宽分辨率，并区分请求帧率与显示器实际刷新率。
- 🟢 说明帧节奏、客户端缓冲与全范围色彩，限制不支持或串流中的帧节奏变更，并确认色彩范围修改；默认值真机验证仍待完成。
- 🟢 在 GameController 支持范围内增加手柄按键/组合键测试、独立摇杆死区与鼠标模式控制。
- 🟢 增加可选断开后锁定电脑操作，通过完整 Win+L 按键事件实现并提示主机失败。
- 🟢 进入后台时断开并保留电脑应用；返回时可选择提示重连，默认关闭。
- 🟢 通过二维码备份代码导出版本化设置，验证代码并确认后恢复；排除配对、电脑地址及账号。
- 🟢 增加 App 内遥控器操作指南、诊断及项目/许可证链接，不显示不存在的下载或付费解锁。
- 🔴 核实现有 Foundation Sunshine 对主机渲染比例、显示器选择与仅控制会话的协商支持。
- 🔴 核实 tvOS 可用采音路径与主机扩展的麦克风转发；验证前保持不可用。
- 🔴 验证现有原生插帧路径在 Apple 硬件上的能力；不加载 Windows Lossless Scaling DLL，不宣称等同 Android 插帧。
- 🔴 继续评估 Moonlight V+ Android 截图，将可行功能逐项加入待办，实现并完成相应验证后更新状态。
- 🔴 完成真机 160/200 Mbps 4K60、持续 HDR10 及立体声/5.1/7.1 输出验证。

### 本批五项功能

1. 🟢 **重连提示**：比较当前保存的分辨率、帧率、编码、HDR 与色彩范围和连接初始设置，在菜单及报告中说明何时需要重连。
2. 🟢 **性能设置说明**：说明帧节奏与输出路径限制、客户端帧队列及全范围色彩；限制不支持的帧节奏修改，色彩范围修改需确认。
3. 🟢 **前后台返回**：进入后台时断开，不关闭或锁定电脑应用；可选返回重连提示默认关闭。
4. 🟢 **设置备份**：扫描本地生成的二维码，复制其中的 `SELENE1:` 代码，通过 iPhone Apple TV 遥控器键盘粘贴至“设置 → 其他 → 设置备份”，预览并确认后恢复。仅包含允许的设置字段，不可用的编码、HDR 或插帧选项会调整。
5. 🟢 **主机扩展报告**：“帮助与诊断”区分实际码率请求结果与未知或尚未实现的主机操作，不开放未经验证的分辨率、HDR、DPI 或麦克风控制。

🔴 本批五项功能的真机验收仍待完成，上一批未完成的真机检查继续保留。

### 上一批五项实施阶段

1. 🟢 **串流返回菜单稳定性**：统一返回事件去重并恢复菜单焦点。用户确认返回操作保留串流；连续返回、设置往返与手柄验收仍待完成。
2. 🟢 **小封面与菜单配置**：可选紧凑应用卡片，六项快捷入口可独立设置显示。
3. 🟢 **断开后锁定电脑**：默认关闭，仅主动普通断开前发送 Win+L；报告发送结果，不宣称主机已锁定。
4. 🟢 **手柄控制设置**：本地输入测试、左右摇杆独立 0–30% 径向死区，以及仅当前会话生效的鼠标模式。
5. 🟢 **App 内指南与诊断**：三语遥控器、配对与故障说明，实时能力报告，以及项目、反馈和 GPLv3 许可证二维码入口。

🔴 新网格、快捷项显示、Windows 锁屏、手柄鼠标与三语帮助的真机验收仍待完成，详见验证记录。

详见 [Android 菜单可行性评估](docs/ANDROID_MENU_ROADMAP.md)。不直接照搬触屏专用控件；Dolby Vision、Atmos 与高度声道布局仍不支持。

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
