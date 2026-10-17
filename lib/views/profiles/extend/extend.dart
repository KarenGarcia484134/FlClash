import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/config/custom_routings.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'script.dart';
import 'standard.dart';

class ExtendView extends ConsumerStatefulWidget {
  final int profileId;

  const ExtendView({super.key, required this.profileId});

  @override
  ConsumerState<ExtendView> createState() => _ExtendViewState();
}

/// Custom routing is a view of its own rather than a mode: it applies on top
/// of whichever of standard or script the profile uses.
enum _ExtendTab { customRouting, standard, script }

class _ExtendViewState extends ConsumerState<ExtendView> {
  late SetupAction _setupAction;
  var _tab = _ExtendTab.customRouting;

  void _handleTab(_ExtendTab tab) {
    setState(() {
      _tab = tab;
    });
  }

  @override
  void initState() {
    super.initState();
    _setupAction = ref.read(setupActionProvider.notifier);
    ref.listenManual(clashConfigProvider(widget.profileId), (_, _) {});
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return ProfileIdProvider(
      profileId: widget.profileId,
      child: CommonScaffold(
        title: appLocalizations.extend,
        body: ScrollConfiguration(
          behavior: const ShowBarScrollBehavior(),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: context.appBarInset)),
              _Title(tab: _tab, onTab: _handleTab),
              _Content(tab: _tab),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _setupAction.autoApplyProfile();
    super.dispose();
  }
}

class _Title extends ConsumerWidget {
  final _ExtendTab tab;
  final ValueChanged<_ExtendTab> onTab;

  const _Title({required this.tab, required this.onTab});

  String _getModeTitle(BuildContext context, ExtendType type) {
    return switch (type) {
      ExtendType.standard => context.appLocalizations.standard,
      ExtendType.script => context.appLocalizations.script,
    };
  }

  String _getTitle(BuildContext context, _ExtendTab tab) {
    return switch (tab) {
      _ExtendTab.customRouting => context.appLocalizations.customRouting,
      _ExtendTab.standard => context.appLocalizations.standard,
      _ExtendTab.script => context.appLocalizations.script,
    };
  }

  Glyph _getIcon(_ExtendTab tab) {
    return switch (tab) {
      _ExtendTab.customRouting => AppGlyphs.split,
      _ExtendTab.standard => AppGlyphs.star,
      _ExtendTab.script => AppGlyphs.code,
    };
  }

  ExtendType? _modeOf(_ExtendTab tab) {
    return switch (tab) {
      _ExtendTab.customRouting => null,
      _ExtendTab.standard => ExtendType.standard,
      _ExtendTab.script => ExtendType.script,
    };
  }

  String _getDesc(BuildContext context, ExtendType extendType) {
    final appLocalizations = context.appLocalizations;
    return switch (tab) {
      _ExtendTab.customRouting =>
        '${appLocalizations.customRoutingDesc}\n'
            '${appLocalizations.currentExtendMode(_getModeTitle(context, extendType))}',
      _ExtendTab.standard => appLocalizations.standardModeDesc,
      _ExtendTab.script => appLocalizations.scriptModeDesc,
    };
  }

  void _handleSelect(WidgetRef ref, int profileId, _ExtendTab tab) {
    onTab(tab);
    final mode = _modeOf(tab);
    if (mode == null) {
      return;
    }
    ref.read(profilesProvider.notifier).updateProfile(profileId, (state) {
      return state.copyWith(extendType: mode);
    });
  }

  @override
  Widget build(context, ref) {
    final appLocalizations = context.appLocalizations;
    final profileId = ProfileIdProvider.of(context)!.profileId;
    final extendType = ref.watch(extendTypeProvider(profileId));
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoHeader(info: Info(label: appLocalizations.extendMode)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 16,
              children: [
                for (final item in _ExtendTab.values)
                  CommonCard(
                    isSelected: tab == item,
                    fillsSelection: true,
                    onPressed: () {
                      _handleSelect(ref, profileId, item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GlyphIcon(_getIcon(item)),
                          const SizedBox(width: 8),
                          Flexible(child: Text(_getTitle(context, item))),
                          if (_modeOf(item) == extendType) ...[
                            const SizedBox(width: 8),
                            GlyphIcon(
                              AppGlyphs.checkCircle,
                              fill: 1,
                              size: 18,
                              color: context.colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _getDesc(context, extendType),
              style: AppTextStyle.footnote
                  .of(context)
                  .copyWith(
                    color: context.colorScheme.onSurfaceVariant.opacity80,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final _ExtendTab tab;

  const _Content({required this.tab});

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      _ExtendTab.customRouting => const CustomRoutingContent(),
      _ExtendTab.standard => const StandardContent(),
      _ExtendTab.script => const ScriptContent(),
    };
  }
}
