//go:build !with_gvisor || no_tailscale

package core

import (
	"context"
	"errors"
)

func tailscaleStatus(context.Context, TailscaleStatusParams) (TailscaleStatusResult, error) {
	return TailscaleStatusResult{}, errors.New("tailscale is not built in")
}

func reconcileTailscale() {}

func notifyTailscaleNetworkChange() {}

func retireTailscaleNode(string) {}

func tailscalePing(_ context.Context, _ string, target string) TailscalePingResult {
	return TailscalePingResult{Target: target, LatencyMs: -1, Error: "tailscale is not built in"}
}
