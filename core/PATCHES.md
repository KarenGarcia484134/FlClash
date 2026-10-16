# mihomo patches

`core/Clash.Meta` points at the fork
[KarenGarcia484134/Clash.Meta](https://github.com/KarenGarcia484134/Clash.Meta),
branch `FlClash-patched`: upstream `chen08209/Clash.Meta` branch `FlClash`
plus the commits below. Every patch only adds files, so a rebase onto a newer
upstream does not conflict.

| Commit | Files | Purpose |
| --- | --- | --- |
| feat(tailscale): expose node status for FlClash | `adapter/outbound/tailscale_status.go`, `tailscale_status_test.go` | Adds `Started`, `Start` and `Status` (tsnet `LocalClient().Status()`) on the tailscale outbound, used by the `tailscaleStatus` core method. |
| feat(tailscale): unwrap, compare and adopt nodes across reloads | same files | `UnwrapTailscale` (sees through the parser's auto-close wrapper), `SameConfig` and `Adopt`, which let `core/tailscale_status_ts.go` keep one running tsnet node across config applies instead of a new one per apply. |

## Syncing with upstream

```sh
cd core/Clash.Meta
git remote add upstream https://github.com/chen08209/Clash.Meta.git
git fetch upstream FlClash
git rebase upstream/FlClash
go test -tags with_gvisor ./adapter/outbound/ -run TestTailscaleStatus
git push --force-with-lease origin HEAD:FlClash-patched
cd ../.. && git add core/Clash.Meta && git commit -m "chore: sync mihomo"
```

If upstream renames the `server`, `serverStarted`, `option`,
`unregisterDNSResolver` or `ensureStarted` members of `Tailscale`, or
`autoCloseProxyAdapter`, only `tailscale_status.go` needs adjusting.
