import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/session.dart';
import '../theme.dart';
import '../ui.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key, required this.session, this.initialTab = 0});

  final CustomerSession session;
  final int initialTab;

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Invoices'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _InvoiceList(session: widget.session),
          _PaymentList(session: widget.session),
        ],
      ),
    );
  }
}

class _InvoiceList extends StatefulWidget {
  const _InvoiceList({required this.session});

  final CustomerSession session;

  @override
  State<_InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<_InvoiceList> {
  List<Map<String, dynamic>>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = listOfMaps(await ApiClient(widget.session).get('/invoices'));
      if (mounted) {
        setState(() {
          _items = data;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items == null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_items == null) return const Center(child: CircularProgressIndicator());
    if (_items!.isEmpty) {
      return const EmptyState(
        icon: Icons.description_outlined,
        title: 'No invoices',
        message: 'Issued invoices will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: _items!.length,
        itemBuilder: (_, index) {
          final invoice = _items![index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                title: Text(
                  '${invoice['number']}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  'Due ${shortDate(invoice['due_at'])}\nOutstanding ${money(invoice['outstanding_amount'])}',
                ),
                isThreeLine: true,
                trailing: StatusPill('${invoice['status']}'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _InvoiceDetail(
                      session: widget.session,
                      id: invoice['id'] as int,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceDetail extends StatefulWidget {
  const _InvoiceDetail({required this.session, required this.id});

  final CustomerSession session;
  final int id;

  @override
  State<_InvoiceDetail> createState() => _InvoiceDetailState();
}

class _InvoiceDetailState extends State<_InvoiceDetail> {
  Map<String, dynamic>? _invoice;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = mapOf(
        await ApiClient(widget.session).get('/invoices/${widget.id}'),
      );
      if (mounted) setState(() => _invoice = data);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_invoice?['number']?.toString() ?? 'Invoice')),
      body: _error != null
          ? ErrorView(message: _error!, onRetry: _load)
          : _invoice == null
          ? const Center(child: CircularProgressIndicator())
          : _content(),
    );
  }

  Widget _content() {
    final invoice = _invoice!;
    final items = listOfMaps(invoice['items']);
    final payments = listOfMaps(invoice['payments']);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${invoice['number']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StatusPill('${invoice['status']}'),
                  ],
                ),
                const Divider(height: 28),
                _amountRow('Subtotal', invoice['subtotal']),
                _amountRow('Tax', invoice['tax']),
                _amountRow('Invoice total', invoice['total'], strong: true),
                _amountRow('Paid', invoice['paid_amount']),
                _amountRow(
                  'Outstanding',
                  invoice['outstanding_amount'],
                  strong: true,
                  color: statusColor('${invoice['status']}'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Invoice items',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        ...items.map(
          (item) => Card(
            child: ListTile(
              title: Text('${item['name']}'),
              subtitle: Text(
                '${item['quantity']} × ${money(item['unit_price'])}',
              ),
              trailing: Text(
                money(item['line_total']),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        if (payments.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text(
            'Payments applied',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 9),
          ...payments.map(
            (payment) => Card(
              child: ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.green,
                ),
                title: Text('${payment['number']}'),
                subtitle: Text(shortDate(payment['received_at'])),
                trailing: Text(money(payment['amount'])),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _amountRow(
    String label,
    dynamic value, {
    bool strong = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(
            money(value),
            style: TextStyle(
              color: color,
              fontSize: strong ? 17 : 14,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentList extends StatefulWidget {
  const _PaymentList({required this.session});

  final CustomerSession session;

  @override
  State<_PaymentList> createState() => _PaymentListState();
}

class _PaymentListState extends State<_PaymentList> {
  List<Map<String, dynamic>>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = listOfMaps(await ApiClient(widget.session).get('/payments'));
      if (mounted) setState(() => _items = data);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items == null) {
      return ErrorView(message: _error!, onRetry: _load);
    }
    if (_items == null) return const Center(child: CircularProgressIndicator());
    if (_items!.isEmpty) {
      return const EmptyState(
        icon: Icons.payments_outlined,
        title: 'No payments',
        message: 'Payment receipts will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: _items!.length,
        itemBuilder: (_, index) {
          final payment = _items![index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.mint,
                  child: Icon(Icons.done, color: AppColors.green),
                ),
                title: Text(
                  '${payment['number']}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${shortDate(payment['received_at'])} · ${payment['method']}',
                ),
                trailing: Text(
                  money(payment['amount']),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
