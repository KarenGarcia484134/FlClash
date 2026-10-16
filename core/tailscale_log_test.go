package core

import (
	"testing"

	"github.com/metacubex/mihomo/log"
)

func TestIsTailscaleAuthEvent(t *testing.T) {
	cases := map[string]bool{
		"[Tailscale](Tailscale) To start this tsnet server, restart with TS_AUTHKEY set, or go to: https://login.tailscale.com/a/1": true,
		"[Tailscale](Tailscale) AuthLoop: state is Running; done":                                                                   true,
		"[Tailscale](Tailscale) tsnet starting with hostname":                                                                       false,
		"[TCP] dial go to: x": false,
	}
	for payload, want := range cases {
		if got := isTailscaleAuthEvent(log.Event{LogLevel: log.INFO, Payload: payload}); got != want {
			t.Errorf("%q: got %v, want %v", payload, got, want)
		}
	}
}
