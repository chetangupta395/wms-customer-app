import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/session.dart';
import '../theme.dart';
import '../ui.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    required this.session,
    required this.onOrderPlaced,
  });

  final CustomerSession session;
  final VoidCallback onOrderPlaced;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Map<String, dynamic>>? _products;
  final Map<int, double> _cart = {};
  String _query = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = listOfMaps(await ApiClient(widget.session).get('/products'));
      if (mounted) setState(() => _products = data);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  int get _cartCount =>
      _cart.values.fold<double>(0, (sum, qty) => sum + qty).round();

  void _add(Map<String, dynamic> product) {
    final id = product['id'] as int;
    setState(() => _cart[id] = (_cart[id] ?? 0) + 1);
  }

  Future<void> _openCart() async {
    final placed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _CartScreen(
          session: widget.session,
          products: _products!
              .where((product) => _cart.containsKey(product['id']))
              .toList(),
          quantities: Map<int, double>.from(_cart),
        ),
      ),
    );
    if (placed == true) {
      setState(() => _cart.clear());
      widget.onOrderPlaced();
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = (_products ?? []).where((product) {
      final haystack =
          '${product['name']} ${product['sku']} ${product['brand']}'
              .toLowerCase();
      return haystack.contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Search products or SKU',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _error != null && _products == null
                ? ErrorView(message: _error!, onRetry: _load)
                : _products == null
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'No products found',
                    message: 'Try another product name or SKU.',
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        0,
                        18,
                        _cart.isEmpty ? 24 : 100,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: .72,
                          ),
                      itemCount: products.length,
                      itemBuilder: (_, index) {
                        final product = products[index];
                        final qty = _cart[product['id']] ?? 0;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 68,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.mint,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: AppColors.green,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${product['sku']}',
                                  style: const TextStyle(
                                    color: AppColors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    '${product['name']}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${money(product['price'])} / ${product['unit'] ?? 'unit'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  height: 38,
                                  child: qty == 0
                                      ? FilledButton.icon(
                                          onPressed: () => _add(product),
                                          icon: const Icon(Icons.add, size: 17),
                                          label: const Text('Add'),
                                        )
                                      : _QtyControl(
                                          qty: qty,
                                          onMinus: () => setState(() {
                                            if (qty <= 1) {
                                              _cart.remove(product['id']);
                                            } else {
                                              _cart[product['id']] = qty - 1;
                                            }
                                          }),
                                          onPlus: () => _add(product),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _cart.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SizedBox(
                width: double.infinity,
                child: FloatingActionButton.extended(
                  onPressed: _openCart,
                  backgroundColor: AppColors.ink,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: Text('View cart · $_cartCount items'),
                ),
              ),
            ),
    );
  }
}

class _CartScreen extends StatefulWidget {
  const _CartScreen({
    required this.session,
    required this.products,
    required this.quantities,
  });

  final CustomerSession session;
  final List<Map<String, dynamic>> products;
  final Map<int, double> quantities;

  @override
  State<_CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<_CartScreen> {
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _notes = TextEditingController();
  bool _busy = false;

  double get _total => widget.products.fold(0, (sum, product) {
    final qty = widget.quantities[product['id']] ?? 0;
    return sum + qty * (double.tryParse('${product['price']}') ?? 0);
  });

  Future<void> _placeOrder() async {
    setState(() => _busy = true);
    try {
      await ApiClient(widget.session).post('/orders', {
        if (_address.text.trim().isNotEmpty)
          'shipping_address': _address.text.trim(),
        if (_city.text.trim().isNotEmpty) 'shipping_city': _city.text.trim(),
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
        'items': widget.products
            .where((product) => (widget.quantities[product['id']] ?? 0) > 0)
            .map(
              (product) => {
                'product_id': product['id'],
                'ordered_qty': widget.quantities[product['id']],
              },
            )
            .toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully.')),
        );
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _address.dispose();
    _city.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review order')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          ...widget.products.map((product) {
            final qty = widget.quantities[product['id']] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.green,
                    ),
                  ),
                  title: Text(
                    '${product['name']}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('$qty × ${money(product['price'])}'),
                  trailing: Text(
                    money(qty * (double.tryParse('${product['price']}') ?? 0)),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 14),
          const Text(
            'Delivery details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Shipping address (optional)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _city,
            decoration: const InputDecoration(labelText: 'City (optional)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Order notes'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimated total',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                    Text(
                      money(_total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: _busy ? null : _placeOrder,
                child: Text(_busy ? 'Placing...' : 'Place order'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  const _QtyControl({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });

  final double qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(onTap: onMinus, child: const Icon(Icons.remove, size: 18)),
          Text(
            '${qty.toInt()}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          InkWell(onTap: onPlus, child: const Icon(Icons.add, size: 18)),
        ],
      ),
    );
  }
}
