import 'package:flutter/material.dart';

enum HomeSettingsMenuAction { language, account, help, fullSettings }

/// Mail + settings icon row, styled to sit "on glass" over the immersive
/// home background.
class HomeSceneTopIcons extends StatelessWidget {
  const HomeSceneTopIcons({
    super.key,
    required this.onNotificationTap,
    required this.onAccountTap,
    required this.onLanguageTap,
    required this.onHelpTap,
    required this.onFullSettingsTap,
    required this.languageSummary,
    required this.accountSummary,
  });

  final VoidCallback onNotificationTap;
  final VoidCallback onAccountTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onHelpTap;
  final VoidCallback onFullSettingsTap;
  final String languageSummary;
  final String accountSummary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x33101828),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x44FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onNotificationTap,
            icon: const Icon(Icons.mail_outline_rounded),
            color: Colors.white,
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          ),
          PopupMenuButton<HomeSettingsMenuAction>(
            tooltip: 'Pengaturan',
            onSelected: (value) {
              switch (value) {
                case HomeSettingsMenuAction.language:
                  onLanguageTap();
                case HomeSettingsMenuAction.account:
                  onAccountTap();
                case HomeSettingsMenuAction.help:
                  onHelpTap();
                case HomeSettingsMenuAction.fullSettings:
                  onFullSettingsTap();
              }
            },
            color: const Color(0xFFFCFEFF),
            surfaceTintColor: Colors.transparent,
            elevation: 10,
            offset: const Offset(0, 34),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFDCE5F2)),
            ),
            constraints: const BoxConstraints(minWidth: 230),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.settings_outlined),
            iconColor: Colors.white,
            iconSize: 20,
            itemBuilder: (context) => [
              PopupMenuItem<HomeSettingsMenuAction>(
                value: HomeSettingsMenuAction.language,
                child: _SettingsMenuTile(
                  icon: Icons.language_rounded,
                  title: 'Bahasa',
                  subtitle: languageSummary,
                ),
              ),
              PopupMenuItem<HomeSettingsMenuAction>(
                value: HomeSettingsMenuAction.account,
                child: _SettingsMenuTile(
                  icon: Icons.manage_accounts_rounded,
                  title: 'Akun',
                  subtitle: accountSummary,
                ),
              ),
              PopupMenuItem<HomeSettingsMenuAction>(
                value: HomeSettingsMenuAction.help,
                child: const _SettingsMenuTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Bantuan',
                  subtitle: 'Cara pakai Youneka dengan cepat',
                ),
              ),
              PopupMenuItem<HomeSettingsMenuAction>(
                value: HomeSettingsMenuAction.fullSettings,
                child: const _SettingsMenuTile(
                  icon: Icons.settings_rounded,
                  title: 'Pengaturan lengkap',
                  subtitle: 'Bahasa, fokus, dan preferensi app',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsMenuTile extends StatelessWidget {
  const _SettingsMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: const Color(0xFF304867), size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF182740),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7B90AF),
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
