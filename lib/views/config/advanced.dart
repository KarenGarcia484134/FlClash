import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/views/config/custom_routings.dart';
import 'package:fl_clash/views/config/dialer_proxy.dart';
import 'package:fl_clash/views/config/dns.dart';
import 'package:fl_clash/views/config/listeners.dart';
import 'package:fl_clash/views/config/filters.dart';
import 'package:fl_clash/views/config/icon_sets.dart';
import 'package:fl_clash/views/config/mitm.dart';
import 'package:fl_clash/views/config/network.dart';
import 'package:fl_clash/views/config/providers.dart';
import 'package:fl_clash/views/config/scripts.dart';
import 'package:fl_clash/views/config/tailscale.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/views/profiles/custom/custom_proxies.dart';
import 'package:flutter/widgets.dart';

import 'rules.dart';

class AdvancedConfigView extends ConsumerWidget {
  const AdvancedConfigView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final items = [
      ListItem.open(
        title: Text(appLocalizations.network),
        leading: const GlyphIcon(AppGlyphs.key),
        widget: BaseScaffold(
          title: appLocalizations.network,
          body: const NetworkListView(),
        ),
      ),
      ListItem.open(
        title: const Text('DNS'),
        leading: const GlyphIcon(AppGlyphs.dns),
        widget: const DnsView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.addedRules),
        leading: const GlyphIcon(AppGlyphs.rules),
        widget: const AddedRulesView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.customRouting),
        leading: const GlyphIcon(AppGlyphs.split),
        widget: const CustomRoutingsView(),
      ),
      ListItem.open(
        title: const Text('Tailscale'),
        leading: const GlyphIcon(AppGlyphs.vpn),
        widget: const TailscaleView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.listeners),
        leading: const GlyphIcon(AppGlyphs.devices),
        widget: const ListenersView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.dialerProxy),
        subtitle: switch (dialerProxySkippedCount(ref)) {
          0 => null,
          final count => Text(
            appLocalizations.dialerProxySkippedTip(count),
            style: TextStyle(color: context.colorScheme.error),
          ),
        },
        leading: const GlyphIcon(AppGlyphs.link),
        widget: const DialerProxyView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.script),
        leading: const GlyphIcon(AppGlyphs.code),
        widget: const ScriptsView(),
      ),
      if (mitmFeature)
        ListItem.open(
          title: Text(appLocalizations.mitm),
          leading: const GlyphIcon(AppGlyphs.lockOpen),
          widget: MitmView(isAndroid: system.isAndroid),
        ),
    ];
    final customItems = [
      ListItem.open(
        title: Text(appLocalizations.proxies),
        leading: const GlyphIcon(AppGlyphs.proxies),
        widget: const CustomProxiesView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.ruleProviders),
        leading: const GlyphIcon(AppGlyphs.resources),
        widget: const ClashProvidersView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.filters),
        leading: const GlyphIcon(AppGlyphs.filter),
        widget: const FiltersView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.iconSets),
        leading: const GlyphIcon(AppGlyphs.photos),
        widget: const IconSetsView(),
      ),
    ];
    return BaseScaffold(
      title: appLocalizations.advancedConfig,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.sectionsTopPadding,
          bottom: 16 + context.bottomInset,
        ),
        children: [
          generateSection(items: items),
          generateSection(
            title: appLocalizations.customResources,
            items: customItems,
          ),
        ],
      ),
    );
  }
}
