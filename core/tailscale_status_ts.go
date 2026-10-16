//go:build with_gvisor && !no_tailscale

package core

import (
	"context"
	"errors"
	"sort"
	"time"

	"github.com/metacubex/mihomo/adapter/outbound"
	"github.com/metacubex/mihomo/tunnel"
	"github.com/metacubex/tailscale/ipn/ipnstate"
)

func tailscaleStatus(ctx context.Context, params TailscaleStatusParams) (TailscaleStatusResult, error) {
	proxy, ok := tunnel.AllProxies()[params.Name]
	if !ok || proxy == nil {
		return TailscaleStatusResult{}, errTailscaleNodeMissing
	}
	node, ok := proxy.Adapter().(*outbound.Tailscale)
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
