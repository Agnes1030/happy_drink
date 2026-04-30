import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import 'parse_confirmation_screen.dart';

class PhotoParseScreen extends StatefulWidget {
  const PhotoParseScreen({
    super.key,
    required this.apiClient,
    required this.userId,
    required this.onSaved,
  });

  final ApiClient apiClient;
  final String userId;
  final VoidCallback onSaved;

  @override
  State<PhotoParseScreen> createState() => _PhotoParseScreenState();
}

class _PhotoParseScreenState extends State<PhotoParseScreen> {
  final _picker = ImagePicker();
  bool _loading = false;

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() => _loading = true);
    try {
      final payload = await widget.apiClient.parseRecordPhoto(
        userId: widget.userId,
        imageFile: File(picked.path),
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ParseConfirmationScreen(
            apiClient: widget.apiClient,
            userId: widget.userId,
            parsePayload: payload,
            onSaved: widget.onSaved,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('识别失败: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('拍照扫描')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('从相册或相机选择图片，系统会自动 OCR 识别并让你确认结果。'),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loading ? null : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('从相册选择'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _loading ? null : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('拍照识别'),
            ),
            if (_loading) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('正在上传并识别图片...'),
            ],
          ],
        ),
      ),
    );
  }
}
