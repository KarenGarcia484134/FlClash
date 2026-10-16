import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/config/custom_routings.dart';
import 'package:fl_clash/views/dashboard/widget_metrics.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
  const CustomRoutingCard({super.key});

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
    final padding = DashboardWidgetMetrics.paddingOf(context);
    return SizedBox(
      height: DashboardWidgetMetrics.heightOf(context, 1),
      child: CommonCard(
        radius: DashboardWidgetMetrics.radiusOf(context),
        infoPadding: padding.copyWith(bottom: 0),
        info: Info(
          label: appLocalizations.customRouting,
          glyph: AppGlyphs.split,
        ),
        onPressed: () =>
            BaseNavigator.push(context, const CustomRoutingsView()),
        child: Container(
          padding: padding.copyWith(top: 0),
          alignment: AlignmentDirectional.bottomStart,
          child: SizedBox(
            height:
                globalState.measure.bodyMediumHeight *
                    DashboardWidgetMetrics.textScaleOf(context) +
                2,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                profileId == null
                    ? appLocalizations.customRoutingCardNoProfile
                    : appLocalizations.customRoutingCardCount(
                        counts.applied,
                        counts.total,
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.toLight.adjustSize(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
