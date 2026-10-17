package core

import (
	"bufio"
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/metacubex/mihomo/component/age"
	"github.com/metacubex/mihomo/config"
	"go.yaml.in/yaml/v3"
)

// What makes a profile large stays in the Core; the overlay the host sends
// back replaces every other section. Proxies are merged so host-injected
// nodes (Tailscale) survive next to the profile's list.
var profileBaseSections = []string{"proxies", "proxy-groups", "sub-rules"}

func handleGetProfileBase(path string) (*ProfileBase, error) {
	defer scheduleLoadMemoryRelease()
	buf, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	digest := sha256.Sum256(buf)
	raw, err := unmarshalRawConfig(buf)
	if err != nil {
		return nil, err
	}
	base := &ProfileBase{
		Digest:      hex.EncodeToString(digest[:]),
		MatchRules:  []string{},
		Proxies:     len(raw.Proxy),
		ProxyGroups: len(raw.ProxyGroup),
		Rules:       len(raw.Rule),
	}
	for _, rule := range raw.Rule {
		if isMatchRule(rule) {
			base.MatchRules = append(base.MatchRules, rule)
		}
	}
	base.Outline = outlineOf(raw)
	raw.Proxy, raw.ProxyGroup, raw.Rule, raw.SubRules = nil, nil, nil, nil
	base.Config = raw
	return base, nil
}

func outlineOf(raw *config.RawConfig) ProfileOutline {
	outline := ProfileOutline{
		Proxies:     make([]map[string]any, 0, len(raw.Proxy)),
		ProxyGroups: make([]map[string]any, 0, len(raw.ProxyGroup)),
		SubRules:    make([]string, 0, len(raw.SubRules)),
	}
	for _, proxy := range raw.Proxy {
		name, _ := proxy["name"].(string)
		if name == "" {
			continue
		}
		item := map[string]any{"name": name, "type": proxy["type"]}
		if via, ok := proxy["dialer-proxy"].(string); ok && via != "" {
			item["dialer-proxy"] = via
		}
		outline.Proxies = append(outline.Proxies, item)
	}
	for _, group := range raw.ProxyGroup {
		name, _ := group["name"].(string)
		if name == "" {
			continue
		}
		members := []string{}
		if list, ok := group["proxies"].([]any); ok {
			for _, member := range list {
				if text, ok := member.(string); ok {
					members = append(members, text)
				}
			}
		}
		outline.ProxyGroups = append(outline.ProxyGroups, map[string]any{
			"name": name, "type": group["type"], "proxies": members,
		})
	}
	for name := range raw.SubRules {
		outline.SubRules = append(outline.SubRules, name)
	}
	sort.Strings(outline.SubRules)
	return outline
}

func handleGetProfileOutbounds(path string) (*ProfileOutbounds, error) {
	defer scheduleLoadMemoryRelease()
	buf, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	raw, err := unmarshalRawConfig(buf)
	if err != nil {
		return nil, err
	}
	subRules := make(map[string][]string, len(raw.SubRules))
	for name := range raw.SubRules {
		subRules[name] = []string{}
	}
	return &ProfileOutbounds{
		Proxies:     outboundsOf(raw.Proxy),
		ProxyGroups: outboundsOf(raw.ProxyGroup),
		SubRules:    subRules,
	}, nil
}

func outboundsOf(mappings []map[string]any) []ProfileOutbound {
	outbounds := make([]ProfileOutbound, 0, len(mappings))
	for _, mapping := range mappings {
		name, _ := mapping["name"].(string)
		kind, _ := mapping["type"].(string)
		outbounds = append(outbounds, ProfileOutbound{Name: name, Type: kind})
	}
	return outbounds
}

// The merged config goes to the spill directory, so the host reads it as text
// and never decodes it.
func handleBuildProfile(base *SetupBase) (string, error) {
	defer scheduleLoadMemoryRelease()
	document, err := mergeProfileBase(base)
	if err != nil {
		return "", err
	}
	dir, err := makeSpilledResponseDir()
	if err != nil {
		return "", err
	}
	path, err := writeDocumentFile(dir, "*.yaml", document)
	if err != nil {
		return "", err
	}
	scheduleReclaimOwnership()
	return path, nil
}

// Mirrors Rule.parse in Dart, which reads the type from the first field.
func isMatchRule(rule string) bool {
	kind, _, _ := strings.Cut(rule, ",")
	return strings.EqualFold(strings.TrimSpace(kind), "MATCH")
}

func loadConfigWithBase(base *SetupBase, configPath string) (*config.Config, error) {
	document, err := mergeProfileBase(base)
	if err != nil {
		return nil, err
	}
	raw := config.DefaultRawConfig()
	if err := document.Decode(raw); err != nil {
		return nil, err
	}
	if err := writeConfigDocument(configPath, document); err != nil {
		return nil, err
	}
	cfg, err := config.ParseRawConfig(raw)
	if err != nil {
		return nil, err
	}
	return withPlatformLimits(cfg), nil
}

func mergeProfileBase(base *SetupBase) (*yaml.Node, error) {
	buf, err := os.ReadFile(base.Path)
	if err != nil {
		return nil, err
	}
	if buf, err = age.DecryptBytes(buf); err != nil {
		return nil, fmt.Errorf("decrypt config error: %w", err)
	}
	retag := bytes.Contains(buf, []byte("short-id"))
	var profileDocument, overlayDocument yaml.Node
	if err := yaml.Unmarshal(buf, &profileDocument); err != nil {
		return nil, err
	}
	if err := yaml.Unmarshal([]byte(base.Overlay), &overlayDocument); err != nil {
		return nil, err
	}
	profile, err := documentMapping(&profileDocument)
	if err != nil {
		return nil, err
	}
	root, err := documentMapping(&overlayDocument)
	if err != nil {
		return nil, err
	}
	for _, key := range profileBaseSections {
		switch key {
		case "proxies":
			// The host may inject a few proxies of its own (Tailscale) into the
			// overlay; keep those on top of the profile's list, which stays in
			// the Core so a large subscription never crosses the bridge.
			if merged := mergeOverlayProxies(mappingValue(profile, key), mappingValue(root, key)); merged != nil {
				setMappingValue(root, key, merged)
			}
		default:
			if value := mappingValue(profile, key); value != nil {
				setMappingValue(root, key, value)
			}
		}
	}
	rules, err := appendRules(mappingValue(root, "rules"), mappingValue(profile, "rules"))
	if err != nil {
		return nil, err
	}
	if rules != nil {
		setMappingValue(root, "rules", rules)
	}
	if retag {
		retagShortIDs(root)
	}
	return &yaml.Node{Kind: yaml.DocumentNode, Content: []*yaml.Node{root}}, nil
}

func documentMapping(document *yaml.Node) (*yaml.Node, error) {
	node := document
	if node.Kind == yaml.DocumentNode && len(node.Content) > 0 {
		node = resolveAlias(node.Content[0])
	}
	switch {
	case node.Kind == yaml.MappingNode:
		return node, nil
	case node.Kind == 0, node.Kind == yaml.DocumentNode, isNull(node):
		return &yaml.Node{Kind: yaml.MappingNode, Tag: "!!map"}, nil
	}
	return nil, fmt.Errorf("line %d: a config must be a mapping", node.Line)
}

// A key the mapping lacks is looked up in its merge keys, as the decoder does.
func mappingValue(mapping *yaml.Node, key string) *yaml.Node {
	var sources []*yaml.Node
	for i := 0; i+1 < len(mapping.Content); i += 2 {
		name, value := mapping.Content[i], mapping.Content[i+1]
		if name.Kind != yaml.ScalarNode {
			continue
		}
		if name.ShortTag() == "!!merge" {
			sources = append(sources, value)
		} else if name.Value == key {
			return value
		}
	}
	for _, source := range sources {
		source = resolveAlias(source)
		candidates := []*yaml.Node{source}
		if source.Kind == yaml.SequenceNode {
			candidates = source.Content
		}
		for _, candidate := range candidates {
			if candidate = resolveAlias(candidate); candidate.Kind == yaml.MappingNode {
				if value := mappingValue(candidate, key); value != nil {
					return value
				}
			}
		}
	}
	return nil
}

func setMappingValue(mapping *yaml.Node, key string, value *yaml.Node) {
	for i := 0; i+1 < len(mapping.Content); i += 2 {
		if name := mapping.Content[i]; name.Kind == yaml.ScalarNode && name.Value == key {
			mapping.Content[i+1] = value
			return
		}
	}
	mapping.Content = append(
		mapping.Content,
		&yaml.Node{Kind: yaml.ScalarNode, Tag: "!!str", Value: key},
		value,
	)
}

// The overlay's proxies are either new (the injected Tailscale node), put in
// front of the profile's, or patches of a profile proxy by name, such as a
// dialer-proxy set or, with a null value, removed.
func mergeOverlayProxies(profile, overlay *yaml.Node) *yaml.Node {
	profile, overlay = resolveAlias(profile), resolveAlias(overlay)
	if overlay == nil || isNull(overlay) || overlay.Kind != yaml.SequenceNode || len(overlay.Content) == 0 {
		if profile == nil || isNull(profile) {
			return nil
		}
		return profile
	}
	if profile == nil || isNull(profile) {
		profile = &yaml.Node{Kind: yaml.SequenceNode, Tag: "!!seq"}
	}
	if profile.Kind != yaml.SequenceNode {
		return profile
	}
	index := make(map[string]int, len(profile.Content))
	for i, item := range profile.Content {
		if name := proxyNameOf(item); name != "" {
			if _, seen := index[name]; !seen {
				index[name] = i
			}
		}
	}
	items := append([]*yaml.Node(nil), profile.Content...)
	extra := make([]*yaml.Node, 0, len(overlay.Content))
	added := map[string]bool{}
	for _, item := range overlay.Content {
		name := proxyNameOf(item)
		if name == "" {
			continue
		}
		if i, ok := index[name]; ok {
			items[i] = patchMapping(items[i], item)
			continue
		}
		if added[name] {
			continue
		}
		added[name] = true
		extra = append(extra, item)
	}
	content := make([]*yaml.Node, 0, len(extra)+len(items))
	content = append(append(content, extra...), items...)
	return &yaml.Node{Kind: yaml.SequenceNode, Tag: "!!seq", Content: content}
}

// A copy of base with every key of patch but its name set over it; a null
// clears the key, also one that base only gets through a merge key.
func patchMapping(base, patch *yaml.Node) *yaml.Node {
	base, patch = resolveAlias(base), resolveAlias(patch)
	if base.Kind != yaml.MappingNode || patch.Kind != yaml.MappingNode {
		return base
	}
	out := &yaml.Node{Kind: yaml.MappingNode, Tag: "!!map", Content: append([]*yaml.Node(nil), base.Content...)}
	for i := 0; i+1 < len(patch.Content); i += 2 {
		key, value := patch.Content[i], resolveAlias(patch.Content[i+1])
		if key.Kind != yaml.ScalarNode || key.Value == "name" {
			continue
		}
		if !isNull(value) {
			setMappingValue(out, key.Value, value)
			continue
		}
		removeMappingKey(out, key.Value)
		if mappingValue(out, key.Value) != nil {
			setMappingValue(out, key.Value, &yaml.Node{Kind: yaml.ScalarNode, Tag: "!!str", Value: ""})
		}
	}
	return out
}

func removeMappingKey(mapping *yaml.Node, key string) {
	for i := 0; i+1 < len(mapping.Content); i += 2 {
		if name := mapping.Content[i]; name.Kind == yaml.ScalarNode && name.ShortTag() != "!!merge" && name.Value == key {
			mapping.Content = append(mapping.Content[:i:i], mapping.Content[i+2:]...)
			return
		}
	}
}

func proxyNameOf(item *yaml.Node) string {
	item = resolveAlias(item)
	if item == nil || item.Kind != yaml.MappingNode {
		return ""
	}
	if name := mappingValue(item, "name"); name != nil {
		name = resolveAlias(name)
		if name.Kind == yaml.ScalarNode {
			return name.Value
		}
	}
	return ""
}

// The overlay's rules are the ones the host adds in front of the profile's.
func appendRules(added, profile *yaml.Node) (*yaml.Node, error) {
	if profile == nil {
		return nil, nil
	}
	added, profile = resolveAlias(added), resolveAlias(profile)
	if added == nil || isNull(added) || (added.Kind == yaml.SequenceNode && len(added.Content) == 0) {
		return profile, nil
	}
	if isNull(profile) {
		return added, nil
	}
	if added.Kind != yaml.SequenceNode || profile.Kind != yaml.SequenceNode {
		return nil, fmt.Errorf("line %d: rules must be a list", profile.Line)
	}
	content := make([]*yaml.Node, 0, len(added.Content)+len(profile.Content))
	content = append(append(content, added.Content...), profile.Content...)
	return &yaml.Node{Kind: yaml.SequenceNode, Tag: "!!seq", Content: content}, nil
}

func resolveAlias(node *yaml.Node) *yaml.Node {
	for node != nil && node.Kind == yaml.AliasNode && node.Alias != nil {
		node = node.Alias
	}
	return node
}

func isNull(node *yaml.Node) bool {
	return node.Kind == yaml.ScalarNode && node.ShortTag() == "!!null"
}

// config.yaml is read again without this process: by the Android service
// starting on its own and by mihomo's own reload through the controller.
func writeConfigDocument(path string, document *yaml.Node) error {
	temporary, err := writeDocumentFile(filepath.Dir(path), ".config-*.yaml", document)
	if err != nil {
		return err
	}
	if err := os.Rename(temporary, path); err != nil {
		_ = os.Remove(temporary)
		return err
	}
	scheduleReclaimOwnership()
	return nil
}

func writeDocumentFile(dir, pattern string, document *yaml.Node) (string, error) {
	inlineAliases(document)
	file, err := os.CreateTemp(dir, pattern)
	if err != nil {
		return "", err
	}
	writer := bufio.NewWriterSize(file, 1<<20)
	err = errors.Join(
		encodeConfigMapping(writer, document.Content[0]),
		writer.Flush(),
		file.Close(),
		os.Chmod(file.Name(), 0o644),
	)
	if err != nil {
		_ = os.Remove(file.Name())
		return "", err
	}
	return file.Name(), nil
}

// One Encode call keeps every event it emitted until it returns, several times
// the size of a large profile, so a long top-level list goes out in slices.
const encodeSliceLength = 4096

// The mapping is drained as it is written, so the parse that follows does not
// share the heap with the whole tree.
func encodeConfigMapping(w io.Writer, mapping *yaml.Node) error {
	for i := 0; i+1 < len(mapping.Content); i += 2 {
		key, value := mapping.Content[i], mapping.Content[i+1]
		mapping.Content[i+1] = nil
		if value.Kind != yaml.SequenceNode || len(value.Content) <= encodeSliceLength {
			pair := &yaml.Node{Kind: yaml.MappingNode, Tag: "!!map", Content: []*yaml.Node{key, value}}
			if err := encodeYamlPiece(w, pair, nil); err != nil {
				return err
			}
			continue
		}
		if err := encodeYamlPiece(w, key, []byte(":\n")); err != nil {
			return err
		}
		for start := 0; start < len(value.Content); start += encodeSliceLength {
			items := value.Content[start:min(start+encodeSliceLength, len(value.Content))]
			slice := &yaml.Node{Kind: yaml.SequenceNode, Tag: "!!seq", Content: items}
			if err := encodeYamlPiece(w, slice, nil); err != nil {
				return err
			}
			clear(items)
		}
	}
	return nil
}

// Each piece is a document of its own; an end marker left between two of them
// would end config.yaml there.
func encodeYamlPiece(w io.Writer, node *yaml.Node, suffix []byte) error {
	var buffer bytes.Buffer
	encoder := yaml.NewEncoder(&buffer)
	encoder.SetIndent(2)
	if err := errors.Join(encoder.Encode(node), encoder.Close()); err != nil {
		return err
	}
	piece := bytes.TrimSuffix(buffer.Bytes(), []byte("...\n"))
	if suffix != nil {
		piece = append(bytes.TrimSuffix(piece, []byte("\n")), suffix...)
	}
	_, err := w.Write(piece)
	return err
}

// An anchor may sit in a section the overlay replaced, so every alias is
// written out in full, as the host's own encoder always did.
func inlineAliases(root *yaml.Node) {
	visited := map[*yaml.Node]struct{}{}
	var walk func(node *yaml.Node)
	walk = func(node *yaml.Node) {
		if _, seen := visited[node]; seen {
			return
		}
		if node.Anchor != "" {
			visited[node] = struct{}{}
			node.Anchor = ""
		}
		for i, child := range node.Content {
			child = resolveAlias(child)
			node.Content[i] = child
			walk(child)
		}
	}
	walk(root)
}
