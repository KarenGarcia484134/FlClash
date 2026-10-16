//go:build with_gvisor && !no_tailscale

package core

import (
	"net/netip"
	"testing"

	"github.com/metacubex/tailscale/ipn/ipnstate"
	"github.com/metacubex/tailscale/types/key"
)

func TestConvertTailscaleStatus(t *testing.T) {
	status := &ipnstate.Status{
		BackendState:   "Running",
		MagicDNSSuffix: "tail.ts.net",
		TailscaleIPs:   []netip.Addr{netip.MustParseAddr("100.64.0.1")},
		Self:           &ipnstate.PeerStatus{HostName: "me", Online: true},
		Peer: map[key.NodePublic]*ipnstate.PeerStatus{
			key.NewNode().Public(): {HostName: "zeta", Online: true, ExitNodeOption: true,
				TailscaleIPs: []netip.Addr{netip.MustParseAddr("100.64.0.9"), netip.MustParseAddr("fd7a:115c:a1e9::9")}},
			key.NewNode().Public(): {HostName: "alpha", OS: "linux"},
		},
	}
	result := convertTailscaleStatus(status)
	if !result.Started || result.BackendState != "Running" || result.MagicDNSSuffix != "tail.ts.net" {
		t.Fatalf("unexpected header: %+v", result)
	}
	if result.Self == nil || len(result.Self.IPs) != 1 || result.Self.IPs[0] != "100.64.0.1" {
		t.Fatalf("self IPs should fall back to the node IPs: %+v", result.Self)
	}
	if len(result.Peers) != 2 || result.Peers[0].HostName != "zeta" || result.Peers[1].HostName != "alpha" {
		t.Fatalf("online peers should sort first: %+v", result.Peers)
	}
	if !result.Peers[0].ExitNodeOption || len(result.Peers[0].IPs) != 2 {
		t.Fatalf("peer fields lost: %+v", result.Peers[0])
	}
}

func TestTailscaleStatusMissingNode(t *testing.T) {
	result := handleTailscaleStatus(TailscaleStatusParams{Name: "absent"})
	if result.Error == "" || result.Started || result.Peers == nil {
		t.Fatalf("missing node should report an error: %+v", result)
	}
}
