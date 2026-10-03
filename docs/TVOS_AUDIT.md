# tvOS 静态审查与功能差异

审查基线：VoidLink `38e16f1ee3158c3a2c1027fc09fd01bb983b3fd6`。下表只证明相关源码存在，不能证明编译或真机行为正确。

| 能力 | 现有实现证据 | 首版处理 |
| --- | --- | --- |
| 独立 TV target | `VoidLink.xcodeproj`、`VoidLink TV/Info.plist` | 保留；修 SDK 引用、签名与版本设置 |
| 主机发现与配对 | Network 下 MDNSManager、DiscoveryManager、PairManager | 真机确认自动发现、IP 与 PIN |
| 本地网络声明 | TV Info.plist 已有 Bonjour 与本地网络说明 | 保留，验证首次授权及拒绝行为 |
| TV 设置及状态恢复 | SettingsViewController 与 AppDelegate 的 TARGET_OS_TV 分支 | 优先复用，验证冷启动与重新打开设置 |
| 串流统计 | StreamFrameViewController 的统计定时器与覆盖层 | 复用并核验数据来源 |
| 遥控器串流操作 | StreamView 的 TV Menu/PlayPause 通知处理 | 验证菜单、返回与输入占用 |
| 手柄导航及轮盘 | ControllerSupport、ControllerNavigator | 验证 PS4/PS5、残留按键及重连 |
| 手柄运动与设备运动 | ControllerSupport 将设备运动排除在 TV 外 | 区分手柄能力，不移植手机陀螺仪假设 |
| 麦克风 | MicHandler 在 tvOS 下权限请求返回 false | 首版不启用麦克风重定向 |
| 触控布局 profile | OSCProfilesManager 和 ProfileSelector | 不视为已存在的串流画质预设 |
| 新系统插帧 | FrameInterpolator 包含 SDK 26 类型 | 构建需 Xcode 26+；首版不新增或承诺插帧 |
| Foundation 扩展 | 底层为 VoidLink 自己的 voidlink-c fork | 不直接替换成 Android V+ 核心，另做协议审查 |
| 电视图标与 Top Shelf | 当前沿用上游图片 | 后续替换为本项目独立资产 |

## 本次准备已处理

- 四处硬编码 AppleTVOS 11.4/15.2 SDK 路径改为当前 SDKROOT。
- TV Debug/Release 使用独立 Bundle ID、显示名和数字构建版本，移除 TV target 的上游开发者 Team。
- 增加共享 scheme；修正上游忽略 scheme 和新增 CI 的规则。
- 提供不签名真机 Debug/Release 构建脚本和 CI；保留现有 Swift Package 锁文件。

## 尚未验证

Xcode 工程解析、Swift/Objective-C 编译、预构建静态库的 SDK/架构兼容性、着色器/资源加载、真实网络串流、HDR、音视频同步、遥控器焦点、手柄输入及震动均需 Mac/真机。现有二进制库的设备构建路径已存在；模拟器库及架构需要单独验证，因此第一轮不承诺模拟器可用。

Windows 不做基于猜测的大量 API 重写。下一步以首次 Mac 构建日志为依据修复实际错误。
