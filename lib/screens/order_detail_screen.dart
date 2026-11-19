import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/session.dart';
import '../theme.dart';
import '../ui.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.session,
    required this.orderId,
  });

  final CustomerSession session;
  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  String? _error;
  bool _repeating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = mapOf(
        await ApiClient(widget.session).get('/orders/${widget.orderId}'),
      );
      if (mounted) setState(() => _order = data);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _repeat() async {
    setState(() => _repeating = true);
    try {
      final order = mapOf(
        await ApiClient(
          widget.session,
        ).post('/orders/${widget.orderId}/repeat'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Repeat order ${order['number']} placed.')),
        );
      }
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _repeating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_order?['number']?.toString() ?? 'Order')),
      body: _error != null && _order == null
          ? ErrorView(message: _error!, onRetry: _load)
          : _order == null
          ? const Center(child: CircularProgressIndicator())
          : _content(),
    );
  }

  Widget _content() {
    final order = _order!;
    final items = listOfMaps(order['items']);
    final shipments = listOfMaps(order['shipments']);
    final totals = mapOf(order['totals']);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${order['number']}',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StatusPill('${order['status']}'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Placed ${shortDate(order['order_date'])}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const Divider(height: 30),
                _row('Order total', money(order['total']), strong: true),
                _row('Ordered quantity', '${totals['ordered'] ?? 0}'),
                _row('Shipped quantity', '${totals['shipped'] ?? 0}'),
                _row('Delivered quantity', '${totals['delivered'] ?? 0}'),
              ],
            ),
          ),
        ),
        if (shipments.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text(
            'Delivery tracking',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...shipments.map(
            (shipment) => Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppColors.mint,
                      child: Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${shipment['number']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              StatusPill('${shipment['status']}'),
                            ],
                          ),
                          if (shipment['carrier'] != null)
                            Text('${shipment['carrier']}'),
                          if (shipment['tracking_number'] != null)
                            Text(
                              'Tracking: ${shipment['tracking_number']}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        const Text(
          'Items',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                title: Text(
                  '${item['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${item['sku']} · ${item['ordered_qty']} ${item['unit']}',
                ),
                trailing: Text(
                  money(
                    (double.tryParse('${item['ordered_qty']}') ?? 0) *
                        (double.tryParse('${item['unit_price']}') ?? 0),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _repeating ? null : _repeat,
          icon: const Icon(Icons.replay),
          label: Text(_repeating ? 'Placing order...' : 'Repeat this order'),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              fontSize: strong ? 17 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
