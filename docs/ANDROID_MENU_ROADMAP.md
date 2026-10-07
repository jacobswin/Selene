# Moonlight V+ Android menu reference / Android 菜单参考

Reference reviewed: user-provided streaming-menu photo, 2026-10-07. The personal photo is not committed. This is a feasibility review against local Selene code, not proof of host protocol support or physical streaming results.

| Reference control / 参考功能 | Decision / 结论 |
| --- | --- |
| Disconnect / 断开连接 | Implemented dialog action; leaves the PC app running. 已实现菜单操作，电脑应用继续运行。 |
| Disconnect and exit / 断开并退出 | Implemented separate confirmed action using the existing host quit request; host rejection remains an error, not a successful quit. 独立确认操作，复用主机退出请求；主机拒绝时提示失败。 |
| Bitrate / 实时码率 | Existing client setting and live request path can be reused; direct dialog controls are TODO. 可复用现有实时路径，菜单快捷控制待做。 |
| Performance / 性能监控 | Existing statistics overlay can be reused; Android floating/fixed modes require a tvOS-specific design. 可复用统计，悬浮/固定布局需适配。 |
| Alt+Tab, Win, special keys / 特殊按键 | Feasible through existing key-event sending; shortcuts and balanced key-up handling are TODO. 可复用按键协议，快捷入口与按键释放待做。 |
| Screen keyboard / 屏幕键盘 | Reuse explicit tvOS text input, not Android touch UI. 复用主动 tvOS 文本输入，不复制触屏键盘。 |
| Host keyboard / 主机键盘 | Meaning and host operation need verification before implementation. 需核实具体行为及主机操作。 |
| Resolution, HDR during streaming / 串流中分辨率和 HDR | Current settings negotiate at stream start; reliable in-session switching is not established. Investigate protocol support or use explicit reconnect. 当前启动协商，实时切换未确认；核实协议或明确重新连接。 |
| DPI 250 / DPI 100 | No confirmed existing Windows DPI command; conditional investigation, not promised support. 未确认 DPI 控制命令，不承诺支持。 |
| Touch/mouse/trackpad input, pan/zoom / 触控、鼠标、触摸板、平移缩放 | Keep native remote and physical device input; Android touch mode selector is out of scope. 保留遥控器与实体外设，触屏模式切换不照搬。 |
| Gyro / 体感助手 | Android touch-device gyro UI is out of scope; compatible controller motion is a separate capability, not inferred from this photo. 不搬手机体感开关，手柄体感能力另行验证。 |
| Crown / 王冠 | Later settings photos identify this as a touch-widget profile system. Not ported to tvOS. 后续设置照片确认它是触屏控件配置，不移植到 tvOS。 |

Checklist policy: README.md and README_CN.md carry matching tasks. Check an implementation off only after the relevant build/checks pass; record physical acceptance separately. Additional screenshots are reviewed individually. No host protocol redesign, touch controls menu, or unverified format claims.

## Settings photos 1–14 / 设置照片 1–14

| Photos / 照片 | Existing or feasible / 已有或可做 | Conditional or excluded / 有条件或不移植 |
| --- | --- | --- |
| 1 Quality / 串流质量 | Existing preset/custom resolutions, FPS and manual bitrate; TODO adaptive bitrate and optional low-bandwidth presets. 已有分辨率、帧率、手动码率；自适应与低带宽档位待做。 | Host render scaling needs a supported request. 主机渲染比例需协议支持。 |
| 2 Codec/HDR / 编码 | Existing H.264/HEVC, hardware-gated AV1, HDR10 and color-range code; TODO comprehensive capability report and output validation. 已有编码/HDR10及色彩范围代码；报告与输出验证待做。 | A host Windows HDR toggle differs from negotiated stream HDR. 主机 Windows HDR 开关不等于串流 HDR 协商。 |
| 3 Host / 主机 | Existing host-audio and quit requests; TODO optional Win+L and explicit lifecycle policy. 已有主机音频与退出请求；锁定与前后台策略待做。 | Monitor selection and input-only streaming need host support. 显示器选择与仅控制需核实主机。 |
| 4 Display / 显示 | Fit/stretch/alignment/offset controls are client-feasible; preserving aspect ratio is the default. 画面适配、拉伸、对齐、偏移可做，默认保持比例。 | Device rotation, separate mobile external-screen routing and Android picture-in-picture UI are not copied. 不照搬移动设备旋转、外接屏与 Android 画中画界面。 |
| 5 Performance / 性能 | Adaptive bitrate, better frame-pacing explanations and queue validation are TODO. 自适应码率、帧节奏说明和队列验证待做。 | Android MediaCodec low-latency switches are not tvOS APIs; extra FPS choices do not establish physical 90/120 Hz support. 不照搬 MediaCodec 开关，不将帧率选项写成实际刷新率支持。 |
| 6 Interpolation / 插帧 | Existing native FrameInterpolator code warrants separate hardware/latency/artifact validation. 现有原生插帧需单独验证硬件、延迟与画质。 | Do not import a Windows DLL into tvOS or present this as Lossless Scaling. 不导入 Windows DLL，不冒充 Lossless Scaling。 |
| 7 Audio / 音频 | Keep truthful stereo/5.1/7.1 output and physical route diagnostics. 保留真实立体声/5.1/7.1与输出诊断。 | No AC3/E-AC3 host receive path established; Android IEC61937, effects and spatializer switches are not ported. 未建立 AC3/E-AC3接收路径，不照搬 Android 直通/音效/空间化开关，7.1.4不加入。 |
| 8 Microphone / 麦克风 | Investigate supported capture routes, permissions, host extension and mute state. 核实采音路径、权限、主机扩展及静音状态。 | Siri Remote dictation does not establish continuous microphone access. 遥控器听写不等于连续麦克风采音。 |
| 9 Controllers / 手柄 | Shortcut testing, dead zones, calibration and mouse-mode UI are feasible candidates. 快捷键测试、死区、校准、鼠标模式可做。 | Joy-Con combining and rumble/motion require actual GameController device capability; no Android USB driver port. Joy-Con合并、震动、体感按实际设备验证，不搬 Android USB 驱动。 |
| 10 Touch/input / 输入 | Explicit keyboard entry and special-key shortcuts are feasible. 主动键盘与特殊键快捷入口可做。 | Touch drag, double-tap thresholds and automatic host touch keyboard are not copied. 不搬触屏拖动、双击阈值及自动主机触摸键盘。 |
| 11 Crown / 王冠 | Menu shortcut selection can be adapted independently. 菜单快捷项可独立适配。 | Touch-widget profile management is out of scope. 触屏控件配置不移植。 |
| 12 Interface / 界面 | Existing three-language selector; compact covers and shortcut visibility are TODO. 已有三语言；小封面与快捷项显隐待做。 | No touch floating bubble. Warning preferences must not hide connection failures. 不加入触屏悬浮球，不用隐藏警告配置掩盖连接失败。 |
| 13 Backup / 备份 | Versioned settings backup through a TV-compatible flow is TODO. 适配电视的版本化设置备份待做。 | No direct Android folder picker/sync or automatic export of pairing secrets. 不搬 Android 文件夹同步，不自动导出配对密钥。 |
| 14 Help / 帮助 | User guide, version/project links and licenses are feasible; basic About already exists. 指南、版本/项目链接与许可证可做，已有基础关于页面。 | No unrelated PC download, donation QR, GitHub-Star unlock or fake update channel. 不复制无关下载、捐赠码、Star解锁或不存在的更新渠道。 |

### Platform evidence / 平台依据

- [Apple: tvOS camera and microphone capture](https://developer.apple.com/videos/play/wwdc2023/10256/) provides supported capture APIs, but does not establish a Siri Remote raw-microphone route. 支持采集 API 不代表能持续采集遥控器麦克风。
- [Apple: background Metal restrictions](https://developer.apple.com/documentation/metal/preparing-your-metal-app-to-run-in-the-background) limits background GPU access. 后台策略不能假定 GPU 持续可用。
- [Apple: multichannel content declaration](https://developer.apple.com/documentation/avfaudio/avaudiosession/supportsmultichannelcontent) and [spatial audio route state](https://developer.apple.com/documentation/avfaudio/avaudiosessionportdescription/isspatialaudioenabled) describe system capabilities, not proof that the host stream carries Atmos. 多声道声明与系统空间音频状态不能证明源串流是 Atmos。

These are implementation candidates, not claims that the photographed Android build's behavior has been independently verified. The photos show settings, not end-to-end capability evidence. 未将照片上的开关当作实际功能验证证据。
