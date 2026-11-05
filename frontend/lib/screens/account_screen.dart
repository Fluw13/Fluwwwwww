import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content/info_page.dart';
import '../content/legal_pages.dart';
import '../core/history/history_kind.dart';
import '../core/history/history_scope.dart';
import '../core/history/session_history.dart';
import '../core/support/support_contact.dart';
import '../core/theme/app_spacing.dart';
import '../services/api_service.dart';
import '../widgets/account/account_header_card.dart';
import '../widgets/account/settings_group.dart';
import '../widgets/account/settings_tile.dart';
import '../widgets/account/theme_mode_selector.dart';
import 'history_screen.dart';
import 'info_page_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, this.apiService});

  final ApiService? apiService;

  void _openHistory(BuildContext context, HistoryKind kind) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen(kind: kind, apiService: apiService)));
  }

  void _openPage(BuildContext context, InfoPage page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => InfoPageScreen(page: page)));
  }

  Future<void> _copySupportEmail(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: SupportContact.email));
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Đã chép ${SupportContact.email}')));
  }

  static String _countLabel(int count) => count == 0 ? 'Chưa có' : '$count mục';

  @override
  Widget build(BuildContext context) {
    final SessionHistory? history = HistoryScope.watch(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.xxl,
          ),
          children: [
            const AccountHeaderCard(),
            const SizedBox(height: AppSpacing.xxl),
            const SettingsGroup(
              title: 'Giao diện',
              footnote: 'Lựa chọn được lưu trên máy này.',
              children: [
                Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: ThemeModeSelector(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SettingsGroup(
              title: 'Lịch sử',
              footnote: HistoryScreen.sessionNote,
              children: [
                SettingsTile(
                  icon: Icons.qr_code_scanner,
                  title: HistoryKind.scans.title,
                  subtitle: _countLabel(history?.scans.length ?? 0),
                  onTap: () => _openHistory(context, HistoryKind.scans),
                ),
                SettingsTile(
                  icon: Icons.search,
                  title: HistoryKind.searches.title,
                  subtitle: _countLabel(history?.searches.length ?? 0),
                  onTap: () => _openHistory(context, HistoryKind.searches),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SettingsGroup(
              title: 'Hỗ trợ',
              footnote: SupportContact.isSample ? 'Địa chỉ mẫu, sẽ được thay bằng email hỗ trợ chính thức.' : null,
              children: [
                SettingsTile(
                  icon: Icons.mail_outline,
                  title: 'Liên hệ hỗ trợ và góp ý',
                  subtitle: SupportContact.email,
                  trailingIcon: Icons.copy_outlined,
                  tapHint: 'chép email',
                  onTap: () => _copySupportEmail(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SettingsGroup(
              title: 'Pháp lý',
              children: [
                SettingsTile(
                  icon: Icons.description_outlined,
                  title: LegalPages.terms.title,
                  onTap: () => _openPage(context, LegalPages.terms),
                ),
                SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: LegalPages.privacy.title,
                  onTap: () => _openPage(context, LegalPages.privacy),
                ),
                SettingsTile(
                  icon: Icons.dataset_outlined,
                  title: LegalPages.dataSources.title,
                  onTap: () => _openPage(context, LegalPages.dataSources),
                ),
                SettingsTile(
                  icon: Icons.auto_awesome_outlined,
                  title: LegalPages.aiDisclaimer.title,
                  onTap: () => _openPage(context, LegalPages.aiDisclaimer),
                ),
                SettingsTile(
                  icon: Icons.code,
                  title: 'Giấy phép mã nguồn mở',
                  onTap: () => showLicensePage(context: context, applicationName: 'Fluw'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
