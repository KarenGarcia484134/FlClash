import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

/// prism_ui's [BackLayerScope] that can step aside for one action: a picker
/// that pops with its pick while searching would otherwise only end the
/// search, as the layer takes the pop, and lose the pick.
class DetachableBackLayerScope extends StatefulWidget {
  final Widget child;
  final VoidCallback onBack;

  const DetachableBackLayerScope({
    super.key,
    required this.onBack,
    required this.child,
  });

  @override
  State<DetachableBackLayerScope> createState() =>
      DetachableBackLayerScopeState();
}

class DetachableBackLayerScopeState extends State<DetachableBackLayerScope> {
  ModalRoute<dynamic>? _route;
  LocalHistoryEntry? _entry;
  bool _isDetaching = false;
  bool _isPageActive = true;
  int _syncRevision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final isPageActive = PageActivityScope.isActiveOf(context);
    if (identical(_route, route) && _isPageActive == isPageActive) {
      return;
    }
    _detach();
    _route = route;
    _isPageActive = isPageActive;
    final revision = ++_syncRevision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || revision != _syncRevision) {
        return;
      }
      if (!_isPageActive) {
        widget.onBack();
        return;
      }
      if (route == null) {
        return;
      }
      _attach(route);
    });
  }

  void _attach(ModalRoute<dynamic> route) {
    final entry = LocalHistoryEntry(
      impliesAppBarDismissal: false,
      onRemove: _handleRemove,
    );
    _entry = entry;
    route.addLocalHistoryEntry(entry);
  }

  /// Runs [action] with the layer off the route, then puts it back if the
  /// route is still the current one.
  void runWithoutLayer(VoidCallback action) {
    final route = _route;
    final hadEntry = _entry != null;
    _detach();
    action();
    if (hadEntry && mounted && _entry == null && route?.isCurrent == true) {
      _attach(route!);
    }
  }

  void _handleRemove() {
    _entry = null;
    if (!_isDetaching && mounted) {
      widget.onBack();
    }
  }

  void _detach() {
    final entry = _entry;
    if (entry == null) {
      return;
    }
    _entry = null;
    _isDetaching = true;
    entry.remove();
    _isDetaching = false;
  }

  @override
  void dispose() {
    _syncRevision++;
    _detach();
    _route = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
