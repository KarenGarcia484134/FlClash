import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/features.dart';
import 'package:fl_clash/icons/icons.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/config/custom_routings.dart';
import 'package:fl_clash/views/config/outbound_delay.dart';
import 'package:fl_clash/views/config/tailscale.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

bool get _linux => system.isLinux;

List<ListenerType> get availableListenerTypes => [
  for (final type in ListenerType.values)
    if (!type.linuxOnly || _linux) type,
];

String listenerIssueText(BuildContext context, ListenerIssue issue) {
  final l = context.appLocalizations;
  return switch (issue) {
    ListenerIssue.invalidName => l.emptyTip(l.name),
    ListenerIssue.invalidPort => l.listenerPortInvalid,
    ListenerIssue.invalidListen => l.listenerListenInvalid,
    ListenerIssue.invalidUser => l.listenerUserInvalid,
    ListenerIssue.duplicateName => l.listenerDuplicateName,
    ListenerIssue.duplicatePort => l.listenerDuplicatePort,
    ListenerIssue.appPort => l.listenerAppPort,
    ListenerIssue.unsupported => l.listenerUnsupported,
    ListenerIssue.missingTarget => l.listenerMissingTarget,
    ListenerIssue.missingRule => l.listenerMissingRule,
  };
}

ListenerContext _currentContext(WidgetRef ref) {
  final profileId = ref.watch(currentProfileIdProvider);
  final config = profileId == null
      ? null
      : ref.watch(clashConfigProvider(profileId)).value;
  final patch = ref.watch(patchClashConfigProvider);
  return ListenerContext(
    appPorts: appInboundPorts(patch),
    outbounds: {
      ...?config?.proxies.map((e) => e.name),
      ...?config?.proxyGroups.map((e) => e.name),
      ?currentTailscaleProxyName(ref),
    },
    subRules: {...?config?.subRules},
    linux: _linux,
  );
}

Future<void> _copy(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    context.showNotifier(
      context.appLocalizations.copySuccess,
      level: MessageLevel.success,
    );
  }
}

class ListenersView extends ConsumerWidget {
  const ListenersView({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    InboundListenerProps? item,
  ]) async {
    final res = await BaseNavigator.push<InboundListenerProps>(
      context,
      ListenerEditView(item: item),
    );
    if (res != null) {
      ref.read(listenersSettingProvider.notifier).put(res);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    InboundListenerProps item,
  ) async {
    final l = context.appLocalizations;
    final res = await dialogs.showMessage(
      title: l.tip,
      message: TextSpan(text: l.deleteTip(item.name)),
    );
    if (res == true) {
      ref.read(listenersSettingProvider.notifier).remove(item.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final props = ref.watch(listenersSettingProvider);
    final issues = listenerIssues(props.items, _currentContext(ref));
    final running = ref.watch(isStartProvider);
    final notifier = ref.read(listenersSettingProvider.notifier);
    return CommonScaffold(
      title: l.listeners,
      actions: [
        IconButton(
          tooltip: l.addListener,
          onPressed: () => _edit(context, ref),
          icon: const GlyphIcon(AppGlyphs.addCircle),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(
          16,
        ).copyWith(top: context.contentTopPadding),
        children: [
          generateSectionV3(
            items: [
              FormRow(
                title: l.listenersEnable,
                onPressed: () => notifier.update(
                  (state) => state.copyWith(enable: !state.enable),
                ),
                trailing: Switch(
                  value: props.enable,
                  onChanged: (value) =>
                      notifier.update((state) => state.copyWith(enable: value)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(l.listenersDesc, style: context.listCaptionStyle),
          ),
          const SizedBox(height: 8),
          if (props.items.isEmpty)
            NullStatus(label: l.nullTip(l.listeners))
          else
            for (final (index, item) in props.items.indexed)
              ContextMenuRegion(
                key: ValueKey(item.id),
                menuItems: [
                  for (final address in listenerAddresses(item))
                    CommonPopupMenuItem(
                      glyph: AppGlyphs.copy,
                      label: address,
                      onPressed: () => _copy(context, address),
                    ),
                  CommonPopupMenuItem(
                    glyph: AppGlyphs.edit,
                    label: l.edit,
                    onPressed: () => _edit(context, ref, item),
                  ),
                  CommonPopupMenuItem(
                    danger: true,
                    glyph: AppGlyphs.delete,
                    label: l.delete,
                    onPressed: () => _delete(context, ref, item),
                  ),
                ],
                child: ItemPositionProvider(
                  position: ItemPosition.get(index, props.items.length),
                  child: _ListenerItem(
                    item: item,
                    issue: issues[item.id],
                    active:
                        running &&
                        props.enable &&
                        item.enabled &&
                        !issues.containsKey(item.id),
                    onPressed: () => _edit(context, ref, item),
                    onChanged: (value) =>
                        notifier.put(item.copyWith(enabled: value)),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _ListenerItem extends StatelessWidget {
  const _ListenerItem({
    required this.item,
    required this.issue,
    required this.active,
    required this.onPressed,
    required this.onChanged,
  });

  final InboundListenerProps item;
  final ListenerIssue? issue;
  final bool active;
  final VoidCallback onPressed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final captionStyle = context.listCaptionStyle;
    final issue = this.issue;
    final address = listenerAddresses(item).last;
    return DecorationListItem(
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Tooltip(
        message: active ? l.listenerActive : l.listenerInactive,
        child: SizedBox.square(
          dimension: 10,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: const CircleBorder(),
              color: issue != null
                  ? context.colorScheme.error
                  : active
                  ? context.colorScheme.primary
                  : context.colorScheme.outline,
            ),
          ),
        ),
      ),
      title: Text(
        '${item.name} · ${item.type.name}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: address,
              style: captionStyle?.toJetBrainsMono.copyWith(
                color: context.colorScheme.tertiary,
              ),
            ),
            TextSpan(
              text:
                  '  → ${item.proxy.isNotEmpty
                      ? item.proxy
                      : item.rule.isNotEmpty
                      ? item.rule
                      : l.listenerFollowRules}',
            ),
            if (issue != null)
              TextSpan(
                text: '  ${listenerIssueText(context, issue)}',
                style: TextStyle(color: context.colorScheme.error),
              ),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: captionStyle,
      ),
      trailing: Switch(value: item.enabled, onChanged: onChanged),
      onPressed: onPressed,
    );
  }
}

class ListenerEditView extends ConsumerStatefulWidget {
  const ListenerEditView({super.key, this.item});

  final InboundListenerProps? item;

  @override
  ConsumerState<ListenerEditView> createState() => _ListenerEditViewState();
}

class _UserDraft {
  _UserDraft(ListenerUser user)
    : username = TextEditingController(text: user.username),
      password = TextEditingController(text: user.password);

  final TextEditingController username;
  final TextEditingController password;

  ListenerUser get user =>
      ListenerUser(username: username.text.trim(), password: password.text);

  void dispose() {
    username.dispose();
    password.dispose();
  }
}

class _ListenerEditViewState extends ConsumerState<ListenerEditView> {
  final _formKey = GlobalKey<FormState>();
  late final InboundListenerProps _initial;
  late final TextEditingController _name;
  late final TextEditingController _listen;
  late final TextEditingController _port;
  late ListenerType _type;
  late bool _udp;
  late String _proxy;
  late String _rule;
  late final List<_UserDraft> _users;

  @override
  void initState() {
    super.initState();
    _initial = widget.item ?? _newListener();
    _name = TextEditingController(text: _initial.name);
    _listen = TextEditingController(text: _initial.listen);
    _port = TextEditingController(
      text: _initial.port == 0 ? '' : '${_initial.port}',
    );
    _type = _initial.type;
    _udp = _initial.udp;
    _proxy = _initial.proxy;
    _rule = _initial.rule;
    _users = [for (final user in _initial.users) _UserDraft(user)];
  }

  InboundListenerProps _newListener() {
    final items = ref.read(listenersSettingProvider).items;
    final taken = {
      ...items.map((e) => e.port),
      ...appInboundPorts(ref.read(patchClashConfigProvider)),
    };
    var port = 7891;
    while (taken.contains(port)) {
      port++;
    }
    return InboundListenerProps(
      id: '${snowflake.id}',
      name: 'listener-${items.length + 1}',
      port: port,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _listen.dispose();
    _port.dispose();
    for (final user in _users) {
      user.dispose();
    }
    super.dispose();
  }

  InboundListenerProps get _draft => _initial.copyWith(
    name: _name.text.trim(),
    listen: _listen.text.trim(),
    port: int.tryParse(_port.text.trim()) ?? 0,
    type: _type,
    udp: _udp,
    proxy: _proxy,
    rule: _proxy.isEmpty ? _rule : '',
    users: _type.supportsUsers
        ? [for (final user in _users) user.user]
        : const [],
  );

  ListenerIssue? _conflict(InboundListenerProps draft) {
    final others = [
      for (final item in ref.read(listenersSettingProvider).items)
        if (item.id != draft.id) item.copyWith(enabled: true),
    ];
    final issues = listenerIssues([
      ...others,
      draft.copyWith(enabled: true),
    ], _currentContext(ref));
    return switch (issues[draft.id]) {
      final issue?
          when issue == ListenerIssue.duplicateName ||
              issue == ListenerIssue.duplicatePort ||
              issue == ListenerIssue.appPort =>
        issue,
      _ => null,
    };
  }

  void _save() {
    if (_formKey.currentState?.validate() == false) {
      return;
    }
    final draft = _draft;
    final issue = listenerFieldIssue(draft, linux: _linux) ?? _conflict(draft);
    if (issue != null) {
      dialogs.showMessage(
        message: TextSpan(text: listenerIssueText(context, issue)),
      );
      return;
    }
    Navigator.of(context).pop(draft);
  }

  Future<void> _pickProxy() async {
    final l = context.appLocalizations;
    final res = await showSheet<String>(
      context: context,
      builder: (_) => OutboundPickerSheet(
        title: l.listenerOutbound,
        selected: _proxy,
        basicItems: const ['', 'DIRECT', 'REJECT'],
        basicLabel: (item) => item.isEmpty ? l.listenerFollowRules : item,
      ),
    );
    if (res != null) {
      setState(() => _proxy = res);
    }
  }

  Future<void> _pickRule(List<String> subRules) async {
    final l = context.appLocalizations;
    final res = await dialogs.showCommonDialog<String>(
      context: context,
      child: OptionsDialog<String>(
        title: l.listenerSubRule,
        options: ['', ...subRules],
        textBuilder: (item) => item.isEmpty ? l.listenerFollowRules : item,
        value: _rule,
      ),
    );
    if (res != null) {
      setState(() => _rule = res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final profileId = ref.watch(currentProfileIdProvider);
    final subRules = profileId == null
        ? const <String>[]
        : ref.watch(clashConfigProvider(profileId)).value?.subRules ??
              const <String>[];
    final lan = isLanListenAddress(_listen.text.trim());
    return CommonScaffold(
      title: widget.item == null ? l.addListener : l.editListener,
      actions: [
        IconButton(
          tooltip: l.save,
          onPressed: _save,
          icon: const GlyphIcon(AppGlyphs.check),
        ),
      ],
      body: Form(
        key: _formKey,
        child: Builder(
          builder: (context) => ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              context.contentTopPadding,
              16,
              16 + BottomInsetScope.of(context),
            ),
            children: [
              TextFormField(
                controller: _name,
                inputFormatters: TextInputLimits.limit(TextInputLimits.name),
                validator: (value) => value?.trim().isNotEmpty == true
                    ? null
                    : l.emptyTip(l.name),
                decoration: InputDecoration(
                  border: AppShape.input,
                  labelText: l.name,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<ListenerType>(
                segments: [
                  for (final type in availableListenerTypes)
                    ButtonSegment(value: type, label: Text(type.name)),
                ],
                selected: {_type},
                onSelectionChanged: (value) =>
                    setState(() => _type = value.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _listen,
                style: context.textTheme.bodyMedium?.toJetBrainsMono,
                onChanged: (_) => setState(() {}),
                validator: (value) => isValidListenAddress(value?.trim() ?? '')
                    ? null
                    : l.listenerListenInvalid,
                decoration: InputDecoration(
                  border: AppShape.input,
                  labelText: l.listenerListen,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final (value, label) in [
                    (listenerLoopback, l.listenerLocalOnly),
                    (listenerAnyAddress, l.listenerLan),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _listen.text.trim() == value,
                      onSelected: (_) => setState(() => _listen.text = value),
                    ),
                ],
              ),
              if (lan) ...[
                const SizedBox(height: 8),
                Text(
                  l.listenerLanWarning,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _port,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: context.textTheme.bodyMedium?.toJetBrainsMono,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  final port = int.tryParse(value?.trim() ?? '') ?? 0;
                  if (!isValidListenerPort(port)) {
                    return l.listenerPortInvalid;
                  }
                  final issue = _conflict(_draft.copyWith(port: port));
                  return issue == null
                      ? null
                      : listenerIssueText(context, issue);
                },
                decoration: InputDecoration(
                  border: AppShape.input,
                  labelText: l.port,
                ),
              ),
              const SizedBox(height: 16),
              ItemPositionProvider(
                position: ItemPosition.startAndEnd,
                child: FormRow(
                  title: l.listenerOutbound,
                  onPressed: _pickProxy,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _proxy.isEmpty ? l.listenerFollowRules : _proxy,
                          style: context.textTheme.bodyMedium?.toJetBrainsMono
                              .copyWith(color: context.colorScheme.tertiary),
                        ),
                      ),
                      if (hasOutboundDelay(_proxy))
                        OutboundDelayBadge(name: _proxy),
                    ],
                  ),
                ),
              ),
              if (_proxy.isEmpty && subRules.isNotEmpty) ...[
                const SizedBox(height: 8),
                ItemPositionProvider(
                  position: ItemPosition.startAndEnd,
                  child: FormRow(
                    title: l.listenerSubRule,
                    onPressed: () => _pickRule(subRules),
                    trailing: Text(
                      _rule.isEmpty ? l.listenerFollowRules : _rule,
                      style: context.textTheme.bodyMedium?.toJetBrainsMono
                          .copyWith(color: context.colorScheme.tertiary),
                    ),
                  ),
                ),
              ],
              if (_type.supportsUdp) ...[
                const SizedBox(height: 8),
                ItemPositionProvider(
                  position: ItemPosition.startAndEnd,
                  child: FormRow(
                    title: 'UDP',
                    onPressed: () => setState(() => _udp = !_udp),
                    trailing: Switch(
                      value: _udp,
                      onChanged: (value) => setState(() => _udp = value),
                    ),
                  ),
                ),
              ],
              if (_type.supportsUsers) ...[
                const SizedBox(height: 8),
                ListHeader(
                  title: l.listenerUsers,
                  padding: EdgeInsets.zero,
                  actions: [
                    EntryButton.add(
                      onPressed: () => setState(
                        () => _users.add(_UserDraft(const ListenerUser())),
                      ),
                    ),
                  ],
                ),
                if (_users.isEmpty)
                  Text(l.listenerUsersEmpty, style: context.listCaptionStyle),
                for (final user in _users)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: user.username,
                            validator: (value) =>
                                value?.trim().isNotEmpty == true
                                ? null
                                : l.listenerUserInvalid,
                            decoration: InputDecoration(
                              border: AppShape.input,
                              labelText: l.username,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: user.password,
                            obscureText: true,
                            decoration: InputDecoration(
                              border: AppShape.input,
                              labelText: l.password,
                            ),
                          ),
                        ),
                        EntryButton.remove(
                          onPressed: () => setState(() {
                            _users.remove(user);
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => user.dispose(),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
