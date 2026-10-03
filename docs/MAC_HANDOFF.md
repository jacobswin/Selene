# 转移到 Mac 并继续开发

## 当前交接点

Windows 已完成源码和 tvOS 构建配置准备。**现在可以打开 Mac，开始第一次 Xcode 编译。** 这不是已完成的应用：串流预设、独立图标及真机验收尚未完成。先构建，再继续功能开发。

分支：`codex/tvos-baseline`。上游提交：`38e16f1ee3158c3a2c1027fc09fd01bb983b3fd6`。已固定所有 Git 子模块，保留 Swift Package 锁文件。Xcode 26+；最低运行版本 tvOS 16.0。

## 不需要先创建 GitHub 仓库的转移方法

Windows 交付文件 `build/MoonlightPlus-TV.bundle` 是包含本项目提交和历史的 Git bundle。用 U 盘、局域网共享或文件同步将其复制到 Mac。不要只复制 `.xcodeproj`。

在 Mac 终端进入保存 bundle 的目录，再运行：

```bash
git clone -b codex/tvos-baseline ./MoonlightPlus-TV.bundle MoonlightPlus-TV
cd MoonlightPlus-TV
git submodule update --init --recursive
git status --short
git submodule status --recursive
```

bundle 不包含子模块的对象库；初始化子模块与 Xcode 解析 Swift Package 均需要访问 GitHub。初始化后的子模块状态不应以 `-`、`+` 或 `U` 开头。

克隆后的 origin 指向本地 bundle，不能向它推送。后续需要跨设备 Git 同步时，在自己的 GitHub 账号创建空仓库，然后将 origin 改成该仓库地址并推送当前分支；不要推送至上游作者仓库。

也可以直接复制整个当前项目目录（包含隐藏 `.git` 及子模块），但会更大，且仍需联网下载 Swift Package。bundle 是推荐交付方式。

## Mac 首次构建

1. 安装完整 Xcode 26 或更新版本，打开一次并完成首次组件安装。在 Xcode Settings → Locations 中选择对应 Command Line Tools；安装 tvOS 平台支持。
2. Mac Codex 打开 `MoonlightPlus-TV` 项目目录。先阅读本文件、`IMPLEMENTATION_PLAN.md` 和 `TVOS_AUDIT.md`。
3. 执行：

```bash
bash BuildScripts/build-tvos.sh Debug
bash BuildScripts/build-tvos.sh Release
```

脚本输出 `build/tvos-Debug.log`、`build/tvos-Release.log` 及 `.xcresult`。没有 Xcode 或版本过旧时会停止。出现编译失败时保留日志，先修复第一个实际错误并重新构建；不升级子模块或包来碰运气。

上游有新的 SDK 类型，故 Xcode 16 无法作为本基线构建工具。CI 明确选择 Xcode 26.3，避免 macos-15 默认 Xcode 16.4；来源为 GitHub runner-images 的 macos-15 软件清单。CI 文件已准备，但尚未上传或运行。

## 签名并安装到 Apple TV

1. 用 Xcode 打开 `VoidLink.xcodeproj`，选择共享 scheme **Moonlight Plus TV**。
2. 选择 **VoidLink TV** target → Signing & Capabilities，启用自动签名并选择自己的 Team。若账号不能注册默认 Bundle ID，替换成自己唯一的标识。
3. Mac 与 Apple TV 放在同一网络。Apple TV 打开“设置 → 遥控器与设备 → 遥控器 App 与设备”；Xcode 打开 Window → Devices and Simulators，按配对码完成连接。
4. 选择真实 Apple TV 为运行目标，点击 Run。构建脚本/CI 生成的未签名 `.app` 不能直接作为可安装发行包。
5. 首次开启局域网访问权限，以 1080p60、H.264、20 Mbps、SDR、立体声配对 Foundation Sunshine 并测试。

如个人免费 Team 遇到 tvOS provisioning 限制，保留 Xcode 的具体签名错误，再确定账号条件。不要把未签名构建成功视为设备安装成功。

## 给 Mac 上 Codex 的接续提示

> 继续这个 Moonlight Plus tvOS 项目。请先阅读 docs/MAC_HANDOFF.md、docs/IMPLEMENTATION_PLAN.md、docs/TVOS_AUDIT.md。用户设备为第三代 Apple TV 4K，服务端 Foundation Sunshine，手柄 PS4/PS5。Windows 已固定 VoidLink 基线并准备构建配置，但没有完成 Xcode 编译或真机验收。先运行 BuildScripts/build-tvos.sh 的 Debug/Release 构建，依据实际错误修复并确认真机基础串流，再按实施方案完成串流预设、统计、快捷菜单与独立图标。不要直接替换底层 fork，不要声称尚未测试的功能可用。

## 真机记录

使用 `DEVICE_TESTS.md` 记录系统版本、Xcode 版本、主机版本、网络方式和实际结果。未执行项目保留“未验证”。
