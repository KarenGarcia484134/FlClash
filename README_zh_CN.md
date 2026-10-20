<div align="center">

<img src="assets/images/icon.png" alt="FlClash" width="88">

# FlClash（二次开发版）

[English](README.md) · **简体中文**

基于 [chen08209/FlClash](https://github.com/chen08209/FlClash) 二次开发，感谢原作者。

[下载](#下载) · [功能](#功能) · [安装说明](#安装说明) · [构建与发布](#构建与发布) · [内核补丁](#内核补丁) · [同步上游](#同步上游) · [许可证](#许可证)

</div>

## 功能

### 自定义分流

- 位于「进阶配置 → 自定义分流」，在「配置 → 扩展」中按配置勾选启用
- 可视化编辑规则：域名后缀 / 关键字 / 完整域名、IP-CIDR / IP-CIDR6、GEOSITE、GEOIP、进程名、规则集等，多个条件可按 OR / AND 组合
- 每条分流独立选择出口：策略（DIRECT / REJECT 等）、代理组、单个节点或 Tailscale 节点；出口不存在时标红并在生成配置时跳过
- 按列表顺序**前置注入**到配置规则的最前面；支持拖动排序、启用开关、复制（副本名为“名称 copy”）
- 仪表盘卡片：「自定义分流」卡片显示当前配置已启用的条目数，点按直达管理列表（列表中可直接勾选是否在当前配置中使用）；新老用户默认添加一次，删除后不会再自动出现
- 出口延迟：选择出口时每个节点显示延迟（绿 / 黄 / 红 / 超时，与代理页共享测速结果），支持全部测速、点按或**长按**节点单独测速（长按不会选中）、按延迟排序、隐藏超时；代理组显示当前选中的节点及其延迟；分流列表中每条的出口旁也显示延迟，点按或长按即可重测

### 前置代理

- 在「代理」页**长按**普通节点打开菜单（可扩展），选择「设置前置代理」，从其他节点 / 代理组中挑选（带延迟显示），或选「不使用」
- 按配置、按节点名保存，生成最终配置时注入 `dialer-proxy`；覆盖订阅自带的前置代理，订阅自带的也会显示
- 自动排除会形成循环的选择（自身、A→B→A、包含该节点的代理组）；订阅更新后节点或目标不存在时跳过并在界面中提示
- 设置了前置代理的节点显示“经 XX”；延迟测试测的是整条链路
- 「进阶配置 → 前置代理」集中查看、修改、删除或清除全部；仅适用于配置文件中直接定义的节点（不含代理集合中的节点）

### 自动应用与重启核心

- 修改自定义分流（编辑、启用开关、按配置勾选——包括仪表盘卡片列表和扩展页、排序、复制、删除）、前置代理或 Tailscale 设置后，核心运行时会自动重新应用当前配置（防抖），并提示「已应用」或失败原因
- 已有连接默认继续沿用旧规则；可在「通用」中开启「应用配置时关闭连接」，让新规则立即作用于所有连接
- 仪表盘新增「重启核心」卡片：确认后重启并显示进度与结果；新老用户默认添加一次

### 多端口

- 「进阶配置 → 多端口」：额外的本地代理端口（mihomo `listeners`），支持 mixed / socks / http，Linux 桌面版另有 redir / tproxy（其他平台隐藏）
- 每个端口可设名称、启用开关、监听地址（默认 127.0.0.1，可选 0.0.0.0 局域网并给出提醒）、端口、UDP、用户名密码认证
- 出口：跟随规则（默认）、配置中的子规则，或通过带延迟显示的出口选择器固定到某个节点 / 代理组 / DIRECT
- 校验端口范围以及与应用自身端口、其他监听器的冲突；名称或端口与配置文件自带的 listener 相同时以你的为准，出口或子规则不存在时跳过并标红
- 全局生效（不区分配置），有总开关；修改后自动重新应用；列表显示监听状态，长按可复制地址（如 socks5://127.0.0.1:7891）

### 界面风格

- 设置 → 主题 →「界面风格」：**经典**（默认，即 0.9.11 的 Material 外观）或 **新版**（上游 0.9.1 的重新设计：iOS 字号体系、分层表面、iOS 配色、液态玻璃），切换后立即生效
- 两种风格各自保存主题色：经典沿用之前设置的颜色和 Material 配色方案，新版使用 iOS 色板和配色风格；液态玻璃仅在新版中提供
- 0.9.1 重新设计的页面（围绕当前出口的仪表盘、代理组卡片、连接 / 请求表格）在两种风格下都保留；切换改变的是主题，不是页面布局

### 扩展页布局

- 「自定义分流」成为独立标签，位于「标准 / 脚本」之前并默认选中
- 切换标签不会改动配置原本使用的模式，当前生效的模式带有标记

### 可视化 Tailscale

- 位于「进阶配置 → Tailscale」：主机名、认证密钥、控制服务器（支持 Headscale）、出口节点、tailnet 域名后缀、接受子网路由、临时节点、UDP
- 两种登录方式：认证密钥，或网页链接登录（可复制、在浏览器中打开）；显示登录状态和真实的错误原因，并区分“网络无法连接控制服务器”和“认证密钥被拒绝”
- **连接代理**：Tailscale 自身连接控制服务器、DERP 中继和其他设备的流量可以走指定的代理组或节点，适合无法直连控制服务器的网络
- 设备列表：本机 tailnet IP、全部设备的在线状态、系统、出口节点能力；支持搜索、复制 IP
- 一键「添加到自定义分流」：设备的 MagicDNS 域名与 IPv4 / IPv6 地址合并为一条 OR 规则
- 自动前置注入 100.64.0.0/10、fd7a:115c:a1e9::/48、ts.net 等规则以及 MagicDNS 解析；节点名与配置中已有的代理不冲突
- 登录状态保存在应用数据目录，重新应用配置时保留同一个节点；「退出登录并重置」会清除登录状态

## 下载

前往本仓库的 [Releases](https://github.com/KarenGarcia484134/FlClash/releases) 下载：

- `v*` 标签为正式版，包含 Android、Windows、macOS、Linux 安装包；macOS 分为 `macos-arm64.dmg`（Apple 芯片）和 `macos-amd64.dmg`（Intel 处理器）
- `build-…` 开头的为开发预览版（预发布）

## 安装说明

> [!IMPORTANT]
> Android 包名仍为 `com.follow.clash`，但签名与官方版不同。**请先卸载官方 FlClash 再安装本版本**（卸载前可在应用内备份配置）。

- 安装包同时带有 v1 / v2 / v3 签名
- 在 Android 上，Tailscale 节点运行在 FlClash 内部；Android 同一时间只允许一个 VPN，因此无法与官方 Tailscale 应用同时开启 VPN

## 构建与发布

发布由 [`.github/workflows/release.yaml`](.github/workflows/release.yaml) 完成，产物发布到本仓库的 GitHub Releases：

- **推送 `v*` 标签**：构建全部平台并发布正式版（标签含 `-` 时为预发布）
- **手动运行（workflow_dispatch）**：
  - `desktop`：是否同时构建 Windows / Linux / macOS
  - `version`：覆盖版本号，例如 `0.9.6` 或 `0.9.6+2026101606`，留空则使用 `pubspec.yaml`
- Android 签名使用仓库密钥 `KEYSTORE`、`KEY_ALIAS`、`STORE_PASSWORD`、`KEY_PASSWORD`；APK 会重新签名，并在上传前校验 v1 / v2 / v3 签名
- **发布说明**由 `dart run tool/changelog.dart render fork-release` 从 [`changelog.json`](changelog.json) 生成。打标签前：修改 `pubspec.yaml` 版本号，运行 `dart run tool/changelog.dart release --version X.Y.Z`，按需把新条目改写成中文，然后把 `CHANGELOG.md` 和 `changelog.json` 与版本号一起提交。如果推送标签前漏了这一步，工作流会根据上一个标签以来的约定式提交自动生成说明

本地构建方法与上游相同：

```sh
git clone --recursive https://github.com/KarenGarcia484134/FlClash.git
cd FlClash
dart setup.dart android   # 或 windows / linux / macos
```

## 内核补丁

`core/Clash.Meta` 子模块指向 [KarenGarcia484134/Clash.Meta](https://github.com/KarenGarcia484134/Clash.Meta) 的 `FlClash-patched` 分支，即上游 `FlClash` 分支加上少量补丁。补丁只**新增**文件（读取 Tailscale 节点状态、在重载配置时保留同一个节点），不修改上游文件，详见 [`core/PATCHES.md`](core/PATCHES.md)。

## 同步上游

应用代码：

```sh
git remote add upstream https://github.com/chen08209/FlClash.git
git fetch upstream --tags
git merge v<上游版本>   # 优先合并最新的发布标签而不是 main
```

当前已同步到上游 **v0.9.1**（本仓库以 0.9.12 发布）。

内核子模块：按 [`core/PATCHES.md`](core/PATCHES.md) 中的步骤，把 `FlClash-patched` 变基到上游最新的 `FlClash` 分支并推送，再提交子模块的新指针。

## 许可证

与上游相同，使用 [GPL-3.0](LICENSE) 许可证。原项目版权归 [chen08209/FlClash](https://github.com/chen08209/FlClash) 的作者所有，本仓库的修改同样以 GPL-3.0 发布。
