import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../themes/theme_provider.dart';

class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark;

    return SwitchListTile(
      secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
      title: const Text('Dark Mode'),
      subtitle: Text(isDark ? 'On' : 'Off'),
      value: isDark,
      onChanged: (val) =>
          ref.read(themeNotifierProvider.notifier).toggleTheme(),
    );
  }
}
