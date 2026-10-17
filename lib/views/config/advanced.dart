import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/views/config/custom_routings.dart';
import 'package:fl_clash/views/config/dialer_proxy.dart';
import 'package:fl_clash/views/config/dns.dart';
import 'package:fl_clash/views/config/listeners.dart';
import 'package:fl_clash/views/config/network.dart';
import 'package:fl_clash/views/config/scripts.dart';
import 'package:fl_clash/views/config/tailscale.dart';
import 'package:fl_clash/widgets/list.dart';
import 'package:fl_clash/widgets/scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
    ];
    return BaseScaffold(
      title: appLocalizations.advancedConfig,
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ).copyWith(top: context.contentTopPadding, bottom: 16),
        children: [generateSectionV3(items: items)],
      ),
    );
  }
}
