//go:build with_gvisor && !no_tailscale

package core

import (
	"context"
	"strings"

	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/adapter/outbound"
	C "github.com/metacubex/mihomo/constant"
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

func parseTestTailscale(t *testing.T, authKey string) C.Proxy {
	t.Helper()
	proxy, err := adapter.ParseProxy(map[string]any{
		"name":      "Tailscale",
		"type":      "tailscale",
		"state-dir": "tailscale/reconcile",
		"auth-key":  authKey,
	})
	if err != nil {
		t.Fatalf("parse tailscale: %v", err)
	}
	return proxy
}

func TestReconcileKeepsTheRunningNode(t *testing.T) {
	C.SetHomeDir(t.TempDir())
	liveTailscale = map[string]C.Proxy{}
	t.Cleanup(func() { liveTailscale = map[string]C.Proxy{} })

	first := parseTestTailscale(t, "k")
	if _, changed := reconcileTailscaleNodes(map[string]C.Proxy{"Tailscale": first}); changed {
		t.Fatal("the first apply has nothing to keep")
	}
	second := parseTestTailscale(t, "k")
	next, changed := reconcileTailscaleNodes(map[string]C.Proxy{"Tailscale": second})
	if !changed || next["Tailscale"] != first {
		t.Fatal("an unchanged node must survive the reload")
	}
	dropped, _ := outbound.UnwrapTailscale(second.Adapter())
	if err := dropped.Start(context.Background()); err == nil || !strings.Contains(err.Error(), "closed") {
		t.Fatalf("the duplicate built by the reload must be closed, got %v", err)
	}
	node, _ := outbound.UnwrapTailscale(first.Adapter())

	third := parseTestTailscale(t, "changed")
	next, changed = reconcileTailscaleNodes(map[string]C.Proxy{"Tailscale": third})
	if changed || next["Tailscale"] != third {
		t.Fatal("changed options must take the new node")
	}
	if err := node.Start(context.Background()); err == nil || !strings.Contains(err.Error(), "closed") {
		t.Fatalf("the replaced node must be closed, got %v", err)
	}

	retireTailscaleNode("Tailscale")
	if len(liveTailscale) != 0 {
		t.Fatal("a reset must forget the node")
	}
	fourth := parseTestTailscale(t, "changed")
	t.Cleanup(func() { _ = fourth.Adapter().Close() })
	if next, _ := reconcileTailscaleNodes(map[string]C.Proxy{"Tailscale": fourth}); next["Tailscale"] != fourth {
		t.Fatal("after a reset the next apply must use its fresh node")
	}
}

func TestFindTailscaleNodeUnwraps(t *testing.T) {
	C.SetHomeDir(t.TempDir())
	proxy := parseTestTailscale(t, "")
	t.Cleanup(func() { _ = proxy.Adapter().Close() })
	if _, ok := findTailscaleNode(map[string]C.Proxy{"Tailscale": proxy}, "Tailscale"); !ok {
		t.Fatal("the parsed node must be found through its wrapper")
	}
}
