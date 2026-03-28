import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ThemeSelector extends StatelessWidget {
  final AppThemeNotifier themeNotifier;

  const ThemeSelector({super.key, required this.themeNotifier});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppTheme>(
      icon: const Icon(Icons.palette, color: Colors.white54),
      tooltip: 'Theme',
      onSelected: (theme) {
        themeNotifier.setTheme(theme);
        themeNotifier.saveTheme();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: AppTheme.system,
          child: _ThemeItem(
            title: 'System Theme',
            subtitle: 'Follow device settings',
            icon: Icons.device_hub,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: AppTheme.light,
          child: _ThemeItem(
            title: 'Light Theme',
            subtitle: 'Light mode',
            icon: Icons.light_mode,
          ),
        ),
        const PopupMenuItem(
          value: AppTheme.dark,
          child: _ThemeItem(
            title: 'Dark Theme',
            subtitle: 'Dark mode',
            icon: Icons.dark_mode,
          ),
        ),
      ],
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

class _ThemeItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ThemeItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00D4AA),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}