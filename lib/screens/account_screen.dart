import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/session.dart';
import '../theme.dart';
import 'invoices_screen.dart';
import 'support_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, required this.session});

  final CustomerSession session;

  Future<void> _logout(BuildContext context) async {
    try {
      await ApiClient(session).post('/auth/logout');
    } catch (_) {
      // Local sign-out must remain available when the server is unreachable.
    }
    await session.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 29,
                backgroundColor: AppColors.green,
                child: Text(
                  session.name.isEmpty ? 'C' : session.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      session.customerName,
                      style: const TextStyle(color: AppColors.green),
                    ),
                    Text(
                      session.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Account activity',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _AccountTile(
                icon: Icons.description_outlined,
                title: 'Invoices',
                subtitle: 'Invoices, due dates and outstanding',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        InvoicesScreen(session: session, initialTab: 0),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 66),
              _AccountTile(
                icon: Icons.payments_outlined,
                title: 'Payments',
                subtitle: 'Receipts and invoice allocations',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        InvoicesScreen(session: session, initialTab: 1),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 66),
              _AccountTile(
                icon: Icons.support_agent,
                title: 'Help & support',
                subtitle: 'Raise and follow support tickets',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SupportScreen(session: session),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Connection',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Server',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                Text(
                  session.baseUrl,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Company code',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                Text(
                  session.tenant.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: AppColors.green),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
