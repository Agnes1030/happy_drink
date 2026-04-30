import 'dart:io';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../widgets/record_form_utils.dart';

class ParseConfirmationScreen extends StatefulWidget {
  const ParseConfirmationScreen({
    super.key,
    required this.apiClient,
    required this.userId,
    required this.parsePayload,
    required this.onSaved,
  });

  final ApiClient apiClient;
  final String userId;
  final Map<String, dynamic> parsePayload;
  final VoidCallback onSaved;

  @override
  State<ParseConfirmationScreen> createState() => _ParseConfirmationScreenState();
}

class _ParseConfirmationScreenState extends State<ParseConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _drinkType;
  late TextEditingController _brand;
  late TextEditingController _product;
  late TextEditingController _sizeMl;
  late TextEditingController _price;
  late TextEditingController _note;
  late TextEditingController _time;
  String? _sugarLevel;
  String? _moodTag;
  bool _saving = false;

  Map<String, dynamic> get _draft => widget.parsePayload['draft'] as Map<String, dynamic>;

  @override
  void initState() {
    super.initState();
    _drinkType = (_draft['drink_type'] ?? 'other').toString();
    _brand = TextEditingController(text: (_draft['brand'] ?? '').toString());
    _product = TextEditingController(text: (_draft['product_name'] ?? '').toString());
    _sizeMl = TextEditingController(text: (_draft['size_ml'] ?? '').toString());
    _price = TextEditingController(text: (_draft['total_price'] ?? _draft['unit_price'] ?? '').toString());
    _note = TextEditingController();
    _time = TextEditingController(text: (_draft['consumed_at'] ?? DateTime.now().toIso8601String()).toString());
    _sugarLevel = _draft['sugar_level']?.toString();
  }

  @override
  void dispose() {
    _brand.dispose();
    _product.dispose();
    _sizeMl.dispose();
    _price.dispose();
    _note.dispose();
    _time.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.apiClient.confirmPhotoRecord({
        'user_id': widget.userId,
        'parse_job_id': widget.parsePayload['parse_job_id'],
        'drink_type': _drinkType,
        'brand': _brand.text.trim(),
        'product_name': _product.text.trim(),
        'size_ml': int.tryParse(_sizeMl.text),
        'sugar_level': _sugarLevel,
        'cups': 1,
        'unit_price': double.tryParse(_price.text),
        'total_price': double.tryParse(_price.text),
        'consumed_at': DateTime.tryParse(_time.text)?.toIso8601String() ?? DateTime.now().toIso8601String(),
        'note': _note.text.trim(),
        'mood_tag': _moodTag,
        'image_url': widget.parsePayload['image_url'],
        'parse_confidence': widget.parsePayload['confidence'],
      });
      widget.onSaved();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存识别记录')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('确认识别结果')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.parsePayload['image_url'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(widget.parsePayload['image_url'].toString()), height: 180, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          Text('识别置信度：${widget.parsePayload['confidence']}'),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'coffee', icon: Icon(Icons.local_cafe), label: Text('咖啡')),
                    ButtonSegment(value: 'milk_tea', icon: Icon(Icons.emoji_food_beverage), label: Text('奶茶')),
                    ButtonSegment(value: 'other', icon: Icon(Icons.local_drink), label: Text('其他')),
                  ],
                  selected: {_drinkType},
                  onSelectionChanged: (values) => setState(() => _drinkType = values.first),
                ),
                const SizedBox(height: 16),
                TextFormField(controller: _brand, decoration: const InputDecoration(labelText: '品牌')),
                const SizedBox(height: 12),
                TextFormField(controller: _product, decoration: const InputDecoration(labelText: '饮品名称')),
                const SizedBox(height: 12),
                TextFormField(controller: _sizeMl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '容量(ml)')),
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
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: '价格(¥)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return '请输入价格';
                    if (double.tryParse(value) == null) return '请输入数字';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(controller: _time, decoration: const InputDecoration(labelText: '饮用时间 ISO 字符串')),
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
                  decoration: InputDecoration(
                    labelText: '备注',
                    helperText: estimateCalories(
                      sugarLevel: _sugarLevel,
                      sizeMl: int.tryParse(_sizeMl.text),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? '保存中...' : '确认并保存'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('OCR 原文', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text((widget.parsePayload['raw_text'] ?? '').toString()),
        ],
      ),
    );
  }
}
