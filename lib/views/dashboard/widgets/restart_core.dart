import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'card.dart';

/// Restarts the core after a confirmation, reporting the outcome.
Future<void> confirmRestartCore(BuildContext context, WidgetRef ref) async {
  final appLocalizations = context.appLocalizations;
  final res = await dialogs.showMessage(
    message: TextSpan(text: appLocalizations.restartCoreTip),
  );
  if (res != true) {
    return;
  }
  try {
    final ok = await ref.read(coreActionProvider.notifier).restartCore();
    dialogs.showNotifier(
      ok
          ? appLocalizations.restartCoreDone
          : appLocalizations.restartCoreFailed,
      level: ok ? MessageLevel.success : MessageLevel.error,
    );
  } catch (error) {
    dialogs.showNotifier(
      '${appLocalizations.restartCoreFailed}: $error',
      level: MessageLevel.error,
    );
  }
}

class RestartCoreCard extends ConsumerWidget {
  const RestartCoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final restarting = ref.watch(coreStatusProvider) == CoreStatus.connecting;
    return DashboardCard(
      semanticLabel: appLocalizations.restartCore,
      onTap: restarting ? null : () => confirmRestartCore(context, ref),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.refresh,
            title: appLocalizations.restartCore,
          ),
          Row(
            spacing: 8,
            children: [
              if (restarting)
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              Flexible(
                child: Text(
                  restarting
                      ? appLocalizations.restartingCore
                      : appLocalizations.restartCoreCardDesc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subheadline.of(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
