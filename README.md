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
- Dashboard card: a "Custom routing" card shows how many entries the current profile uses and opens the management list in one tap (where each entry can be ticked for the current profile); added once by default for new and existing users, and stays removed if you remove it
- Outbound latency: the outbound picker shows each node's delay (green / yellow / red / timeout, shared with the proxies page), with test all, tap or **long-press** a node to test it (long-press does not select), sort by latency and hide timeouts; groups show their current node and its delay; each entry in the routing list shows its outbound's delay, tap or long-press to retest

### Dialer proxy

- On the Proxies page, **long-press** a plain node to open its (extensible) menu and choose "Set dialer proxy": pick another node or group (with latency badges), or "None"
- Saved per profile, by node name, and injected as `dialer-proxy` when the final config is generated; it overrides a dialer-proxy from the subscription, which is shown too
- Choices that would loop (the node itself, A→B→A, groups containing the node) are excluded; if the node or target disappears after a subscription update the setting is skipped and flagged in the UI
- Nodes with a dialer proxy show "via XX"; delay tests measure the whole chain
- "Advanced config → Dialer proxy" lists, edits, deletes or clears them all; applies to nodes defined in the profile itself (not proxy-provider nodes)

### Auto-apply and core restart

- Editing custom routings (edits, enable switches, per-profile ticks including the dashboard card list and the Extend page, reorder, copy, delete), dialer proxies or Tailscale settings reapplies the current profile automatically while the core runs (debounced), with an "Applied" toast or the failure reason
- Existing connections keep their old route by default; turn on "Close connections on apply" in General to make new rules hit every connection at once
- New "Restart core" dashboard card: confirms, then restarts and shows progress and the result; added once by default for new and existing users

### Multi-port

- "Advanced config → Multi-port": extra local proxy ports (mihomo `listeners`) of type mixed / socks / http, plus redir / tproxy on desktop Linux (hidden elsewhere)
- Each has a name, enable switch, listen address (127.0.0.1 by default, 0.0.0.0 for LAN with a warning), port, UDP and username/password users
- Outbound: follow rules (default), a sub-rule of the profile, or a fixed node / group / DIRECT from the outbound picker with latency
- Port range and clashes with the app's own ports and other listeners are checked; a profile listener with the same name or port gives way to yours; a missing outbound or sub-rule is skipped and flagged
- App-wide (not per profile) with a master switch; changes reapply automatically; the list shows whether each is listening, and long-press copies its address (e.g. socks5://127.0.0.1:7891)

### Interface style

- Settings → Theme → "Interface style": **Classic** (default, the Material look of 0.9.11) or **New** (upstream's 0.9.1 redesign: iOS type scale, layered surfaces, iOS color palette, Liquid Glass); switching applies immediately
- Each style keeps its own theme colors: Classic keeps the colors and Material color scheme you had before, New uses the iOS palette and color styles; Liquid Glass is only offered in New
- The redesigned screens of 0.9.1 (dashboard around the current exit, proxy group cards, connection / request tables) are kept in both styles; the switch changes the theme, not the layouts

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
- **Release notes** are generated from [`changelog.json`](changelog.json) by `dart run tool/changelog.dart render fork-release`. Before tagging, bump `pubspec.yaml`, run `dart run tool/changelog.dart release --version X.Y.Z`, optionally rewrite the new entries' wording (in Chinese), and commit `CHANGELOG.md` and `changelog.json` with the bump. If a tag is pushed without this step, the workflow builds its notes from the conventional commits since the previous tag instead

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
git fetch upstream --tags
git merge v<upstream release>   # prefer the latest release tag over main
```

The fork is currently synced to upstream **v0.9.1** (released here as 0.9.12).

Core submodule: follow [`core/PATCHES.md`](core/PATCHES.md) to rebase `FlClash-patched` onto upstream's latest `FlClash` branch, push it, then commit the new submodule pointer.

## License

Same as upstream: [GPL-3.0](LICENSE). The original project is copyright the authors of [chen08209/FlClash](https://github.com/chen08209/FlClash); the changes in this repository are released under GPL-3.0 as well.
