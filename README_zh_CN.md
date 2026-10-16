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

- `v*` 标签为正式版，包含 Android、Windows、macOS、Linux 安装包
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
git fetch upstream
git merge upstream/main
```

内核子模块：按 [`core/PATCHES.md`](core/PATCHES.md) 中的步骤，把 `FlClash-patched` 变基到上游最新的 `FlClash` 分支并推送，再提交子模块的新指针。

## 许可证

与上游相同，使用 [GPL-3.0](LICENSE) 许可证。原项目版权归 [chen08209/FlClash](https://github.com/chen08209/FlClash) 的作者所有，本仓库的修改同样以 GPL-3.0 发布。
