# Apple TV 真机验收记录

所有项目初始状态：**未验证**。填写实际日志与结果后才可标记通过。

设备：第三代 Apple TV 4K。tvOS 版本：待真机填写。Xcode 版本：27.0 (27A266a)。Foundation Sunshine 版本、主机 GPU、网络连接方式、电视型号：待测试填写。手柄：填写 DualShock 4 或 DualSense 具体型号。

| 测试 | 验收条件 | 状态 |
| --- | --- | --- |
| Debug/Release 构建 | 转移包恢复、初始化固定依赖后，两种未签名真机配置均成功 | 已通过（2026-10-03，Xcode 27.0） |
| 安装与冷启动 | 自己的 Team 签名成功，应用正常打开 | 未验证 |
| 自动发现/手动 IP/PIN 配对 | 首次授权后可添加主机、配对并显示游戏列表 | 未验证 |
| 授权拒绝与主机离线 | 可理解的错误提示，可重新尝试 | 未验证 |
| 1080p60 SDR 30 分钟 | H.264、20 Mbps、立体声；无崩溃、持续黑屏或持续音画失步 | 未验证 |
| 4K60 SDR 30 分钟 | HEVC、40 Mbps；记录统计与网络环境 | 未验证 |
| HDR 与 SDR 切换 | 色彩、亮度正常；失败可退回 SDR | 未验证 |
| PS4/PS5 手柄 | 按键、摇杆、扳机正确；重连后无卡键 | 未验证 |
| 基础震动 | 在支持的系统、手柄及主机配置下单独记录 | 未验证 |
| 遥控器独立操作 | 不连接手柄，冷启动后可移动焦点、添加主机、配对、浏览游戏和启动串流 | 未验证 |
| 遥控器设置 | 展开设置分组，调整开关、选项和码率加减按钮，长列表可滚动且焦点清晰 | 未验证 |
| 遥控器返回 | 设置返回主界面，游戏列表返回主机列表，系统弹窗优先关闭 | 未验证 |
| 焦点恢复 | 打开/关闭设置、切换列表、App 回到前台后无焦点丢失；设置打开时焦点不进入背后列表 | 未验证 |
| 遥控器/手柄切换 | 菜单无双重触发；串流时 PS4/PS5 输入仍传送至主机；关闭菜单后无残留输入 | 未验证 |
| 断开/重连/结束主机应用 | 行为明确，结束应用前确认 | 未验证 |
| 网络中断与恢复 | 无崩溃，可再次连接 | 未验证 |
| 重启后数据保留 | 主机、配对和设置正确恢复 | 未验证 |
| 独立图标 | 主屏幕与相关 TV 资源显示正确 | 未实现 |

每次测试补充：提交 SHA、开始时间、持续时间、预期与实际结果、日志路径及截图。统计未提供的数据写“不可用”，不得估算填充。

Mac 启动检查：tvOS 27.0 arm64 模拟器构建、安装、启动已通过，自动发现局域网主机。未进行配对、串流或遥控器按键导航验收。


2026-10-03 更新：原版风格的全屏原生设置列表；移除 Dolby Vision/Atmos 不可用设置行。声音保留立体声、5.1、7.1；2.1、5.1.2、7.1.4 显示禁用及原因，未实现实际输出。

本轮 Debug 模拟器与未签名 tvOS 真机目标构建通过。150/160/200/300/800 Mbps 解析、边界和 JSON 往返测试通过；这不等同 Core Data 重启恢复及实际串流验收。4K 模拟器启动通过。真机安装、160/200 Mbps 吞吐、30 分钟 HDR10 和功放声道输出仍未验证。

研究结果：Windows 支持 Atmos；Foundation Sunshine 已发布实验性 Dolby Vision Profile 8.4 主机支持，其音频源码有 2/6/8/12 声道配置。当前客户端核心最多 8 声道，Opus→PCM 无 Atmos 对象元数据。主机没有独立 2.1 或 5.1.2 配置；不能将 7.1.4 PCM 标注为 Atmos。尚未确认用户安装的 Foundation 版本。

来源：[Microsoft Spatial Sound](https://learn.microsoft.com/en-us/windows/win32/coreaudio/spatial-sound)、[Foundation 发布记录](https://github.com/AlkaidLab/foundation-sunshine/releases)、[Foundation 音频实现](https://github.com/AlkaidLab/foundation-sunshine/blob/master/src/audio.cpp)。


2026-10-03 原生手柄菜单导航：tvOS 禁用自定义 Controller Navigation（不读取旧开关来启用），隐藏相关设置、鼠标调节和径向菜单延迟。遥控器与手柄菜单交给系统焦点，串流 ControllerSupport 输入保持；打开原生设置时切换菜单输入，关闭时恢复串流委托。手柄真机 A/B、方向键及摇杆导航、关闭设置后游戏按键恢复尚待实测。

HEVC 菜单：始终显示 HEVC (H.265)，无硬解时禁用，不再隐藏；真实 Apple TV 硬解能力检测仍需真机确认。

品牌更新：工程与共享 Scheme 名为 Selene；App 产品与显示名 Selene。独立图标覆盖主屏幕、商店、Top Shelf、启动图片及关于页。重命名后的模拟器 Debug 构建通过，内置 Info.plist 显示名核对为 Selene。

主界面焦点修复：Add Host 改用原生 UIBarButtonItem，4K 模拟器按右验证白底黑字高亮；主机动作按钮改用系统 UIButton，卡片加白色边框及 1.04 倍缩放，按下验证焦点清晰可见。不使用自定义 Controller Navigation。

焦点样式修订：依据用户反馈改为小号“＋”原生导航按钮；移除主机卡片的粗白框、阴影与整体缩放，仅提亮焦点所在卡片背景，保留具体操作按钮的系统高亮。4K 模拟器已验证主机 → 导航 → 加号切换，构建通过。
Figma 可编辑设计：https://www.figma.com/design/6b4fUyrUXdMxNE7U4nn63j?node-id=2-18 。


Settings 视觉更新：双栏布局（左侧分类、右侧设置），深色背景、独立圆角行、标题与数值层级；分类选择保留蓝色背景，当前焦点为单层白色高亮。设备能力独立分类，所有可用设置沿用原模型。模拟器 Debug 构建通过；4K 模拟器已检查设置打开及左右焦点切换，无重复系统焦点外框。声音分类、长列表完整导航、串流中菜单及物理遥控器/手柄仍需进一步验收。

可编辑 Figma 设置设计：https://www.figma.com/design/6b4fUyrUXdMxNE7U4nn63j?node-id=4-2 。设计展示的分辨率和码率是示例值，App 使用原先保存的配置。


2026-10-03 分类与语言：左侧分类收到焦点即切换右侧内容，不需 Select；移除对可选 UITableViewDelegate 焦点方法的 super 调用，避免运行时异常。4K 模拟器已验证视频→手柄→其他的连续方向导航。设置→其他→语言提供跟随系统、简体中文、繁體中文、English；选择立即刷新标题、分类、选项、主机操作文字并保存至客户端 UserDefaults。已验证英语与繁体中文即时切换、重启保留繁体中文，并恢复跟随系统。系统首选语言不属于中文/英语时回退英语；中文区域/文字脚本解析与格式占位符通过生产代码测试。Debug 构建与码率回归通过。真机遥控器及所有异常消息逐条验收仍待实测。截图：verification/settings-language-hant.png。

2026-10-04 真机准备：appletvos Debug 编译成功（未签名，尚未安装）。<Apple TV IP> 网络可达，AirPlay 解析为客厅的 Apple TV、AppleTV11,1、tvOS 26.6。Mac 开发证书有效，蓝牙开启。Apple TV 重启后及 Device Hub 重启后，Pair Nearby Device → Apple TV 列表仍为空，CoreDevice 只列出模拟器。真机安装和全部真机验收未完成；需要进一步确认电视配对页面状态。未删除配对记录或修改网络安全配置。

真机配对后续：系统日志确认 2026-10-04 配对完成（Successfully wirelessly paired）。随后 CoreDevice 获取开发连接失败，RemotePairingError 1005：This device does not support tunnel connections。Device Hub 显示 Currently Unavailable，devicectl/xctrace 尚未列出真机。配对成功不等于已安装或通过真机验收；仍需解决开发连接。

2026-10-04 真机连接恢复：继续使用 Xcode 27，刷新 CoreDevice 服务后设备进入 connected 状态并完成开发支持准备。签名 Debug 构建成功，devicectl 安装 com.jacob.moonlightplus.tvos 成功并启动，进程检查显示 Selene 正在运行。真机确认为 Apple TV 4K 第二代（AppleTV11,1）、tvOS 26.6（23L773）。devicectl 截图成功，3840×2160，已发现 the test PC；截图时处于 Sunshine 主机 PIN 配对页面。Device Hub 实时屏幕共享要求 tvOS 27，当前不可用，但安装、启动与截图不受此限制。实体遥控器导航、语言切换及串流指标尚待用户操作验证。原始配对截图仅保留在本地，不公开发布。
