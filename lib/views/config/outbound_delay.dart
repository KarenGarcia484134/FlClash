import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum LatencyLevel { good, fair, poor, failed }

LatencyLevel? latencyLevelOf(int? delay) => switch (delay) {
  null => null,
  < 0 => LatencyLevel.failed,
  < 300 => LatencyLevel.good,
  < 800 => LatencyLevel.fair,
  _ => LatencyLevel.poor,
};

/// Built-in policies have no node behind them to measure.
bool hasOutboundDelay(String name) =>
    name.isNotEmpty && !RuleTarget.ruleTargets.contains(name);

/// Sort key putting measured outbounds first, fastest first, then failed
/// ones, then the ones never tested.
int latencySortKey(int? delay) => switch (delay) {
  null => 1 << 30,
  < 0 => (1 << 30) - 1,
  _ => delay,
};

void testOutboundDelay(WidgetRef ref, String name) {
  if (!hasOutboundDelay(name)) {
    return;
  }
  ref
      .read(proxiesActionProvider.notifier)
      .proxyDelayTest(Proxy(name: name, type: ''));
}

void testOutboundDelays(WidgetRef ref, Iterable<String> names) {
  final proxies = [
    for (final name in names)
      if (hasOutboundDelay(name)) Proxy(name: name, type: ''),
  ];
  if (proxies.isEmpty) {
    return;
  }
  ref.read(proxiesActionProvider.notifier).delayTest(proxies);
}

/// The delay of an outbound from the shared delay results the proxies page
/// fills, so a value measured anywhere shows up here at once. A group shows
/// the delay of the node it currently uses. Tapping or long-pressing it
/// measures again.
class OutboundDelayBadge extends ConsumerWidget {
  const OutboundDelayBadge({super.key, required this.name, this.size = 12});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasOutboundDelay(name)) {
      return const SizedBox.shrink();
    }
    final delay = ref.watch(delayProvider(proxyName: name));
    final phase = ref.watch(delayTestPhaseProvider(proxyName: name));
    final colorScheme = context.colorScheme;
    final style = AppTextStyle.caption2.of(context);
    final Widget child = switch (phase) {
      DelayTestPhase.running => SizedBox.square(
        dimension: size,
        child: const CommonCircleLoading(),
      ),
      DelayTestPhase.queued => GlyphIcon(
        AppGlyphs.clock,
        size: size,
        color: colorScheme.onSurfaceVariant.opacity38,
      ),
      null when delay == null => GlyphIcon(
        AppGlyphs.bolt,
        size: size,
        color: colorScheme.onSurfaceVariant,
      ),
      null => Text(
        delay! > 0
            ? '$delay ms'
            : delayFailureText(delay, context.appLocalizations),
        maxLines: 1,
        style: style.copyWith(
          color: switch (latencyLevelOf(delay)) {
            LatencyLevel.good => colorScheme.success,
            LatencyLevel.fair => colorScheme.warning,
            LatencyLevel.poor => colorScheme.error,
            _ => colorScheme.onSurfaceVariant,
          },
        ),
      ),
    };
    return Tooltip(
      message: context.appLocalizations.delayTest,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => testOutboundDelay(ref, name),
        onLongPress: () => testOutboundDelay(ref, name),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: child,
        ),
      ),
    );
  }
}

/// Orders outbounds by their shared delay results. [keep] stays listed even
/// when it timed out, so the current choice never disappears.
List<String> sortedOutbounds(
  List<String> names,
  Map<String, int?> delays, {
  required bool sortByDelay,
  required bool hideTimeout,
  String? keep,
}) {
  final visible = [
    for (final name in names)
      if (!hideTimeout || name == keep || (delays[name] ?? 0) >= 0) name,
  ];
  if (!sortByDelay) {
    return visible;
  }
  final indexed = visible.indexed.toList()
    ..sort((a, b) {
      final byDelay = latencySortKey(
        delays[a.$2],
      ).compareTo(latencySortKey(delays[b.$2]));
      return byDelay != 0 ? byDelay : a.$1.compareTo(b.$1);
    });
  return [for (final item in indexed) item.$2];
}
