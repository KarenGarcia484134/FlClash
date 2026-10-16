//go:build with_gvisor && !no_tailscale

package core

import (
	"context"
	"errors"
	"maps"
	"sort"
	"sync"
	"time"

	"github.com/metacubex/mihomo/adapter/outbound"
	"github.com/metacubex/mihomo/adapter/outboundgroup"
	C "github.com/metacubex/mihomo/constant"
	"github.com/metacubex/mihomo/tunnel"
	"github.com/metacubex/tailscale/ipn/ipnstate"
)

func findTailscaleNode(proxies map[string]C.Proxy, name string) (*outbound.Tailscale, bool) {
	if proxy, ok := proxies[name]; ok && proxy != nil {
		if node, ok := outbound.UnwrapTailscale(proxy.Adapter()); ok {
			return node, true
		}
	}
	return nil, false
}

func tailscaleStatus(ctx context.Context, params TailscaleStatusParams) (TailscaleStatusResult, error) {
	node, ok := findTailscaleNode(tunnel.AllProxies(), params.Name)
	if !ok {
		return TailscaleStatusResult{}, errTailscaleNodeMissing
	}
	if params.Start && !node.Started() {
		if err := node.Start(ctx); err != nil {
			return TailscaleStatusResult{Started: node.Started()}, err
		}
	}
	status, err := node.Status(ctx)
	if errors.Is(err, outbound.ErrTailscaleNotStarted) {
		return TailscaleStatusResult{}, nil
	}
	if err != nil {
		return TailscaleStatusResult{Started: true}, err
	}
	return convertTailscaleStatus(status), nil
}

func convertTailscaleStatus(status *ipnstate.Status) TailscaleStatusResult {
	result := TailscaleStatusResult{
		Started:        true,
		BackendState:   status.BackendState,
		AuthURL:        status.AuthURL,
		Health:         status.Health,
		MagicDNSSuffix: status.MagicDNSSuffix,
	}
	if status.CurrentTailnet != nil && status.CurrentTailnet.MagicDNSSuffix != "" {
		result.MagicDNSSuffix = status.CurrentTailnet.MagicDNSSuffix
	}
	if status.Self != nil {
		self := convertTailscalePeer(status.Self)
		if len(self.IPs) == 0 {
			for _, ip := range status.TailscaleIPs {
				self.IPs = append(self.IPs, ip.String())
			}
		}
		result.Self = &self
	}
	for _, peer := range status.Peer {
		if peer != nil {
			result.Peers = append(result.Peers, convertTailscalePeer(peer))
		}
	}
	sort.SliceStable(result.Peers, func(i, j int) bool {
		a, b := result.Peers[i], result.Peers[j]
		if a.Online != b.Online {
			return a.Online
		}
		return a.HostName < b.HostName
	})
	return result
}

func convertTailscalePeer(peer *ipnstate.PeerStatus) TailscalePeer {
	item := TailscalePeer{
		ID:             string(peer.ID),
		HostName:       peer.HostName,
		DNSName:        peer.DNSName,
		OS:             peer.OS,
		Online:         peer.Online,
		ExitNode:       peer.ExitNode,
		ExitNodeOption: peer.ExitNodeOption,
		IPs:            []string{},
	}
	for _, ip := range peer.TailscaleIPs {
		item.IPs = append(item.IPs, ip.String())
	}
	if !peer.LastSeen.IsZero() {
		item.LastSeen = peer.LastSeen.UTC().Format(time.RFC3339)
	}
	return item
}

var (
	liveTailscaleMu sync.Mutex
	liveTailscale   = map[string]C.Proxy{}
)

func groupMembers(proxies map[string]C.Proxy) map[C.Proxy]bool {
	members := map[C.Proxy]bool{}
	for _, proxy := range proxies {
		if group, ok := proxy.Adapter().(outboundgroup.ProxyGroup); ok {
			for _, member := range group.Proxies() {
				members[member] = true
			}
		}
	}
	return members
}

// Every apply parses a fresh tailscale outbound, and mihomo never closes the
// one it replaces. Each would be its own tsnet node on the same state dir:
// a login started on one is lost when the next takes over, and the replaced
// ones keep running. Keep the running node when its options are unchanged,
// and close the ones that are really gone.
func reconcileTailscaleNodes(current map[string]C.Proxy) (map[string]C.Proxy, bool) {
	liveTailscaleMu.Lock()
	defer liveTailscaleMu.Unlock()
	var next map[string]C.Proxy
	var members map[C.Proxy]bool
	kept := map[string]C.Proxy{}
	for name, proxy := range current {
		node, ok := outbound.UnwrapTailscale(proxy.Adapter())
		if !ok {
			continue
		}
		kept[name] = proxy
		old, ok := liveTailscale[name]
		if !ok || old == proxy {
			continue
		}
		oldNode, ok := outbound.UnwrapTailscale(old.Adapter())
		if !ok || !oldNode.SameConfig(node) {
			continue
		}
		if members == nil {
			members = groupMembers(current)
		}
		if members[proxy] {
			continue
		}
		_ = proxy.Adapter().Close()
		oldNode.Adopt()
		if next == nil {
			next = maps.Clone(current)
		}
		next[name] = old
		kept[name] = old
	}
	for name, old := range liveTailscale {
		if kept[name] != old {
			_ = old.Adapter().Close()
		}
	}
	liveTailscale = kept
	if next == nil {
		return current, false
	}
	return next, true
}

func reconcileTailscale() {
	if next, changed := reconcileTailscaleNodes(tunnel.Proxies()); changed {
		tunnel.UpdateProxies(next, tunnel.Providers())
	}
}

// retireTailscaleNode closes the running node so the next apply starts a
// fresh one, which a reset needs after it wipes the state dir.
func retireTailscaleNode(name string) {
	liveTailscaleMu.Lock()
	defer liveTailscaleMu.Unlock()
	if proxy, ok := liveTailscale[name]; ok {
		_ = proxy.Adapter().Close()
		delete(liveTailscale, name)
	}
}
