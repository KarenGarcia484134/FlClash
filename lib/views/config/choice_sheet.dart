import 'package:fl_clash/features/features.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

/// A single choice from a short list, in the app's selection sheet.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T item) labelOf,
  required T? value,
}) {
  return showSheet<T>(
    context: context,
    builder: (context) => SelectionSheet<T>(
      title: title,
      sections: [SelectionSection(items: options)],
      labelBuilder: labelOf,
      selectedOf: (_) => value,
      onSelected: (item) => Navigator.of(context).pop(item),
    ),
  );
}
