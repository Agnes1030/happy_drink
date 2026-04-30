import 'package:flutter/material.dart';

import '../services/api_client.dart';

class DrinkHistoryScreen extends StatefulWidget {
  const DrinkHistoryScreen({
    super.key,
    required this.apiClient,
    required this.userId,
    required this.refreshSignal,
  });

  final ApiClient apiClient;
  final String userId;
  final int refreshSignal;

  @override
  State<DrinkHistoryScreen> createState() => _DrinkHistoryScreenState();
}

class _DrinkHistoryScreenState extends State<DrinkHistoryScreen> {
  String? _drinkType;
  final _brand = TextEditingController();
  List<dynamic> _items = const [];
  int _total = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant DrinkHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _load();
    }
  }

  @override
  void dispose() {
    _brand.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.apiClient.getRecords(
        userId: widget.userId,
        drinkType: _drinkType,
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        limit: 50,
      );
      setState(() {
        _items = data['items'] as List<dynamic>? ?? const [];
        _total = data['total'] as int? ?? 0;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('记录', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: _brand,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: '按品牌筛选'),
                onSubmitted: (_) => _load(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('全部'),
                    selected: _drinkType == null,
                    onSelected: (_) {
                      setState(() => _drinkType = null);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('咖啡'),
                    selected: _drinkType == 'coffee',
                    onSelected: (_) {
                      setState(() => _drinkType = 'coffee');
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('奶茶'),
                    selected: _drinkType == 'milk_tea',
                    onSelected: (_) {
                      setState(() => _drinkType = 'milk_tea');
                      _load();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('共 $_total 条记录', style: Theme.of(context).textTheme.labelMedium),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final item = _items[i] as Map<String, dynamic>;
                final price = item['total_price'] ?? item['unit_price'] ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(item['drink_type'] == 'milk_tea' ? '奶' : '咖'),
                    ),
                    title: Text(item['product_name']?.toString().isNotEmpty == true
                        ? item['product_name'].toString()
                        : '未命名饮品'),
                    subtitle: Text('${item['brand'] ?? '未知品牌'} · ${item['consumed_at'] ?? ''}'),
                    trailing: Text('¥$price'),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
