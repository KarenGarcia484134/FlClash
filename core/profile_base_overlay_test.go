package core

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"

	"go.yaml.in/yaml/v3"
)

// testdata/large_profile_overlay.yaml is what the host builds for
// testdata/large_profile.yaml (see test/common/large_profile_overlay_test.dart):
// dialer-proxy patches, a Tailscale node, a routing to a profile group,
// listeners on a profile group and sub-rule, and Tailscale DNS.

func TestProfileOutlineMatchesWhatTheHostInjectsAgainst(t *testing.T) {
	base, err := handleGetProfileBase("testdata/large_profile.yaml")
	if err != nil {
		t.Fatalf("handleGetProfileBase = %v", err)
	}
	want := ProfileOutline{
		Proxies: []map[string]any{
			{"name": "HK", "type": "socks5"},
			{"name": "JP", "type": "socks5", "dialer-proxy": "SG"},
			{"name": "SG", "type": "socks5"},
		},
		ProxyGroups: []map[string]any{
			{"name": "Auto", "type": "select", "proxies": []string{"JP", "SG"}},
		},
		SubRules: []string{"sub"},
	}
	if !reflect.DeepEqual(base.Outline, want) {
		t.Errorf("outline = %#v\nwant %#v", base.Outline, want)
	}
}

func mergedLargeProfile(t *testing.T) map[string]any {
	t.Helper()
	overlay, err := os.ReadFile("testdata/large_profile_overlay.yaml")
	if err != nil {
		t.Fatalf("read overlay: %v", err)
	}
	document, err := mergeProfileBase(&SetupBase{Path: "testdata/large_profile.yaml", Overlay: string(overlay)})
	if err != nil {
		t.Fatalf("mergeProfileBase = %v", err)
	}
	path, err := writeDocumentFile(t.TempDir(), "*.yaml", document)
	if err != nil {
		t.Fatalf("write merged: %v", err)
	}
	buf, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read merged: %v", err)
	}
	var merged map[string]any
	if err := yaml.Unmarshal(buf, &merged); err != nil {
		t.Fatalf("decode merged: %v", err)
	}
	return merged
}

func TestLargeProfileMergeKeepsEveryForkInjection(t *testing.T) {
	merged := mergedLargeProfile(t)

	proxies := map[string]map[string]any{}
	var order []string
	for _, item := range merged["proxies"].([]any) {
		proxy := item.(map[string]any)
		name := proxy["name"].(string)
		proxies[name] = proxy
		order = append(order, name)
	}
	if want := []string{"Tailscale", "HK", "JP", "SG"}; !reflect.DeepEqual(order, want) {
		t.Errorf("proxies = %v, want %v", order, want)
	}
	if got := proxies["HK"]["dialer-proxy"]; got != "Auto" {
		t.Errorf("HK dialer-proxy = %v, want the user's Auto", got)
	}
	if got := proxies["HK"]["port"]; got != 1081 {
		t.Errorf("HK lost its own keys: port = %v", got)
	}
	if got, ok := proxies["JP"]["dialer-proxy"]; ok && got != "" {
		t.Errorf("JP dialer-proxy = %v, want it cleared", got)
	}
	if got := proxies["SG"]["dialer-proxy"]; got != nil {
		t.Errorf("SG gained a dialer-proxy: %v", got)
	}
	if ts := proxies["Tailscale"]; ts["type"] != "tailscale" || ts["dialer-proxy"] != "HK" {
		t.Errorf("Tailscale node = %v, want type tailscale via HK", ts)
	}

	rules := merged["rules"].([]any)
	wantRules := []any{
		"IP-CIDR,100.64.0.0/10,Tailscale,no-resolve",
		"IP-CIDR6,fd7a:115c:a1e9::/48,Tailscale,no-resolve",
		"DOMAIN-SUFFIX,ts.net,Tailscale",
		"DOMAIN-SUFFIX,routed.example,Auto",
		"DOMAIN-SUFFIX,example.com,Auto",
		"MATCH,DIRECT",
	}
	if !reflect.DeepEqual(rules, wantRules) {
		t.Errorf("rules = %v\nwant %v", rules, wantRules)
	}

	groups := merged["proxy-groups"].([]any)
	if len(groups) != 1 || groups[0].(map[string]any)["name"] != "Auto" {
		t.Errorf("proxy-groups = %v, want the profile's", groups)
	}
	if sub := merged["sub-rules"].(map[string]any); sub["sub"] == nil {
		t.Errorf("sub-rules = %v, want the profile's", sub)
	}

	var listeners []string
	for _, item := range merged["listeners"].([]any) {
		listener := item.(map[string]any)
		listeners = append(listeners, listener["name"].(string))
		switch listener["name"] {
		case "via-auto":
			if listener["proxy"] != "Auto" {
				t.Errorf("via-auto proxy = %v", listener["proxy"])
			}
		case "via-sub":
			if listener["rule"] != "sub" {
				t.Errorf("via-sub rule = %v", listener["rule"])
			}
		}
	}
	if want := []string{"own", "via-auto", "via-sub"}; !reflect.DeepEqual(listeners, want) {
		t.Errorf("listeners = %v, want %v", listeners, want)
	}

	policy := merged["dns"].(map[string]any)["nameserver-policy"].(map[string]any)
	if policy["+.ts.net"] != "tailscale://Tailscale" {
		t.Errorf("nameserver-policy = %v", policy)
	}
}

func TestLargeProfileMergedConfigLoads(t *testing.T) {
	if !tailscaleBuilt {
		t.Skip("parsing the Tailscale node needs the with_gvisor build tag")
	}
	overlay, err := os.ReadFile("testdata/large_profile_overlay.yaml")
	if err != nil {
		t.Fatalf("read overlay: %v", err)
	}
	cfg, err := loadConfigWithBase(
		&SetupBase{Path: "testdata/large_profile.yaml", Overlay: string(overlay)},
		filepath.Join(t.TempDir(), "config.yaml"),
	)
	if err != nil {
		t.Fatalf("loadConfigWithBase = %v", err)
	}
	for _, name := range []string{"Tailscale", "HK", "JP", "SG", "Auto"} {
		if cfg.Proxies[name] == nil {
			t.Errorf("proxy %s is missing", name)
		}
	}
	if len(cfg.SubRules["sub"]) != 1 {
		t.Errorf("sub-rules = %v", cfg.SubRules)
	}
	for _, name := range []string{"own", "via-auto", "via-sub"} {
		if cfg.Listeners[name] == nil {
			t.Errorf("listener %s is missing", name)
		}
	}
}
