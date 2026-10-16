package core

import (
	"strings"

	"github.com/metacubex/mihomo/log"
)

// tsnet reports its interactive login URL and login result only at info
// level, while the app defaults the Core to error; the app reads these two
// lines to drive its Tailscale login screen, so they pass at any level.
func isTailscaleAuthEvent(event log.Event) bool {
	payload := event.Payload
	if !strings.HasPrefix(payload, "[Tailscale](") {
		return false
	}
	return strings.Contains(payload, "or go to: ") ||
		strings.Contains(payload, "AuthLoop: state is ")
}
