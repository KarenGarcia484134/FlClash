<div align="center">

<img src="assets/images/icon.png" alt="FlClash" width="88">

# FlClash (fork)

**English** · [简体中文](README_zh_CN.md)

Based on [chen08209/FlClash](https://github.com/chen08209/FlClash). Thanks to the original author.

[Download](#download) · [Features](#features) · [Installation](#installation) · [Build & release](#build--release) · [Patched core](#patched-core) · [Syncing with upstream](#syncing-with-upstream) · [License](#license)

</div>

## Features

### Custom routing

- Under Advanced config → Custom routing, enabled per profile under Profile → Extend
- Visual rule editor: domain suffix / keyword / exact domain, IP-CIDR / IP-CIDR6, GEOSITE, GEOIP, process name, rule sets and more, combined with OR / AND
- A separate outbound per entry: a policy (DIRECT / REJECT …), a group, a single node or the Tailscale node; a missing outbound is marked red and skipped when the config is generated
- Injected **in front of** the profile's rules in list order; drag to reorder, toggle, and duplicate (the copy is named "name copy")

### Extend tab layout

- Custom routing is its own tab, placed before Standard / Script and selected by default
- Switching tabs does not change the profile's mode; the active mode is marked

### Visual Tailscale

- Under Advanced config → Tailscale: hostname, auth key, control server (Headscale supported), exit node, tailnet DNS suffixes, accept routes, ephemeral, UDP
- Two ways to log in: an auth key, or a browser URL (copy / open in browser); shows the login status and the real error, telling "cannot reach the control server" apart from "auth key rejected"
- **Connection proxy**: Tailscale's own traffic to the control server, DERP relays and peers can go through a chosen group or node, for networks that cannot reach the control server directly
- Device list: this device's tailnet IPs and every peer's online status, OS and exit-node capability; search and copy IPs
- One-tap "Add to custom routing": a peer's MagicDNS name and its IPv4 / IPv6 addresses in one OR rule
- Injects front rules for 100.64.0.0/10, fd7a:115c:a1e9::/48 and ts.net plus MagicDNS resolution; the node's name never clashes with a profile's own proxies
- The login is kept in the app's data directory and the same node survives config reloads; "Log out & reset" clears it

## Download

Get builds from this repository's [Releases](https://github.com/KarenGarcia484134/FlClash/releases):

- `v*` tags are stable releases with Android, Windows, macOS and Linux packages
- `build-…` releases are development previews (pre-releases)

## Installation

> [!IMPORTANT]
> The Android package is still `com.follow.clash` but signed with a different key. **Uninstall the official FlClash before installing this one** (back up your settings in the app first).

- APKs carry v1 / v2 / v3 signatures
- On Android the Tailscale node runs inside FlClash; Android allows one VPN at a time, so it cannot run alongside the official Tailscale app's VPN

## Build & release

Releases are built by [`.github/workflows/release.yaml`](.github/workflows/release.yaml) and published to this repository's GitHub Releases:

- **Push a `v*` tag**: builds every platform and publishes a stable release (a tag containing `-` becomes a pre-release)
- **Run it manually (workflow_dispatch)**:
  - `desktop`: also build Windows / Linux / macOS
  - `version`: version override such as `0.9.6` or `0.9.6+2026101606`; blank uses `pubspec.yaml`
- Android signing uses the repository secrets `KEYSTORE`, `KEY_ALIAS`, `STORE_PASSWORD` and `KEY_PASSWORD`; APKs are re-signed and their v1 / v2 / v3 signatures verified before upload

Local builds work as upstream:

```sh
git clone --recursive https://github.com/KarenGarcia484134/FlClash.git
cd FlClash
dart setup.dart android   # or windows / linux / macos
```

## Patched core

The `core/Clash.Meta` submodule points at the `FlClash-patched` branch of [KarenGarcia484134/Clash.Meta](https://github.com/KarenGarcia484134/Clash.Meta): upstream's `FlClash` branch plus a few patches. The patches only **add** files (reading Tailscale node status, keeping one node across config reloads) and change no upstream file. See [`core/PATCHES.md`](core/PATCHES.md).

## Syncing with upstream

App code:

```sh
git remote add upstream https://github.com/chen08209/FlClash.git
git fetch upstream
git merge upstream/main
```

Core submodule: follow [`core/PATCHES.md`](core/PATCHES.md) to rebase `FlClash-patched` onto upstream's latest `FlClash` branch, push it, then commit the new submodule pointer.

## License

Same as upstream: [GPL-3.0](LICENSE). The original project is copyright the authors of [chen08209/FlClash](https://github.com/chen08209/FlClash); the changes in this repository are released under GPL-3.0 as well.
