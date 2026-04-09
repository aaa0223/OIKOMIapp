import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

const _privacyUrl = 'https://kobu-kgw.github.io/OIKOMIapp/privacy.html';
const _termsUrl = 'https://kobu-kgw.github.io/OIKOMIapp/terms.html';
const _supportUrl = 'https://kobu-kgw.github.io/OIKOMIapp/support.html';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);

    if (value) {
      final tasks = await DatabaseService.getAllIncompleteTasks();
      await NotificationService.rescheduleAllNotifications(tasks);
    } else {
      await NotificationService.cancelAllNotifications();
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URLを開けませんでした')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        title: const Text(
          '設定',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        children: [
          // ─── 一般 ───────────────────────────────────────────────
          _SectionHeader('一般'),
          _SettingsCard(
            children: [
              SwitchListTile.adaptive(
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                title: const Text('通知'),
                activeTrackColor: Colors.blue,
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                title: const Text('言語'),
                trailing: Text(
                  'システム設定に従う',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ),
            ],
          ),

          // ─── 情報 ────────────────────────────────────────────────
          _SectionHeader('情報'),
          _SettingsCard(
            children: [
              const ListTile(
                title: Text('バージョン'),
                trailing: Text(
                  '1.1.0',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                title: const Text('プライバシーポリシー'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _launchUrl(_privacyUrl),
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                title: const Text('利用規約'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _launchUrl(_termsUrl),
              ),
              const Divider(height: 1, indent: 16),
              ListTile(
                title: const Text('サポート・お問い合わせ'),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _launchUrl(_supportUrl),
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }
}
