package core

import (
	"context"
	"errors"
	"time"
)

type TailscaleStatusParams struct {
	Name  string `json:"name"`
	Start bool   `json:"start"`
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
	MagicDNSSuffix string          `json:"magicDnsSuffix"`
	Self           *TailscalePeer  `json:"self"`
	Peers          []TailscalePeer `json:"peers"`
	Error          string          `json:"error,omitempty"`
}

var errTailscaleNodeMissing = errors.New("tailscale node not found")

const tailscaleStatusTimeout = 15 * time.Second

func handleTailscaleStatus(params TailscaleStatusParams) TailscaleStatusResult {
	ctx, cancel := context.WithTimeout(context.Background(), tailscaleStatusTimeout)
	defer cancel()
	result, err := tailscaleStatus(ctx, params)
	if err != nil {
		result.Error = err.Error()
	}
	if result.Peers == nil {
		result.Peers = []TailscalePeer{}
	}
	return result
}
