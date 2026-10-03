# Windows 基线检查记录

日期：2026-10-03。范围：构建准备阶段，不包含 Xcode 编译或设备验收。

已执行并通过：

- `git diff --check`：改动无空白错误。
- Git Bash `bash -n BuildScripts/build-tvos.sh`：shell 语法正确。
- Windows 执行构建脚本：返回失败并明确要求 macOS/full Xcode，未假装完成构建。
- Python 标准库解析 TV Info.plist 与共享 scheme XML：应用名、Bonjour 服务、target ID 与产品名一致。
- TV Debug/Release 设置检查：独立 Bundle ID、空 Team、数字构建版本一致，四处旧 SDK 路径已消除。
- Swift Package 锁文件 JSON 解析与固定 revision 检查。
- 五个 tvOS 静态库及 ImGui、音频触觉源码文件存在；全部子模块与固定提交一致。
- 构建相关文件实际采用 LF，并通过 `.gitattributes` 保证后续检出行为。
- 独立只读代码审查：未发现本阶段新增配置或脚本的阻断问题。

以上检查不验证 Xcode 工程语义、Swift/Objective-C 可编译性、静态库平台兼容性或真实串流。未运行 GitHub CI，未发布远程仓库。

交付时在外部输出记录 Git bundle 验证及 SHA-256；bundle 包含本项目 Git 历史，不包含子模块对象库。
