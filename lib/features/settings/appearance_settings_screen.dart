import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/settings/app_settings.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/widgets/color_picker_sheet.dart';
import '../../shared/widgets/settings_rows.dart';

const List<String> _appColorPresets = <String>[
  '#B71C1C', '#E65100', '#F9A825', '#2E7D32',
  '#00695C', '#1565C0', '#4527A0', '#AD1457',
];

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final controller = ref.read(settingsControllerProvider);
    // 系统配色与 OLED 纯黑依赖 Android 的动态取色，其它平台不展示。
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    return Scaffold(
      appBar: AppBar(title: const Text('外观')),
      body: SettingsList(
        children: <Widget>[
          SettingsSection(
            title: '语言',
            children: <Widget>[
              SettingsPickerRow<LanguageSetting>(
                title: '应用语言',
                description: '跟随系统或选择应用界面语言',
                icon: Icons.language,
                value: settings.language,
                options: const <(LanguageSetting, String)>[
                  (LanguageSetting.system, '跟随系统'),
                  (LanguageSetting.zhCN, '简体中文'),
                  (LanguageSetting.zhTW, '繁體中文'),
                ],
                onChanged: (value) => controller.update(
                  (settings) => settings.copyWith(language: value),
                ),
              ),
            ],
          ),
          SettingsSection(
            title: '主题',
            children: <Widget>[
              SettingsPickerRow<ThemeSetting>(
                title: '应用外观',
                description: '跟随设备或选择固定外观',
                icon: Icons.brightness_6_outlined,
                value: settings.theme,
                options: const <(ThemeSetting, String)>[
                  (ThemeSetting.system, '跟随系统'),
                  (ThemeSetting.light, '浅色'),
                  (ThemeSetting.dark, '深色'),
                ],
                onChanged: (value) => controller.update(
                  (settings) => settings.copyWith(theme: value),
                ),
              ),
              SettingsToggleRow(
                title: '提取封面颜色',
                description: '在书籍详情页使用封面颜色',
                icon: Icons.color_lens_outlined,
                value: settings.coverColorExtraction,
                onChanged: (value) => controller.update(
                  (settings) => settings.copyWith(coverColorExtraction: value),
                ),
              ),
              SettingsRow(
                title: '应用配色',
                description: isAndroid && settings.useSystemColor
                    ? '关闭系统配色后可自定义'
                    : settings.seedColorValue,
                icon: Icons.palette_outlined,
                enabled: !isAndroid || !settings.useSystemColor,
                onTap: isAndroid && settings.useSystemColor
                    ? null
                    : () async {
                        final picked = await showColorPickerSheet(
                          context,
                          initial: settings.seedColorValue,
                          title: '应用配色',
                          presets: _appColorPresets,
                        );
                        if (picked == null) return;
                        controller.update(
                          (settings) => settings.copyWith(seedColorValue: picked),
                        );
                      },
                trailing: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: parseSeedColor(settings.seedColorValue),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              if (isAndroid) ...<Widget>[
                SettingsToggleRow(
                  title: '系统配色',
                  description: '使用设备壁纸的颜色',
                  icon: Icons.wallpaper_outlined,
                  value: settings.useSystemColor,
                  onChanged: (value) => controller.update(
                    (settings) => settings.copyWith(useSystemColor: value),
                  ),
                ),
                SettingsToggleRow(
                  title: 'OLED 纯黑',
                  description: '在深色模式下使用纯黑背景',
                  icon: Icons.contrast,
                  value: settings.oledBlack,
                  onChanged: (value) => controller.update(
                    (settings) => settings.copyWith(oledBlack: value),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
