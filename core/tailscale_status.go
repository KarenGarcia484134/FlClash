package core

import (
	"context"
	"errors"
	"time"
)

type TailscaleStatusParams struct {
	Name  string `json:"name"`
	Start bool   `json:"start"`
	Reset bool   `json:"reset"`
	// Wait follows a started node until it settles, so a connect does not
	// report the passing NeedsLogin a node with a saved key goes through.
	Wait bool `json:"wait"`
	// Rebind reports a network change to the node first.
	Rebind bool `json:"rebind"`
}

type TailscalePingParams struct {
	Name    string   `json:"name"`
	Targets []string `json:"targets"`
}

type TailscalePingResult struct {
	Target string `json:"target"`
	// LatencyMs is -1 when the ping failed.
	LatencyMs int    `json:"latencyMs"`
	Endpoint  string `json:"endpoint,omitempty"`
	DERPID    int    `json:"derpRegionId,omitempty"`
	DERPCode  string `json:"derpRegionCode,omitempty"`
	PeerRelay string `json:"peerRelay,omitempty"`
	Error     string `json:"error,omitempty"`
}

type TailscalePeer struct {
	ID             string   `json:"id"`
	HostName       string   `json:"hostName"`
	DNSName        string   `json:"dnsName"`
	OS             string   `json:"os"`
	IPs            []string `json:"ips"`
	Online         bool     `json:"online"`
	ExitNode       bool     `json:"exitNode"`
	ExitNodeOption bool     `json:"exitNodeOption"`
	LastSeen       string   `json:"lastSeen,omitempty"`
}

type TailscaleStatusResult struct {
	Started        bool            `json:"started"`
	BackendState   string          `json:"backendState"`
	AuthURL        string          `json:"authUrl,omitempty"`
	Health         []string        `json:"health,omitempty"`
	MagicDNSSuffix string          `json:"magicDnsSuffix"`
	Self           *TailscalePeer  `json:"self"`
	Peers          []TailscalePeer `json:"peers"`
	Error          string          `json:"error,omitempty"`
	// DialerProxy is what the running node's own traffic really goes
	// through; empty means directly.
	DialerProxy string `json:"dialerProxy,omitempty"`
	// DERPRoutes tells, by DERP region code, whether the node's connection
	// to that relay went "direct" or through the "proxy".
	DERPRoutes map[string]string `json:"derpRoutes,omitempty"`
	// ExitNodeError is why the configured exit node could not be set.
	ExitNodeError string `json:"exitNodeError,omitempty"`
}

var errTailscaleNodeMissing = errors.New("tailscale node not found")

const (
	tailscaleStatusTimeout = 15 * time.Second
	tailscaleSettleTimeout = 10 * time.Second
	tailscalePingTimeout   = 5 * time.Second
	tailscalePingParallel  = 8
)

func handleTailscalePing(params TailscalePingParams) []TailscalePingResult {
	results := make([]TailscalePingResult, len(params.Targets))
	sem := make(chan struct{}, tailscalePingParallel)
	done := make(chan struct{})
	for i, target := range params.Targets {
		go func() {
			sem <- struct{}{}
			defer func() { <-sem; done <- struct{}{} }()
			ctx, cancel := context.WithTimeout(context.Background(), tailscalePingTimeout)
			defer cancel()
			results[i] = tailscalePing(ctx, params.Name, target)
		}()
	}
	for range params.Targets {
		<-done
	}
	return results
}

func handleTailscaleStatus(params TailscaleStatusParams) TailscaleStatusResult {
	ctx, cancel := context.WithTimeout(context.Background(), tailscaleStatusTimeout)
	defer cancel()
	if params.Reset {
		retireTailscaleNode(params.Name)
		return TailscaleStatusResult{Peers: []TailscalePeer{}}
	}
	result, err := tailscaleStatus(ctx, params)
	if err != nil {
		result.Error = err.Error()
	}
	if result.Peers == nil {
		result.Peers = []TailscalePeer{}
	}
	return result
}
