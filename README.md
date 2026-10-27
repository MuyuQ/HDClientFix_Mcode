# HDClientFix_Mcode · HD 客户端修复

![WoW 3.3.5a HD](https://img.shields.io/badge/WoW-3.3.5a_HD-blue)

为目标 3.3.5a HD 客户端修复角色面板、部分窗口文字和交互，并汉化 WDM 的地图交通提示。合并原 `CharPanelFix_Mcode` 与 `WDM_ZH_Mcode`，各项修复保留独立开关。

[下载源码 ZIP](https://github.com/MuyuQ/HDClientFix_Mcode/archive/refs/heads/main.zip) · [详细使用说明](docs/USAGE.md) · [更新记录](CHANGELOG.md) · [反馈问题](https://github.com/MuyuQ/HDClientFix_Mcode/issues)

## 功能与依赖

| 模块 | 功能 | 依赖 |
|---|---|---|
| 角色面板 | 重复文字与按钮、装等、模型交互、背景和布局修复 | 主要功能需要 ElvUI＋ElvUI_Enhanced，并启用 Enhanced 角色面板模块 |
| 其他窗口 | 公会页、地下城查找器文字适配，试衣间拖转 | ElvUI |
| 自己的 GS 提示 | 悬停自己时补充 GS，已有行不重复添加 | GearScoreLite |
| 地图交通提示 | 汉化 19 种船只、飞艇目的地提示 | 目标 HD 客户端内置 WDM 1.0.5；不依赖 ElvUI |

缺少依赖时暂停对应功能，设置页显示原因。地图贴图和厄运之槌室外图导航由配套汉化 MPQ 提供，本插件不携带这些资源。

## 安装与升级

1. 完全退出游戏，备份旧插件目录。
2. 下载 ZIP，找到包含 `HDClientFix_Mcode.toc` 的文件夹，改名为 **`HDClientFix_Mcode`**，放入 `Interface/AddOns/`。
3. 若仍安装旧 `CharPanelFix_Mcode`、`WDM_ZH_Mcode` 或 `Mcode_CharPanelFix`，将其移到 AddOns 外，保留 WDM 本体、ElvUI 和其他依赖。
4. 完全重启游戏，启用插件，输入 `/hdfix` 检查依赖并调整各项开关。

升级已有同名插件时，备份后完整替换目录，避免残留旧文件。账号存档保留，无需手工复制或改名迁移。

## 使用

输入 **`/hdfix`**，或打开 **ESC → 界面 → 插件 → HD 客户端修复**。设置按“角色面板”“其他窗口与提示”“地图”分组，每项独立控制；战斗中请等待脱战后修改。

原 `/cpfix on`、`/cpfix off`、`/cpfix dump`、`/cpfix reload` 命令继续可用。关闭不同修复项是否需要重载，以设置页和 [使用说明](docs/USAGE.md) 为准。

## 反馈

遇到文字重叠、模型交互或 GS 显示问题，请附插件版本、ElvUI／Enhanced 状态、操作步骤及截图，并提供 `/cpfix dump` 的输出。

版本以 [`HDClientFix_Mcode.toc`](HDClientFix_Mcode.toc) 为准。角色面板修复作者 Mcode，地图交通提示汉化作者 MuyuQ；感谢提供实测反馈的玩家。
