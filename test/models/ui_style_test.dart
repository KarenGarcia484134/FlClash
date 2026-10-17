import 'dart:convert';

import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('ThemeProps ui style', () {
    test('a config from before the split keeps its colors for classic', () {
      final props = ThemeProps.fromJson({
        'primaryColor': 0xFF03A9F4,
        'primaryColors': [0xFF03A9F4, 0xFF665390],
        'schemeVariant': 'vibrant',
        'themeMode': 'dark',
      });

      expect(props.uiStyle, UiStyle.classic);
      expect(props.classicPrimaryColor, 0xFF03A9F4);
      expect(props.classicPrimaryColors, [0xFF03A9F4, 0xFF665390]);
      expect(props.schemeVariant, DynamicSchemeVariant.vibrant);
      expect(props.activePrimaryColor, 0xFF03A9F4);
    });

    test('the upgrade reset of modern colors leaves classic ones alone', () {
      final legacy = ThemeProps.fromJson({'primaryColor': 0xFF03A9F4});
      final reset = legacy.copyWith(
        primaryColor: defaultPrimaryColor,
        primaryColors: defaultPrimaryColors,
        colorStyle: ColorStyle.vivid,
      );
      final reloaded = ThemeProps.fromJson(jsonDecode(jsonEncode(reset)));

      expect(reloaded.classicPrimaryColor, 0xFF03A9F4);
      expect(reloaded.primaryColor, defaultPrimaryColor);
    });

    test('a system color chosen for classic survives a reload', () {
      final props = defaultThemeProps.copyWith(classicPrimaryColor: null);

      expect(
        ThemeProps.fromJson(jsonDecode(jsonEncode(props))).classicPrimaryColor,
        isNull,
      );
    });

    test('a fresh config starts classic on its own defaults', () {
      final props = ThemeProps.fromJson({});

      expect(props.uiStyle, UiStyle.classic);
      expect(props.classicPrimaryColor, classicDefaultPrimaryColor);
      expect(props.classicPrimaryColors, classicDefaultPrimaryColors);
      expect(props.hasDefaultColors, isTrue);
    });

    test('glass is off in classic whatever is stored', () {
      const props = ThemeProps(liquidGlass: LiquidGlassMode.ultra);

      expect(props.effectiveLiquidGlass, LiquidGlassMode.none);
      expect(
        props.copyWith(uiStyle: UiStyle.modern).effectiveLiquidGlass,
        LiquidGlassMode.ultra,
      );
    });

    test('color edits go to the palette of the style in use', () {
      const classic = ThemeProps(primaryColor: 1, classicPrimaryColor: 2);
      final modern = classic.copyWith(uiStyle: UiStyle.modern);

      expect(classic.withActivePrimaryColor(3).classicPrimaryColor, 3);
      expect(classic.withActivePrimaryColor(3).primaryColor, 1);
      expect(modern.withActivePrimaryColor(3).primaryColor, 3);
      expect(modern.withActivePrimaryColor(3).classicPrimaryColor, 2);
      expect(classic.withActivePrimaryColors([4]).classicPrimaryColors, [4]);
      expect(
        classic.withDefaultColors.schemeVariant,
        DynamicSchemeVariant.content,
      );
    });
  });

  group('AppTextStyle', () {
    Future<(TextStyle, TextStyle)> styleUnder(
      WidgetTester tester,
      ThemeData theme,
    ) async {
      late TextStyle style;
      late TextStyle slot;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              style = AppTextStyle.body.of(context);
              slot = Theme.of(context).textTheme.bodyLarge!;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return (style, slot);
    }

    testWidgets('keeps the Material scale in a classic theme', (tester) async {
      final theme = ThemeData(extensions: const [ClassicTypography()]);
      final (style, slot) = await styleUnder(tester, theme);

      expect(style, slot);
      expect(style.fontSize, isNot(AppTextStyle.body.size));
    });

    testWidgets('uses the iOS scale otherwise', (tester) async {
      final (style, _) = await styleUnder(tester, ThemeData());

      expect(style.fontSize, AppTextStyle.body.size);
    });
  });
}
