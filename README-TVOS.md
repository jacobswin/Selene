# Moonlight Plus for Apple TV

基于 [VoidLink](https://github.com/The-Fried-Fish/VoidLink-previously-moonlight-zwm) 的独立 tvOS 开发项目，参考 [Moonlight V+](https://github.com/qiin2333/moonlight-vplus)。当前交付为构建准备基线，尚未完成 Mac 编译和真机验收。

目标：第三代 Apple TV 4K、Foundation Sunshine、PS4/PS5 手柄。先稳定串流，再实现配置预设、统计与快捷菜单。构建需要 Xcode 26+；最低运行版本 tvOS 16.0。

- 转移和构建：[Mac 交接说明](docs/MAC_HANDOFF.md)
- 已确认方案：[实施计划](docs/IMPLEMENTATION_PLAN.md)
- 平台差异：[tvOS 审查](docs/TVOS_AUDIT.md)
- 实际验收：[真机记录](docs/DEVICE_TESTS.md)

应用显示名与 Bundle ID 独立；保留上游内部工程名及代码。原始 README、版权署名及 `LICENSE.txt` 保留，本项目遵循 GPLv3。当前图标仍为上游资产，独立图标在后续阶段完成。没有对外发布或上传仓库。
