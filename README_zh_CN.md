> [!NOTE]
> **这是 [chen08209/FlClash](https://github.com/chen08209/FlClash) 的二次开发分支（fork）**，感谢上游作者的出色工作。以下是本分支新增的内容，原版说明保留在下方。

## 本分支新增功能

- **自定义分流**（进阶配置 → 自定义分流，配置 → 扩展中按配置勾选）
  - 可视化编辑规则：域名后缀 / 关键字 / 完整域名、IP-CIDR(6)、GEOSITE、GEOIP、进程名、规则集等，多条件 OR / AND 组合
  - 每条分流独立选择出口（策略、代理组或单个节点），出口不存在时标红并在注入时跳过
  - 生成配置时按列表顺序**前置注入**到规则最前面，支持拖动排序、启用开关、复制（副本名为“名称 copy”）
- **扩展页布局**：自定义分流成为独立标签，位于“标准 / 脚本”之前并默认选中；切换标签不会改动配置原本的模式
- **可视化 Tailscale**（进阶配置 → Tailscale）
  - 认证密钥登录或网页链接登录（链接可复制 / 在浏览器打开），显示登录状态与错误原因
  - **连接代理**：Tailscale 自身连接控制服务器 / DERP 的流量可走指定代理组或节点，适合无法直连控制服务器的网络
  - 显示本机 tailnet IP 与全部设备（在线状态、系统、出口节点能力），支持搜索、复制 IP、一键“添加到自定义分流”（MagicDNS 域名 + IPv4/IPv6 合并为一条 OR 规则）
  - 自动注入 100.64.0.0/10、fd7a:115c:a1e9::/48、ts.net 等前置规则和 MagicDNS 解析；退出登录并重置会清除登录状态

### 下载

从本分支的 [Releases](https://github.com/KarenGarcia484134/FlClash/releases) 下载。正式版对应 `v*` 标签；`build-…` 开头的是开发预览版。

> [!IMPORTANT]
> Android 包名同为 `com.follow.clash`，但签名与官方版不同，**需要先卸载官方 FlClash 再安装**（卸载前可先在应用内备份配置）。安装包同时带有 v1/v2/v3 签名。

### 发布流程

[`.github/workflows/release.yaml`](.github/workflows/release.yaml)：推送 `v*` 标签发布正式版；或手动运行 workflow（`workflow_dispatch`），可选是否构建桌面端，并用 `version` 输入覆盖版本号（留空则使用 `pubspec.yaml`）。Android 包会重新签名并校验 v1/v2/v3 签名后再上传。

### 内核补丁

`core/Clash.Meta` 子模块指向 [KarenGarcia484134/Clash.Meta](https://github.com/KarenGarcia484134/Clash.Meta) 的 `FlClash-patched` 分支：在上游 `FlClash` 分支上只**新增**了一个文件，用于读取 Tailscale 节点状态并在重载配置时保留同一个节点。补丁说明与同步上游的方法见 [`core/PATCHES.md`](core/PATCHES.md)。

---

<div align="center">

<img src="assets/images/icon.png" alt="FlClash" width="88">

# FlClash

基于 ClashMeta 的多平台代理客户端，简单易用，开源无广告。

[English](README.md) · **简体中文**

[![Release](https://img.shields.io/github/v/release/chen08209/FlClash?style=flat-square&label=release)](https://github.com/chen08209/FlClash/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/chen08209/FlClash/total?style=flat-square&logo=github)](https://github.com/chen08209/FlClash/releases)
[![License](https://img.shields.io/github/license/chen08209/FlClash?style=flat-square)](LICENSE)
[![Telegram](https://img.shields.io/badge/Telegram-channel-26A5E4?style=flat-square&logo=telegram&logoColor=white)](https://t.me/FlClash)

[官网](https://chen08209.github.io/FlClash/zh) · [下载](#下载) · [更新日志](CHANGELOG.md) · [从源码构建](#从源码构建)

</div>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="snapshots/preview-dark.png">
    <img alt="FlClash 在 MacBook 与手机上的仪表盘" src="snapshots/preview.png" width="92%">
  </picture>
</p>

## 功能

- **一个应用覆盖 Android、Windows、macOS 和 Linux**，桌面端同时提供 x64 与 ARM64 版本。
- **mihomo（Clash.Meta）内核**：规则分流、代理组、延迟测试、系统代理与 TUN 模式。
- **配置管理**：通过订阅链接或文件导入配置，内置编辑器，支持覆写脚本以及自定义规则、代理和代理组。
- **实时查看**连接、请求、DNS 查询和日志。
- **Material You 设计，融合 Apple 式交互**：支持动态取色、浅色与深色主题，连续曲率圆角，弹出面板可在几档高度间吸附，布局随屏幕从手机到桌面自适应。
- **备份与恢复**：通过 WebDAV 或本地文件。
- **平台细节**：Android 上有快捷设置磁贴、分应用代理和 Android TV 支持；桌面端有托盘菜单和全局快捷键。
- **开源无广告**，以 GPL-3.0 协议发布。

## 下载

从 [GitHub Releases](https://github.com/chen08209/FlClash/releases/latest) 获取最新版本，或打开
[官网](https://chen08209.github.io/FlClash/zh#download)，它会自动为你的设备选好安装包。

| 平台 | 安装包 | 说明 |
| --- | --- | --- |
| Android | `arm64-v8a`、`armeabi-v7a`、`x86_64` 三种 APK | 绝大多数手机选 `arm64-v8a`。也可以通过下方的 F-Droid 仓库安装。 |
| Windows 10 及以上 | 安装版（`.exe`）或便携版（`.zip`），分 x64 与 ARM64 | 骁龙等 ARM 架构笔记本选 ARM64。 |
| macOS 12 及以上 | Apple Silicon 与 Intel 两种 DMG | 也可以通过 Homebrew 安装。 |
| Linux | `.deb`、`.rpm` 和 AppImage，分 x64 与 ARM64 | 托盘依赖见下方说明。 |

<p>
  <a href="https://chen08209.github.io/FlClash-fdroid-repo/repo?fingerprint=789D6D32668712EF7672F9E58DEEB15FBD6DCEEC5AE7A4371EA72F2AAE8A12FD"><img alt="Get it on F-Droid" src="snapshots/get-it-on-fdroid.svg" height="56"></a>
  <a href="https://github.com/chen08209/FlClash/releases/latest"><img alt="Get it on GitHub" src="snapshots/get-it-on-github.svg" height="56"></a>
</p>

**Homebrew**

```bash
brew tap chen08209/tap
brew install --cask flclash
```

**Linux 托盘图标**

`.deb` 安装包会自动安装所需依赖。使用 AppImage 或 `.rpm` 时，需要先安装 AyatanaAppIndicator 库，托盘图标才能显示：

```bash
sudo apt-get install libayatana-appindicator3-1   # Debian 与 Ubuntu
sudo dnf install libayatana-appindicator-gtk3     # Fedora
```

## 使用

**通过链接导入配置。** 打开下面格式的链接，即可把订阅导入 FlClash。`clashmeta://` 和 `flclash://` 开头的链接同样可用。

```text
clash://install-config?url=<经过 URL 编码的订阅链接>
```

**Android 自动化。** Tasker、MacroDroid 等应用可以用下面的 Action 启动 Activity，从而启动、停止或切换代理：

```text
com.follow.clash.action.START
com.follow.clash.action.STOP
com.follow.clash.action.TOGGLE
```

在电脑上也可以通过 adb 触发：

```bash
adb shell am start -a com.follow.clash.action.TOGGLE
```

## 从源码构建

需要 [Flutter](https://docs.flutter.dev/get-started/install) 3.47（正式版构建使用 3.47.6）、[Go](https://go.dev/dl/) 1.27，
以及通过 rustup 安装的 [Rust](https://rustup.rs/)。桌面端需要在对应系统上构建，Android 在任意系统上都能构建。

```bash
git clone --recursive https://github.com/chen08209/FlClash.git
cd FlClash
flutter pub get
dart setup.dart android   # 或 windows、macos、linux
```

安装包输出到 `dist/`。Go 内核和 Rust 库会在 Flutter 构建过程中一并编译。

| 平台 | 额外依赖 |
| --- | --- |
| Android | 带 NDK 的 Android SDK。加上 `--arch arm64` 可以只构建单个 ABI。 |
| Windows | 编译内核用的 GCC（MinGW-w64），以及打包安装程序用的 [Inno Setup](https://jrsoftware.org/isinfo.php) 6。 |
| macOS | Xcode 与 Node.js。脚本会通过 npm 安装 `appdmg`。 |
| Linux | Debian 或 Ubuntu。脚本会用 apt 安装构建所需的软件包，并下载 `appimagetool`。 |

其余选项可以运行 `dart setup.dart --help` 查看，例如用 `--targets` 只构建部分安装包格式。

## 支持

给仓库点一个 Star 是支持项目最简单的方式。问题讨论和更新通知请关注 [Telegram 频道](https://t.me/FlClash)，
Bug 与功能建议请提交到 [GitHub Issues](https://github.com/chen08209/FlClash/issues)。

<a href="https://star-history.com/#chen08209/FlClash&Date">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=chen08209/FlClash&type=Date&theme=dark">
    <img alt="Star history" src="https://api.star-history.com/svg?repos=chen08209/FlClash&type=Date" width="640">
  </picture>
</a>

## 许可证

FlClash 以 [GPL-3.0 协议](LICENSE)发布。
