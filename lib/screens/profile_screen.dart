import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Config'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserInfo(context),
            const Divider(height: 32),
            _buildExportSection(context),
            const Divider(height: 32),
            _buildRemoteConfigSection(context),
            const Divider(height: 32),
            _buildCrashlyticsSection(context),
            const Divider(height: 32),
            _buildNotificationCenter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;

    if (user == null) return const SizedBox.shrink();

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
          child: user.photoURL == null ? const Icon(Icons.person, size: 40) : null,
        ),
        const SizedBox(height: 12),
        Text(
          user.displayName ?? 'Unknown User',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(user.email ?? '', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            await context.read<ProfileViewModel>().logLogout();
            if (context.mounted) {
              await context.read<AuthViewModel>().signOut();
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildExportSection(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Report Export',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (viewModel.isExporting)
          const Center(child: CircularProgressIndicator())
        else
          ElevatedButton.icon(
            onPressed: () => viewModel.exportDashboardAsPdf(),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export Dashboard as PDF'),
          ),
        if (viewModel.exportError.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            viewModel.exportError,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (viewModel.exportUrl.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Export successful!',
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: viewModel.exportUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRemoteConfigSection(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Remote Config',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => viewModel.refreshRemoteConfig(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('Max Journals Displayed'),
          trailing: Text(
            '${viewModel.maxJournalsDisplayed}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('Max Keywords Displayed'),
          trailing: Text(
            '${viewModel.maxKeywordsDisplayed}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ],
    );
  }

  Widget _buildCrashlyticsSection(BuildContext context) {
    final viewModel = context.read<ProfileViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Crashlytics Demo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () {
                viewModel.triggerHandledException();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Handled exception recorded!')),
                );
              },
              child: const Text('Trigger Handled Exception'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => viewModel.triggerTestCrash(),
              child: const Text('Trigger Test Crash'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationCenter(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Center',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (viewModel.notifications.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No new notifications')),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: viewModel.notifications.length,
            itemBuilder: (context, index) {
              final message = viewModel.notifications[index];
              final sentTime = message.sentTime ?? DateTime.now();
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_active, color: Colors.amber),
                  title: Text(message.notification?.title ?? 'New Message'),
                  subtitle: Text(message.notification?.body ?? 'No content'),
                  trailing: Text(
                    '${sentTime.hour}:${sentTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
