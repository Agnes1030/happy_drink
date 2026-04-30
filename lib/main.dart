import 'dart:io';

import 'package:flutter/material.dart';

import 'services/api_client.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

void main() {
  runApp(const SipTrackApp());
}

class SipTrackApp extends StatelessWidget {
  const SipTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    const userId = '00000000-0000-0000-0000-000000000001';
    final baseUrl = Platform.isIOS ? 'http://localhost:8000' : 'http://127.0.0.1:8000';
    final apiClient = ApiClient(baseUrl: baseUrl);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SipTrack',
      theme: AppTheme.light(),
      home: AppShell(apiClient: apiClient, userId: userId),
    );
  }
}
