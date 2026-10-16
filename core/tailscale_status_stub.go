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

func retireTailscaleNode(string) {}
