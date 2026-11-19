import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/session.dart';
import '../theme.dart';
import '../ui.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, required this.session});

  final CustomerSession session;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  List<Map<String, dynamic>>? _tickets;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = listOfMaps(await ApiClient(widget.session).get('/tickets'));
      if (mounted) {
        setState(() {
          _tickets = data;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _newTicket() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _NewTicketScreen(session: widget.session),
      ),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTicket,
        icon: const Icon(Icons.add),
        label: const Text('New ticket'),
      ),
      body: _error != null && _tickets == null
          ? ErrorView(message: _error!, onRetry: _load)
          : _tickets == null
          ? const Center(child: CircularProgressIndicator())
          : _tickets!.isEmpty
          ? const EmptyState(
              icon: Icons.support_agent,
              title: 'No support tickets',
              message: 'Need help? Create a ticket and our team will respond.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 90),
                itemCount: _tickets!.length,
                itemBuilder: (_, index) {
                  final ticket = _tickets![index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        title: Text(
                          '${ticket['subject']}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${ticket['number']} · ${shortDate(ticket['created_at'])}',
                        ),
                        trailing: StatusPill('${ticket['status']}'),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _TicketDetailScreen(
                                session: widget.session,
                                id: ticket['id'] as int,
                              ),
                            ),
                          );
                          _load();
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _NewTicketScreen extends StatefulWidget {
  const _NewTicketScreen({required this.session});

  final CustomerSession session;

  @override
  State<_NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<_NewTicketScreen> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  String _priority = 'normal';
  bool _busy = false;

  Future<void> _submit() async {
    if (_subject.text.trim().isEmpty || _body.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ApiClient(widget.session).post('/tickets', {
        'subject': _subject.text.trim(),
        'priority': _priority,
        'body': _body.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New support ticket')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 13),
          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Low')),
              DropdownMenuItem(value: 'normal', child: Text('Normal')),
              DropdownMenuItem(value: 'high', child: Text('High')),
              DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
            ],
            onChanged: (value) => _priority = value ?? 'normal',
          ),
          const SizedBox(height: 13),
          TextField(
            controller: _body,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'How can we help?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Submitting...' : 'Submit ticket'),
          ),
        ],
      ),
    );
  }
}

class _TicketDetailScreen extends StatefulWidget {
  const _TicketDetailScreen({required this.session, required this.id});

  final CustomerSession session;
  final int id;

  @override
  State<_TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<_TicketDetailScreen> {
  final _reply = TextEditingController();
  Map<String, dynamic>? _ticket;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = mapOf(
        await ApiClient(widget.session).get('/tickets/${widget.id}'),
      );
      if (mounted) {
        setState(() {
          _ticket = data;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _send() async {
    if (_reply.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final data = mapOf(
        await ApiClient(
          widget.session,
        ).post('/tickets/${widget.id}/comments', {'body': _reply.text.trim()}),
      );
      _reply.clear();
      if (mounted) setState(() => _ticket = data);
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final closed = ['closed', 'resolved'].contains(_ticket?['status']);
    return Scaffold(
      appBar: AppBar(title: Text(_ticket?['number']?.toString() ?? 'Ticket')),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _ticket == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_ticket!['subject']}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          StatusPill('${_ticket!['status']}'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...listOfMaps(_ticket!['comments']).map((comment) {
                        final mine = comment['author_type'] == 'customer_user';
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 310),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: mine ? AppColors.green : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: mine
                                  ? null
                                  : Border.all(color: AppColors.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${comment['author']}',
                                  style: TextStyle(
                                    color: mine
                                        ? AppColors.lime
                                        : AppColors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${comment['body']}',
                                  style: TextStyle(
                                    color: mine ? Colors.white : AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  shortDate(comment['created_at']),
                                  style: TextStyle(
                                    color: mine
                                        ? Colors.white70
                                        : AppColors.muted,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                if (!closed)
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _reply,
                              decoration: const InputDecoration(
                                hintText: 'Write a reply...',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _busy ? null : _send,
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
