import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_client.dart';
import '../widgets/record_form_utils.dart';

class AddNewSipScreen extends StatefulWidget {
  const AddNewSipScreen({
    super.key,
    required this.apiClient,
    required this.userId,
    required this.onSaved,
  });

  final ApiClient apiClient;
  final String userId;
  final VoidCallback onSaved;

  @override
  State<AddNewSipScreen> createState() => _AddNewSipScreenState();
}

class _AddNewSipScreenState extends State<AddNewSipScreen> {
  final _formKey = GlobalKey<FormState>();
  String _drinkType = 'coffee';
  String? _sugarLevel;
  String? _moodTag;
  final _brand = TextEditingController();
  final _product = TextEditingController();
  final _sizeMl = TextEditingController(text: '350');
  final _price = TextEditingController();
  final _note = TextEditingController();
  int _cups = 1;
  bool _saving = false;

  @override
  void dispose() {
    _brand.dispose();
    _product.dispose();
    _sizeMl.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.apiClient.createRecord({
        'user_id': widget.userId,
        'drink_type': _drinkType,
        'brand': _brand.text.trim(),
        'product_name': _product.text.trim(),
        'size_ml': int.tryParse(_sizeMl.text),
        'sugar_level': _sugarLevel,
        'cups': _cups,
        'unit_price': double.tryParse(_price.text),
        'total_price': (double.tryParse(_price.text) ?? 0) * _cups,
        'consumed_at': DateTime.now().toIso8601String(),
        'note': composeNote(_moodTag, _note.text),
        'source': 'manual',
      });
      widget.onSaved();
      _brand.clear();
      _product.clear();
      _price.clear();
      _note.clear();
      setState(() {
        _drinkType = 'coffee';
        _sugarLevel = null;
        _moodTag = null;
        _cups = 1;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存记录')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('新增记录', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: Column(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'coffee', icon: Icon(Icons.local_cafe), label: Text('咖啡')),
                  ButtonSegment(value: 'milk_tea', icon: Icon(Icons.emoji_food_beverage), label: Text('奶茶')),
                ],
                selected: {_drinkType},
                onSelectionChanged: (v) => setState(() => _drinkType = v.first),
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _brand, decoration: const InputDecoration(labelText: '品牌名称')),
              const SizedBox(height: 12),
              TextFormField(controller: _product, decoration: const InputDecoration(labelText: '饮品名称')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _sugarLevel,
                decoration: const InputDecoration(labelText: '甜度'),
                items: sugarOptions
                    .map((item) => DropdownMenuItem<String?>(value: item['value'], child: Text(item['label']!)))
                    .toList(),
                onChanged: (value) => setState(() => _sugarLevel = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sizeMl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '容量(ml)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: '单价(¥)'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return '请输入价格';
                        if (double.tryParse(v) == null) return '请输入数字';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  estimateCalories(
                    sugarLevel: _sugarLevel,
                    sizeMl: int.tryParse(_sizeMl.text),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('数量'),
                  IconButton(
                    onPressed: _cups > 1 ? () => setState(() => _cups--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_cups'),
                  IconButton(
                    onPressed: () => setState(() => _cups++),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: moodOptions
                    .map((mood) => ChoiceChip(
                          label: Text(mood),
                          selected: _moodTag == mood,
                          onSelected: (_) => setState(() => _moodTag = mood),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '备注 / 心情补充'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? '保存中...' : '保存记录'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
