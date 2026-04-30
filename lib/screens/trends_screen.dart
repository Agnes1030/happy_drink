import 'package:flutter/material.dart';

import '../services/api_client.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({
    super.key,
    required this.apiClient,
    required this.userId,
    required this.refreshSignal,
  });

  final ApiClient apiClient;
  final String userId;
  final int refreshSignal;

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  static const _weekdayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  String _range = '7d';
  List<dynamic> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TrendsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.apiClient.getRecords(
        userId: widget.userId,
        limit: 200,
      );
      setState(() {
        _items = data['items'] as List<dynamic>? ?? const [];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    final now = DateTime.now();
    final days = _range == '30d' ? 30 : 7;
    final start = now.subtract(Duration(days: days - 1));
    return _items
        .cast<Map<String, dynamic>>()
        .where((item) {
          final consumedAt = DateTime.tryParse(item['consumed_at']?.toString() ?? '');
          return consumedAt != null && !consumedAt.isBefore(DateTime(start.year, start.month, start.day));
        })
        .toList();
  }

  List<_BarDatum> get _barData {
    final now = DateTime.now();
    final days = _range == '30d' ? 30 : 7;
    final filtered = _filteredItems;
    final counts = <DateTime, int>{};
    for (var i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1 - i));
      counts[date] = 0;
    }
    for (final item in filtered) {
      final consumedAt = DateTime.tryParse(item['consumed_at']?.toString() ?? '');
      final cups = item['cups'] is num ? (item['cups'] as num).toInt() : 0;
      if (consumedAt == null) continue;
      final key = DateTime(consumedAt.year, consumedAt.month, consumedAt.day);
      if (counts.containsKey(key)) {
        counts[key] = counts[key]! + cups;
      }
    }
    return counts.entries.map((entry) {
      final date = entry.key;
      final label = _range == '7d'
          ? _weekdayLabels[date.weekday - 1]
          : '${date.month}/${date.day}';
      return _BarDatum(date: date, label: label, value: entry.value);
    }).toList();
  }

  List<_AxisTick> get _yAxisTicks {
    final maxValue = _barData.fold<int>(1, (max, item) => item.value > max ? item.value : max);
    final step = maxValue <= 4 ? 1 : (maxValue / 4).ceil();
    return [
      for (int value = step * 4; value >= 0; value -= step)
        _AxisTick(value: value, ratio: maxValue == 0 ? 0 : value / (step * 4)),
    ];
  }

  int get _milkTeaCount => _filteredItems.where((item) => item['drink_type'] == 'milk_tea').length;
  int get _coffeeCount => _filteredItems.where((item) => item['drink_type'] == 'coffee').length;
  double get _totalSpending => _filteredItems.fold<double>(0, (sum, item) {
        final value = item['total_price'] ?? item['unit_price'] ?? 0;
        return sum + (value is num ? value.toDouble() : 0);
      });
  double get _averagePrice => _filteredItems.isEmpty ? 0 : _totalSpending / _filteredItems.length;

  @override
  Widget build(BuildContext context) {
    final bars = _barData;
    final maxValue = bars.fold<int>(1, (max, item) => item.value > max ? item.value : max);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('趋势', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: '7d', label: Text('近7天')),
              ButtonSegment(value: '30d', label: Text('近30天')),
            ],
            selected: {_range},
            onSelectionChanged: (values) => setState(() => _range = values.first),
          ),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          if (!_loading && _error == null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('每日饮用杯数', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 240,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 36,
                            child: Column(
                              children: [
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Stack(
                                        children: _yAxisTicks.map((tick) {
                                          final top = (1 - tick.ratio) * (constraints.maxHeight - 1);
                                          return Positioned(
                                            top: top,
                                            right: 0,
                                            child: Text('${tick.value}', style: Theme.of(context).textTheme.labelSmall),
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 22),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: _range == '30d' ? 820 : null,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return Stack(
                                            children: [
                                              for (final tick in _yAxisTicks)
                                                Positioned(
                                                  top: (1 - tick.ratio) * (constraints.maxHeight - 1),
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(height: 1, color: Theme.of(context).dividerColor),
                                                ),
                                              Positioned(
                                                left: 0,
                                                right: 0,
                                                bottom: 0,
                                                child: Container(height: 1.5, color: Theme.of(context).colorScheme.outline),
                                              ),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: bars.asMap().entries.map((entry) {
                                                  final bar = entry.value;
                                                  final ratio = maxValue == 0 ? 0.0 : bar.value / maxValue;
                                                  return SizedBox(
                                                    width: _range == '30d' ? 26 : 46,
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        Text('${bar.value}', style: Theme.of(context).textTheme.labelSmall),
                                                        const SizedBox(height: 4),
                                                        Container(
                                                          width: _range == '30d' ? 14 : 26,
                                                          height: (constraints.maxHeight - 28) * ratio,
                                                          decoration: BoxDecoration(
                                                            color: Theme.of(context).colorScheme.primary,
                                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: bars.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final bar = entry.value;
                                        final shouldShowLabel = _range == '7d' || index == 0 || index == 9 || index == 19 || index == 29;
                                        return SizedBox(
                                          width: _range == '30d' ? 26 : 46,
                                          child: Text(
                                            shouldShowLabel ? bar.label : '',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.labelSmall,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PreferencePieCard(
                    milkTeaCount: _milkTeaCount,
                    coffeeCount: _coffeeCount,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TrendCard(
                    title: '总花费',
                    value: '¥${_totalSpending.toStringAsFixed(2)}',
                    subtitle: _range == '30d' ? '近30天' : '近7天',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _TrendCard(
              title: '饮品均价',
              value: '¥${_averagePrice.toStringAsFixed(2)}',
              subtitle: _filteredItems.isEmpty ? '暂无记录' : '按 ${_filteredItems.length} 条记录计算',
            ),
          ],
        ],
      ),
    );
  }
}

class _AxisTick {
  const _AxisTick({required this.value, required this.ratio});

  final int value;
  final double ratio;
}

class _PreferencePieCard extends StatelessWidget {
  const _PreferencePieCard({required this.milkTeaCount, required this.coffeeCount});

  final int milkTeaCount;
  final int coffeeCount;

  @override
  Widget build(BuildContext context) {
    final total = milkTeaCount + coffeeCount;
    final coffeeRatio = total == 0 ? 0.5 : coffeeCount / total;
    final milkTeaRatio = total == 0 ? 0.5 : milkTeaCount / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('饮品偏好', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 12),
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    coffeeRatio: coffeeRatio,
                    coffeeColor: Theme.of(context).colorScheme.primary,
                    milkTeaColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _LegendRow(
              color: Theme.of(context).colorScheme.primary,
              label: '咖啡',
              value: total == 0 ? '0%' : '${(coffeeRatio * 100).round()}%',
            ),
            const SizedBox(height: 6),
            _LegendRow(
              color: Theme.of(context).colorScheme.secondary,
              label: '奶茶',
              value: total == 0 ? '0%' : '${(milkTeaRatio * 100).round()}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _PieChartPainter extends CustomPainter {
  const _PieChartPainter({
    required this.coffeeRatio,
    required this.coffeeColor,
    required this.milkTeaColor,
  });

  final double coffeeRatio;
  final Color coffeeColor;
  final Color milkTeaColor;

  @override
  void paint(Canvas canvas, Size size) {
    const startAngle = -1.5708;
    final rect = Offset.zero & size;
    final coffeeSweep = 6.28318 * coffeeRatio;
    final milkTeaSweep = 6.28318 - coffeeSweep;

    final coffeePaint = Paint()..color = coffeeColor;
    final milkTeaPaint = Paint()..color = milkTeaColor;
    final holePaint = Paint()..color = Colors.white;

    canvas.drawArc(rect, startAngle, coffeeSweep, true, coffeePaint);
    canvas.drawArc(rect, startAngle + coffeeSweep, milkTeaSweep, true, milkTeaPaint);
    canvas.drawCircle(size.center(Offset.zero), size.width * 0.26, holePaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.coffeeRatio != coffeeRatio ||
        oldDelegate.coffeeColor != coffeeColor ||
        oldDelegate.milkTeaColor != milkTeaColor;
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.title, required this.value, this.subtitle});

  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: Theme.of(context).textTheme.labelSmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarDatum {
  const _BarDatum({required this.date, required this.label, required this.value});

  final DateTime date;
  final String label;
  final int value;
}
