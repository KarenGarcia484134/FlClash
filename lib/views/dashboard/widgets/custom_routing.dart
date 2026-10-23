import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/views/config/custom_routings.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';

/// How many custom routings take effect for the current profile: selected
/// for it and switched on.
({int applied, int total}) customRoutingCounts(
  Iterable<({int id, bool enabled})> routings,
  Iterable<int> selected,
) {
  final ids = selected.toSet();
  final all = routings.toList();
  return (
    applied: all.where((item) => item.enabled && ids.contains(item.id)).length,
    total: all.length,
  );
}

class CustomRoutingCard extends ConsumerWidget {
  const CustomRoutingCard({super.key, this.dense = false});

  /// One line, the count beside the title, for the desktop's tile row.
  final bool dense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final routings = ref.watch(customRoutingsProvider).value ?? const [];
    final profileId = ref.watch(currentProfileIdProvider);
    final selected = profileId == null
        ? const <int>[]
        : ref.watch(profileCustomRoutingIdsProvider(profileId)).value ??
              const <int>[];
    final counts = customRoutingCounts(
      routings.map((item) => (id: item.id, enabled: item.enabled)),
      selected,
    );
    final summary = profileId == null
        ? appLocalizations.customRoutingCardNoProfile
        : appLocalizations.customRoutingCardCount(counts.applied, counts.total);
    void open() => BaseNavigator.push(context, const CustomRoutingsView());
    if (dense) {
      return DashboardTileCard(
        semanticLabel: appLocalizations.customRouting,
        onTap: open,
        glyph: AppGlyphs.split,
        title: appLocalizations.customRouting,
        status: Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis),
        chevron: true,
      );
    }
    return DashboardCard(
      semanticLabel: appLocalizations.customRouting,
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.split,
            title: appLocalizations.customRouting,
            chevron: true,
          ),
          Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.subheadline.of(context),
          ),
        ],
      ),
    );
  }
}
